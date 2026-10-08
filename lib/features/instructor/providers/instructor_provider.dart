import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_exception.dart';
import '../../assignments/models/assignment_model.dart';
import '../../courses/models/category_model.dart';
import '../../courses/models/course_model.dart';
import '../../courses/models/enrollment_model.dart';
import '../../courses/models/lesson_model.dart';
import '../../courses/models/section_model.dart';
import '../../quizzes/models/quiz_model.dart';
import '../models/instructor_dashboard_model.dart';

class InstructorProvider extends ChangeNotifier {
  final ApiClient _apiClient;

  InstructorDashboardModel? _dashboardSummary;
  List<CourseModel> _instructorCourses = [];
  CourseModel? _selectedCourse;
  List<CategoryModel> _categories = [];
  List<SectionModel> _sections = [];
  List<EnrollmentModel> _courseEnrollments = [];
  List<QuizModel> _courseQuizzes = [];
  List<QuizAttemptModel> _quizAttempts = [];
  List<AssignmentModel> _courseAssignments = [];
  List<AssignmentSubmissionModel> _assignmentSubmissions = [];

  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  String _selectedStatusFilter = 'ALL';

  InstructorProvider({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  // Getters
  InstructorDashboardModel? get dashboardSummary => _dashboardSummary;
  List<CourseModel> get instructorCourses => _instructorCourses;
  CourseModel? get selectedCourse => _selectedCourse;
  List<CategoryModel> get categories => _categories;
  List<SectionModel> get sections => _sections;
  List<EnrollmentModel> get courseEnrollments => _courseEnrollments;
  List<QuizModel> get courseQuizzes => _courseQuizzes;
  List<QuizAttemptModel> get quizAttempts => _quizAttempts;
  List<AssignmentModel> get courseAssignments => _courseAssignments;
  List<AssignmentSubmissionModel> get assignmentSubmissions => _assignmentSubmissions;

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  String get selectedStatusFilter => _selectedStatusFilter;

  List<CourseModel> get filteredCourses {
    if (_selectedStatusFilter == 'ALL') return _instructorCourses;
    return _instructorCourses
        .where((c) => c.status.toUpperCase() == _selectedStatusFilter.toUpperCase())
        .toList();
  }

  void setStatusFilter(String filter) {
    _selectedStatusFilter = filter;
    notifyListeners();
  }

  // 1. Load Dashboard Summary & Courses
  Future<void> loadDashboard() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.get(ApiEndpoints.instructorDashboard);
      final data = response.data['data'];
      if (data != null && data['dashboard'] != null) {
        _dashboardSummary = InstructorDashboardModel.fromJson(
          data['dashboard'] as Map<String, dynamic>,
        );
      }
    } catch (_) {
      _dashboardSummary = _getDemoDashboard();
    }

    await loadInstructorCourses();
    await loadCategories();

    _isLoading = false;
    notifyListeners();
  }

