import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:profit_from_it_investors/model/whats_new_story.dart';
import 'package:profit_from_it_investors/utility/constant.dart';
import 'package:profit_from_it_investors/utility/local_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Authenticated, admin-managed daily story API.
/// Does not use the legacy release-notes /api/whats-new endpoint.
class WhatsNewStoryService {
  WhatsNewStoryService._();

  static const _timeout = Duration(seconds: 5);
  static final http.Client _client = http.Client();
  static const _seenPrefix = 'daily_whats_new_story_seen_';

  // Development-only override: allows the active story to be previewed on
  // every app launch without changing server-side daily view records.
  // Enable with: flutter run --dart-define=FORCE_WHATS_NEW_STORY=true
  // Never effective in profile or release builds.
  static const bool _forceStoryFlag = bool.fromEnvironment(
    'FORCE_WHATS_NEW_STORY',
    defaultValue: false,
  );
  static bool get _forceStoryForTesting => kDebugMode && _forceStoryFlag;

  static String _istDate() {
    final now = DateTime.now().toUtc().add(
      const Duration(hours: 5, minutes: 30),
    );
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  static Future<bool> _seenLocallyToday(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_seenPrefix$userId') == _istDate();
  }

  static Future<void> _markSeenLocally(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_seenPrefix$userId', _istDate());
  }

  static Future<Map<String, String>?> _headers() async {
    final token = await LocalStorage.getAccessToken();
    final userId = await LocalStorage.getId();
    if (token.isEmpty || userId.isEmpty) return null;
    return {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Cache-Control': 'no-cache',
    };
  }

  static Uri _endpoint(String path) => Uri.parse('${Constants.apiUrl}$path');

  static Map<String, dynamic>? _data(http.Response response) {
    if (response.statusCode != 200) return null;
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) return null;
    final data = decoded['data'];
    return data is Map<String, dynamic> ? data : null;
  }

  /// Fail open: API errors or no eligible story must never block dashboard.
  /// Local IST-day gating also prevents repeat display when view-sync fails.
  static Future<WhatsNewStory?> fetchForToday() async {
    try {
      final userId = await LocalStorage.getId();
      if (userId.isEmpty) return null;
      if (!_forceStoryForTesting && await _seenLocallyToday(userId)) {
        return null;
      }

      final headers = await _headers();
      if (headers == null) return null;

      final response = await _client
          .get(_endpoint('whats-new-stories/active'), headers: headers)
          .timeout(_timeout);
      final data = _data(response);
      if (data == null) return null;

      final story = WhatsNewStory.fromJson(data);
      if (story == null) return null;
      if (story.viewedToday && !_forceStoryForTesting) {
        // The investor might have watched on a second device.
        await _markSeenLocally(userId);
        return null;
      }
      return story;
    } catch (error) {
      debugPrint('[DAILY STORY] Availability check failed: $error');
      return null;
    }
  }

  /// Opening the story counts as a view (including an eventual skip).
  /// Persist the local seen flag first, so a temporary API failure cannot
  /// repeatedly interrupt the investor on the same device that day.
  static Future<void> recordOpened(int storyId) async {
    try {
      final userId = await LocalStorage.getId();
      if (userId.isEmpty) return;
      await _markSeenLocally(userId);
      final headers = await _headers();
      if (headers == null) return;
      final response = await _client
          .post(
            _endpoint('whats-new-stories/$storyId/view'),
            headers: headers,
            body: '{}',
          )
          .timeout(_timeout);
      if (response.statusCode != 200) {
        debugPrint('[DAILY STORY] View sync status: ${response.statusCode}');
      }
    } catch (error) {
      debugPrint('[DAILY STORY] View sync failed: $error');
    }
  }

  /// The server is authoritative for both current like count and user state.
  static Future<({int count, bool liked})?> getLikes(int storyId) async {
    try {
      final headers = await _headers();
      if (headers == null) return null;
      final response = await _client
          .get(_endpoint('whats-new-stories/$storyId/likes'), headers: headers)
          .timeout(_timeout);
      return _parseLikes(_data(response));
    } catch (error) {
      debugPrint('[DAILY STORY] Like refresh failed: $error');
      return null;
    }
  }

  static Future<({int count, bool liked})?> setLike(
    int storyId, {
    required bool liked,
  }) async {
    try {
      final headers = await _headers();
      if (headers == null) return null;
      final uri = _endpoint('whats-new-stories/$storyId/like');
      final response =
          await (liked
                  ? _client.post(uri, headers: headers, body: '{}')
                  : _client.delete(uri, headers: headers))
              .timeout(_timeout);
      return _parseLikes(_data(response));
    } catch (error) {
      debugPrint('[DAILY STORY] Like update failed: $error');
      return null;
    }
  }

  static ({int count, bool liked})? _parseLikes(Map<String, dynamic>? data) {
    if (data == null) return null;
    final count = int.tryParse('${data['likes_count']}');
    if (count == null) return null;
    final value = data['is_liked'];
    return (
      count: count < 0 ? 0 : count,
      liked: value == true || value == 1 || value == '1',
    );
  }
}
