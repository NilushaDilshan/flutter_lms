import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? code;
  final dynamic data;
  final List<String> errors;

  ApiException({
    required this.message,
    this.statusCode,
    this.code,
    this.data,
    this.errors = const [],
  });

  factory ApiException.fromDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(
          message: 'Connection timed out. Please check your internet connection or server availability.',
          statusCode: 408,
        );

      case DioExceptionType.connectionError:
        return ApiException(
          message: 'Cannot reach the backend server. Verify that Docker backend is running and the network host is accessible.',
          statusCode: 503,
        );

      case DioExceptionType.badResponse:
        return ApiException._fromResponse(error.response);

      case DioExceptionType.cancel:
        return ApiException(
          message: 'Request was cancelled.',
          statusCode: 499,
        );

      case DioExceptionType.badCertificate:
        return ApiException(
          message: 'SSL certificate verification failed.',
          statusCode: 495,
        );

      case DioExceptionType.unknown:
      default:
        return ApiException(
          message: error.message ?? 'An unexpected network error occurred.',
          statusCode: 500,
        );
    }
  }

  factory ApiException._fromResponse(Response? response) {
    final statusCode = response?.statusCode ?? 500;
    final responseData = response?.data;

    String message = 'An unexpected error occurred. Please try again.';
    String? code;
    List<String> errors = [];

    if (responseData is Map<String, dynamic>) {
      // Backend pattern: { status: 'error', message: '...', code: '...', errors: [...] }
      if (responseData['message'] is String && (responseData['message'] as String).isNotEmpty) {
        message = responseData['message'];
      }

      code = responseData['code']?.toString() ?? responseData['errorCode']?.toString();

      if (responseData['errors'] is List) {
        errors = (responseData['errors'] as List)
            .map((e) => e.toString())
            .where((e) => e.isNotEmpty)
            .toList();
      }
    }

    // Role / StatusCode-specific user-friendly fallbacks
    switch (statusCode) {
      case 400:
        if (message == 'An unexpected error occurred. Please try again.') {
          message = 'Invalid request data. Please check your input.';
        }
        break;
      case 401:
        if (message == 'An unexpected error occurred. Please try again.') {
          message = 'Authentication required. Please sign in again.';
        }
        break;
      case 403:
        if (message == 'An unexpected error occurred. Please try again.') {
          message = 'Access forbidden. You do not have permission for this role action.';
        }
        break;
      case 404:
        if (message == 'An unexpected error occurred. Please try again.') {
          message = 'The requested resource was not found.';
        }
        break;
      case 409:
        if (message == 'An unexpected error occurred. Please try again.') {
          message = 'A conflict occurred. The record may already exist.';
        }
        break;
      case 500:
      case 502:
      case 503:
        message = 'Server encountered an issue. Please try again shortly.';
        break;
    }

    return ApiException(
      message: message,
      statusCode: statusCode,
      code: code,
      data: responseData,
      errors: errors,
    );
  }

  @override
  String toString() => message;
}
