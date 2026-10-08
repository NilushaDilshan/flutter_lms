import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_exception.dart';
import '../models/assignment_model.dart';

class AssignmentProvider extends ChangeNotifier {
  final ApiClient _apiClient;

  List<AssignmentModel> _assignments = [];
  AssignmentModel? _selectedAssignment;
  AssignmentSubmissionModel? _mySubmission;

  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  AssignmentProvider({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  List<AssignmentModel> get assignments => _assignments;
  AssignmentModel? get selectedAssignment => _selectedAssignment;
  AssignmentSubmissionModel? get mySubmission => _mySubmission;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  // Load assignments for a course
  Future<void> loadCourseAssignments(String courseId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.get(ApiEndpoints.courseAssignments(courseId));
      final data = response.data['data'];
      if (data != null && data['assignments'] is List) {
        _assignments = (data['assignments'] as List)
            .map((a) => AssignmentModel.fromJson(a as Map<String, dynamic>))
            .toList();
      } else {
        _assignments = [];
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _assignments = _getDemoAssignments(courseId);
    } catch (_) {
      _assignments = _getDemoAssignments(courseId);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load details and current submission for an assignment
  Future<void> loadAssignmentDetails(String assignmentId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.get(ApiEndpoints.assignmentById(assignmentId));
      final data = response.data['data'];
      if (data != null && data['assignment'] != null) {
        _selectedAssignment = AssignmentModel.fromJson(data['assignment'] as Map<String, dynamic>);
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _selectedAssignment ??= _getDemoAssignments('').firstWhere(
        (a) => a.id == assignmentId,
        orElse: () => _getDemoAssignments('').first,
      );
    } catch (_) {
      _selectedAssignment ??= _getDemoAssignments('').firstWhere(
        (a) => a.id == assignmentId,
        orElse: () => _getDemoAssignments('').first,
      );
    }

    // Also fetch student's submission status
    await loadMySubmission(assignmentId);

    _isLoading = false;
    notifyListeners();
  }

  // Load my existing submission for an assignment
  Future<void> loadMySubmission(String assignmentId) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.myAssignmentSubmission(assignmentId));
      final data = response.data['data'];
      if (data != null && data['submission'] != null) {
        _mySubmission = AssignmentSubmissionModel.fromJson(data['submission'] as Map<String, dynamic>);
      } else {
        _mySubmission = null;
      }
    } catch (_) {
      // No submission yet or offline
    }
    notifyListeners();
  }

  // Submit assignment using FormData only (supporting text-only, file-only, text-plus-file)
  Future<bool> submitAssignment({
    required String assignmentId,
    String? textAnswer,
    String? filePath,
    String? fileName,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    final formMap = <String, dynamic>{};
    if (textAnswer != null && textAnswer.trim().isNotEmpty) {
      formMap['textAnswer'] = textAnswer.trim();
    }

    if (filePath != null && filePath.isNotEmpty) {
      formMap['file'] = await MultipartFile.fromFile(
        filePath,
        filename: fileName ?? filePath.split('/').last,
      );
    }

    final formData = FormData.fromMap(formMap);

    try {
      final response = await _apiClient.uploadMultipart(
        ApiEndpoints.submitAssignment(assignmentId),
        formData: formData,
      );

      final data = response.data['data'];
      if (data != null && data['submission'] != null) {
        _mySubmission = AssignmentSubmissionModel.fromJson(data['submission'] as Map<String, dynamic>);
        _isSubmitting = false;
        notifyListeners();
        return true;
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Failed to submit assignment';
    }

    // Demo fallback for offline
    _mySubmission = AssignmentSubmissionModel(
      id: 'demo-sub-${DateTime.now().millisecondsSinceEpoch}',
      assignmentId: assignmentId,
      studentId: 'student-me',
      textAnswer: textAnswer,
      fileName: fileName ?? 'submission.pdf',
      status: 'SUBMITTED',
      submittedAt: DateTime.now(),
    );
    _isSubmitting = false;
    notifyListeners();
    return true;
  }

  List<AssignmentModel> _getDemoAssignments(String courseId) {
    return [
      AssignmentModel(
        id: 'assign-flutter-ui',
        courseId: courseId,
        title: 'Assignment 1: Responsive Dashboard UI',
        description: 'Build a multi-column responsive dashboard in Flutter using LayoutBuilder and MediaQuery. Support phone and tablet orientations.',
        dueDate: DateTime.now().add(const Duration(days: 7)),
        maxMarks: 100,
        attachmentName: 'dashboard_specs.pdf',
      ),
      AssignmentModel(
        id: 'assign-api-integration',
        courseId: courseId,
        title: 'Assignment 2: Network Client with Dio',
        description: 'Implement an authentication interceptor with token refresh mechanism. Test against mock endpoints.',
        dueDate: DateTime.now().add(const Duration(days: 14)),
        maxMarks: 100,
      ),
    ];
  }
}
