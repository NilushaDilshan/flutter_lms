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
  final Map<String, AssignmentSubmissionModel> _submissionsByAssignmentId = {};

  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  AssignmentProvider({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient() {
    _seedInitialSubmissions();
  }

  void _seedInitialSubmissions() {
    // Demo student has submitted Assignment 1: Responsive Dashboard UI
    _submissionsByAssignmentId['assign-flutter-ui'] = AssignmentSubmissionModel(
      id: 'demo-sub-1',
      assignmentId: 'assign-flutter-ui',
      studentId: 'student-me',
      studentName: 'Kamal Perera',
      textAnswer: 'Implemented responsive dashboard layouts across mobile and tablet breakpoints using LayoutBuilder.',
      fileName: 'dashboard_specs.pdf',
      status: 'SUBMITTED',
      submittedAt: DateTime.now().subtract(const Duration(days: 1)),
    );
  }

  List<AssignmentModel> get assignments => _assignments;
  AssignmentModel? get selectedAssignment => _selectedAssignment;
  AssignmentSubmissionModel? get mySubmission => _mySubmission;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  bool isAssignmentSubmitted(String assignmentId) {
    return _submissionsByAssignmentId.containsKey(assignmentId);
  }

  AssignmentSubmissionModel? getSubmission(String assignmentId) {
    return _submissionsByAssignmentId[assignmentId];
  }

  // Load assignments for all enrolled courses
  Future<void> loadAssignmentsForCourses(List<String> courseIds) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    List<AssignmentModel> all = [];
    final validIds = courseIds.where((id) => id.isNotEmpty).toSet().toList();

    for (final cId in validIds) {
      try {
        final response = await _apiClient.get(ApiEndpoints.courseAssignments(cId));
        final data = response.data['data'];
        if (data != null && data['assignments'] is List) {
          final list = (data['assignments'] as List)
              .map((a) => AssignmentModel.fromJson(a as Map<String, dynamic>))
              .toList();
          all.addAll(list);
        } else {
          all.addAll(_getDemoAssignments(cId));
        }
      } catch (_) {
        all.addAll(_getDemoAssignments(cId));
      }
    }

    if (all.isEmpty) {
      all = _getAllDemoAssignments();
    }

    final Map<String, AssignmentModel> unique = {};
    for (final a in all) {
      unique[a.id] = a;
    }
    _assignments = unique.values.toList();
    _isLoading = false;
    notifyListeners();
  }

  // Load assignments for a course
  Future<void> loadCourseAssignments(String courseId) async {
    if (courseId.isEmpty) {
      await loadAssignmentsForCourses([
        '6a5c39ae384147c91b73906a',
        'course-2',
      ]);
      return;
    }

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
        _assignments = _getDemoAssignments(courseId);
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
        _submissionsByAssignmentId[assignmentId] = _mySubmission!;
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
        _submissionsByAssignmentId[assignmentId] = _mySubmission!;
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
    _submissionsByAssignmentId[assignmentId] = _mySubmission!;
    _isSubmitting = false;
    notifyListeners();
    return true;
  }

  List<AssignmentModel> _getAllDemoAssignments() {
    return [
      ..._getDemoAssignments('6a5c39ae384147c91b73906a'),
      ..._getDemoAssignments('course-2'),
      ..._getDemoAssignments('course-3'),
    ];
  }

  List<AssignmentModel> _getDemoAssignments(String courseId) {
    if (courseId == 'course-2') {
      return [
        AssignmentModel(
          id: 'assign-bloc-pattern',
          courseId: 'course-2',
          courseTitle: 'Mastering Advanced Dart & Flutter Architecture',
          title: 'Assignment 3: BLoC Pattern & State Hydration',
          description: 'Implement a production state management layer using Flutter BLoC, HydratedBloc for offline caching, and unit tests.',
          dueDate: DateTime.now().add(const Duration(days: 10)),
          maxMarks: 100,
          attachmentName: 'bloc_architecture_spec.pdf',
        ),
        AssignmentModel(
          id: 'assign-testing-suite',
          courseId: 'course-2',
          courseTitle: 'Mastering Advanced Dart & Flutter Architecture',
          title: 'Assignment 4: Automated Integration Testing Suite',
          description: 'Write end-to-end integration tests using integration_test package covering the authentication and playback flows.',
          dueDate: DateTime.now().add(const Duration(days: 18)),
          maxMarks: 100,
        ),
      ];
    } else if (courseId == 'course-3') {
      return [
        AssignmentModel(
          id: 'assign-auth-gateway',
          courseId: 'course-3',
          courseTitle: 'Full-Stack Web & REST APIs with Node.js',
          title: 'Assignment 5: Microservice Authentication Gateway',
          description: 'Design and deploy an Express JWT authentication microservice with refresh token rotation and rate limiting middleware.',
          dueDate: DateTime.now().add(const Duration(days: 5)),
          maxMarks: 100,
          attachmentName: 'jwt_gateway_spec.pdf',
        ),
      ];
    }

    final effectiveId = courseId.isNotEmpty ? courseId : '6a5c39ae384147c91b73906a';
    final effectiveTitle = effectiveId == '6a5c39ae384147c91b73906a'
        ? 'Flutter Development for Beginners'
        : 'Flutter Course';
    return [
      AssignmentModel(
        id: 'assign-flutter-ui',
        courseId: effectiveId,
        courseTitle: effectiveTitle,
        title: 'Assignment 1: Responsive Dashboard UI',
        description: 'Build a multi-column responsive dashboard in Flutter using LayoutBuilder and MediaQuery. Support phone and tablet orientations.',
        dueDate: DateTime.now().add(const Duration(days: 7)),
        maxMarks: 100,
        attachmentName: 'dashboard_specs.pdf',
      ),
      AssignmentModel(
        id: 'assign-api-integration',
        courseId: effectiveId,
        courseTitle: effectiveTitle,
        title: 'Assignment 2: Network Client with Dio',
        description: 'Implement an authentication interceptor with token refresh mechanism. Test against mock endpoints.',
        dueDate: DateTime.now().add(const Duration(days: 14)),
        maxMarks: 100,
      ),
    ];
  }
}
