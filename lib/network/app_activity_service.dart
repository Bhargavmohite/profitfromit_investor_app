import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:profit_from_it_investors/utility/constant.dart';
import 'package:profit_from_it_investors/utility/local_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Optional, best-effort operational telemetry. This class NEVER uses the
/// normal httpPost helper: a monitoring 401/503 must not log out the investor
/// or interfere with normal financial API requests.
///
/// No portfolio amounts, ISINs, screen arguments, OTPs, or user-entered data
/// are transmitted. Only allowlisted screen keys and installation metadata.
class AppActivityService with WidgetsBindingObserver {
  AppActivityService._();

  static final AppActivityService instance = AppActivityService._();

  static void _debugLog(String message) {
    if (kDebugMode) debugPrint('[APP ACTIVITY] $message');
  }

  static const bool enabled = bool.fromEnvironment(
    'ENABLE_APP_ACTIVITY',
    defaultValue: true,
  );
  static const _installationPrefKey = 'app_activity_installation_id';
  static const _timeout = Duration(seconds: 4);
  static const _retryDelay = Duration(seconds: 60);
  static const _heartbeatInterval = Duration(seconds: 30);
  static const _screenPattern = r'^[a-z][a-z0-9_.-]{0,99}$';
  static final _screenRegex = RegExp(_screenPattern);

  final http.Client _client = http.Client();
  Timer? _heartbeatTimer;
  Timer? _screenTimer;
  bool _initialized = false;
  bool _foreground = true;
  bool _starting = false;
  bool _heartbeatBusy = false;
  bool _screenBusy = false;
  String? _sessionUuid;
  String? _activeToken;
  String? _activeUserId;
  String _currentScreen = 'app_launch';
  String? _lastSentScreen;
  DateTime? _retryAfter;
  int _generation = 0;

