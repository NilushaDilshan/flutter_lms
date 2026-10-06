import 'package:flutter/foundation.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/storage/token_storage.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isInitialized = false;

  AuthProvider({
    ApiClient? apiClient,
    TokenStorage? tokenStorage,
  })  : _apiClient = apiClient ?? ApiClient(),
        _tokenStorage = tokenStorage ?? TokenStorage();

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;
  bool get isInitialized => _isInitialized;
  String? get userRole => _currentUser?.role;

  /// Used in Demo / Offline mode to set a fake user so Profile screen
  /// shows correct name, email and role instead of "User Name".
  void setDemoUser({
    required String firstName,
    required String lastName,
    required String email,
    required String role,
  }) {
    _currentUser = UserModel(
      id: 'demo-user',
      firstName: firstName,
      lastName: lastName,
      email: email,
      role: role,
      isEmailVerified: true,
    );
    notifyListeners();
  }

  // Restore session from encrypted storage
  Future<bool> initSession() async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await _tokenStorage.getAccessToken();
      final userId = await _tokenStorage.getUserId();
      final role = await _tokenStorage.getUserRole();
      final email = await _tokenStorage.getUserEmail();
      final name = await _tokenStorage.getUserName();

      if (token != null && token.isNotEmpty && userId != null) {
        // Construct user from cached storage
        final nameParts = (name ?? '').split(' ');
        _currentUser = UserModel(
          id: userId,
          firstName: nameParts.isNotEmpty ? nameParts.first : 'User',
          lastName: nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '',
          email: email ?? '',
          role: role ?? 'STUDENT',
          isEmailVerified: true,
        );

        // Fetch fresh user profile in background
        _fetchFreshProfile();
      }
    } catch (_) {
      await _tokenStorage.clear();
      _currentUser = null;
    } finally {
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
    }

    return isAuthenticated;
  }

  Future<void> _fetchFreshProfile() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.currentUser);
      if (response.data is Map<String, dynamic>) {
        final data = response.data['data'];
        if (data != null && data['user'] != null) {
          _currentUser = UserModel.fromJson(data['user']);
          notifyListeners();
        }
      }
    } catch (_) {
      // Continue with cached user session
    }
  }

  // Login
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiClient.post(
        ApiEndpoints.login,
        data: {
          'email': email.trim(),
          'password': password,
        },
      );

      final data = response.data['data'];
      final userJson = data['user'] as Map<String, dynamic>;
      final tokensJson = data['tokens'] as Map<String, dynamic>;

      final user = UserModel.fromJson(userJson);
      final accessToken = tokensJson['accessToken']?.toString() ?? '';
      final refreshToken = tokensJson['refreshToken']?.toString() ?? '';

      await _tokenStorage.saveSession(
        accessToken: accessToken,
        refreshToken: refreshToken,
        role: user.role,
        userId: user.id,
        email: user.email,
        name: user.fullName,
      );

      _currentUser = user;
      _setLoading(false);
      return user;
    } on ApiException catch (e) {
      _setError(e.message);
      _setLoading(false);
      rethrow;
    } catch (e) {
      _setError('Login failed. Please check your credentials.');
      _setLoading(false);
      throw ApiException(message: 'Login failed');
    }
  }

  // Register Student
  Future<Map<String, dynamic>> registerStudent({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String confirmPassword,
    required String dateOfBirth,
    required String educationLevel,
    required List<String> learningGoals,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiClient.post(
        ApiEndpoints.registerStudent,
        data: {
          'firstName': firstName.trim(),
          'lastName': lastName.trim(),
          'email': email.trim(),
          'password': password,
          'confirmPassword': confirmPassword,
          'dateOfBirth': dateOfBirth,
          'educationLevel': educationLevel,
          'learningGoals': learningGoals,
        },
      );

      _setLoading(false);
      return (response.data['data'] as Map<String, dynamic>?) ?? {};
    } on ApiException catch (e) {
      _setError(e.message);
      _setLoading(false);
      rethrow;
    }
  }

  // Register Instructor
  Future<Map<String, dynamic>> registerInstructor({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String confirmPassword,
    required String headline,
    required String qualification,
    required int experienceYears,
    required List<String> expertise,
    required String biography,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiClient.post(
        ApiEndpoints.registerInstructor,
        data: {
          'firstName': firstName.trim(),
          'lastName': lastName.trim(),
          'email': email.trim(),
          'password': password,
          'confirmPassword': confirmPassword,
          'headline': headline.trim(),
          'qualification': qualification.trim(),
          'experienceYears': experienceYears,
          'expertise': expertise,
          'biography': biography.trim(),
        },
      );

      _setLoading(false);
      return (response.data['data'] as Map<String, dynamic>?) ?? {};
    } on ApiException catch (e) {
      _setError(e.message);
      _setLoading(false);
      rethrow;
    }
  }

  // Verify Email with OTP
  Future<bool> verifyEmail({
    required String email,
    required String otp,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiClient.post(
        ApiEndpoints.verifyEmail,
        data: {
          'email': email.trim(),
          'otp': otp.trim(),
        },
      );

      _setLoading(false);
      return response.statusCode == 200 || response.statusCode == 201;
    } on ApiException catch (e) {
      _setError(e.message);
      _setLoading(false);
      rethrow;
    }
  }

  // Resend OTP
  Future<void> resendVerificationOtp(String email) async {
    _clearError();
    try {
      await _apiClient.post(
        ApiEndpoints.resendVerificationOtp,
        data: {'email': email.trim()},
      );
    } on ApiException catch (e) {
      _setError(e.message);
      rethrow;
    }
  }

  // Forgot Password
  Future<void> forgotPassword(String email) async {
    _setLoading(true);
    _clearError();

    try {
      await _apiClient.post(
        ApiEndpoints.forgotPassword,
        data: {'email': email.trim()},
      );
      _setLoading(false);
    } on ApiException catch (e) {
      _setError(e.message);
      _setLoading(false);
      rethrow;
    }
  }

  // Verify Password Reset OTP
  Future<String> verifyResetOtp({
    required String email,
    required String otp,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiClient.post(
        ApiEndpoints.verifyResetOtp,
        data: {
          'email': email.trim(),
          'otp': otp.trim(),
        },
      );

      final data = response.data['data'] as Map<String, dynamic>;
      final resetToken = data['resetToken']?.toString() ?? '';
      _setLoading(false);
      return resetToken;
    } on ApiException catch (e) {
      _setError(e.message);
      _setLoading(false);
      rethrow;
    }
  }

  // Reset Password
  Future<void> resetPassword({
    required String resetToken,
    required String newPassword,
    required String confirmPassword,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      await _apiClient.post(
        ApiEndpoints.resetPassword,
        data: {
          'resetToken': resetToken,
          'newPassword': newPassword,
          'confirmPassword': confirmPassword,
        },
      );
      _setLoading(false);
    } on ApiException catch (e) {
      _setError(e.message);
      _setLoading(false);
      rethrow;
    }
  }

  // Logout Current Session
  Future<void> logout() async {
    try {
      await _apiClient.post(ApiEndpoints.logout);
    } catch (_) {
      // Clear local storage regardless of backend state
    } finally {
      await _tokenStorage.clear();
      _currentUser = null;
      notifyListeners();
    }
  }

  // Logout All Devices
  Future<void> logoutAll() async {
    try {
      await _apiClient.post(ApiEndpoints.logoutAll);
    } catch (_) {
      // Clear local storage regardless of backend state
    } finally {
      await _tokenStorage.clear();
      _currentUser = null;
      notifyListeners();
    }
  }

  void updateCurrentUser(UserModel user) {
    _currentUser = user;
    notifyListeners();
  }

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  void _setError(String msg) {
    _errorMessage = msg;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}
