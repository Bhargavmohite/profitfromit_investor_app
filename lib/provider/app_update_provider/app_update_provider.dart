import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:profit_from_it_investors/model/app_version_response.dart';
import 'package:profit_from_it_investors/network/http_request.dart';
import 'package:profit_from_it_investors/utility/constant.dart';
import 'package:url_launcher/url_launcher.dart';

enum AppUpdateStatus { unknown, none, optional, mandatory }

class AppUpdateProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _lastError;

  String _installedVersion = '';
  int _installedBuild = 0;

  AppUpdateStatus _updateStatus = AppUpdateStatus.unknown;

  bool get isLoading => _isLoading;
  String? get lastError => _lastError;

  String get installedVersion => _installedVersion;
  int get installedBuild => _installedBuild;

  AppUpdateStatus get updateStatus => _updateStatus;

  bool get hasUpdate =>
      _updateStatus == AppUpdateStatus.optional ||
      _updateStatus == AppUpdateStatus.mandatory;

  bool get isOptionalUpdate => _updateStatus == AppUpdateStatus.optional;

  bool get isMandatoryUpdate => _updateStatus == AppUpdateStatus.mandatory;

  bool get isUpToDate => _updateStatus == AppUpdateStatus.none;

  AppVersionResponse? appVersionResponse;

  AppVersionData? get data => appVersionResponse?.data;

  PlatformUpdateConfig? get androidConfig => data?.android;
  PlatformUpdateConfig? get iosConfig => data?.ios;
  UpdateUiConfig? get uiConfig => data?.ui;

  PlatformUpdateConfig? get currentPlatformConfig {
    if (Platform.isAndroid) {
      return androidConfig;
    }

    if (Platform.isIOS) {
      return iosConfig;
    }

    return null;
  }

  String get storeUrl => currentPlatformConfig?.storeUrl ?? '';

  /// Fetches server update configuration and compares it with
  /// the version/build currently installed on this device.
  ///
  /// This still DOES NOT show any popup and DOES NOT navigate
  /// to the Play Store / App Store. That will be added separately.
  ///
  /// Fail-open behavior:
  /// If the version API fails, the app is NOT blocked.
  Future<bool> checkForUpdate() async {
    try {
      _isLoading = true;
      _lastError = null;
      _updateStatus = AppUpdateStatus.unknown;
      notifyListeners();

      await _loadInstalledAppInfo();

      final apiLoaded = await _fetchAppVersionConfig();

      if (!apiLoaded) {
        // Do not block users because of a temporary API/network issue.
        _updateStatus = AppUpdateStatus.none;
        return false;
      }

      _evaluateUpdateStatus();

      return true;
    } on SocketException {
      _lastError = 'No internet connection.';
      _updateStatus = AppUpdateStatus.none;
      return false;
    } catch (e) {
      debugPrint('app update check error =====> ${e.toString()}');

      _lastError = 'Unable to check for app updates.';
      _updateStatus = AppUpdateStatus.none;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Kept separately so it can still be used elsewhere if needed.
  Future<bool> fetchAppVersion() async {
    try {
      _isLoading = true;
      _lastError = null;
      notifyListeners();

      return await _fetchAppVersionConfig();
    } on SocketException {
      _lastError = 'No internet connection.';
      return false;
    } catch (e) {
      debugPrint('app version api error =====> ${e.toString()}');

      _lastError = 'Unable to check for app updates.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadInstalledAppInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();

    _installedVersion = packageInfo.version.trim();
    _installedBuild = int.tryParse(packageInfo.buildNumber.trim()) ?? 0;
  }

  Future<bool> _fetchAppVersionConfig() async {
    Response? response = await httpGet(CMD.appVersion);

    if (response == null) {
      _lastError = 'No response received from app version service.';
      return false;
    }

    appVersionResponse = appVersionResponseFromJson(response.body);

    if (response.statusCode == 200 &&
        appVersionResponse?.status == 200 &&
        appVersionResponse?.data != null) {
      return true;
    }

    _lastError =
        appVersionResponse?.message ??
        'Unable to load app version configuration.';

    return false;
  }

  void _evaluateUpdateStatus() {
    final config = currentPlatformConfig;

    if (config == null) {
      _updateStatus = AppUpdateStatus.none;
      return;
    }

    final isBelowMinimum = _isInstalledBelowTarget(
      targetVersion: config.minimumVersion,
      targetBuild: config.minimumBuild,
    );

    if (isBelowMinimum) {
      _updateStatus = AppUpdateStatus.mandatory;
      return;
    }

    final isBelowLatest = _isInstalledBelowTarget(
      targetVersion: config.latestVersion,
      targetBuild: config.latestBuild,
    );

    if (isBelowLatest) {
      _updateStatus = AppUpdateStatus.optional;
      return;
    }

    _updateStatus = AppUpdateStatus.none;
  }

  /// Build number is preferred whenever the backend provides one.
  /// This avoids edge cases with version strings.
  ///
  /// Example:
  /// installed 1.0.5+7
  /// target    1.0.6+8
  /// => build 7 < 8 => outdated
  ///
  /// If targetBuild is 0, semantic version comparison is used.
  bool _isInstalledBelowTarget({
    required String targetVersion,
    required int targetBuild,
  }) {
    if (targetBuild > 0 && _installedBuild > 0) {
      return _installedBuild < targetBuild;
    }

    return _compareVersions(_installedVersion, targetVersion) < 0;
  }

  /// Returns:
  /// -1 when current < target
  ///  0 when current == target
  ///  1 when current > target
  int _compareVersions(String current, String target) {
    final currentParts = _normalizeVersion(current);
    final targetParts = _normalizeVersion(target);

    final maxLength = currentParts.length > targetParts.length
        ? currentParts.length
        : targetParts.length;

    for (int i = 0; i < maxLength; i++) {
      final currentValue = i < currentParts.length ? currentParts[i] : 0;

      final targetValue = i < targetParts.length ? targetParts[i] : 0;

      if (currentValue < targetValue) {
        return -1;
      }

      if (currentValue > targetValue) {
        return 1;
      }
    }

    return 0;
  }

  List<int> _normalizeVersion(String version) {
    final cleaned = version
        .trim()
        .split('+')
        .first
        .replaceAll(RegExp(r'[^0-9.]'), '');

    if (cleaned.isEmpty) {
      return const [0, 0, 0];
    }

    return cleaned.split('.').map((part) => int.tryParse(part) ?? 0).toList();
  }

  /// Opens the platform-specific store page in the external
  /// Play Store / App Store application.
  ///
  /// Returns true when the store launch request succeeds.
  Future<bool> openStore() async {
    final url = storeUrl.trim();

    if (url.isEmpty) {
      _lastError = 'App Store link is not available.';
      notifyListeners();
      return false;
    }

    try {
      final uri = Uri.parse(url);

      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        _lastError = 'Unable to open the app store.';
        notifyListeners();
      }

      return launched;
    } catch (e) {
      debugPrint('open app store error =====> ${e.toString()}');

      _lastError = 'Unable to open the app store.';
      notifyListeners();
      return false;
    }
  }

  void clearData() {
    appVersionResponse = null;
    _lastError = null;
    _installedVersion = '';
    _installedBuild = 0;
    _updateStatus = AppUpdateStatus.unknown;
    notifyListeners();
  }
}
