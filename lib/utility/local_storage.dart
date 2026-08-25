

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

  /// Remove all
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
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