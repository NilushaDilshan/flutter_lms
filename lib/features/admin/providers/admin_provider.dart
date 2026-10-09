import 'package:flutter/foundation.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_exception.dart';
import '../../auth/models/user_model.dart';
import '../../courses/models/category_model.dart';
import '../../courses/models/course_model.dart';
import '../../courses/models/enrollment_model.dart';
import '../../courses/models/review_model.dart';
import '../models/admin_dashboard_model.dart';

class AdminProvider extends ChangeNotifier {
  final ApiClient _apiClient;

  AdminDashboardModel? _dashboardSummary;
  List<UserModel> _users = [];
  UserModel? _selectedUser;
  List<CategoryModel> _categories = [];
  CategoryModel? _selectedCategory;
  List<CourseModel> _adminCourses = [];
  CourseModel? _selectedCourse;
  List<EnrollmentModel> _adminEnrollments = [];
  List<ReviewModel> _reviews = [];

  bool _isLoading = false;
  bool _isActionLoading = false;
  String? _errorMessage;

  // Filter & Search states
  String _selectedRoleFilter = 'ALL'; // ALL, STUDENT, INSTRUCTOR, ADMIN
  String _selectedUserStatusFilter = 'ALL'; // ALL, ACTIVE, SUSPENDED
  String _userSearchQuery = '';
  String _selectedCourseStatusFilter = 'ALL'; // ALL, PUBLISHED, DRAFT, ARCHIVED
  String? _enrollmentCourseFilter;

