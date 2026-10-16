import 'package:flutter/foundation.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_exception.dart';
import '../models/quiz_model.dart';

class QuizProvider extends ChangeNotifier {
  final ApiClient _apiClient;

  List<QuizModel> _quizzes = [];
  QuizModel? _selectedQuiz;
  QuizAttemptModel? _activeAttempt;
  QuizAttemptModel? _lastResult;
  List<QuizAttemptModel> _myAttempts = [];
  final Map<String, QuizAttemptModel> _attemptsByQuizId = {};

  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  QuizProvider({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient() {
    _seedInitialAttempts();
  }

  void _seedInitialAttempts() {
    // Used only by tests / seedDemoQuizzes()
    _attemptsByQuizId['quiz-state-mgmt'] = QuizAttemptModel(
      id: 'demo-att-passed-1',
      quizId: 'quiz-state-mgmt',
      studentId: 'student-me',
      studentName: 'Kamal Perera',
      score: 18,
      totalMarks: 20,
      percentage: 90.0,
      passed: true,
      status: 'SUBMITTED',
      attemptNumber: 1,
      startedAt: DateTime.now().subtract(const Duration(hours: 2)),
      submittedAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 40)),
    );
  }

  List<QuizModel> get quizzes => _quizzes;
  QuizModel? get selectedQuiz => _selectedQuiz;
  QuizAttemptModel? get activeAttempt => _activeAttempt;
  QuizAttemptModel? get lastResult => _lastResult;
  List<QuizAttemptModel> get myAttempts => _myAttempts;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  bool isQuizCompleted(String quizId) {
    final att = _attemptsByQuizId[quizId];
    return att != null && (att.passed || att.isSubmitted);
  }

  QuizAttemptModel? getQuizAttempt(String quizId) {
    return _attemptsByQuizId[quizId];
  }

  void seedDemoQuizzes() {
    _quizzes = _getAllDemoQuizzes();
    _seedInitialAttempts();
    notifyListeners();
  }

  // Load quizzes available for all enrolled courses
  Future<void> loadQuizzesForCourses(List<String> courseIds) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    List<QuizModel> all = [];
    final validIds = courseIds.where((id) => id.isNotEmpty).toSet().toList();

    for (final cId in validIds) {
      try {
        final response = await _apiClient.get(ApiEndpoints.courseQuizzes(cId));
        final data = response.data['data'];
        if (data != null && data['quizzes'] is List) {
          final list = (data['quizzes'] as List)
              .whereType<Map>()
              .map((q) => QuizModel.fromJson(Map<String, dynamic>.from(q)))
              .toList();
          all.addAll(list);
        }
      } catch (_) {
        // Keep genuine results
      }
    }

