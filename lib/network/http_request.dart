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

Future<Response?> httpMultipartPost(
  String url,
  Map<String, String> fields, {
  String? fileField,
  String? filePath,
  String? fileName,
  List<int>? fileBytes,
  Map<String, String> headers = const {},
}) async {
  final totalWatch = Stopwatch()..start();
  final uri = Uri.parse('${Constants.apiUrl}$url');

  try {
    final finalHeaders = Map<String, String>.from(await _buildHeaders(headers));

    // MultipartRequest must generate its own Content-Type header with boundary.
    finalHeaders.removeWhere((key, _) => key.toLowerCase() == 'content-type');

    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll(finalHeaders)
      ..fields.addAll(fields);

    if (fileField != null && fileName != null) {
      // Prefer the actual picker-created file on disk. Streaming the source
      // file avoids an unnecessary in-memory copy and preserves the exact
      // binary payload for Excel/PDF/image attachments. Picker paths are
      // temporary, but this upload starts immediately while the cache file is
      // still available. Fall back to picker-provided bytes when no readable
      // path exists (for example on web/virtual-file providers).
      bool attachedFromPath = false;
      if (filePath != null && filePath.trim().isNotEmpty) {
        final pickedFile = File(filePath);
        if (await pickedFile.exists()) {
          final fileLength = await pickedFile.length();
          if (fileLength <= 0) {
            throw const FormatException('Selected attachment is empty.');
          }

          request.files.add(
            await http.MultipartFile.fromPath(
              fileField,
              pickedFile.path,
              filename: fileName,
            ),
          );
          attachedFromPath = true;
        }
      }

      if (!attachedFromPath && fileBytes != null && fileBytes.isNotEmpty) {
        request.files.add(
          http.MultipartFile.fromBytes(
            fileField,
            fileBytes,
            filename: fileName,
          ),
        );
      }
    }

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

    debugPrint(
      '[HTTP PERF] MULTIPART POST $url | status=${res.statusCode} '
      '| headers=${headersMs}ms | body=${bodyMs}ms '
      '| total=${totalWatch.elapsedMilliseconds}ms '
      '| bytes=${responseBody.length}',
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
      '[HTTP PERF] MULTIPART POST $url timed out after '
      '${totalWatch.elapsedMilliseconds}ms',
    );
    rethrow;
  } on SocketException {
    debugPrint(
      '[HTTP PERF] MULTIPART POST $url socket error after '
      '${totalWatch.elapsedMilliseconds}ms',
    );
    rethrow;
  }
}

/// Download raw binary attachment bytes without JSON/string conversion.
/// Authorization is sent only to the configured API host to avoid token leaks
/// through third-party storage or signed URLs.
Future<http.Response> httpDownloadAttachment(Uri uri) async {
  final apiHost = Uri.parse(Constants.apiUrl).host;
  final headers = <String, String>{'Accept': 'application/octet-stream, */*'};
  if (uri.host.toLowerCase() == apiHost.toLowerCase()) {
    final token = await LocalStorage.getAccessToken();
    if (token.isNotEmpty) headers['Authorization'] = 'Bearer $token';
    if (SessionManager.userId.isNotEmpty) {
      headers['user-id'] = SessionManager.userId;
    }
  }
  final request = http.Request('GET', uri)..headers.addAll(headers);
  final streamed = await _httpClient.send(request).timeout(_requestTimeout);
  final bytes = await streamed.stream.toBytes();
  return http.Response.bytes(
    bytes,
    streamed.statusCode,
    headers: streamed.headers,
    request: streamed.request,
    isRedirect: streamed.isRedirect,
    reasonPhrase: streamed.reasonPhrase,
  );
}
