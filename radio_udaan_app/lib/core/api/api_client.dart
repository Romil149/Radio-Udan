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
    if (onUnauthorized != null) {
      _dio.interceptors.add(
        InterceptorsWrapper(
          onError: (error, handler) {
            if (error.response?.statusCode == 401) {
              onUnauthorized();
            }
            handler.next(error);
          },
        ),
      );
    }
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

  static String _normalizeBase(String url) {
    var normalized = url.trim();
    if (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    return normalized;
  }
}
