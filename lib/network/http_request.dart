import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:profit_from_it_investors/ui/authentication/login_screen/login_screen.dart';
import 'package:profit_from_it_investors/utility/common.dart';
import 'package:profit_from_it_investors/utility/constant.dart';
import 'package:profit_from_it_investors/utility/local_storage.dart';
import 'package:profit_from_it_investors/utility/network_helper.dart';
import 'package:profit_from_it_investors/utility/session_manager.dart';

Future<Response?> httpGet(String url, {Map<String, String> headers = const {}}) async {
  debugPrint("http get request url ===================> $url");
  if (!await NetworkCheck.isOnline()) {
    debugPrint("❌ No Internet Connection");
    // Common.showToast("No internet connection. Please check your network.");
    throw const SocketException("No internet connection");
  }

  if (headers.isEmpty) {
    String token = await LocalStorage.getAccessToken();
    String userId = SessionManager.userId;
    headers = {
      if (token != "") ...{"Authorization": "Bearer $token"},
      if (userId.isNotEmpty) "user-id": userId,
      "Content-Type": "application/json",
      'Accept': 'application/json',
    };
  }
  debugPrint("http get request url ===================> ${headers.toString()}");
  var request = http.Request('GET', Uri.parse("${Constants.apiUrl}$url"));

  request.headers.addAll(headers);
  http.StreamedResponse response = await request.send();
  http.Response res = http.Response(await response.stream.bytesToString(), response.statusCode);
  debugPrint("http get response $url ===================> ${res.body}");
  if (res.statusCode == 401) {
    LocalStorage.clearAll();
    nextRoute(
      MaterialPageRoute(
        builder: (context) {
          return LoginScreen();
        },
      ),
      isClearBackRoutes: true,
    );
    return res;
  } else {
    return res;
  }
}

Future<Response?> httpPost(String url, dynamic body, {Map<String, String> headers = const {}}) async {
  debugPrint("http post request url ===================> $url");
  debugPrint("http post request body ===================> $body");

  if (!await NetworkCheck.isOnline()) {
    debugPrint("❌ No Internet Connection");
    // Common.showToast("No internet connection. Please check your network.");
    throw const SocketException("No internet connection");
  }

  var myBody = json.encode(body);
  var finalURL = "${Constants.apiUrl}$url";
  debugPrint("http post request final url ===================> ${Constants.apiUrl}$url");
  debugPrint("http post request final body ===================> $myBody");
  if (headers.isEmpty) {
    String token = await LocalStorage.getAccessToken();
    String userId = SessionManager.userId;
    headers = {
      if (token != "") ...{"Authorization": "Bearer $token"},
      if (userId.isNotEmpty) "user-id": userId,
      "Content-Type": "application/json",
      'Accept': 'application/json',
    };
  }

  var request = http.Request('POST', Uri.parse(finalURL));

  debugPrint("http post request header ===================> ${headers.toString()}");

  request.body = myBody;
  request.headers.addAll(headers);
  http.StreamedResponse response = await request.send();

  http.Response res = http.Response(await response.stream.bytesToString(), response.statusCode);

  debugPrint("http post response ===================> ${res.body}");

  if (res.statusCode == 401) {
    LocalStorage.clearAll();
    nextRoute(
      MaterialPageRoute(
        builder: (context) {
          return LoginScreen();
        },
      ),
      isClearBackRoutes: true,
    );
    return res;
  } else {
    return res;
  }
}
