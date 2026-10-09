import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_lms/core/api/api_client.dart';
import 'package:flutter_lms/core/storage/token_storage.dart';
import 'package:flutter_lms/features/assignments/providers/assignment_provider.dart';
import 'package:flutter_lms/features/assignments/screens/assignment_list_screen.dart';
import 'package:flutter_lms/features/courses/providers/course_provider.dart';
import 'package:flutter_lms/features/quizzes/providers/quiz_provider.dart';
import 'package:flutter_lms/features/quizzes/screens/quiz_list_screen.dart';

/// Creates a [Dio] instance that immediately throws a connection error for every
/// request, so providers fall through to their offline/demo data without waiting
/// for real network timeouts.
Dio _offlineDio() {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'http://localhost:3000/api',
      connectTimeout: const Duration(milliseconds: 50),
      receiveTimeout: const Duration(milliseconds: 50),
    ),
  );
  return dio;
}

/// Creates an [ApiClient] backed by the offline-immediate Dio.
ApiClient _offlineClient() => ApiClient(
      tokenStorage: TokenStorage(),
      customDio: _offlineDio(),
    );

void main() {
  // ---------------------------------------------------------------------------
  // Day 10: Course Enrollment & Continue Learning Flow (unit tests — fast)
  // ---------------------------------------------------------------------------
  group('Day 10: Course Enrollment & Continue Learning Flow', () {
    test('isEnrolled returns true for demo-enrolled courseId', () async {
      final provider = CourseProvider(apiClient: _offlineClient());
      await provider.loadMyEnrollments();

      // Demo seed contains '6a5c39ae384147c91b73906a' as an ACTIVE enrollment
      expect(provider.isEnrolled('6a5c39ae384147c91b73906a'), isTrue);
    });

    test('isEnrolled returns true for second demo-enrolled courseId (course-2)', () async {
      final provider = CourseProvider(apiClient: _offlineClient());
      await provider.loadMyEnrollments();

      expect(provider.isEnrolled('course-2'), isTrue);
    });

    test('isEnrolled returns false for a non-enrolled courseId', () async {
      final provider = CourseProvider(apiClient: _offlineClient());
      await provider.loadMyEnrollments();

      // course-3 is NOT in demo enrollments
      expect(provider.isEnrolled('course-3'), isFalse);
    });

    test('getEnrollment returns non-null with 45% progress for enrolled courseId', () async {
      final provider = CourseProvider(apiClient: _offlineClient());
      await provider.loadMyEnrollments();

      final enrollment = provider.getEnrollment('6a5c39ae384147c91b73906a');
      expect(enrollment, isNotNull);
      expect(enrollment!.progressPercentage, equals(45));
    });

    test('isQuizCompleted returns true for seeded quiz (quiz-state-mgmt)', () {
      final provider = QuizProvider(apiClient: _offlineClient());
      // Seeded in constructor — no async needed
      expect(provider.isQuizCompleted('quiz-state-mgmt'), isTrue);
    });

    test('isAssignmentSubmitted returns true for seeded assignment (assign-flutter-ui)', () {
      final provider = AssignmentProvider(apiClient: _offlineClient());
      // Seeded in constructor — no async needed
      expect(provider.isAssignmentSubmitted('assign-flutter-ui'), isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // Day 10: Assessments Filtering & Completion Status Badges (widget tests)
  // ---------------------------------------------------------------------------
  group('Day 10: Assessments Filtering & Completion Status Badges', () {
    testWidgets(
        'QuizListScreen renders quizzes and displays COMPLETED badge for completed quiz',
        (tester) async {
      final quizProvider = QuizProvider(apiClient: _offlineClient());
      // Pre-populate with demo data using the offline client (instant fallback)
      await quizProvider.loadCourseQuizzes('');

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: quizProvider),
          ],
          child: const MaterialApp(
            home: QuizListScreen(),
          ),
        ),
      );

      // pumpAndSettle waits for all animations and async callbacks to finish
      await tester.pumpAndSettle();

      // Quizzes should be loaded
      expect(find.byType(ListView), findsOneWidget);

      // Quiz 2 (quiz-state-mgmt) is seeded as completed/passed -> COMPLETED badge
      expect(find.textContaining('COMPLETED'), findsAtLeastNWidgets(1));

      // Both 'Retake Quiz' and 'Start Quiz Attempt' buttons should be present
      expect(find.textContaining('Retake Quiz'), findsAtLeastNWidgets(1));
      expect(find.text('Start Quiz Attempt'), findsAtLeastNWidgets(1));
    });

    testWidgets(
        'AssignmentListScreen renders assignments and displays COMPLETED badge for submitted assignment',
        (tester) async {
      final assignmentProvider = AssignmentProvider(apiClient: _offlineClient());
      await assignmentProvider.loadCourseAssignments('');

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: assignmentProvider),
          ],
          child: const MaterialApp(
            home: AssignmentListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assignments list should render
      expect(find.byType(ListView), findsOneWidget);

      // Assignment 1 (assign-flutter-ui) is seeded as submitted -> COMPLETED badge
      expect(find.text('COMPLETED'), findsAtLeastNWidgets(1));

      // Completed assignment shows 'Completed • View Submission'
      expect(find.text('Completed • View Submission'), findsAtLeastNWidgets(1));

      // Pending assignment shows 'View & Submit'
      expect(find.text('View & Submit'), findsAtLeastNWidgets(1));
    });
  });

  // ---------------------------------------------------------------------------
  // Day 10: Responsive Layout Verification
  // ---------------------------------------------------------------------------
  group('Day 10: Responsive Layout Verification', () {
    testWidgets(
        'QuizListScreen renders correctly on mobile phone dimensions (360x640)',
        (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final quizProvider = QuizProvider(apiClient: _offlineClient());
      await quizProvider.loadCourseQuizzes('');

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: quizProvider),
          ],
          child: const MaterialApp(
            home: QuizListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(QuizListScreen), findsOneWidget);
    });

    testWidgets(
        'AssignmentListScreen renders correctly on tablet dimensions (1024x768)',
        (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final assignmentProvider = AssignmentProvider(apiClient: _offlineClient());
      await assignmentProvider.loadCourseAssignments('');

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: assignmentProvider),
          ],
          child: const MaterialApp(
            home: AssignmentListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(AssignmentListScreen), findsOneWidget);
    });
  });
}
