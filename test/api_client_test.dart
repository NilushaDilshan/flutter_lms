import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_lms/core/api/api_endpoints.dart';
import 'package:flutter_lms/core/api/api_exception.dart';
import 'package:flutter_lms/core/api/api_response.dart';
import 'package:flutter_lms/core/config/app_config.dart';
import 'package:flutter_lms/features/auth/models/auth_tokens_model.dart';
import 'package:flutter_lms/features/auth/models/user_model.dart';
import 'package:flutter_lms/features/profile/models/instructor_profile_model.dart';
import 'package:flutter_lms/features/profile/models/student_profile_model.dart';

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

  group('Day 5: Auth Models & Profile Unit Tests', () {
    test('UserModel serializes and deserializes properly with role helpers', () {
      final userJson = {
        'id': 'usr_123',
        'firstName': 'Kamal',
        'lastName': 'Perera',
        'email': 'kamal@example.com',
        'role': 'STUDENT',
        'isEmailVerified': true,
      };

      final user = UserModel.fromJson(userJson);
      expect(user.id, 'usr_123');
      expect(user.fullName, 'Kamal Perera');
      expect(user.isStudent, isTrue);
      expect(user.isInstructor, isFalse);
      expect(user.isAdmin, isFalse);

      final instructorUser = user.copyWith(role: 'INSTRUCTOR');
      expect(instructorUser.isInstructor, isTrue);
    });

    test('AuthTokensModel parses accessToken and refreshToken', () {
      final tokenJson = {
        'accessToken': 'jwt_access_token_123',
        'refreshToken': 'jwt_refresh_token_456',
      };

      final tokens = AuthTokensModel.fromJson(tokenJson);
      expect(tokens.accessToken, 'jwt_access_token_123');
      expect(tokens.refreshToken, 'jwt_refresh_token_456');
    });

    test('StudentProfileModel and InstructorProfileModel parse backend payloads', () {
      final studentJson = {
        'id': 'sp_1',
        'userId': 'usr_1',
        'educationLevel': 'Undergraduate',
        'learningGoals': ['Flutter', 'Clean Architecture'],
      };

      final student = StudentProfileModel.fromJson(studentJson);
      expect(student.educationLevel, 'Undergraduate');
      expect(student.learningGoals.length, 2);

      final instructorJson = {
        'id': 'ip_1',
        'userId': 'usr_2',
        'headline': 'Lead Engineer',
        'qualification': 'MSc Computer Science',
        'experienceYears': 8,
        'expertise': ['Flutter', 'Node.js'],
        'biography': 'Engineering instructor',
      };

      final instructor = InstructorProfileModel.fromJson(instructorJson);
      expect(instructor.headline, 'Lead Engineer');
      expect(instructor.experienceYears, 8);
      expect(instructor.expertise.first, 'Flutter');
    });
  });
}
