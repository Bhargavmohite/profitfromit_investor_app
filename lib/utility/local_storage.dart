import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:profit_from_it_investors/model/otp_verification_response.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static Future saveAccessToken(String data) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return await prefs.setString('access_token', data);
  }

  static Future<String> getAccessToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String data = prefs.getString('access_token') ?? '';
    return data;
  }

  static Future saveId(String data) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return await prefs.setString('id', data);
  }

  static Future<String> getId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String data = prefs.getString('id') ?? '';
    return data;
  }

  static Future saveName(String data) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return await prefs.setString('name', data);
  }

  static Future<String> getName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String data = prefs.getString('name') ?? '';
    return data;
  }

  static Future saveProfileImage(String data) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return await prefs.setString('profileImage', data);
  }

  static Future<String> getProfileImage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String data = prefs.getString('profileImage') ?? '';
    return data;
  }

  static Future saveCode(String data) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return await prefs.setString('code', data);
  }

  static Future<String> getCode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String data = prefs.getString('code') ?? '';
    return data;
  }

  static Future saveMobile(String data) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return await prefs.setString('mobile', data);
  }

  static Future<String> getMobile() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String data = prefs.getString('mobile') ?? '';
    return data;
  }

  static Future saveEmail(String data) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return await prefs.setString('email', data);
  }

  static Future<String> getEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String data = prefs.getString('email') ?? '';
    return data;
  }

  /// Save Model to SharedPreferences
  static Future<void> saveOTPResponse(OtpVerificationResponse response) async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonString = jsonEncode(response.toJson());
    await prefs.setString("otp_response", jsonString);
  }

  /// Get Model from SharedPreferences
  static Future<OtpVerificationResponse?> getOTPResponse() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString("otp_response");

    if (jsonString == null || jsonString.isEmpty) {
      return null;
    }

    try {
      final Map<String, dynamic> jsonData = jsonDecode(jsonString);
      return OtpVerificationResponse.fromJson(jsonData);
    } catch (e) {
      debugPrint("Error decoding OtpVerificationResponse: $e");
      return null;
    }
  }

  static Future saveLastFCMUpdate(String data) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return await prefs.setString('last_fcm_update_date', data);
  }

  static Future<String> getLastFCMUpdate() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String data = prefs.getString('last_fcm_update_date') ?? '';
    return data;
  }

  static String _nominationPromptDateKey() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  static Future<bool> wasNominationPromptShownToday(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final lastShown =
        prefs.getString('nomination_prompt_last_shown_$userId') ?? '';
    return lastShown == _nominationPromptDateKey();
  }

  static Future<void> markNominationPromptShownToday(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'nomination_prompt_last_shown_$userId',
      _nominationPromptDateKey(),
    );
  }

  static const String _whatsNewCompletedAppSignatureKey =
      'whats_new_completed_app_signature';

  static Future<void> saveWhatsNewCompletedAppSignature(
    String signature,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_whatsNewCompletedAppSignatureKey, signature);
  }

  static Future<String> getWhatsNewCompletedAppSignature() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_whatsNewCompletedAppSignatureKey) ?? '';
  }

  static Future<bool> hasExistingAppStateForWhatsNew() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getKeys().any(
      (key) => key != _whatsNewCompletedAppSignatureKey,
    );
  }

  /// Remove login/session data while preserving the once-per-day nomination
  /// reminder history. This prevents a same-day logout/login from showing the
  /// reminder twice for the same client.
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();

    final nominationHistory = <String, String>{};
    for (final key in prefs.getKeys()) {
      if (key.startsWith('nomination_prompt_last_shown_')) {
        final value = prefs.getString(key);
        if (value != null) {
          nominationHistory[key] = value;
        }
      }
    }

    // Device-level release state should survive logout/login.
    final whatsNewSignature =
        prefs.getString(_whatsNewCompletedAppSignatureKey) ?? '';

    await prefs.clear();

    for (final entry in nominationHistory.entries) {
      await prefs.setString(entry.key, entry.value);
    }

    if (whatsNewSignature.isNotEmpty) {
      await prefs.setString(
        _whatsNewCompletedAppSignatureKey,
        whatsNewSignature,
      );
    }
  }

  static Future saveRole(String data) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return await prefs.setString('role', data);
  }

  static Future<String> getRole() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String data = prefs.getString('role') ?? '';
    return data;
  }
}
