import 'package:dio/dio.dart';

import '../api/api_error.dart';

/// Maps transport and WordPress REST failures to a single [ApiError] for UI layers.
ApiError parseApiError(Object error) {
  if (error is ApiError) {
    return error;
  }
  if (error is DioException) {
    return ApiError.fromDioException(error);
  }
  return ApiError(message: error.toString());
}
