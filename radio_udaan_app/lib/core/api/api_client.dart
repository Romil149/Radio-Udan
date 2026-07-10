import 'package:dio/dio.dart';

import '../config/app_env.dart';
import '../constants/app_constants.dart';

/// Low-level HTTP client for a single App API base URL and optional bearer token.
class ApiClient {
  ApiClient({
    required String baseUrl,
    String? bearerToken,
    void Function()? onUnauthorized,
  }) : _dio = Dio(
          BaseOptions(
            baseUrl: _normalizeBase(baseUrl),
            connectTimeout: AppConstants.apiConnectTimeout,
            receiveTimeout: AppConstants.apiReceiveTimeout,
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
          ),
        ) {
    if (bearerToken != null && bearerToken.isNotEmpty) {
      _dio.options.headers['Authorization'] = 'Bearer $bearerToken';
    }
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) async {
          if (_shouldAutoRetry(error)) {
            final options = error.requestOptions;
            options.extra['ru_auto_retried'] = true;
            try {
              final response = await _dio.fetch(options);
              handler.resolve(response);
              return;
            } on DioException catch (retryError) {
              error = retryError;
            }
          }

          if (error.response?.statusCode == 401) {
            onUnauthorized?.call();
          }
          handler.next(error);
        },
      ),
    );
  }

  final Dio _dio;

  Dio get dio => _dio;

  /// First-request client using the compile-time bootstrap URL from [AppEnv].
  factory ApiClient.bootstrap({String? bearerToken}) {
    return ApiClient(
      baseUrl: AppEnv.bootstrapApiBaseUrl,
      bearerToken: bearerToken,
    );
  }

  /// Idempotent GET/HEAD only; transport/timeout only; once per request.
  static bool _shouldAutoRetry(DioException error) {
    final method = error.requestOptions.method.toUpperCase();
    if (method != 'GET' && method != 'HEAD') {
      return false;
    }
    if (error.requestOptions.extra['ru_auto_retried'] == true) {
      return false;
    }
    // Never auto-retry HTTP 4xx/5xx response errors.
    if (error.response != null) {
      return false;
    }
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return true;
      default:
        return false;
    }
  }

  static String _normalizeBase(String url) {
    var normalized = url.trim();
    if (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    return normalized;
  }
}
