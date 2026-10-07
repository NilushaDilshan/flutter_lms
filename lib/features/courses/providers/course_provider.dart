import 'package:flutter/foundation.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_exception.dart';
import '../models/category_model.dart';
import '../models/course_model.dart';
import '../models/enrollment_model.dart';
import '../models/lesson_model.dart';
import '../models/progress_model.dart';
import '../models/section_model.dart';

class CourseProvider extends ChangeNotifier {
  final ApiClient _apiClient;

  List<CategoryModel> _categories = [];
  List<CourseModel> _courses = [];
  List<EnrollmentModel> _myEnrollments = [];
  CourseModel? _selectedCourse;
  List<SectionModel> _sections = [];
  CourseProgressModel? _currentProgress;

  bool _isLoading = false;
  bool _isLoadingDetails = false;
  bool _isActionLoading = false;
  String? _errorMessage;

  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasNextPage = false;
  bool _isLoadingMore = false;

  String? _selectedCategoryId;
  String? _selectedLevel;
  String _searchQuery = '';

  CourseProvider({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  List<CategoryModel> get categories => _categories;
  List<CourseModel> get courses => _courses;
  List<EnrollmentModel> get myEnrollments => _myEnrollments;
  CourseModel? get selectedCourse => _selectedCourse;
  List<SectionModel> get sections => _sections;
  CourseProgressModel? get currentProgress => _currentProgress;

  bool get isLoading => _isLoading;
  bool get isLoadingDetails => _isLoadingDetails;
  bool get isActionLoading => _isActionLoading;
  String? get errorMessage => _errorMessage;

  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  bool get hasNextPage => _hasNextPage;
  bool get isLoadingMore => _isLoadingMore;

  String? get selectedCategoryId => _selectedCategoryId;
  String? get selectedLevel => _selectedLevel;
  String get searchQuery => _searchQuery;

  // ── FILTER ACTIONS ────────────────────────────────────────────────────────
  void setCategoryFilter(String? categoryId) {
    if (_selectedCategoryId == categoryId) {
      _selectedCategoryId = null; // Toggle off
    } else {
      _selectedCategoryId = categoryId;
    }
    notifyListeners();
    loadCourses();
  }

  void setLevelFilter(String? level) {
    if (_selectedLevel == level) {
      _selectedLevel = null;
    } else {
      _selectedLevel = level;
    }
    notifyListeners();
    loadCourses();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
    loadCourses();
  }

  // ── LOAD CATEGORIES ───────────────────────────────────────────────────────
  Future<void> loadCategories() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.categories);
      final data = response.data['data'];
      if (data != null && data['categories'] is List) {
        _categories = (data['categories'] as List)
            .whereType<Map<String, dynamic>>()
            .map((c) => CategoryModel.fromJson(c))
            .where((c) => c.isActive)
            .toList();
        notifyListeners();
      }
    } catch (_) {
      // Demo fallback categories if offline
      if (_categories.isEmpty) {
        _categories = _getDemoCategories();
        notifyListeners();
      }
    }
  }

  // ── LOAD PUBLISHED COURSES ────────────────────────────────────────────────
  Future<void> loadCourses({bool refresh = true}) async {
    if (refresh) {
      _isLoading = true;
      _currentPage = 1;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final Map<String, dynamic> queryParams = {
        'page': _currentPage,
        'limit': 10,
      };

      if (_selectedCategoryId != null && _selectedCategoryId!.isNotEmpty) {
        queryParams['category'] = _selectedCategoryId;
      }
      if (_selectedLevel != null && _selectedLevel!.isNotEmpty) {
        queryParams['level'] = _selectedLevel;
      }
      if (_searchQuery.trim().isNotEmpty) {
        queryParams['search'] = _searchQuery.trim();
      }

      final response = await _apiClient.get(
        ApiEndpoints.publishedCourses,
        queryParameters: queryParams,
      );

      final data = response.data['data'];
      if (data != null) {
        if (data['courses'] is List) {
          final fetched = (data['courses'] as List)
              .whereType<Map<String, dynamic>>()
              .map((c) => CourseModel.fromJson(c))
              .toList();
          if (refresh) {
            _courses = fetched;
          } else {
            _courses.addAll(fetched);
          }
        }
        if (data['pagination'] is Map<String, dynamic>) {
          final pag = data['pagination'] as Map<String, dynamic>;
          _currentPage = (pag['page'] as num?)?.toInt() ?? _currentPage;
          _totalPages = (pag['totalPages'] as num?)?.toInt() ?? 1;
          _hasNextPage = pag['hasNextPage'] as bool? ?? false;
        } else {
          _hasNextPage = false;
        }
      }
    } catch (e) {
      // Fallback demo courses if offline
      if (refresh) {
        _courses = _getFilteredDemoCourses();
        _hasNextPage = false;
      }
    } finally {
      _isLoading = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreCourses() async {
    if (!_hasNextPage || _isLoadingMore || _isLoading) return;
    _isLoadingMore = true;
    _currentPage++;
    notifyListeners();
    await loadCourses(refresh: false);
  }

  // ── LOAD COURSE DETAILS & SECTIONS ────────────────────────────────────────
  Future<void> loadCourseDetails(String courseId) async {
    _isLoadingDetails = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Fetch Course Detail
      final courseResponse = await _apiClient.get(ApiEndpoints.courseById(courseId));
      final courseData = courseResponse.data['data'];
      if (courseData != null && courseData['course'] != null) {
        _selectedCourse = CourseModel.fromJson(courseData['course'] as Map<String, dynamic>);
      }

      // 2. Fetch Course Sections
      try {
        final sectionsResponse = await _apiClient.get(ApiEndpoints.courseSections(courseId));
        final sectionsData = sectionsResponse.data['data'];
        if (sectionsData != null && sectionsData['sections'] is List) {
          final rawSections = (sectionsData['sections'] as List)
              .whereType<Map<String, dynamic>>()
              .map((s) => SectionModel.fromJson(s))
              .toList();

          // Fetch lessons for each section
          List<SectionModel> populatedSections = [];
          for (final s in rawSections) {
            try {
              final lessonsResponse = await _apiClient.get(ApiEndpoints.sectionLessons(s.id));
              final lessonsData = lessonsResponse.data['data'];
              if (lessonsData != null && lessonsData['lessons'] is List) {
                final lessonsList = (lessonsData['lessons'] as List)
                    .whereType<Map<String, dynamic>>()
                    .map((l) => LessonModel.fromJson(l))
                    .toList();
                populatedSections.add(s.copyWith(lessons: lessonsList));
              } else {
                populatedSections.add(s);
              }
            } catch (_) {
              populatedSections.add(s);
            }
          }
          _sections = populatedSections;
        }
      } catch (_) {
        _sections = _getDemoSections(courseId);
      }

      // 3. Load Progress if enrolled
      if (isEnrolled(courseId)) {
        await loadCourseProgress(courseId);
      }
    } catch (e) {
      // Offline fallback
      _selectedCourse ??= _courses.firstWhere(
        (c) => c.id == courseId,
        orElse: () => _getDemoCourses().first,
      );
      _sections = _getDemoSections(courseId);
    } finally {
      _isLoadingDetails = false;
      notifyListeners();
    }
  }

  // ── ENROLL IN COURSE ──────────────────────────────────────────────────────
  Future<bool> enrollInCourse(String courseId) async {
    _isActionLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.post(ApiEndpoints.enrollCourse(courseId));
      final data = response.data['data'];
      if (data != null && data['enrollment'] != null) {
        final newEnrollment = EnrollmentModel.fromJson(data['enrollment'] as Map<String, dynamic>);
        _myEnrollments.removeWhere((e) => e.courseId == courseId);
        _myEnrollments.add(newEnrollment);
      }
      // Reload details + progress now that enrollment is confirmed
      await loadCourseDetails(courseId);
      await loadCourseProgress(courseId);
      _isActionLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      if (e is ApiException) {
        if (e.statusCode == 409) {
          // Already enrolled on backend: sync existing enrollment & progress
          await loadMyEnrollments();
          await loadCourseProgress(courseId);
          _isActionLoading = false;
          _errorMessage = null;
          notifyListeners();
          return true;
        } else if (e.statusCode == 403) {
          // 403 Role / Ownership error (e.g. instructors or admins cannot enroll as students)
          _errorMessage = e.message.isNotEmpty
              ? e.message
              : 'Enrollment restricted: Only student accounts may enroll in courses.';
          _isActionLoading = false;
          notifyListeners();
          return false;
        } else if (e.statusCode != 503 && e.statusCode != 408) {
          // Real backend validation or client error
          _errorMessage = e.message;
          _isActionLoading = false;
          notifyListeners();
          return false;
        }
      }

      // Offline simulation fallback ONLY if connection timeout / service unavailable
      final demoEnrollment = EnrollmentModel(
        id: 'demo-enroll-${DateTime.now().millisecondsSinceEpoch}',
        studentId: 'student-me',
        courseId: courseId,
        course: _selectedCourse,
        progressPercentage: 0,
        enrolledAt: DateTime.now(),
      );
      _myEnrollments.removeWhere((e) => e.courseId == courseId);
      _myEnrollments.add(demoEnrollment);

      _isActionLoading = false;
      notifyListeners();
      return true;
    }
  }

  // ── LOAD MY ENROLLMENTS ───────────────────────────────────────────────────
  Future<void> loadMyEnrollments() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.myEnrollments);
      final data = response.data['data'];
      if (data != null && data['enrollments'] is List) {
        _myEnrollments = (data['enrollments'] as List)
            .whereType<Map<String, dynamic>>()
            .map((e) => EnrollmentModel.fromJson(e))
            .toList();
        notifyListeners();
      }
    } catch (_) {
      // Keep existing or demo
    }
  }

  // ── LOAD COURSE PROGRESS ──────────────────────────────────────────────────
  Future<void> loadCourseProgress(String courseId) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.courseProgress(courseId));
      final data = response.data['data'];
      if (data != null) {
        _currentProgress = CourseProgressModel.fromJson(data as Map<String, dynamic>);
        // Update lesson completion status in sections
        _updateLessonCompletionStatuses();
        notifyListeners();
      }
    } catch (_) {
      // Keep existing progress
    }
  }

  void _updateLessonCompletionStatuses() {
    if (_currentProgress == null) return;
    List<SectionModel> updated = [];
    for (final s in _sections) {
      final updatedLessons = s.lessons.map((l) {
        final isDone = _currentProgress!.isLessonCompleted(l.id);
        return l.copyWith(isCompleted: isDone);
      }).toList();
      updated.add(s.copyWith(lessons: updatedLessons));
    }
    _sections = updated;
  }

  // ── LESSON PROGRESS: START & COMPLETE ─────────────────────────────────────
  Future<void> startLesson(String lessonId) async {
    try {
      await _apiClient.patch(ApiEndpoints.startLesson(lessonId));
    } catch (_) {}
  }

  Future<bool> completeLesson(String lessonId, String courseId) async {
    _isActionLoading = true;
    notifyListeners();

    try {
      final response = await _apiClient.patch(ApiEndpoints.completeLesson(lessonId));
      final data = response.data['data'];

      int? backendPct;
      int? backendTotal;
      int? backendCompleted;

      // Backend returns { lessonProgress: {...}, courseProgress: {progressPercentage, totalLessons, completedLessons} }
      if (data != null && data['courseProgress'] is Map<String, dynamic>) {
        final cp = data['courseProgress'] as Map<String, dynamic>;
        backendPct = (cp['progressPercentage'] as num?)?.toInt();
        backendTotal = (cp['totalLessons'] as num?)?.toInt();
        backendCompleted = (cp['completedLessons'] as num?)?.toInt();
      }

      // Mark locally with exact backend stats or fallback calculated stats
      _markLessonCompletedLocally(
        lessonId,
        courseId: courseId,
        explicitPercentage: backendPct,
        explicitTotal: backendTotal,
        explicitCompleted: backendCompleted,
      );

      // Refresh official backend-calculated progress directly from server
      await loadCourseProgress(courseId);

      _isActionLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      // Offline fallback: mark lesson completed locally
      _markLessonCompletedLocally(lessonId, courseId: courseId);
      _isActionLoading = false;
      notifyListeners();
      return true;
    }
  }

  void _markLessonCompletedLocally(
    String lessonId, {
    String? courseId,
    int? explicitPercentage,
    int? explicitTotal,
    int? explicitCompleted,
  }) {
    List<SectionModel> updated = [];
    int total = 0;
    int completed = 0;

    for (final s in _sections) {
      final updatedLessons = s.lessons.map((l) {
        total++;
        if (l.id == lessonId || l.isCompleted) {
          completed++;
          return l.copyWith(isCompleted: true);
        }
        return l;
      }).toList();
      updated.add(s.copyWith(lessons: updatedLessons));
    }
    _sections = updated;

    final finalTotal = explicitTotal ?? (total > 0 ? total : (_currentProgress?.totalLessons ?? 0));
    final finalCompleted = explicitCompleted ?? (completed > 0 ? completed : (_currentProgress?.completedLessons ?? 0));
    final finalPct = explicitPercentage ?? (finalTotal > 0 ? ((finalCompleted / finalTotal) * 100).round() : 0);
    final Map<String, String> statusMap = Map.from(_currentProgress?.lessonStatusMap ?? {});
    statusMap[lessonId] = 'COMPLETED';

    _currentProgress = CourseProgressModel(
      progressPercentage: finalPct,
      totalLessons: finalTotal,
      completedLessons: finalCompleted,
      lessonStatusMap: statusMap,
    );

    // Also update _myEnrollments so MyCoursesScreen and dashboard show updated progress immediately
    if (courseId != null) {
      final enrollIndex = _myEnrollments.indexWhere((e) => e.courseId == courseId);
      if (enrollIndex != -1) {
        _myEnrollments[enrollIndex] = _myEnrollments[enrollIndex].copyWith(
          progressPercentage: finalPct,
          status: finalPct >= 100 ? 'COMPLETED' : 'ACTIVE',
        );
      }
    }
  }

  bool isEnrolled(String courseId) {
    return _myEnrollments.any((e) => e.courseId == courseId && e.isActive);
  }

  EnrollmentModel? getEnrollment(String courseId) {
    try {
      return _myEnrollments.firstWhere((e) => e.courseId == courseId);
    } catch (_) {
      return null;
    }
  }

  // ── DEMO FALLBACK DATA ────────────────────────────────────────────────────
  List<CategoryModel> _getDemoCategories() {
    return [
      CategoryModel(id: 'cat-1', name: 'Mobile App Development', slug: 'mobile-app-development'),
      CategoryModel(id: 'cat-2', name: 'Frontend Development', slug: 'frontend-development'),
      CategoryModel(id: 'cat-3', name: 'Backend Development', slug: 'backend-development'),
      CategoryModel(id: 'cat-4', name: 'Web Development', slug: 'web-development'),
    ];
  }

  List<CourseModel> _getDemoCourses() {
    return [
      CourseModel(
        id: '6a5c39ae384147c91b73906a',
        title: 'Flutter Development for Beginners',
        slug: 'flutter-development-for-beginners',
        shortDescription: 'Learn Dart and Flutter by building complete mobile applications from scratch.',
        description: 'Comprehensive course covering Flutter widgets, state management, REST APIs, and responsive design for Android and iOS.',
        level: 'BEGINNER',
        language: 'English',
        isFree: true,
        price: 0,
        averageRating: 4.9,
        reviewCount: 38,
        totalEnrollments: 142,
        categoryId: 'cat-1',
        categoryName: 'Mobile App Development',
        learningOutcomes: [
          'Understand Dart fundamentals & async programming',
          'Build responsive layouts and complex UI widgets',
          'Implement state management with Provider',
          'Integrate REST APIs and offline persistence',
        ],
        requirements: [
          'Basic programming concepts (loops, functions)',
          'Computer with Flutter SDK installed',
        ],
      ),
      CourseModel(
        id: 'course-2',
        title: 'Mastering Advanced Dart & Flutter Architecture',
        slug: 'advanced-flutter-architecture',
        shortDescription: 'Clean Architecture, BLoC, Queued Interceptors, and Production Testing.',
        description: 'Deep dive into scalable Flutter architectural patterns, modularization, custom painters, and automated CI/CD workflows.',
        level: 'ADVANCED',
        language: 'English',
        isFree: false,
        price: 49.99,
        averageRating: 4.8,
        reviewCount: 19,
        totalEnrollments: 85,
        categoryId: 'cat-1',
        categoryName: 'Mobile App Development',
        learningOutcomes: [
          'Design scalable clean architecture apps',
          'Advanced Dio interceptors & token rotation',
          'Comprehensive unit, widget and integration tests',
        ],
      ),
      CourseModel(
        id: 'course-3',
        title: 'Full-Stack Web & REST APIs with Node.js',
        slug: 'fullstack-web-nodejs',
        shortDescription: 'Build high-performance REST APIs with Express, MongoDB, Docker and JWT Auth.',
        description: 'Master backend engineering, database modeling with Mongoose, rate limiting, and containerized deployments with Docker.',
        level: 'INTERMEDIATE',
        language: 'English',
        isFree: true,
        price: 0,
        averageRating: 4.7,
        reviewCount: 24,
        totalEnrollments: 110,
        categoryId: 'cat-3',
        categoryName: 'Backend Development',
        learningOutcomes: [
          'Design robust RESTful APIs with Express',
          'Secure authentication with JWT & refresh tokens',
          'Deploy applications using Docker containers',
        ],
      ),
    ];
  }

  List<CourseModel> _getFilteredDemoCourses() {
    var list = _getDemoCourses();
    if (_selectedCategoryId != null && _selectedCategoryId!.isNotEmpty) {
      list = list.where((c) => c.categoryId == _selectedCategoryId).toList();
    }
    if (_selectedLevel != null && _selectedLevel!.isNotEmpty) {
      list = list.where((c) => c.level == _selectedLevel).toList();
    }
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((c) => c.title.toLowerCase().contains(q) || c.shortDescription.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  List<SectionModel> _getDemoSections(String courseId) {
    return [
      SectionModel(
        id: 'sec-1',
        courseId: courseId,
        title: '1. Getting Started & Architecture Overview',
        description: 'Introduction to development environment and fundamentals.',
        order: 1,
        lessons: [
          LessonModel(
            id: '6a5d1038db5f89beaf1a27b5',
            courseId: courseId,
            sectionId: 'sec-1',
            title: 'Understanding Flutter & Architecture',
            description: 'Course syllabus and setup documentation.',
            lessonType: LessonType.document,
            documentUrl: 'https://flutter.dev/docs/resources/cheatsheet',
            documentName: 'Flutter_Architecture_Guide.pdf',
            durationMinutes: 12,
            order: 1,
            isPreview: true,
          ),
          LessonModel(
            id: '6a5c66bc384147c91b739075',
            courseId: courseId,
            sectionId: 'sec-1',
            title: 'What Is Flutter & Reactive UI?',
            description: 'Core concepts of Flutter widgets tree and reactive rendering.',
            lessonType: LessonType.text,
            textContent: '''### Welcome to Flutter Development

Flutter is Google's UI toolkit for building beautiful, natively compiled applications for mobile, web, and desktop from a single codebase.

#### Why Flutter?
- **Fast Development**: Hot reload helps you quickly experiment, build UIs, add features, and fix bugs.
- **Expressive and Flexible UI**: Built-in Material Design and Cupertino widgets, rich motion APIs, and smooth, natural scrolling.
- **Native Performance**: Flutter widgets incorporate all critical platform differences such as scrolling, navigation, icons, and fonts.

#### The Widget Tree
In Flutter, almost everything is a widget. Structural elements (like buttons or menus), stylistic elements (like fonts or colors), and layout aspects (like padding or alignment) are all widgets that compose a hierarchy called the **Widget Tree**.''',
            durationMinutes: 10,
            order: 2,
            isPreview: true,
          ),
          LessonModel(
            id: '6a5c6751384147c91b739076',
            courseId: courseId,
            sectionId: 'sec-1',
            title: 'Installing Flutter & Building Your First App',
            description: 'Step-by-step video guide to configure IDE and run on physical device.',
            lessonType: LessonType.video,
            videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
            durationMinutes: 15,
            order: 3,
            isPreview: false,
          ),
        ],
      ),
    ];
  }
}
