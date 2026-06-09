// ignore_for_file: avoid_print
// Live HTTP smoke test for the App API (VM-only, no Flutter/Dio).
// Run: dart run tool/live_api_check.dart
// Override base: API_BASE_URL=https://radio/wp-json/radioudaan/v1

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

const _defaultBaseUrl = 'https://radio/wp-json/radioudaan/v1';
const _phone = '+919777001122';
const _timeout = Duration(seconds: 20);

Future<void> main() async {
  final baseUrl = _normalizeBase(
    Platform.environment['API_BASE_URL'] ?? _defaultBaseUrl,
  );
  final client = _createClient(baseUrl);
  var passed = 0;
  var failed = 0;

  print('API base: $baseUrl');
  print('');

  Future<void> check(String name, Future<void> Function() fn) async {
    try {
      await fn();
      print('PASS  $name');
      passed++;
    } catch (e) {
      print('FAIL  $name');
      print('      $e');
      if (e is _ApiCheckException) {
        print('      status=${e.statusCode} body=${e.body}');
      }
      failed++;
    }
  }

  try {
    await check('GET /health', () async {
      final data = await _getJson(client, baseUrl, '/health');
      if (data['status'] != 'ok') {
        throw StateError('unexpected health: $data');
      }
    });

    await check('GET /config', () async {
      final data = await _getJson(client, baseUrl, '/config');
      final streamUrl = data['stream_url']?.toString() ?? '';
      if (!streamUrl.contains('radio')) {
        throw StateError('unexpected stream_url: $streamUrl');
      }
      final branding = data['branding'] as Map<String, dynamic>? ?? {};
      final appName = branding['app_name']?.toString() ?? '';
      if (appName.isEmpty) {
        throw StateError('branding.app_name missing');
      }
      final copy = data['copy'] as Map<String, dynamic>? ?? {};
      if ((copy['tab_radio']?.toString() ?? '').isEmpty) {
        throw StateError('copy.tab_radio missing');
      }
      if ((copy['verify_intro']?.toString() ?? '').isEmpty) {
        throw StateError('copy.verify_intro missing');
      }
    });

    String? requestId;
    String? devOtp;

    await check('POST /auth/otp/request', () async {
      final data = await _postJson(
        client,
        baseUrl,
        '/auth/otp/request',
        {'phone_e164': _phone},
      );
      requestId = data['request_id']?.toString() ?? '';
      if (requestId!.isEmpty) {
        throw StateError('request_id missing: $data');
      }
      devOtp = data['dev_otp']?.toString();
      if (devOtp != null && devOtp!.isNotEmpty) {
        print('      dev_otp present (length ${devOtp!.length})');
      }
    });

    await check('POST /auth/otp/verify', () async {
      if (requestId == null || requestId!.isEmpty) {
        throw StateError('skipped: otp request did not return request_id');
      }
      final otp = devOtp;
      if (otp == null || otp.isEmpty) {
        throw StateError(
          'dev_otp not in otp/request response — enable dev OTP on server',
        );
      }
      final data = await _postJson(
        client,
        baseUrl,
        '/auth/otp/verify',
        {'request_id': requestId, 'otp': otp},
      );
      final token = data['token']?.toString() ?? '';
      if (token.isEmpty) {
        throw StateError('token missing: $data');
      }
      final user = data['user'] as Map<String, dynamic>? ?? {};
      final phone = user['phone_e164']?.toString() ?? '';
      if (phone != _phone) {
        throw StateError('user.phone_e164 mismatch: $phone');
      }
    });
  } finally {
    client.close();
  }

  print('');
  print('Result: $passed passed, $failed failed');
  if (failed > 0) exit(1);
}

String _normalizeBase(String url) {
  var normalized = url.trim();
  if (normalized.endsWith('/')) {
    normalized = normalized.substring(0, normalized.length - 1);
  }
  return normalized;
}

http.Client _createClient(String baseUrl) {
  final uri = Uri.parse(baseUrl);
  final host = uri.host.toLowerCase();
  final isLocalDev = host == 'radio' ||
      host == 'localhost' ||
      host == '127.0.0.1' ||
      host.endsWith('.local');
  if (!isLocalDev) {
    return http.Client();
  }
  final io = HttpClient()
    ..connectionTimeout = _timeout
    ..badCertificateCallback = (_cert, _host, _port) => true;
  return IOClient(io);
}

Future<Map<String, dynamic>> _getJson(
  http.Client client,
  String baseUrl,
  String path,
) async {
  final uri = Uri.parse('$baseUrl$path');
  final response = await client
      .get(uri, headers: _jsonHeaders)
      .timeout(_timeout);
  return _decodeResponse(response);
}

Future<Map<String, dynamic>> _postJson(
  http.Client client,
  String baseUrl,
  String path,
  Map<String, dynamic> body,
) async {
  final uri = Uri.parse('$baseUrl$path');
  final response = await client
      .post(
        uri,
        headers: _jsonHeaders,
        body: jsonEncode(body),
      )
      .timeout(_timeout);
  return _decodeResponse(response);
}

const _jsonHeaders = {
  'Accept': 'application/json',
  'Content-Type': 'application/json',
};

Map<String, dynamic> _decodeResponse(http.Response response) {
  final status = response.statusCode;
  dynamic body;
  try {
    body = jsonDecode(response.body);
  } catch (_) {
    body = response.body;
  }
  if (status < 200 || status >= 300) {
    throw _ApiCheckException(status, body);
  }
  if (body is! Map<String, dynamic>) {
    throw StateError('expected JSON object, got $body');
  }
  return body;
}

class _ApiCheckException implements Exception {
  _ApiCheckException(this.statusCode, this.body);

  final int statusCode;
  final dynamic body;

  @override
  String toString() => 'HTTP $statusCode';
}
