import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_exception.dart';
import '../../auth/models/user_model.dart';
import '../models/instructor_profile_model.dart';
import '../models/student_profile_model.dart';

class ProfileProvider extends ChangeNotifier {
  final ApiClient _apiClient;

  UserModel? _user;
  StudentProfileModel? _studentProfile;
  InstructorProfileModel? _instructorProfile;
  bool _isLoading = false;
  String? _errorMessage;

  ProfileProvider({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  UserModel? get user => _user;
  StudentProfileModel? get studentProfile => _studentProfile;
  InstructorProfileModel? get instructorProfile => _instructorProfile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Load Full Profile
  Future<void> loadFullProfile() async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiClient.get(ApiEndpoints.fullProfile);
      final data = response.data['data'] as Map<String, dynamic>;

      if (data['user'] != null) {
        _user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      }

      final profileData = data['profile'] as Map<String, dynamic>?;
      if (profileData != null) {
        if (_user?.isInstructor == true) {
          _instructorProfile = InstructorProfileModel.fromJson(profileData);
        } else {
          _studentProfile = StudentProfileModel.fromJson(profileData);
        }
      } else {
        if (data['studentProfile'] != null) {
          _studentProfile = StudentProfileModel.fromJson(
            data['studentProfile'] as Map<String, dynamic>,
          );
        }
        if (data['instructorProfile'] != null) {
          _instructorProfile = InstructorProfileModel.fromJson(
            data['instructorProfile'] as Map<String, dynamic>,
          );
        }
      }

      _setLoading(false);
    } on ApiException catch (e) {
      _setError(e.message);
      _setLoading(false);
      rethrow;
    } catch (_) {
      _setError('Failed to load profile.');
      _setLoading(false);
    }
  }

  // Update Base User Account
  Future<void> updateUserAccount({
    required String firstName,
    required String lastName,
    String? bio,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiClient.patch(
        ApiEndpoints.currentUser,
        data: {
          'firstName': firstName.trim(),
          'lastName': lastName.trim(),
          'bio': bio,
        },
      );

      final data = response.data['data'] as Map<String, dynamic>;
      if (data['user'] != null) {
        _user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      }
      _setLoading(false);
    } on ApiException catch (e) {
      _setError(e.message);
      _setLoading(false);
      rethrow;
    }
  }

  // Update Student Profile
  Future<void> updateStudentProfile({
    required String educationLevel,
    required List<String> learningGoals,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiClient.patch(
        ApiEndpoints.studentProfile,
        data: {
          'educationLevel': educationLevel.trim(),
          'learningGoals': learningGoals,
        },
      );

      final data = response.data['data'] as Map<String, dynamic>;
      if (data['profile'] != null) {
        _studentProfile = StudentProfileModel.fromJson(
          data['profile'] as Map<String, dynamic>,
        );
      }
      _setLoading(false);
    } on ApiException catch (e) {
      _setError(e.message);
      _setLoading(false);
      rethrow;
    }
  }

  // Update Instructor Profile
  Future<void> updateInstructorProfile({
    required String headline,
    required String qualification,
    required int experienceYears,
    required List<String> expertise,
    required String biography,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiClient.patch(
        ApiEndpoints.instructorProfile,
        data: {
          'headline': headline.trim(),
          'qualification': qualification.trim(),
          'experienceYears': experienceYears,
          'expertise': expertise,
          'biography': biography.trim(),
        },
      );

      final data = response.data['data'] as Map<String, dynamic>;
      if (data['profile'] != null) {
        _instructorProfile = InstructorProfileModel.fromJson(
          data['profile'] as Map<String, dynamic>,
        );
      }
      _setLoading(false);
    } on ApiException catch (e) {
      _setError(e.message);
      _setLoading(false);
      rethrow;
    }
  }

  // Upload Profile Image
  Future<String?> uploadProfileImage(XFile imageFile) async {
    _setLoading(true);
    _clearError();

    try {
      final fileName = imageFile.name.isNotEmpty ? imageFile.name : 'avatar.jpg';
      final multipartFile = await MultipartFile.fromFile(
        imageFile.path,
        filename: fileName,
      );

      // Exact multipart field key per task specification: 'profileImage'
      final formData = FormData.fromMap({
        'profileImage': multipartFile,
      });

      final response = await _apiClient.uploadMultipart(
        ApiEndpoints.profileImage,
        formData: formData,
      );

      final data = response.data['data'] as Map<String, dynamic>?;
      if (data != null && data['user'] != null) {
        _user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      } else {
        final imageUrl = data?['profileImage']?.toString() ??
            data?['profileImageUrl']?.toString();
        if (imageUrl != null && _user != null) {
          _user = _user!.copyWith(profileImage: imageUrl);
        }
      }

      _setLoading(false);
      notifyListeners();
      return _user?.profileImage;
    } on ApiException catch (e) {
      _setError(e.message);
      _setLoading(false);
      rethrow;
    }
  }

  // Delete Profile Image
  Future<void> deleteProfileImage() async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiClient.delete(ApiEndpoints.profileImage);
      final data = response.data['data'] as Map<String, dynamic>?;
      if (data != null && data['user'] != null) {
        _user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      } else if (_user != null) {
        _user = _user!.copyWith(profileImage: null);
      }
      _setLoading(false);
      notifyListeners();
    } on ApiException catch (e) {
      _setError(e.message);
      _setLoading(false);
      rethrow;
    }
  }

  // Change Password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      await _apiClient.patch(
        ApiEndpoints.changePassword,
        data: {
          'currentPassword': currentPassword,
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