    final Map<String, QuizModel> unique = {};
    for (final q in all) {
      unique[q.id] = q;
    }
    _quizzes = unique.values.toList();
    _isLoading = false;
    notifyListeners();
  }

  // Load quizzes available for a course
  Future<void> loadCourseQuizzes(String courseId) async {
    if (courseId.isEmpty) {
      _quizzes = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      dynamic data;
      try {
        final response = await _apiClient.get(ApiEndpoints.courseQuizzes(courseId));
        data = response.data['data'];
      } on ApiException catch (e) {
        if (e.statusCode == 403) {
          final instructorResp = await _apiClient.get(ApiEndpoints.instructorCourseQuizzes(courseId));
          data = instructorResp.data['data'];
        } else {
          rethrow;
        }
      }
      if (data != null && data['quizzes'] is List) {
        _quizzes = (data['quizzes'] as List)
            .whereType<Map>()
            .map((q) => QuizModel.fromJson(Map<String, dynamic>.from(q)))
            .toList();
      } else {
        _quizzes = [];
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _quizzes = [];
    } catch (_) {
      _errorMessage = 'Failed to load quizzes.';
      _quizzes = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load quiz by ID with questions
  Future<void> loadQuizDetails(String quizId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.get(ApiEndpoints.quizById(quizId));
      final data = response.data['data'];
      if (data != null && data['quiz'] != null) {
        final quizJson = Map<String, dynamic>.from(data['quiz'] as Map);
        final questionsJson = (data['questions'] as List?) ?? [];
        final questions = questionsJson
            .whereType<Map>()
            .map((q) => QuizQuestionModel.fromJson(Map<String, dynamic>.from(q)))
            .toList();
        _selectedQuiz = QuizModel.fromJson(quizJson).copyWith(questions: questions);
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = 'Failed to load quiz details.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Start student attempt
  Future<QuizAttemptModel?> startQuizAttempt(String quizId) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.post(ApiEndpoints.startQuiz(quizId));
      final data = response.data['data'];
      if (data != null && data['attempt'] != null) {
        final attempt = QuizAttemptModel.fromJson(Map<String, dynamic>.from(data['attempt'] as Map));
        _activeAttempt = attempt;

        if (data['questions'] is List) {
          final questions = (data['questions'] as List)
              .whereType<Map>()
              .map((q) => QuizQuestionModel.fromJson(Map<String, dynamic>.from(q)))
              .toList();
          if (_selectedQuiz != null) {
            _selectedQuiz = _selectedQuiz!.copyWith(questions: questions);
          }
        }
        _isSubmitting = false;
        notifyListeners();
        return attempt;
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Could not start quiz attempt';
    }

    _isSubmitting = false;
    notifyListeners();
    return null;
  }

  // Submit attempt with answers
  // Answers format: [{ "questionId": "...", "selectedOptionIds": ["..."] }]
  Future<QuizAttemptModel?> submitQuizAttempt(
    String attemptId,
    Map<String, List<String>> answers,
  ) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    final formattedAnswers = answers.entries
        .map((entry) => {
              'questionId': entry.key,
              'selectedOptionIds': entry.value,
            })
        .toList();

    try {
      final response = await _apiClient.post(
        ApiEndpoints.submitQuizAttempt(attemptId),
        data: {'answers': formattedAnswers},
      );

      final data = response.data['data'];
      if (data != null && data['attempt'] != null) {
        final attempt = QuizAttemptModel.fromJson(Map<String, dynamic>.from(data['attempt'] as Map));
        _lastResult = attempt;
        _activeAttempt = null;
        _attemptsByQuizId[attempt.quizId] = attempt;
        if (_selectedQuiz != null) {
          _attemptsByQuizId[_selectedQuiz!.id] = attempt;
        }
        _isSubmitting = false;
        notifyListeners();
        return attempt;
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = 'Submission failed. Please try again.';
    }

    _isSubmitting = false;
    notifyListeners();
    return null;
  }

  // Load previous attempts for a quiz
  Future<void> loadMyAttempts(String quizId) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.myQuizAttempts(quizId));
      final data = response.data['data'];
      if (data != null && data['attempts'] is List) {
        _myAttempts = (data['attempts'] as List)
            .whereType<Map>()
            .map((a) => QuizAttemptModel.fromJson(Map<String, dynamic>.from(a)))
            .toList();
        if (_myAttempts.isNotEmpty) {
          final bestOrLast = _myAttempts.firstWhere((a) => a.passed, orElse: () => _myAttempts.first);
          _attemptsByQuizId[quizId] = bestOrLast;
        }
        notifyListeners();
      }
    } catch (_) {
      // Keep existing
    }
  }

  List<QuizModel> _getAllDemoQuizzes() {
    return [
      ..._getDemoQuizzes('6a5c39ae384147c91b73906a'),
      ..._getDemoQuizzes('course-2'),
      ..._getDemoQuizzes('course-3'),
    ];
  }

  List<QuizModel> _getDemoQuizzes(String courseId) {
    if (courseId == 'course-2') {
      return [
        QuizModel(
          id: 'quiz-advanced-dart',
          courseId: 'course-2',
          courseTitle: 'Mastering Advanced Dart & Flutter Architecture',
          title: 'Quiz 3: Advanced Dart & Asynchronous Streams',
          description: 'Assess streams, generators, isolates, and reactive data pipelining.',
          passingScore: 80,
          timeLimitMinutes: 20,
          maxAttempts: 2,
          questions: [
            QuizQuestionModel(
              id: 'q-ad-1',
              quizId: 'quiz-advanced-dart',
              questionText: 'Which Dart feature allows asynchronous execution without blocking the event loop?',
              questionType: 'SINGLE_CHOICE',
              marks: 5,
              options: [
                QuizOptionModel(id: 'opt1', text: 'Future and async/await'),
                QuizOptionModel(id: 'opt2', text: 'Synchronous while loop'),
                QuizOptionModel(id: 'opt3', text: 'Thread.sleep()'),
                QuizOptionModel(id: 'opt4', text: 'SetState direct call'),
              ],
            ),
          ],
        ),
        QuizModel(
          id: 'quiz-clean-arch',
          courseId: 'course-2',
          courseTitle: 'Mastering Advanced Dart & Flutter Architecture',
          title: 'Quiz 4: Clean Architecture & SOLID Principles',
          description: 'Evaluation of domain separation, use-cases, repositories, and dependency injection.',
          passingScore: 75,
          timeLimitMinutes: 25,
          maxAttempts: 3,
          questions: [],
        ),
      ];
    } else if (courseId == 'course-3') {
      return [
        QuizModel(
          id: 'quiz-node-express',
          courseId: 'course-3',
          courseTitle: 'Full-Stack Web & REST APIs with Node.js',
          title: 'Quiz 5: RESTful API Engineering with Express',
          description: 'Assess middleware chains, error boundaries, routing, and controller architectures.',
          passingScore: 75,
          timeLimitMinutes: 20,
          maxAttempts: 3,
          questions: [],
        ),
      ];
    }

    final effectiveId = courseId.isNotEmpty ? courseId : '6a5c39ae384147c91b73906a';
    final effectiveTitle = effectiveId == '6a5c39ae384147c91b73906a'
        ? 'Flutter Development for Beginners'
        : 'Flutter Course';
    return [
      QuizModel(
        id: 'quiz-flutter-basics',
        courseId: effectiveId,
        courseTitle: effectiveTitle,
        title: 'Quiz 1: Flutter Fundamentals',
        description: 'Test your understanding of Flutter widgets, state, and rendering pipeline.',
        passingScore: 70,
        timeLimitMinutes: 15,
        maxAttempts: 3,
        questions: [
          QuizQuestionModel(
            id: 'q1',
            quizId: 'quiz-flutter-basics',
            questionText: 'What is the root building block of every Flutter user interface?',
            questionType: 'SINGLE_CHOICE',
            marks: 5,
            options: [
              QuizOptionModel(id: 'opt1', text: 'Widget'),
              QuizOptionModel(id: 'opt2', text: 'Activity'),
              QuizOptionModel(id: 'opt3', text: 'ViewController'),
              QuizOptionModel(id: 'opt4', text: 'Component'),
            ],
          ),
          QuizQuestionModel(
            id: 'q2',
            quizId: 'quiz-flutter-basics',
            questionText: 'Which widget allows you to create scrollable linear lists efficiently?',
            questionType: 'SINGLE_CHOICE',
            marks: 5,
            options: [
              QuizOptionModel(id: 'optA', text: 'ListView.builder'),
              QuizOptionModel(id: 'optB', text: 'Column'),
              QuizOptionModel(id: 'optC', text: 'Row'),
              QuizOptionModel(id: 'optD', text: 'Stack'),
            ],
          ),
        ],
      ),
      QuizModel(
        id: 'quiz-state-mgmt',
        courseId: effectiveId,
        courseTitle: effectiveTitle,
        title: 'Quiz 2: State Management with Provider',
        description: 'Comprehensive assessment of ChangeNotifier, Provider, and reactive rebuilds.',
        passingScore: 75,
        timeLimitMinutes: 20,
        maxAttempts: 2,
        questions: [],
      ),
    ];
  }
}
