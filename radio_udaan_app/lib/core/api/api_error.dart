import 'package:dio/dio.dart';

import '../constants/app_strings.dart';
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
      message = AppStrings.libraryYoutubeNotConfigured;
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
    return ApiError(
      message: error.message ?? 'Network error. Check your connection.',
      statusCode: error.response?.statusCode,
    );
  }

  final String message;
  final String? code;
  final int? statusCode;

  @override
  String toString() => message;
}
