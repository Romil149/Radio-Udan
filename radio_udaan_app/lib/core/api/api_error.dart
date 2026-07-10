import 'package:dio/dio.dart';

import '../config/app_branding.dart';
import '../config/app_copy_accessors.dart';

/// User-facing API failure with optional WordPress error code and HTTP status.
class ApiError implements Exception {
  ApiError({
    required this.message,
    this.code,
    this.statusCode,
  });

  factory ApiError.fromResponse({
    required int? statusCode,
    required Map<String, dynamic>? body,
  }) {
    final code = body?['code']?.toString();
    var message = body?['message']?.toString() ??
        body?['data']?['message']?.toString() ??
        'Something went wrong. Please try again.';

    if (code == 'youtube_not_configured') {
      message = AppCopy.fallback.libraryYoutubeNotConfigured;
    }

    return ApiError(message: message, code: code, statusCode: statusCode);
  }

  static ApiError fromDioException(DioException error) {
    final data = error.response?.data;
    if (data is Map) {
      return ApiError.fromResponse(
        statusCode: error.response?.statusCode,
        body: Map<String, dynamic>.from(data),
      );
    }

    // Never surface raw Dio timeout jargon (e.g. "took longer than 0:00:12").
    if (_isTransientNetworkFailure(error)) {
      return ApiError(
        message: AppCopy.fallback.bootstrapOffline,
        statusCode: error.response?.statusCode,
      );
    }

    final raw = error.message ?? '';
    return ApiError(
      message: raw.isNotEmpty
          ? raw
          : AppCopy.fallback.bootstrapOffline,
      statusCode: error.response?.statusCode,
    );
  }

  static bool _isTransientNetworkFailure(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return true;
      default:
        break;
    }
    final raw = error.message ?? '';
    return raw.contains('XMLHttpRequest') || raw.contains('connection errored');
  }

  final String message;
  final String? code;
  final int? statusCode;

  @override
  String toString() => message;
}
