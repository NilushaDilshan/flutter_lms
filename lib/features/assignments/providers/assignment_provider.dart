import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_exception.dart';
import '../models/assignment_model.dart';
import '../models/assignment_submission_model.dart';

/// Student-facing assignment provider.
/// Uses the shared [ApiClient] so token refresh, interceptors and
/// base URL are all consistent with the rest of the app.
class AssignmentProvider extends ChangeNotifier {
  final ApiClient _apiClient;

  AssignmentProvider({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient() {
    _submittedIds.add('assign-flutter-ui');
  }

  // ── State ─────────────────────────────────────────────────────────────────
  List<AssignmentModel> _assignments = [];
  AssignmentModel? _selectedAssignment;
  AssignmentSubmissionModel? _mySubmission;
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  final Set<String> _submittedIds = {};

  // ── Getters ───────────────────────────────────────────────────────────────
  List<AssignmentModel> get assignments => List.unmodifiable(_assignments);
  AssignmentModel? get selectedAssignment => _selectedAssignment;
  AssignmentSubmissionModel? get mySubmission => _mySubmission;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  // ── 1. Load assignments for one course ────────────────────────────────────
  // GET /api/v1/courses/:courseId/assignments
  Future<void> loadCourseAssignments(
    String courseId, {
    bool forceRefresh = false,
  }) async {
    final cleanedId = courseId.trim();
    if (cleanedId.isEmpty) {
      _errorMessage = 'Course ID is missing. Open Assignments from a course.';
      _assignments = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      try {
        final response =
            await _apiClient.get(ApiEndpoints.courseAssignments(cleanedId));
        _assignments = _parseAssignmentList(response.data);
      } on ApiException catch (e) {
        if (e.statusCode == 403) {
          // If 403 (e.g. INSUFFICIENT_PERMISSION when logged in as Instructor),
          // fallback to instructor assignments endpoint
          final instructorResp = await _apiClient
              .get(ApiEndpoints.instructorCourseAssignments(cleanedId));
          _assignments = _parseAssignmentList(instructorResp.data);
        } else {
          rethrow;
        }
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _assignments = [];
    } catch (e) {
      debugPrint('loadCourseAssignments error: $e');
      _errorMessage = 'Failed to load assignments. Check backend connection.';
      _assignments = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── 2. Load assignments across multiple courses ───────────────────────────
  Future<void> loadAssignmentsForCourses(
    List<String> courseIds, {
    bool forceRefresh = false,
  }) async {
    final ids = courseIds.map((id) => id.trim()).where((id) => id.isNotEmpty).toSet().toList();

    if (ids.isEmpty) {
      _assignments = [];
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait(
        ids.map((id) async {
          try {
            final r = await _apiClient.get(ApiEndpoints.courseAssignments(id));
            return _parseAssignmentList(r.data);
          } catch (_) {
            return <AssignmentModel>[];
          }
        }),
      );
      final combined = results.expand((list) => list).toList();
      final unique = <String, AssignmentModel>{};
      for (final a in combined) {
        final key = a.id.isNotEmpty ? a.id : '${a.courseId}_${a.title}';
        unique[key] = a;
      }
      _assignments = unique.values.toList();
    } catch (e) {
      debugPrint('loadAssignmentsForCourses error: $e');
      _errorMessage = 'Failed to load assignments.';
      _assignments = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── 3. Load single assignment details + student's own submission ──────────
  // GET /api/v1/assignments/:id
  // GET /api/v1/assignments/:id/submission/me
  Future<void> loadAssignmentDetails(String assignmentId) async {
    _isLoading = true;
    _errorMessage = null;
    _selectedAssignment = null;
    _mySubmission = null;
    notifyListeners();

    try {
      // Load assignment
      try {
        final r = await _apiClient.get(ApiEndpoints.assignmentById(assignmentId));
        _selectedAssignment = _parseAssignment(r.data);
      } on ApiException {
        // Fallback to already-loaded list
        _selectedAssignment = _assignments.cast<AssignmentModel?>().firstWhere(
          (a) => a?.id == assignmentId,
          orElse: () => null,
        );
      }

      // Load student's own submission
      try {
        final r = await _apiClient.get(
          ApiEndpoints.myAssignmentSubmission(assignmentId),
        );
        _mySubmission = _parseSubmission(r.data);
        if (_mySubmission != null) _submittedIds.add(assignmentId);
      } on ApiException catch (e) {
        // 404 means not submitted yet — that's fine
        if (e.statusCode != 404) {
          debugPrint('loadAssignmentDetails submission error: $e');
        }
        _mySubmission = null;
      }
    } catch (e) {
      debugPrint('loadAssignmentDetails error: $e');
      _errorMessage = 'Failed to load assignment details.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── 4. Submit or re-submit an assignment ──────────────────────────────────
  // POST /api/v1/assignments/:id/submissions  (multipart/form-data)
  Future<bool> submitAssignment({
    required String assignmentId,
    String? textAnswer,
    String? filePath,
    String? fileName,
    Uint8List? fileBytes,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      MultipartFile? multipartFile;
      if (filePath != null && filePath.isNotEmpty) {
        final name = fileName ?? filePath.split(Platform.pathSeparator).last;
        multipartFile = await MultipartFile.fromFile(
          filePath,
          filename: name,
          contentType: _resolveMediaType(name),
        );
      } else if (fileBytes != null && fileName != null) {
        multipartFile = MultipartFile.fromBytes(
          fileBytes,
          filename: fileName,
          contentType: _resolveMediaType(fileName),
        );
      }

      final formMap = <String, dynamic>{};
      if (textAnswer != null && textAnswer.isNotEmpty) {
        formMap['textAnswer'] = textAnswer;
      }
      if (multipartFile != null) {
        formMap['file'] = multipartFile;
      }

      final response = await _apiClient.uploadMultipart(
        ApiEndpoints.submitAssignment(assignmentId),
        formData: FormData.fromMap(formMap),
      );

      _mySubmission = _parseSubmission(response.data) ??
          AssignmentSubmissionModel(
            id: 'local-${DateTime.now().millisecondsSinceEpoch}',
            assignmentId: assignmentId,
            studentId: '',
            textAnswer: textAnswer,
            fileName: fileName,
            status: 'SUBMITTED',
            submittedAt: DateTime.now(),
          );
      _submittedIds.add(assignmentId);
      _isSubmitting = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      debugPrint('submitAssignment error: $e');
      _errorMessage = 'Submission failed. Check your connection.';
    }

    _isSubmitting = false;
    notifyListeners();
    return false;
  }

  // ── 5. Replace submission file ──────────────────────────────────────────
  // POST /api/v1/submissions/:submissionId/file  (multipart/form-data: file)
  Future<bool> replaceSubmissionFile({
    required String submissionId,
    required String filePath,
    String? fileName,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final name = fileName ?? filePath.split(Platform.pathSeparator).last;
      final multipartFile = await MultipartFile.fromFile(
        filePath,
        filename: name,
        contentType: _resolveMediaType(name),
      );

      final formData = FormData.fromMap({'file': multipartFile});

      final response = await _apiClient.uploadMultipart(
        ApiEndpoints.replaceSubmissionFile(submissionId),
        formData: formData,
      );

      _mySubmission = _parseSubmission(response.data) ?? _mySubmission;
      _isSubmitting = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      debugPrint('replaceSubmissionFile error: $e');
      _errorMessage = 'Failed to replace file.';
    }

    _isSubmitting = false;
    notifyListeners();
    return false;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  List<AssignmentModel> _parseAssignmentList(dynamic payload) {
    List<dynamic> raw = [];
    if (payload is List) {
      raw = payload;
    } else if (payload is Map) {
      final map = Map<String, dynamic>.from(payload);
      for (final k in ['assignments', 'items', 'results', 'records']) {
        if (map[k] is List) { raw = map[k] as List; break; }
      }
      if (raw.isEmpty) {
        for (final k in ['data', 'result']) {
          final nested = map[k];
          if (nested is List) { raw = nested; break; }
          if (nested is Map) {
            for (final nk in ['assignments', 'items', 'results']) {
              if (nested[nk] is List) { raw = nested[nk] as List; break; }
            }
          }
        }
      }
    }
    return raw
        .whereType<Map>()
        .map((item) => AssignmentModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  AssignmentModel? _parseAssignment(dynamic payload) {
    if (payload is! Map) return null;
    final map = Map<String, dynamic>.from(payload);
    final d = map['data'];
    if (d is Map) {
      final a = d['assignment'];
      if (a is Map) return AssignmentModel.fromJson(Map<String, dynamic>.from(a));
      return AssignmentModel.fromJson(Map<String, dynamic>.from(d));
    }
    return null;
  }

  AssignmentSubmissionModel? _parseSubmission(dynamic payload) {
    if (payload is! Map) return null;
    final map = Map<String, dynamic>.from(payload);
    final d = map['data'];
    if (d is Map) {
      final s = d['submission'];
      if (s is Map) return AssignmentSubmissionModel.fromJson(Map<String, dynamic>.from(s));
      return AssignmentSubmissionModel.fromJson(Map<String, dynamic>.from(d));
    }
    return null;
  }


  void clearAssignments() {
    _assignments = [];
    _selectedAssignment = null;
    _mySubmission = null;
    _errorMessage = null;
    notifyListeners();
  }

  // ── Test / Demo helpers ───────────────────────────────────────────────────

  bool isAssignmentSubmitted(String assignmentId) =>
      _submittedIds.contains(assignmentId);

  void seedDemoAssignments() {
    _assignments = [
      AssignmentModel(
        id: 'assign-flutter-ui',
        courseId: 'course-1',
        title: 'Assignment 1: Build a Responsive UI',
        description: 'Create a responsive Flutter screen for mobile and tablet.',
        instructions: 'Use LayoutBuilder and MediaQuery.',
        maximumMarks: 100,
        dueDate: DateTime.now().add(const Duration(days: 3)),
        isPublished: true,
        status: 'SUBMITTED',
      ),
      AssignmentModel(
        id: 'assign-state-mgmt',
        courseId: 'course-1',
        title: 'Assignment 2: State Management Challenge',
        description: 'Implement a shopping cart using Provider.',
        instructions: 'Use ChangeNotifier and Consumer widgets.',
        maximumMarks: 80,
        dueDate: DateTime.now().add(const Duration(days: 7)),
        isPublished: true,
      ),
    ];
    _submittedIds.add('assign-flutter-ui');
    notifyListeners();
  }
}

MediaType _resolveMediaType(String? pathOrName) {
  if (pathOrName != null && pathOrName.isNotEmpty) {
    final lower = pathOrName.toLowerCase();
    if (lower.endsWith('.pdf')) return MediaType('application', 'pdf');
    if (lower.endsWith('.doc')) return MediaType('application', 'msword');
    if (lower.endsWith('.docx')) {
      return MediaType('application',
          'vnd.openxmlformats-officedocument.wordprocessingml.document');
    }
    if (lower.endsWith('.zip')) return MediaType('application', 'zip');
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return MediaType('image', 'jpeg');
    }
    if (lower.endsWith('.png')) return MediaType('image', 'png');
    if (lower.endsWith('.txt')) return MediaType('text', 'plain');
    final lookedUp = lookupMimeType(pathOrName);
    if (lookedUp != null) {
      try {
        return MediaType.parse(lookedUp);
      } catch (_) {}
    }
  }
  return MediaType('application', 'pdf');
}