  void initialize() {
    if (!enabled || !(Platform.isAndroid || Platform.isIOS) || _initialized) {
      return;
    }
    _initialized = true;
    _debugLog(
      'initialized; platform=${Platform.isAndroid ? 'android' : 'ios'}',
    );
    _foreground =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) {
      unawaited(_heartbeat());
    });
    unawaited(_startIfNeeded());
  }

  /// Call only after OTP verification has saved the real authenticated token.
  /// This call intentionally does not await a network response.
  void onAuthenticated() {
    if (!enabled) return;
    initialize();
    _generation++;
    _sessionUuid = null;
    _activeToken = null;
    _activeUserId = null;
    _lastSentScreen = null;
    _retryAfter = null;
    unawaited(_startIfNeeded());
  }

  /// The login token is still available when called. Server session closure
  /// is best-effort; Redis expiry is the fallback if the network is offline.
  void onLoggedOut() {
    final token = _activeToken;
    final sessionUuid = _sessionUuid;
    _generation++;
    _sessionUuid = null;
    _activeToken = null;
    _activeUserId = null;
    _lastSentScreen = null;
    _retryAfter = null;
    _screenTimer?.cancel();
    if (token != null && sessionUuid != null) {
      unawaited(
        _request('state', {
          'session_uuid': sessionUuid,
          'state': 'ended',
        }, token),
      );
    }
  }

  /// Safe screen keys only; details such as a stock ID are never sent.
  void reportScreen(String screenKey) {
    if (!enabled || !_screenRegex.hasMatch(screenKey)) return;
    if (_currentScreen == screenKey && _lastSentScreen == screenKey) return;
    _currentScreen = screenKey;
    _debugLog('current screen: $screenKey');
    _screenTimer?.cancel();
    if (!_foreground) return;

    // Debounce rapid navigation animations to avoid unnecessary DB events.
    _screenTimer = Timer(const Duration(milliseconds: 350), () {
      unawaited(_publishScreen());
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final wasBackground = !_foreground;
      _foreground = true;
      if (wasBackground) {
        unawaited(_resume());
      }
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      if (!_foreground) return;
      _foreground = false;
      _screenTimer?.cancel();
      final uuid = _sessionUuid;
      final token = _activeToken;
      if (uuid != null && token != null) {
        unawaited(
          _request('state', {
            'session_uuid': uuid,
            'state': 'background',
          }, token),
        );
      }
    }
  }

  Future<void> _resume() async {
    final uuid = _sessionUuid;
    final token = _activeToken;
    if (uuid == null || token == null) {
      await _startIfNeeded();
      return;
    }
    final result = await _request('state', {
      'session_uuid': uuid,
      'state': 'foreground',
    }, token);
    if (result?.statusCode == 409) {
      _invalidateSession();
      await _startIfNeeded();
      return;
    }
    if (result?.statusCode == 200) {
      _lastSentScreen = null;
      await _publishScreen();
    }
  }

  Future<void> _startIfNeeded() async {
    if (!enabled || !_initialized || !_foreground || _starting) return;
    if (_sessionUuid != null) return;
    if (_retryAfter != null && DateTime.now().isBefore(_retryAfter!)) return;
    _starting = true;
    final generation = _generation;
    try {
      final token = (await LocalStorage.getAccessToken()).trim();
      final userId = (await LocalStorage.getId()).trim();
      if (token.isEmpty || userId.isEmpty) {
        _debugLog('session start deferred: investor not authenticated');
        return;
      }
      final platform = Platform.isAndroid ? 'android' : 'ios';
      final info = await PackageInfo.fromPlatform();
      final installationId = await _getInstallationId();
      if (generation != _generation || !_foreground) return;
      final startScreen = _currentScreen;

      final result = await _request('start', {
        'installation_id': installationId,
        'platform': platform,
        'app_version': info.version,
        'build_number': info.buildNumber,
        'screen_key': startScreen,
      }, token);
      if (generation != _generation) return;
      if (result?.statusCode != 200) {
        _debugLog(
          'session start failed: HTTP ${result?.statusCode ?? 'network error'}',
        );
        _retryAfter = DateTime.now().add(_retryDelay);
        return;
      }
      final json = jsonDecode(result!.body);
      final data = json is Map<String, dynamic> ? json['data'] : null;
      final sessionUuid = data is Map<String, dynamic>
          ? data['session_uuid']
          : null;
      if (sessionUuid is! String || sessionUuid.isEmpty) {
        _retryAfter = DateTime.now().add(_retryDelay);
        return;
      }
      _sessionUuid = sessionUuid;
      _activeToken = token;
      _activeUserId = userId;
      _lastSentScreen = startScreen;
      _debugLog('start HTTP 200; initial screen: $startScreen');
      _retryAfter = null;
      if (!_foreground) {
        unawaited(
          _request('state', {
            'session_uuid': sessionUuid,
            'state': 'background',
          }, token),
        );
      }
    } catch (error) {
      _debugLog('session start exception: ${error.runtimeType}');
      _retryAfter = DateTime.now().add(_retryDelay);
    } finally {
      _starting = false;
      // A route may have changed while the session was being created.
      if (_sessionUuid != null &&
          _foreground &&
          _lastSentScreen != _currentScreen) {
        unawaited(_publishScreen());
      }
    }
  }

  Future<void> _publishScreen() async {
    if (!_foreground || !_initialized || _screenBusy) return;
    if (_sessionUuid == null) {
      await _startIfNeeded();
      return;
    }
    _screenBusy = true;
    try {
      // Serialize screen changes so a slow older response cannot overwrite
      // the currently visible page on the Laravel side.
      while (_foreground &&
          _sessionUuid != null &&
          _currentScreen != _lastSentScreen) {
        final screen = _currentScreen;
        final uuid = _sessionUuid!;
        final token = _activeToken;
        if (token == null) break;
        final response = await _request('screen', {
          'session_uuid': uuid,
          'screen_key': screen,
        }, token);
        if (uuid != _sessionUuid) break;
        if (response?.statusCode == 200) {
          _lastSentScreen = screen;
          _debugLog('screen HTTP 200: $screen');
        } else if (response?.statusCode == 409) {
          _invalidateSession();
          await _startIfNeeded();
          break;
        } else {
          _debugLog(
            'screen request unsuccessful: $screen, '
            'HTTP ${response?.statusCode ?? 'network error'}',
          );
          // Non-essential monitoring should not retry in a tight loop.
          break;
        }
      }
    } finally {
      _screenBusy = false;
    }
  }

  Future<void> _heartbeat() async {
    if (!_foreground || _heartbeatBusy || !_initialized) return;
    if (_sessionUuid == null) {
      await _startIfNeeded();
      return;
    }
    // Recover a missed screen update on the next heartbeat. Unlike sending a
    // screen request every 30s, this only sends when the current screen differs
    // from the last successfully acknowledged screen.
    if (_currentScreen != _lastSentScreen && !_screenBusy) {
      await _publishScreen();
    }
    final uuid = _sessionUuid!;
    final token = _activeToken;
    if (token == null) return;
    _heartbeatBusy = true;
    try {
      // The normal app client can invalidate an auth token independently.
      // Never keep reporting a signed-out investor as online.
      final currentToken = await LocalStorage.getAccessToken();
      final currentId = await LocalStorage.getId();
      if (currentToken != token || currentId != _activeUserId) {
        onLoggedOut();
        return;
      }
      final response = await _request('heartbeat', {
        'session_uuid': uuid,
      }, token);
      if (uuid == _sessionUuid && response?.statusCode == 409) {
        _invalidateSession();
        await _startIfNeeded();
      }
    } finally {
      _heartbeatBusy = false;
    }
  }

  void _invalidateSession() {
    _sessionUuid = null;
    _activeToken = null;
    _activeUserId = null;
    _lastSentScreen = null;
  }

  Future<http.Response?> _request(
    String endpoint,
    Map<String, dynamic> body,
    String token,
  ) async {
    try {
      // Tracking must never use redirects or the app's global 401 handler.
      final response = await _client
          .post(
            Uri.parse('${Constants.apiUrl}app-activity/$endpoint'),
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(_timeout);
      if (endpoint == 'screen' || response.statusCode != 200) {
        // Status and server message only; never log tokens, investor details,
        // request bodies or full API responses.
        String serverMessage = '';
        if (response.statusCode != 200) {
          try {
            final data = jsonDecode(response.body);
            if (data is Map && data['message'] is String) {
              serverMessage = (data['message'] as String).replaceAll(
                RegExp(r'[\r\n]+'),
                ' ',
              );
              if (serverMessage.length > 160) {
                serverMessage = serverMessage.substring(0, 160);
              }
            }
          } catch (_) {}
        }
        _debugLog(
          '$endpoint HTTP ${response.statusCode}'
          '${serverMessage.isEmpty ? '' : ': $serverMessage'}',
        );
      }
      return response;
    } catch (error) {
      // Network/Redis/monitoring failures must be invisible to investors.
      if (endpoint != 'heartbeat') {
        _debugLog('$endpoint network failure: ${error.runtimeType}');
      }
      return null;
    }
  }

  static Future<String> _getInstallationId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_installationPrefKey);
    if (existing != null && RegExp(r'^[0-9a-f-]{36}$').hasMatch(existing)) {
      return existing;
    }
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40; // RFC 4122 v4
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    final id =
        '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
    await prefs.setString(_installationPrefKey, id);
    return id;
  }
}