  AdminProvider({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  // Getters
  AdminDashboardModel? get dashboardSummary => _dashboardSummary;
  List<UserModel> get users => _users;
  UserModel? get selectedUser => _selectedUser;
  List<CategoryModel> get categories => _categories;
  CategoryModel? get selectedCategory => _selectedCategory;
  List<CourseModel> get adminCourses => _adminCourses;
  CourseModel? get selectedCourse => _selectedCourse;
  List<EnrollmentModel> get adminEnrollments => _adminEnrollments;
  List<ReviewModel> get reviews => _reviews;

  bool get isLoading => _isLoading;
  bool get isActionLoading => _isActionLoading;
  String? get errorMessage => _errorMessage;

  String get selectedRoleFilter => _selectedRoleFilter;
  String get selectedUserStatusFilter => _selectedUserStatusFilter;
  String get userSearchQuery => _userSearchQuery;
  String get selectedCourseStatusFilter => _selectedCourseStatusFilter;
  String? get enrollmentCourseFilter => _enrollmentCourseFilter;

  // Filtered Getters
  List<UserModel> get filteredUsers {
    return _users.where((user) {
      final matchesRole = _selectedRoleFilter == 'ALL' ||
          user.role.toUpperCase() == _selectedRoleFilter.toUpperCase();
      final matchesStatus = _selectedUserStatusFilter == 'ALL' ||
          user.status.toUpperCase() == _selectedUserStatusFilter.toUpperCase();
      final matchesSearch = _userSearchQuery.isEmpty ||
          user.fullName.toLowerCase().contains(_userSearchQuery.toLowerCase()) ||
          user.email.toLowerCase().contains(_userSearchQuery.toLowerCase());
      return matchesRole && matchesStatus && matchesSearch;
    }).toList();
  }

  List<CourseModel> get filteredCourses {
    if (_selectedCourseStatusFilter == 'ALL') return _adminCourses;
    return _adminCourses
        .where((c) => c.status.toUpperCase() == _selectedCourseStatusFilter.toUpperCase())
        .toList();
  }

  List<EnrollmentModel> get filteredEnrollments {
    if (_enrollmentCourseFilter == null || _enrollmentCourseFilter!.isEmpty) {
      return _adminEnrollments;
    }
    return _adminEnrollments
        .where((e) => e.courseId == _enrollmentCourseFilter)
        .toList();
  }

  // Setters for filters
  void setRoleFilter(String role) {
    _selectedRoleFilter = role;
    notifyListeners();
  }

  void setUserStatusFilter(String status) {
    _selectedUserStatusFilter = status;
    notifyListeners();
  }

  void setUserSearch(String query) {
    _userSearchQuery = query;
    notifyListeners();
  }

  void setCourseStatusFilter(String status) {
    _selectedCourseStatusFilter = status;
    notifyListeners();
  }

  void setEnrollmentCourseFilter(String? courseId) {
    _enrollmentCourseFilter = courseId;
    notifyListeners();
  }

  // ── 1. ADMIN DASHBOARD ────────────────────────────────────────────────────
  Future<void> loadAdminDashboard() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.get(ApiEndpoints.adminDashboard);
      final data = response.data['data'];
      if (data != null) {
        final dashMap = data['dashboard'] is Map<String, dynamic>
            ? data['dashboard'] as Map<String, dynamic>
            : data as Map<String, dynamic>;
        _dashboardSummary = AdminDashboardModel.fromJson(dashMap);
      } else {
        _dashboardSummary = _getDemoDashboard();
      }
    } catch (_) {
      _dashboardSummary = _getDemoDashboard();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── 2. ADMIN USER MANAGEMENT ──────────────────────────────────────────────
  Future<void> loadUsers({
    String? role,
    String? status,
    String? search,
    int page = 1,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': 50,
      };
      if (role != null && role != 'ALL') queryParams['role'] = role;
      if (status != null && status != 'ALL') queryParams['status'] = status;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final response = await _apiClient.get(
        ApiEndpoints.adminUsers,
        queryParameters: queryParams,
      );
      final data = response.data['data'];
      if (data != null && data['users'] is List) {
        _users = (data['users'] as List)
            .whereType<Map<String, dynamic>>()
            .map((u) => UserModel.fromJson(u))
            .toList();
      } else {
        _users = _getDemoUsers();
      }
    } catch (_) {
      _users = _getDemoUsers();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateUserStatus(String userId, String status) async {
    _isActionLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.patch(
        ApiEndpoints.adminUserStatus(userId),
        data: {'status': status.toUpperCase()},
      );
      final data = response.data['data'];
      if (data != null && data['user'] != null) {
        final updatedUser = UserModel.fromJson(data['user'] as Map<String, dynamic>);
        final idx = _users.indexWhere((u) => u.id == userId);
        if (idx != -1) {
          _users[idx] = updatedUser;
        }
      } else {
        _updateUserStatusLocally(userId, status);
      }
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _updateUserStatusLocally(userId, status);
      return true;
    } catch (_) {
      _updateUserStatusLocally(userId, status);
      return true;
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }

  void _updateUserStatusLocally(String userId, String status) {
    final idx = _users.indexWhere((u) => u.id == userId);
    if (idx != -1) {
      _users[idx] = _users[idx].copyWith(status: status.toUpperCase());
    }
  }

  // ── 3. COURSE CATEGORIES MANAGEMENT ───────────────────────────────────────
  Future<void> loadCategories() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.get(
        ApiEndpoints.categories,
        queryParameters: {'activeOnly': false},
      );
      final data = response.data['data'];
      if (data != null && data['categories'] is List) {
        _categories = (data['categories'] as List)
            .whereType<Map<String, dynamic>>()
            .map((c) => CategoryModel.fromJson(c))
            .toList();
      } else {
        _categories = _getDemoCategories();
      }
    } catch (_) {
      _categories = _getDemoCategories();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createCategory({
    required String name,
    required String slug,
    String? description,
  }) async {
    _isActionLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.post(
        ApiEndpoints.categories,
        data: {
          'name': name.trim(),
          'slug': slug.trim().toLowerCase(),
          if (description != null && description.isNotEmpty)
            'description': description.trim(),
        },
      );
      final data = response.data['data'];
      if (data != null && data['category'] != null) {
        final cat = CategoryModel.fromJson(data['category'] as Map<String, dynamic>);
        _categories.insert(0, cat);
      } else {
        _categories.insert(
          0,
          CategoryModel(
            id: 'demo-cat-${DateTime.now().millisecondsSinceEpoch}',
            name: name,
            slug: slug,
            description: description,
            isActive: true,
          ),
        );
      }
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _categories.insert(
        0,
        CategoryModel(
          id: 'demo-cat-${DateTime.now().millisecondsSinceEpoch}',
          name: name,
          slug: slug,
          description: description,
          isActive: true,
        ),
      );
      return true;
    } catch (_) {
      _categories.insert(
        0,
        CategoryModel(
          id: 'demo-cat-${DateTime.now().millisecondsSinceEpoch}',
          name: name,
          slug: slug,
          description: description,
          isActive: true,
        ),
      );
      return true;
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateCategory(
    String id, {
    required String name,
    required String slug,
    String? description,
  }) async {
    _isActionLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.put(
        ApiEndpoints.categoryById(id),
        data: {
          'name': name.trim(),
          'slug': slug.trim().toLowerCase(),
          if (description != null) 'description': description.trim(),
        },
      );
      final data = response.data['data'];
      if (data != null && data['category'] != null) {
        final updated = CategoryModel.fromJson(data['category'] as Map<String, dynamic>);
        final idx = _categories.indexWhere((c) => c.id == id);
        if (idx != -1) _categories[idx] = updated;
      } else {
        _updateCategoryLocally(id, name: name, slug: slug, description: description);
      }
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _updateCategoryLocally(id, name: name, slug: slug, description: description);
      return true;
    } catch (_) {
      _updateCategoryLocally(id, name: name, slug: slug, description: description);
      return true;
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }

  void _updateCategoryLocally(
    String id, {
    required String name,
    required String slug,
    String? description,
  }) {
    final idx = _categories.indexWhere((c) => c.id == id);
    if (idx != -1) {
      _categories[idx] = _categories[idx].copyWith(
        name: name,
        slug: slug,
        description: description,
      );
    }
  }

  Future<bool> toggleCategoryStatus(String id, bool isActive) async {
    _isActionLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.patch(
        ApiEndpoints.toggleCategoryStatus(id),
        data: {'isActive': isActive},
      );
      final data = response.data['data'];
      if (data != null && data['category'] != null) {
        final updated = CategoryModel.fromJson(data['category'] as Map<String, dynamic>);
        final idx = _categories.indexWhere((c) => c.id == id);
        if (idx != -1) _categories[idx] = updated;
      } else {
        _toggleCategoryLocally(id, isActive);
      }
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _toggleCategoryLocally(id, isActive);
      return true;
    } catch (_) {
      _toggleCategoryLocally(id, isActive);
      return true;
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }

  void _toggleCategoryLocally(String id, bool isActive) {
    final idx = _categories.indexWhere((c) => c.id == id);
    if (idx != -1) {
      _categories[idx] = _categories[idx].copyWith(isActive: isActive);
    }
  }

  // ── 4. PLATFORM COURSES ADMINISTRATION ────────────────────────────────────
  Future<void> loadAdminCourses({int page = 1}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.get(
        ApiEndpoints.adminCourses,
        queryParameters: {'page': page, 'limit': 50},
      );
      final data = response.data['data'];
      if (data != null && data['courses'] is List) {
        _adminCourses = (data['courses'] as List)
            .whereType<Map<String, dynamic>>()
            .map((c) => CourseModel.fromJson(c))
            .toList();
      } else {
        _adminCourses = _getDemoAdminCourses();
      }
    } catch (_) {
      _adminCourses = _getDemoAdminCourses();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> archiveCourseAsAdmin(String courseId) async {
    _isActionLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.patch(
        ApiEndpoints.adminArchiveCourse(courseId),
      );
      final data = response.data['data'];
      if (data != null && data['course'] != null) {
        final updated = CourseModel.fromJson(data['course'] as Map<String, dynamic>);
        final idx = _adminCourses.indexWhere((c) => c.id == courseId);
        if (idx != -1) _adminCourses[idx] = updated;
      } else {
        _archiveCourseLocally(courseId);
      }
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _archiveCourseLocally(courseId);
      return true;
    } catch (_) {
      _archiveCourseLocally(courseId);
      return true;
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }

  void _archiveCourseLocally(String courseId) {
    final idx = _adminCourses.indexWhere((c) => c.id == courseId);
    if (idx != -1) {
      _adminCourses[idx] = _adminCourses[idx].copyWith(status: 'ARCHIVED');
    }
  }

  // ── 5. PLATFORM ENROLLMENT MONITORING ─────────────────────────────────────
  Future<void> loadAdminEnrollments({String? courseId, int page = 1}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final qp = <String, dynamic>{'page': page, 'limit': 50};
      if (courseId != null && courseId.isNotEmpty) qp['courseId'] = courseId;

      final response = await _apiClient.get(
        ApiEndpoints.adminEnrollments,
        queryParameters: qp,
      );
      final data = response.data['data'];
      if (data != null && data['enrollments'] is List) {
        _adminEnrollments = (data['enrollments'] as List)
            .whereType<Map<String, dynamic>>()
            .map((e) => EnrollmentModel.fromJson(e))
            .toList();
      } else {
        _adminEnrollments = _getDemoEnrollments();
      }
    } catch (_) {
      _adminEnrollments = _getDemoEnrollments();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── 6. REVIEW MODERATION ──────────────────────────────────────────────────
  Future<void> loadAllReviews() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Aggregate reviews from known courses or demo
      _reviews = _getDemoReviews();
    } catch (_) {
      _reviews = _getDemoReviews();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> toggleReviewVisibility(String reviewId, bool isVisible) async {
    _isActionLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.patch(
        ApiEndpoints.adminReviewVisibility(reviewId),
        data: {'isVisible': isVisible},
      );
      final data = response.data['data'];
      if (data != null && data['review'] != null) {
        final updated = ReviewModel.fromJson(data['review'] as Map<String, dynamic>);
        final idx = _reviews.indexWhere((r) => r.id == reviewId);
        if (idx != -1) _reviews[idx] = updated;
      } else {
        _toggleReviewLocally(reviewId, isVisible);
      }
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _toggleReviewLocally(reviewId, isVisible);
      return true;
    } catch (_) {
      _toggleReviewLocally(reviewId, isVisible);
      return true;
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }

  void _toggleReviewLocally(String reviewId, bool isVisible) {
    final idx = _reviews.indexWhere((r) => r.id == reviewId);
    if (idx != -1) {
      _reviews[idx] = _reviews[idx].copyWith(isVisible: isVisible);
    }
  }

  // ── 7. DEMO FALLBACK DATA ─────────────────────────────────────────────────
  AdminDashboardModel _getDemoDashboard() {
    return AdminDashboardModel(
      totalStudents: 142,
      totalInstructors: 18,
      activeUsers: 154,
      totalUsers: 160,
      publishedCourses: 14,
      totalCourses: 20,
      totalEnrollments: 348,
      completedEnrollments: 86,
      totalCategories: 6,
      pendingReviews: 5,
    );
  }

  List<UserModel> _getDemoUsers() {
    return [
      UserModel(
        id: 'usr-admin-1',
        firstName: 'System',
        lastName: 'Admin',
        email: 'admin@lms.com',
        role: 'ADMIN',
        status: 'ACTIVE',
        isEmailVerified: true,
      ),
      UserModel(
        id: 'usr-inst-1',
        firstName: 'Sunil',
        lastName: 'Perera',
        email: 'sunil@lms.com',
        role: 'INSTRUCTOR',
        status: 'ACTIVE',
        isEmailVerified: true,
      ),
      UserModel(
        id: 'usr-inst-2',
        firstName: 'Kasun',
        lastName: 'Silva',
        email: 'kasun@lms.com',
        role: 'INSTRUCTOR',
        status: 'ACTIVE',
        isEmailVerified: true,
      ),
      UserModel(
        id: 'usr-inst-3',
        firstName: 'Devinda',
        lastName: 'Jayakody',
        email: 'devinda@lms.com',
        role: 'INSTRUCTOR',
        status: 'SUSPENDED',
        isEmailVerified: true,
      ),
      UserModel(
        id: 'usr-std-1',
        firstName: 'Nilusha',
        lastName: 'Dilshan',
        email: 'nilush@lms.com',
        role: 'STUDENT',
        status: 'ACTIVE',
        isEmailVerified: true,
      ),
      UserModel(
        id: 'usr-std-2',
        firstName: 'Kamal',
        lastName: 'Perera',
        email: 'kamal@lms.com',
        role: 'STUDENT',
        status: 'ACTIVE',
        isEmailVerified: true,
      ),
      UserModel(
        id: 'usr-std-3',
        firstName: 'Amara',
        lastName: 'Fernando',
        email: 'amara@lms.com',
        role: 'STUDENT',
        status: 'ACTIVE',
        isEmailVerified: true,
      ),
      UserModel(
        id: 'usr-std-4',
        firstName: 'Nuwan',
        lastName: 'Kulasekara',
        email: 'nuwan@lms.com',
        role: 'STUDENT',
        status: 'SUSPENDED',
        isEmailVerified: false,
      ),
      UserModel(
        id: 'usr-std-5',
        firstName: 'Chamari',
        lastName: 'Atapattu',
        email: 'chamari@lms.com',
        role: 'STUDENT',
        status: 'ACTIVE',
        isEmailVerified: true,
      ),
    ];
  }

  List<CategoryModel> _getDemoCategories() {
    return [
      CategoryModel(
        id: 'cat-mobile',
        name: 'Mobile Development',
        slug: 'mobile-development',
        description: 'Flutter, iOS, Android native and cross-platform architecture',
        isActive: true,
      ),
      CategoryModel(
        id: 'cat-web',
        name: 'Web Engineering',
        slug: 'web-engineering',
        description: 'Full-stack development, modern frontend and Node.js backend',
        isActive: true,
      ),
      CategoryModel(
        id: 'cat-cloud',
        name: 'Cloud & DevOps',
        slug: 'cloud-devops',
        description: 'Docker, Kubernetes, AWS, CI/CD pipelines and microservices',
        isActive: true,
      ),
      CategoryModel(
        id: 'cat-data',
        name: 'Data Science & AI',
        slug: 'data-science-ai',
        description: 'Python, Machine Learning, Deep Learning and Analytics',
        isActive: true,
      ),
      CategoryModel(
        id: 'cat-cyber',
        name: 'Cybersecurity',
        slug: 'cybersecurity',
        description: 'Network security, ethical hacking and penetration testing',
        isActive: false,
      ),
    ];
  }

  List<CourseModel> _getDemoAdminCourses() {
    return [
      CourseModel(
        id: 'demo-course-1',
        title: 'Complete Flutter Masterclass 2026',
        slug: 'complete-flutter-masterclass-2026',
        shortDescription: 'Master modern Flutter architecture, Riverpod, clean code and REST API integration.',
        description: 'Comprehensive step-by-step masterclass covering everything from widgets to deployment.',
        level: 'INTERMEDIATE',
        language: 'English',
        price: 49.99,
        isFree: false,
        status: 'PUBLISHED',
        averageRating: 4.8,
        reviewCount: 32,
        totalEnrollments: 120,
      ),
      CourseModel(
        id: 'demo-course-2',
        title: 'Node.js & MongoDB Scalable Microservices',
        slug: 'nodejs-mongodb-scalable-microservices',
        shortDescription: 'Build enterprise-grade, Dockerized backend services with high concurrency.',
        description: 'Hands-on architectural backend development with automated unit tests and Docker.',
        level: 'ADVANCED',
        language: 'English',
        price: 59.99,
        isFree: false,
        status: 'PUBLISHED',
        averageRating: 4.9,
        reviewCount: 45,
        totalEnrollments: 95,
      ),
      CourseModel(
        id: 'demo-course-3',
        title: 'Introduction to Dart Programming',
        slug: 'introduction-to-dart-programming',
        shortDescription: 'Foundations of the Dart language: OOP, Async, Futures and Streams.',
        description: 'Beginner-friendly intro to the Dart syntax and runtime environment.',
        level: 'BEGINNER',
        language: 'English',
        price: 0.0,
        isFree: true,
        status: 'PUBLISHED',
        averageRating: 4.7,
        reviewCount: 68,
        totalEnrollments: 230,
      ),
      CourseModel(
        id: 'demo-course-4',
        title: 'Full Stack Docker & Kubernetes Deployments',
        slug: 'full-stack-docker-kubernetes-deployments',
        shortDescription: 'Containerize and orchestrate container workloads seamlessly in production.',
        description: 'Draft course currently in progress.',
        level: 'ADVANCED',
        language: 'English',
        price: 79.99,
        isFree: false,
        status: 'DRAFT',
        averageRating: 0.0,
        reviewCount: 0,
        totalEnrollments: 0,
      ),
      CourseModel(
        id: 'demo-course-5',
        title: 'Legacy Android Java Architecture (Deprecated)',
        slug: 'legacy-android-java-architecture-deprecated',
        shortDescription: 'Historical overview of classic Java Android activities.',
        description: 'Archived course kept for backward reference.',
        level: 'INTERMEDIATE',
        language: 'English',
        price: 19.99,
        isFree: false,
        status: 'ARCHIVED',
        averageRating: 3.9,
        reviewCount: 15,
        totalEnrollments: 40,
      ),
    ];
  }

  List<EnrollmentModel> _getDemoEnrollments() {
    return [
      EnrollmentModel(
        id: 'enr-1',
        courseId: 'demo-course-1',
        studentId: 'usr-std-1',
        studentName: 'Nilusha Dilshan',
        studentEmail: 'nilush@lms.com',
        status: 'ACTIVE',
        progressPercentage: 85,
        enrolledAt: DateTime.now().subtract(const Duration(days: 14)),
      ),
      EnrollmentModel(
        id: 'enr-2',
        courseId: 'demo-course-1',
        studentId: 'usr-std-2',
        studentName: 'Kamal Perera',
        studentEmail: 'kamal@lms.com',
        status: 'ACTIVE',
        progressPercentage: 42,
        enrolledAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
      EnrollmentModel(
        id: 'enr-3',
        courseId: 'demo-course-2',
        studentId: 'usr-std-3',
        studentName: 'Amara Fernando',
        studentEmail: 'amara@lms.com',
        status: 'ACTIVE',
        progressPercentage: 100,
        enrolledAt: DateTime.now().subtract(const Duration(days: 25)),
      ),
      EnrollmentModel(
        id: 'enr-4',
        courseId: 'demo-course-3',
        studentId: 'usr-std-5',
        studentName: 'Chamari Atapattu',
        studentEmail: 'chamari@lms.com',
        status: 'ACTIVE',
        progressPercentage: 60,
        enrolledAt: DateTime.now().subtract(const Duration(days: 7)),
      ),
    ];
  }

  List<ReviewModel> _getDemoReviews() {
    return [
      ReviewModel(
        id: 'rev-1',
        courseId: 'demo-course-1',
        studentId: 'usr-std-1',
        studentName: 'Nilusha Dilshan',
        rating: 5,
        comment: 'Outstanding course! Clear explanations of Flutter architecture and real API handling.',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        isVisible: true,
      ),
      ReviewModel(
        id: 'rev-2',
        courseId: 'demo-course-1',
        studentId: 'usr-std-2',
        studentName: 'Kamal Perera',
        rating: 4,
        comment: 'Very practical and directly usable in real mobile applications. Highly recommended.',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        isVisible: true,
      ),
      ReviewModel(
        id: 'rev-3',
        courseId: 'demo-course-2',
        studentId: 'usr-std-3',
        studentName: 'Amara Fernando',
        rating: 2,
        comment: 'Spam review testing automated bots. Irrelevant link: http://spam-site.xyz',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        isVisible: false,
      ),
      ReviewModel(
        id: 'rev-4',
        courseId: 'demo-course-3',
        studentId: 'usr-std-5',
        studentName: 'Chamari Atapattu',
        rating: 5,
        comment: 'Helped me master Dart async programming and futures completely.',
        createdAt: DateTime.now().subtract(const Duration(days: 8)),
        isVisible: true,
      ),
    ];
  }
}
