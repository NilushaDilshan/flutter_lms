import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_lms/core/api/api_endpoints.dart';
import 'package:flutter_lms/core/api/api_exception.dart';
import 'package:flutter_lms/core/api/api_response.dart';
import 'package:flutter_lms/core/config/app_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Day 4: Network & API Core Unit Tests', () {
    test('AppConfig sets and formats base URL correctly', () {
      expect(AppConfig.baseUrl, AppConfig.defaultEmulatorBaseUrl);
      AppConfig.setBaseUrl('http://192.168.1.100:5000/');
      expect(AppConfig.baseUrl, 'http://192.168.1.100:5000');
      AppConfig.setBaseUrl(AppConfig.defaultEmulatorBaseUrl);
    });

    test('ApiEndpoints match backend route specification', () {
      expect(ApiEndpoints.login, '/api/v1/auth/login');
      expect(ApiEndpoints.refreshToken, '/api/v1/auth/refresh-token');
      expect(ApiEndpoints.registerStudent, '/api/v1/auth/register/student');
      expect(ApiEndpoints.registerInstructor, '/api/v1/auth/register/instructor');
      expect(ApiEndpoints.publishedCourses, '/api/v1/courses');
      expect(ApiEndpoints.categories, '/api/v1/categories');
    });

    test('ApiException correctly handles connection timeout', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.connectionTimeout,
      );

      final exception = ApiException.fromDioException(dioException);
      expect(exception.statusCode, 408);
      expect(exception.message, contains('timed out'));
    });

    test('ApiException correctly formats 401 unauthorized', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 401,
          data: {'status': 'error', 'message': 'Invalid token'},
        ),
        type: DioExceptionType.badResponse,
      );

      final exception = ApiException.fromDioException(dioException);
      expect(exception.statusCode, 401);
      expect(exception.message, 'Invalid token');
    });

    test('ApiException correctly formats 403 forbidden', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/admin'),
        response: Response(
          requestOptions: RequestOptions(path: '/admin'),
          statusCode: 403,
          data: {'status': 'error', 'message': 'Access forbidden'},
        ),
        type: DioExceptionType.badResponse,
      );

      final exception = ApiException.fromDioException(dioException);
      expect(exception.statusCode, 403);
      expect(exception.message, 'Access forbidden');
    });

    test('ApiResponse deserializes standard JSON payload', () {
      final json = {
        'status': 'success',
        'message': 'Data loaded',
        'data': {'courseId': '123', 'title': 'Flutter Mastery'},
      };

      final response = ApiResponse<Map<String, dynamic>>.fromJson(
        json,
        (data) => data as Map<String, dynamic>,
      );

      expect(response.isSuccess, isTrue);
      expect(response.message, 'Data loaded');
      expect(response.data?['title'], 'Flutter Mastery');
    });
  });
}