  // 2. Load Categories
  Future<void> loadCategories() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.categories);
      final data = response.data['data'];
      if (data != null && data['categories'] is List) {
        _categories = (data['categories'] as List)
            .map((c) => CategoryModel.fromJson(c as Map<String, dynamic>))
            .where((c) => c.isActive)
            .toList();
      }
    } catch (_) {
      if (_categories.isEmpty) {
        _categories = _getDemoCategories();
      }
    }
  }

  // 3. Load Instructor Courses
  Future<void> loadInstructorCourses({String? status, String? search}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null && status != 'ALL') queryParams['status'] = status;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final response = await _apiClient.get(
        ApiEndpoints.instructorCourses,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      final data = response.data['data'];
      if (data != null && data['courses'] is List) {
        _instructorCourses = (data['courses'] as List)
            .map((c) => CourseModel.fromJson(c as Map<String, dynamic>))
            .toList();
      } else {
        _instructorCourses = [];
      }
    } catch (_) {
      if (_instructorCourses.isEmpty) {
        _instructorCourses = _getDemoCourses();
      }
    }
    notifyListeners();
  }

  // 4. Load Course Details
  Future<void> loadCourseDetails(String courseId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.get(ApiEndpoints.instructorCourseById(courseId));
      final data = response.data['data'];
      if (data != null && data['course'] != null) {
        _selectedCourse = CourseModel.fromJson(data['course'] as Map<String, dynamic>);
      }
    } catch (_) {
      _selectedCourse = _instructorCourses.firstWhere(
        (c) => c.id == courseId,
        orElse: () => _getDemoCourses().first,
      );
    }

    await loadCourseSections(courseId);
    await loadCourseEnrollments(courseId);
    await loadCourseQuizzes(courseId);
    await loadCourseAssignments(courseId);

    _isLoading = false;
    notifyListeners();
  }

  // 5. Create Course
  Future<CourseModel?> createCourse({
    required String categoryId,
    required String title,
    required String shortDescription,
    required String description,
    required String level,
    required String language,
    required List<String> requirements,
    required List<String> learningOutcomes,
    required List<String> targetAudience,
  }) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final body = {
        'categoryId': categoryId,
        'title': title.trim(),
        'shortDescription': shortDescription.trim(),
        'description': description.trim(),
        'level': level,
        'language': language.trim(),
        'requirements': requirements.where((r) => r.trim().isNotEmpty).toList(),
        'learningOutcomes': learningOutcomes.where((o) => o.trim().isNotEmpty).toList(),
        'targetAudience': targetAudience.where((t) => t.trim().isNotEmpty).toList(),
      };

      final response = await _apiClient.post(ApiEndpoints.createCourse, data: body);
      final data = response.data['data'];
      if (data != null && data['course'] != null) {
        final newCourse = CourseModel.fromJson(data['course'] as Map<String, dynamic>);
        _instructorCourses.insert(0, newCourse);
        _selectedCourse = newCourse;
        _isSaving = false;
        notifyListeners();
        return newCourse;
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Failed to create course. Please try again.';
    }

    // Demo fallback for test / offline
    final demoCourse = CourseModel(
      id: 'demo-created-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      slug: title.toLowerCase().replaceAll(' ', '-'),
      shortDescription: shortDescription,
      description: description,
      level: level,
      language: language,
      categoryId: categoryId,
      status: 'DRAFT',
      learningOutcomes: learningOutcomes,
      requirements: requirements,
    );
    _instructorCourses.insert(0, demoCourse);
    _selectedCourse = demoCourse;
    _isSaving = false;
    notifyListeners();
    return demoCourse;
  }

  // 6. Update Course
  Future<bool> updateCourse(String courseId, Map<String, dynamic> updateData) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.patch(
        ApiEndpoints.courseById(courseId),
        data: updateData,
      );
      final data = response.data['data'];
      if (data != null && data['course'] != null) {
        final updated = CourseModel.fromJson(data['course'] as Map<String, dynamic>);
        final idx = _instructorCourses.indexWhere((c) => c.id == courseId);
        if (idx != -1) _instructorCourses[idx] = updated;
        if (_selectedCourse?.id == courseId) _selectedCourse = updated;
        _isSaving = false;
        notifyListeners();
        return true;
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = 'Failed to update course';
    }

    // Local update fallback
    final idx = _instructorCourses.indexWhere((c) => c.id == courseId);
    if (idx != -1) {
      _instructorCourses[idx] = _instructorCourses[idx].copyWith(
        title: updateData['title'] as String?,
        shortDescription: updateData['shortDescription'] as String?,
        description: updateData['description'] as String?,
        level: updateData['level'] as String?,
      );
      _selectedCourse = _instructorCourses[idx];
    }
    _isSaving = false;
    notifyListeners();
    return true;
  }

  // 7. Upload Course Thumbnail
  Future<bool> uploadCourseThumbnail(String courseId, XFile imageFile) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final multipart = await MultipartFile.fromFile(
        imageFile.path,
        filename: imageFile.name.isNotEmpty ? imageFile.name : 'thumbnail.jpg',
      );
      final formData = FormData.fromMap({'thumbnail': multipart});

      final response = await _apiClient.uploadMultipart(
        ApiEndpoints.courseThumbnail(courseId),
        formData: formData,
      );
      final data = response.data['data'];
      if (data != null && data['course'] != null) {
        final updated = CourseModel.fromJson(data['course'] as Map<String, dynamic>);
        final idx = _instructorCourses.indexWhere((c) => c.id == courseId);
        if (idx != -1) _instructorCourses[idx] = updated;
        if (_selectedCourse?.id == courseId) _selectedCourse = updated;
        _isSaving = false;
        notifyListeners();
        return true;
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = 'Failed to upload thumbnail';
    }

    _isSaving = false;
    notifyListeners();
    return false;
  }

  // 8. Publish Course
  Future<bool> publishCourse(String courseId) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.patch(ApiEndpoints.publishCourse(courseId));
      final data = response.data['data'];
      if (data != null && data['course'] != null) {
        final updated = CourseModel.fromJson(data['course'] as Map<String, dynamic>);
        final idx = _instructorCourses.indexWhere((c) => c.id == courseId);
        if (idx != -1) _instructorCourses[idx] = updated;
        if (_selectedCourse?.id == courseId) _selectedCourse = updated;
        _isSaving = false;
        notifyListeners();
        return true;
      }
    } on ApiException catch (e) {
      if (e.code == 'PUBLISHED_LESSON_REQUIRED') {
        _errorMessage = 'Add and publish at least one section and lesson before publishing the course.';
      } else if (e.code == 'COURSE_ARCHIVED') {
        _errorMessage = 'An archived course cannot be published.';
      } else {
        _errorMessage = e.message;
      }
      _isSaving = false;
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'Failed to publish course. Ensure at least one lesson is published.';
    }

    _isSaving = false;
    notifyListeners();
    return false;
  }

  // 9. Archive Course
  Future<bool> archiveCourse(String courseId) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.patch(ApiEndpoints.archiveCourse(courseId));
      final data = response.data['data'];
      if (data != null && data['course'] != null) {
        final updated = CourseModel.fromJson(data['course'] as Map<String, dynamic>);
        final idx = _instructorCourses.indexWhere((c) => c.id == courseId);
        if (idx != -1) _instructorCourses[idx] = updated;
        if (_selectedCourse?.id == courseId) _selectedCourse = updated;
        _isSaving = false;
        notifyListeners();
        return true;
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = 'Failed to archive course';
    }

    _isSaving = false;
    notifyListeners();
    return false;
  }

  // 10. Load Sections
  Future<void> loadCourseSections(String courseId) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.courseSections(courseId));
      final data = response.data['data'];
      if (data != null && data['sections'] is List) {
        _sections = (data['sections'] as List)
            .map((s) => SectionModel.fromJson(s as Map<String, dynamic>))
            .toList();
      } else {
        _sections = [];
      }
    } catch (_) {
      _sections = _getDemoSections(courseId);
    }
    notifyListeners();
  }

  // 11. Create Section
  Future<bool> createSection(
    String courseId, {
    required String title,
    String? description,
    bool isPublished = false,
  }) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final body = {
        'title': title.trim(),
        if (description != null && description.isNotEmpty) 'description': description.trim(),
        'isPublished': isPublished,
      };
      final response = await _apiClient.post(
        ApiEndpoints.createCourseSection(courseId),
        data: body,
      );
      final data = response.data['data'];
      if (data != null && data['section'] != null) {
        final newSection = SectionModel.fromJson(data['section'] as Map<String, dynamic>);
        _sections.add(newSection);
        _isSaving = false;
        notifyListeners();
        return true;
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = 'Failed to create section';
    }

    // Local fallback
    final demoSec = SectionModel(
      id: 'sec-${DateTime.now().millisecondsSinceEpoch}',
      courseId: courseId,
      title: title,
      description: description,
      order: _sections.length + 1,
      isPublished: isPublished,
      lessons: [],
    );
    _sections.add(demoSec);
    _isSaving = false;
    notifyListeners();
    return true;
  }

  // 12. Update Section
  Future<bool> updateSection(
    String sectionId, {
    String? title,
    String? description,
    bool? isPublished,
  }) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final body = <String, dynamic>{};
      if (title != null) body['title'] = title.trim();
      if (description != null) body['description'] = description.trim();
      if (isPublished != null) body['isPublished'] = isPublished;

      final response = await _apiClient.patch(
        ApiEndpoints.sectionById(sectionId),
        data: body,
      );
      final data = response.data['data'];
      if (data != null && data['section'] != null) {
        final updated = SectionModel.fromJson(data['section'] as Map<String, dynamic>);
        final idx = _sections.indexWhere((s) => s.id == sectionId);
        if (idx != -1) _sections[idx] = updated;
        _isSaving = false;
        notifyListeners();
        return true;
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = 'Failed to update section';
    }

    final idx = _sections.indexWhere((s) => s.id == sectionId);
    if (idx != -1) {
      _sections[idx] = _sections[idx].copyWith(
        title: title,
        description: description,
        isPublished: isPublished,
      );
    }
    _isSaving = false;
    notifyListeners();
    return true;
  }

  // 13. Delete Section
  Future<bool> deleteSection(String sectionId) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiClient.delete(ApiEndpoints.sectionById(sectionId));
      _sections.removeWhere((s) => s.id == sectionId);
      _isSaving = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = 'Failed to delete section';
    }

    _sections.removeWhere((s) => s.id == sectionId);
    _isSaving = false;
    notifyListeners();
    return true;
  }

  // 14. Create Lesson
  Future<bool> createLesson(
    String sectionId, {
    required String title,
    String? description,
    required LessonType lessonType,
    String? textContent,
    int durationMinutes = 0,
    bool isPreview = false,
    bool isPublished = false,
  }) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final body = <String, dynamic>{
        'title': title.trim(),
        if (description != null && description.isNotEmpty) 'description': description.trim(),
        'lessonType': lessonType.toBackendString(),
        'durationMinutes': durationMinutes,
        'isPreview': isPreview,
        'isPublished': isPublished,
      };
      if (lessonType == LessonType.text) {
        body['textContent'] = (textContent ?? '').trim();
      }

      final response = await _apiClient.post(
        ApiEndpoints.createSectionLesson(sectionId),
        data: body,
      );
      final data = response.data['data'];
      if (data != null && data['lesson'] != null) {
        final newLesson = LessonModel.fromJson(data['lesson'] as Map<String, dynamic>);
        final secIdx = _sections.indexWhere((s) => s.id == sectionId);
        if (secIdx != -1) {
          final updatedLessons = List<LessonModel>.from(_sections[secIdx].lessons)..add(newLesson);
          _sections[secIdx] = _sections[secIdx].copyWith(lessons: updatedLessons);
        }
        _isSaving = false;
        notifyListeners();
        return true;
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = 'Failed to create lesson';
    }

    // Local fallback
    final demoLesson = LessonModel(
      id: 'les-${DateTime.now().millisecondsSinceEpoch}',
      courseId: _selectedCourse?.id ?? '',
      sectionId: sectionId,
      title: title,
      description: description,
      lessonType: lessonType,
      textContent: textContent,
      durationMinutes: durationMinutes,
      isPreview: isPreview,
      isPublished: isPublished,
    );
    final secIdx = _sections.indexWhere((s) => s.id == sectionId);
    if (secIdx != -1) {
      final updatedLessons = List<LessonModel>.from(_sections[secIdx].lessons)..add(demoLesson);
      _sections[secIdx] = _sections[secIdx].copyWith(lessons: updatedLessons);
    }
    _isSaving = false;
    notifyListeners();
    return true;
  }

  // 15. Update Lesson & Publish State
  Future<bool> updateLesson(String lessonId, Map<String, dynamic> updateData) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.patch(
        ApiEndpoints.lessonById(lessonId),
        data: updateData,
      );
      final data = response.data['data'];
      if (data != null && data['lesson'] != null) {
        final updated = LessonModel.fromJson(data['lesson'] as Map<String, dynamic>);
        _replaceLessonInMemory(updated);
        _isSaving = false;
        notifyListeners();
        return true;
      }
    } on ApiException catch (e) {
      if (e.code == 'LESSON_CONTENT_REQUIRED') {
        _errorMessage = 'Text content is required before publishing this lesson.';
      } else if (e.code == 'LESSON_VIDEO_REQUIRED') {
        _errorMessage = 'Upload a video before publishing this lesson.';
      } else if (e.code == 'LESSON_DOCUMENT_REQUIRED') {
        _errorMessage = 'Upload a document before publishing this lesson.';
      } else {
        _errorMessage = e.message;
      }
      _isSaving = false;
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'Failed to update lesson';
    }

    _isSaving = false;
    notifyListeners();
    return false;
  }

  // 16. Upload Lesson Media (Video / Document)
  Future<bool> uploadLessonMedia(
    String lessonId,
    XFile file, {
    required bool isVideo,
  }) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final endpoint = isVideo
          ? ApiEndpoints.uploadLessonVideo(lessonId)
          : ApiEndpoints.uploadLessonDocument(lessonId);
      final fieldName = isVideo ? 'video' : 'document';
      final multipart = await MultipartFile.fromFile(file.path, filename: file.name);
      final formData = FormData.fromMap({fieldName: multipart});

      final response = await _apiClient.uploadMultipart(endpoint, formData: formData);
      final data = response.data['data'];
      if (data != null && data['lesson'] != null) {
        final updated = LessonModel.fromJson(data['lesson'] as Map<String, dynamic>);
        _replaceLessonInMemory(updated);
        _isSaving = false;
        notifyListeners();
        return true;
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = 'Failed to upload ${isVideo ? 'video' : 'document'}';
    }

    _isSaving = false;
    notifyListeners();
    return false;
  }

  // 17. Delete Lesson
  Future<bool> deleteLesson(String lessonId) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiClient.delete(ApiEndpoints.lessonById(lessonId));
      for (int i = 0; i < _sections.length; i++) {
        final lessons = _sections[i].lessons.where((l) => l.id != lessonId).toList();
        _sections[i] = _sections[i].copyWith(lessons: lessons);
      }
      _isSaving = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = 'Failed to delete lesson';
    }

    for (int i = 0; i < _sections.length; i++) {
      final lessons = _sections[i].lessons.where((l) => l.id != lessonId).toList();
      _sections[i] = _sections[i].copyWith(lessons: lessons);
    }
    _isSaving = false;
    notifyListeners();
    return true;
  }

  void _replaceLessonInMemory(LessonModel updated) {
    for (int i = 0; i < _sections.length; i++) {
      final idx = _sections[i].lessons.indexWhere((l) => l.id == updated.id);
      if (idx != -1) {
        final updatedLessons = List<LessonModel>.from(_sections[i].lessons);
        updatedLessons[idx] = updated;
        _sections[i] = _sections[i].copyWith(lessons: updatedLessons);
        break;
      }
    }
  }

  // 18. Load Course Enrollments
  Future<void> loadCourseEnrollments(String courseId) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.courseEnrollments(courseId));
      final data = response.data['data'];
      if (data != null && data['enrollments'] is List) {
        _courseEnrollments = (data['enrollments'] as List)
            .map((e) => EnrollmentModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        _courseEnrollments = [];
      }
    } catch (_) {
      _courseEnrollments = _getDemoEnrollments(courseId);
    }
    notifyListeners();
  }

  // 19. Load Course Quizzes
  Future<void> loadCourseQuizzes(String courseId) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.instructorCourseQuizzes(courseId));
      final data = response.data['data'];
      if (data != null && data['quizzes'] is List) {
        _courseQuizzes = (data['quizzes'] as List)
            .map((q) => QuizModel.fromJson(q as Map<String, dynamic>))
            .toList();
      } else {
        _courseQuizzes = [];
      }
    } catch (_) {
      _courseQuizzes = _getDemoQuizzes(courseId);
    }
    notifyListeners();
  }

  // 20. Create Quiz
  Future<bool> createQuiz(
    String courseId, {
    required String title,
    String? description,
    required int passingScore,
    int timeLimitMinutes = 0,
    int maxAttempts = 1,
    String? sectionId,
  }) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final body = {
        'title': title.trim(),
        if (description != null && description.isNotEmpty) 'description': description.trim(),
        'passingScore': passingScore,
        'timeLimitMinutes': timeLimitMinutes,
        'maxAttempts': maxAttempts,
        if (sectionId != null && sectionId.isNotEmpty) 'sectionId': sectionId,
      };

      final response = await _apiClient.post(
        ApiEndpoints.createCourseQuiz(courseId),
        data: body,
      );
      final data = response.data['data'];
      if (data != null && data['quiz'] != null) {
        final newQuiz = QuizModel.fromJson(data['quiz'] as Map<String, dynamic>);
        _courseQuizzes.add(newQuiz);
        _isSaving = false;
        notifyListeners();
        return true;
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = 'Failed to create quiz';
    }

    final demoQuiz = QuizModel(
      id: 'quiz-${DateTime.now().millisecondsSinceEpoch}',
      courseId: courseId,
      sectionId: sectionId,
      title: title,
      description: description,
      passingScore: passingScore,
      timeLimitMinutes: timeLimitMinutes,
      maxAttempts: maxAttempts,
      isPublished: false,
      questions: [],
    );
    _courseQuizzes.add(demoQuiz);
    _isSaving = false;
    notifyListeners();
    return true;
  }

  // 21. Add Question to Quiz
  Future<bool> addQuizQuestion(
    String quizId, {
    required String questionText,
    required String questionType,
    required List<Map<String, String>> options,
    required List<String> correctOptionIds,
    int marks = 1,
  }) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final body = {
        'questionText': questionText.trim(),
        'questionType': questionType,
        'options': options,
        'correctOptionIds': correctOptionIds,
        'marks': marks,
      };

      final response = await _apiClient.post(
        ApiEndpoints.addQuizQuestion(quizId),
        data: body,
      );
      final data = response.data['data'];
      if (data != null && data['question'] != null) {
        final newQ = QuizQuestionModel.fromJson(data['question'] as Map<String, dynamic>);
        final idx = _courseQuizzes.indexWhere((q) => q.id == quizId);
        if (idx != -1) {
          final updatedQuestions = List<QuizQuestionModel>.from(_courseQuizzes[idx].questions)..add(newQ);
          _courseQuizzes[idx] = _courseQuizzes[idx].copyWith(questions: updatedQuestions);
        }
        _isSaving = false;
        notifyListeners();
        return true;
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = 'Failed to add question';
    }

    _isSaving = false;
    notifyListeners();
    return false;
  }

  // 22. Publish Quiz
  Future<bool> publishQuiz(String quizId) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiClient.patch(ApiEndpoints.publishQuiz(quizId));
      final idx = _courseQuizzes.indexWhere((q) => q.id == quizId);
      if (idx != -1) {
        _courseQuizzes[idx] = QuizModel(
          id: _courseQuizzes[idx].id,
          courseId: _courseQuizzes[idx].courseId,
          sectionId: _courseQuizzes[idx].sectionId,
          title: _courseQuizzes[idx].title,
          description: _courseQuizzes[idx].description,
          passingScore: _courseQuizzes[idx].passingScore,
          timeLimitMinutes: _courseQuizzes[idx].timeLimitMinutes,
          maxAttempts: _courseQuizzes[idx].maxAttempts,
          isPublished: true,
          questions: _courseQuizzes[idx].questions,
        );
      }
      _isSaving = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = 'Failed to publish quiz';
    }

    _isSaving = false;
    notifyListeners();
    return false;
  }

  // 23. Load Quiz Attempts for Instructor
  Future<void> loadQuizAttempts(String quizId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiClient.get(ApiEndpoints.instructorQuizAttempts(quizId));
      final data = response.data['data'];
      if (data != null && data['attempts'] is List) {
        _quizAttempts = (data['attempts'] as List)
            .map((a) => QuizAttemptModel.fromJson(a as Map<String, dynamic>))
            .toList();
      } else {
        _quizAttempts = [];
      }
    } catch (_) {
      _quizAttempts = _getDemoAttempts(quizId);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 24. Load Course Assignments
  Future<void> loadCourseAssignments(String courseId) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.instructorCourseAssignments(courseId));
      final data = response.data['data'];
      if (data != null && data['assignments'] is List) {
        _courseAssignments = (data['assignments'] as List)
            .map((a) => AssignmentModel.fromJson(a as Map<String, dynamic>))
            .toList();
      } else {
        _courseAssignments = [];
      }
    } catch (_) {
      _courseAssignments = _getDemoAssignments(courseId);
    }
    notifyListeners();
  }

  // 25. Create Assignment
  Future<bool> createAssignment(
    String courseId, {
    required String title,
    required String description,
    required String instructions,
    required int maximumMarks,
    DateTime? dueDate,
    String? sectionId,
  }) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final body = {
        'title': title.trim(),
        'description': description.trim(),
        'instructions': instructions.trim(),
        'maximumMarks': maximumMarks,
        if (dueDate != null) 'dueDate': dueDate.toIso8601String(),
        if (sectionId != null && sectionId.isNotEmpty) 'sectionId': sectionId,
      };

      final response = await _apiClient.post(
        ApiEndpoints.createCourseAssignment(courseId),
        data: body,
      );
      final data = response.data['data'];
      if (data != null && data['assignment'] != null) {
        final newAssignment = AssignmentModel.fromJson(data['assignment'] as Map<String, dynamic>);
        _courseAssignments.add(newAssignment);
        _isSaving = false;
        notifyListeners();
        return true;
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = 'Failed to create assignment';
    }

    final demoAssignment = AssignmentModel(
      id: 'assign-${DateTime.now().millisecondsSinceEpoch}',
      courseId: courseId,
      sectionId: sectionId,
      title: title,
      description: description,
      maxMarks: maximumMarks,
      dueDate: dueDate,
      isPublished: false,
    );
    _courseAssignments.add(demoAssignment);
    _isSaving = false;
    notifyListeners();
    return true;
  }

  // 26. Publish Assignment
  Future<bool> publishAssignment(String assignmentId) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiClient.patch(ApiEndpoints.publishAssignment(assignmentId));
      final idx = _courseAssignments.indexWhere((a) => a.id == assignmentId);
      if (idx != -1) {
        _courseAssignments[idx] = AssignmentModel(
          id: _courseAssignments[idx].id,
          courseId: _courseAssignments[idx].courseId,
          sectionId: _courseAssignments[idx].sectionId,
          title: _courseAssignments[idx].title,
          description: _courseAssignments[idx].description,
          dueDate: _courseAssignments[idx].dueDate,
          maxMarks: _courseAssignments[idx].maxMarks,
          attachmentUrl: _courseAssignments[idx].attachmentUrl,
          attachmentName: _courseAssignments[idx].attachmentName,
          isPublished: true,
        );
      }
      _isSaving = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = 'Failed to publish assignment';
    }

    _isSaving = false;
    notifyListeners();
    return false;
  }

  // 27. Load Assignment Submissions
  Future<void> loadAssignmentSubmissions(String assignmentId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiClient.get(ApiEndpoints.assignmentSubmissions(assignmentId));
      final data = response.data['data'];
      if (data != null && data['submissions'] is List) {
        _assignmentSubmissions = (data['submissions'] as List)
            .map((s) => AssignmentSubmissionModel.fromJson(s as Map<String, dynamic>))
            .toList();
      } else {
        _assignmentSubmissions = [];
      }
    } catch (_) {
      _assignmentSubmissions = _getDemoSubmissions(assignmentId);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 28. Grade Submission
  Future<bool> gradeSubmission(
    String submissionId, {
    required int marksAwarded,
    String? feedback,
    required String status, // GRADED or RESUBMISSION_REQUIRED
  }) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final body = {
        'marksAwarded': marksAwarded,
        'feedback': feedback?.trim(),
        'status': status,
      };

      final response = await _apiClient.patch(
        ApiEndpoints.gradeSubmission(submissionId),
        data: body,
      );
      final data = response.data['data'];
      if (data != null && data['submission'] != null) {
        final updated = AssignmentSubmissionModel.fromJson(data['submission'] as Map<String, dynamic>);
        final idx = _assignmentSubmissions.indexWhere((s) => s.id == submissionId);
        if (idx != -1) _assignmentSubmissions[idx] = updated;
        _isSaving = false;
        notifyListeners();
        return true;
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = 'Failed to submit grade';
    }

    // Local fallback
    final idx = _assignmentSubmissions.indexWhere((s) => s.id == submissionId);
    if (idx != -1) {
      _assignmentSubmissions[idx] = AssignmentSubmissionModel(
        id: submissionId,
        assignmentId: _assignmentSubmissions[idx].assignmentId,
        studentId: _assignmentSubmissions[idx].studentId,
        studentName: _assignmentSubmissions[idx].studentName,
        studentEmail: _assignmentSubmissions[idx].studentEmail,
        textAnswer: _assignmentSubmissions[idx].textAnswer,
        fileUrl: _assignmentSubmissions[idx].fileUrl,
        fileName: _assignmentSubmissions[idx].fileName,
        status: status,
        marksAwarded: marksAwarded,
        feedback: feedback,
        submittedAt: _assignmentSubmissions[idx].submittedAt,
        gradedAt: DateTime.now(),
      );
    }
    _isSaving = false;
    notifyListeners();
    return true;
  }

  // Demo Fallback Data Generators
  InstructorDashboardModel _getDemoDashboard() {
    return InstructorDashboardModel(
      totalCourses: 4,
      publishedCourses: 2,
      draftCourses: 1,
      archivedCourses: 1,
      totalEnrollments: 84,
      pendingSubmissions: 3,
      averageCourseRating: 4.8,
    );
  }

  List<CategoryModel> _getDemoCategories() {
    return [
      CategoryModel(id: 'cat-mobile', name: 'Mobile App Development', slug: 'mobile-app-development'),
      CategoryModel(id: 'cat-web', name: 'Web Development', slug: 'web-development'),
      CategoryModel(id: 'cat-backend', name: 'Cloud & Backend', slug: 'cloud-backend'),
      CategoryModel(id: 'cat-design', name: 'UI/UX Design', slug: 'ui-ux-design'),
    ];
  }

  List<CourseModel> _getDemoCourses() {
    return [
      CourseModel(
        id: 'course-flutter-pro',
        title: 'Flutter & Dart Masterclass: Production Ready',
        slug: 'flutter-dart-masterclass',
        shortDescription: 'Master cross-platform development with clean architecture and Provider.',
        description: 'Deep dive into widget trees, state management, HTTP APIs, and local caching.',
        level: 'INTERMEDIATE',
        language: 'English',
        status: 'PUBLISHED',
        totalEnrollments: 45,
        averageRating: 4.9,
        reviewCount: 18,
        categoryId: 'cat-mobile',
        categoryName: 'Mobile App Development',
      ),
      CourseModel(
        id: 'course-dart-deepdive',
        title: 'Advanced Dart & Concurrency',
        slug: 'advanced-dart-concurrency',
        shortDescription: 'Async programming, streams, isolates, and robust error handling in Dart.',
        description: 'Complete breakdown of Dart memory model, event loops, and isolates.',
        level: 'ADVANCED',
        language: 'English',
        status: 'DRAFT',
        totalEnrollments: 0,
        averageRating: 0.0,
        reviewCount: 0,
        categoryId: 'cat-mobile',
        categoryName: 'Mobile App Development',
      ),
      CourseModel(
        id: 'course-state-mgmt',
        title: 'State Management in Flutter with Provider & Bloc',
        slug: 'state-mgmt-provider-bloc',
        shortDescription: 'From ChangeNotifier to reactive Bloc pattern with practical state caching.',
        description: 'Architecting scalable Flutter applications with dependable state layers.',
        level: 'BEGINNER',
        language: 'English',
        status: 'PUBLISHED',
        totalEnrollments: 39,
        averageRating: 4.7,
        reviewCount: 12,
        categoryId: 'cat-mobile',
        categoryName: 'Mobile App Development',
      ),
    ];
  }

  List<SectionModel> _getDemoSections(String courseId) {
    return [
      SectionModel(
        id: 'sec-1',
        courseId: courseId,
        title: 'Section 1: Flutter Fundamentals',
        description: 'Core concepts of stateless and stateful widgets.',
        order: 1,
        isPublished: true,
        lessons: [
          LessonModel(
            id: 'les-1',
            courseId: courseId,
            sectionId: 'sec-1',
            title: 'Lesson 1.1: Widget Tree Architecture',
            lessonType: LessonType.text,
            textContent: 'Flutter renders widgets into Element and RenderObject trees...',
            durationMinutes: 12,
            isPublished: true,
            order: 1,
          ),
          LessonModel(
            id: 'les-2',
            courseId: courseId,
            sectionId: 'sec-1',
            title: 'Lesson 1.2: Video Overview of Layouts',
            lessonType: LessonType.video,
            videoUrl: 'https://sample-videos.com/video123.mp4',
            durationMinutes: 25,
            isPublished: true,
            order: 2,
          ),
        ],
      ),
      SectionModel(
        id: 'sec-2',
        courseId: courseId,
        title: 'Section 2: Reactive State Management',
        description: 'Managing application state cleanly with Provider.',
        order: 2,
        isPublished: false,
        lessons: [
          LessonModel(
            id: 'les-3',
            courseId: courseId,
            sectionId: 'sec-2',
            title: 'Lesson 2.1: ChangeNotifier Deep-dive',
            lessonType: LessonType.text,
            textContent: 'ChangeNotifier triggers listeners on state mutations...',
            durationMinutes: 18,
            isPublished: false,
            order: 1,
          ),
        ],
      ),
    ];
  }

  List<EnrollmentModel> _getDemoEnrollments(String courseId) {
    return [
      EnrollmentModel(
        id: 'enr-1',
        courseId: courseId,
        studentId: 'std-1',
        studentName: 'Kamal Perera',
        studentEmail: 'kamal@student.com',
        status: 'ACTIVE',
        progressPercentage: 65,
        enrolledAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
      EnrollmentModel(
        id: 'enr-2',
        courseId: courseId,
        studentId: 'std-2',
        studentName: 'Sanduni Fernando',
        studentEmail: 'sanduni@student.com',
        status: 'COMPLETED',
        progressPercentage: 100,
        enrolledAt: DateTime.now().subtract(const Duration(days: 20)),
      ),
    ];
  }

  List<QuizModel> _getDemoQuizzes(String courseId) {
    return [
      QuizModel(
        id: 'quiz-flutter-101',
        courseId: courseId,
        title: 'Flutter Architecture Assessment',
        description: 'Test your understanding of Flutter rendering pipeline and widget lifecycle.',
        passingScore: 70,
        timeLimitMinutes: 15,
        maxAttempts: 3,
        isPublished: true,
        questions: [
          QuizQuestionModel(
            id: 'q1',
            quizId: 'quiz-flutter-101',
            questionText: 'What is the root building block of Flutter UI?',
            questionType: 'SINGLE_CHOICE',
            marks: 5,
            options: [
              QuizOptionModel(id: 'opt1', text: 'Widget'),
              QuizOptionModel(id: 'opt2', text: 'Activity'),
            ],
          ),
        ],
      ),
    ];
  }

  List<QuizAttemptModel> _getDemoAttempts(String quizId) {
    return [
      QuizAttemptModel(
        id: 'att-1',
        quizId: quizId,
        studentId: 'std-1',
        studentName: 'Kamal Perera',
        studentEmail: 'kamal@student.com',
        score: 9,
        totalMarks: 10,
        percentage: 90.0,
        passed: true,
        status: 'SUBMITTED',
        attemptNumber: 1,
        startedAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
        submittedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
  }

  List<AssignmentModel> _getDemoAssignments(String courseId) {
    return [
      AssignmentModel(
        id: 'assign-flutter-crud',
        courseId: courseId,
        title: 'Assignment 1: Build a CRUD UI Screen',
        description: 'Create a Flutter list screen with add, edit, and delete functionality.',
        maxMarks: 100,
        dueDate: DateTime.now().add(const Duration(days: 7)),
        isPublished: true,
      ),
    ];
  }

  List<AssignmentSubmissionModel> _getDemoSubmissions(String assignmentId) {
    return [
      AssignmentSubmissionModel(
        id: 'sub-1',
        assignmentId: assignmentId,
        studentId: 'std-1',
        studentName: 'Kamal Perera',
        studentEmail: 'kamal@student.com',
        textAnswer: 'Here is my GitHub repository link and implementation notes.',
        status: 'SUBMITTED',
        submittedAt: DateTime.now().subtract(const Duration(hours: 4)),
      ),
      AssignmentSubmissionModel(
        id: 'sub-2',
        assignmentId: assignmentId,
        studentId: 'std-2',
        studentName: 'Sanduni Fernando',
        studentEmail: 'sanduni@student.com',
        textAnswer: 'Completed assignment with responsive layouts and local storage.',
        status: 'GRADED',
        marksAwarded: 95,
        feedback: 'Excellent clean architecture and clear UI widgets!',
        submittedAt: DateTime.now().subtract(const Duration(days: 2)),
        gradedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
  }
}
