import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:profit_from_it_investors/ui/authentication/login_screen/login_screen.dart';
import 'package:profit_from_it_investors/utility/common.dart';
import 'package:profit_from_it_investors/utility/constant.dart';
import 'package:profit_from_it_investors/utility/local_storage.dart';

import 'package:profit_from_it_investors/utility/session_manager.dart';

// Reuse one client so TCP/TLS connections can be kept alive between requests.
// Do not run a separate google.com DNS lookup before every API request. The API
// request itself is the authoritative connectivity test.
final http.Client _httpClient = http.Client();

const Duration _requestTimeout = Duration(seconds: 30);

Future<Map<String, String>> _buildHeaders(Map<String, String> headers) async {
  if (headers.isNotEmpty) return headers;

  final token = await LocalStorage.getAccessToken();
  final userId = SessionManager.userId;

  return {
    if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    if (userId.isNotEmpty) 'user-id': userId,
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
}

Future<Response?> httpGet(
  String url, {
  Map<String, String> headers = const {},
}) async {
  final totalWatch = Stopwatch()..start();
  final uri = Uri.parse('${Constants.apiUrl}$url');

  try {
    final finalHeaders = await _buildHeaders(headers);
    final request = http.Request('GET', uri)..headers.addAll(finalHeaders);

    final networkWatch = Stopwatch()..start();
    final streamedResponse = await _httpClient
        .send(request)
        .timeout(_requestTimeout);
    final headersMs = networkWatch.elapsedMilliseconds;

    final bodyWatch = Stopwatch()..start();
    final body = await streamedResponse.stream.bytesToString();
    final bodyMs = bodyWatch.elapsedMilliseconds;

    final res = http.Response(
      body,
      streamedResponse.statusCode,
      headers: streamedResponse.headers,
      request: streamedResponse.request,
      isRedirect: streamedResponse.isRedirect,
      persistentConnection: streamedResponse.persistentConnection,
      reasonPhrase: streamedResponse.reasonPhrase,
    );

    debugPrint(
      '[HTTP PERF] GET $url | status=${res.statusCode} '
      '| headers=${headersMs}ms | body=${bodyMs}ms '
      '| total=${totalWatch.elapsedMilliseconds}ms | bytes=${body.length}',
    );

    if (res.statusCode == 401) {
      await LocalStorage.clearAll();
      nextRoute(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        isClearBackRoutes: true,
      );
    }

    return res;
  } on TimeoutException {
    debugPrint(
      '[HTTP PERF] GET $url timed out after ${totalWatch.elapsedMilliseconds}ms',
    );
    rethrow;
  } on SocketException {
    debugPrint(
      '[HTTP PERF] GET $url socket error after ${totalWatch.elapsedMilliseconds}ms',
    );
    rethrow;
  }
}

Future<Response?> httpPost(
  String url,
  dynamic body, {
  Map<String, String> headers = const {},
}) async {
  final totalWatch = Stopwatch()..start();
  final uri = Uri.parse('${Constants.apiUrl}$url');

  try {
    final finalHeaders = await _buildHeaders(headers);
    final encodedBody = json.encode(body);

    final request = http.Request('POST', uri)
      ..headers.addAll(finalHeaders)
      ..body = encodedBody;

    final networkWatch = Stopwatch()..start();
    final streamedResponse = await _httpClient
        .send(request)
        .timeout(_requestTimeout);
    final headersMs = networkWatch.elapsedMilliseconds;

    final bodyWatch = Stopwatch()..start();
    final responseBody = await streamedResponse.stream.bytesToString();
    final bodyMs = bodyWatch.elapsedMilliseconds;

    final res = http.Response(
      responseBody,
      streamedResponse.statusCode,
      headers: streamedResponse.headers,
      request: streamedResponse.request,
      isRedirect: streamedResponse.isRedirect,
      persistentConnection: streamedResponse.persistentConnection,
      reasonPhrase: streamedResponse.reasonPhrase,
    );

    // Do not print the full JSON response. portfolio-chart-full can be large,
    // and printing it is expensive in debug builds. Never log bearer tokens.
    debugPrint(
      '[HTTP PERF] POST $url | status=${res.statusCode} '
      '| headers=${headersMs}ms | body=${bodyMs}ms '
      '| total=${totalWatch.elapsedMilliseconds}ms | bytes=${responseBody.length}',
    );

    if (res.statusCode == 401) {
      await LocalStorage.clearAll();
      nextRoute(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        isClearBackRoutes: true,
      );
    }

    return res;
  } on TimeoutException {
    debugPrint(
      '[HTTP PERF] POST $url timed out after ${totalWatch.elapsedMilliseconds}ms',
    );
    rethrow;
  } on SocketException {
    debugPrint(
      '[HTTP PERF] POST $url socket error after ${totalWatch.elapsedMilliseconds}ms',
    );
    rethrow;
  }
}
