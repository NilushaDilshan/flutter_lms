import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_lms/core/widgets/empty_state_widget.dart';
import 'package:flutter_lms/core/widgets/loading_state_widget.dart';
import 'package:flutter_lms/features/assignments/models/assignment_model.dart';
import 'package:flutter_lms/features/assignments/providers/assignment_provider.dart';
import 'package:flutter_lms/features/assignments/screens/assignment_list_screen.dart';
import 'package:flutter_lms/features/courses/models/review_model.dart';
import 'package:flutter_lms/features/courses/providers/course_provider.dart';
import 'package:flutter_lms/features/notifications/models/notification_model.dart';
import 'package:flutter_lms/features/notifications/providers/notification_provider.dart';
import 'package:flutter_lms/features/notifications/screens/notification_screen.dart';
import 'package:flutter_lms/features/quizzes/models/quiz_model.dart';
import 'package:flutter_lms/features/quizzes/providers/quiz_provider.dart';
import 'package:flutter_lms/features/quizzes/screens/quiz_list_screen.dart';

void main() {
  group('Day 7: Models Unit Tests', () {
    test('QuizModel deserializes backend quiz JSON with questions', () {
      final json = {
        'id': 'quiz-1',
        'courseId': 'course-101',
        'title': 'Flutter Fundamentals Quiz',
        'passingScore': 75,
        'timeLimitMinutes': 20,
        'maxAttempts': 3,
        'questions': [
          {
            'id': 'q1',
            'quizId': 'quiz-1',
            'questionText': 'Is Flutter cross-platform?',
            'questionType': 'TRUE_FALSE',
            'marks': 2,
            'options': [
              {'id': 'opt1', 'text': 'True'},
              {'id': 'opt2', 'text': 'False'},
            ],
          }
        ],
      };

      final quiz = QuizModel.fromJson(json);
      expect(quiz.id, 'quiz-1');
      expect(quiz.passingScore, 75);
      expect(quiz.timeLimitMinutes, 20);
      expect(quiz.questions.length, 1);
      expect(quiz.questions.first.isSingleChoice, true);
      expect(quiz.questions.first.options.length, 2);
    });

    test('QuizAttemptModel deserializes backend attempt with score and passed flag', () {
      final json = {
        'id': 'att-1',
        'quizId': 'quiz-1',
        'studentId': 'stud-1',
        'score': 18,
        'totalMarks': 20,
        'percentage': 90.0,
        'passed': true,
        'status': 'SUBMITTED',
        'attemptNumber': 1,
        'startedAt': '2026-10-08T09:00:00Z',
        'submittedAt': '2026-10-08T09:15:00Z',
      };

      final attempt = QuizAttemptModel.fromJson(json);
      expect(attempt.score, 18);
      expect(attempt.totalMarks, 20);
      expect(attempt.percentage, 90.0);
      expect(attempt.passed, true);
      expect(attempt.isSubmitted, true);
    });

    test('AssignmentModel and AssignmentSubmissionModel deserialize properly', () {
      final assignJson = {
        'id': 'as-1',
        'courseId': 'course-1',
        'title': 'Responsive App Layout',
        'description': 'Build tablet layout',
        'maxMarks': 50,
      };
      final assignment = AssignmentModel.fromJson(assignJson);
      expect(assignment.maxMarks, 50);

      final subJson = {
        'id': 'sub-1',
        'assignmentId': 'as-1',
        'studentId': 'stud-1',
        'textAnswer': 'Here is my GitHub URL',
        'status': 'RESUBMISSION_REQUIRED',
        'feedback': 'Please fix padding on mobile screen',
      };
      final sub = AssignmentSubmissionModel.fromJson(subJson);
      expect(sub.isResubmissionRequired, true);
      expect(sub.canEdit, true);
      expect(sub.feedback, 'Please fix padding on mobile screen');
    });

    test('NotificationModel and ReviewModel deserialize correctly', () {
      final notif = NotificationModel.fromJson({
        'id': 'not-1',
        'type': 'QUIZ_RESULT',
        'title': 'Quiz Graded',
        'message': 'You passed!',
        'isRead': false,
      });
      expect(notif.isRead, false);
      expect(notif.type, 'QUIZ_RESULT');

      final review = ReviewModel.fromJson({
        'id': 'rev-1',
        'courseId': 'c-1',
        'rating': 5,
        'comment': 'Amazing course!',
        'studentName': 'Amal Silva',
      });
      expect(review.rating, 5);
      expect(review.studentName, 'Amal Silva');
    });
  });

  group('Day 7: Widget Tests for Assessment Screens', () {
    testWidgets('QuizListScreen renders correctly with title', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => QuizProvider()),
          ],
          child: const MaterialApp(
            home: QuizListScreen(courseId: 'c-1', courseTitle: 'Flutter 101'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // AppBar title must always render
      expect(find.text('Quizzes: Flutter 101'), findsOneWidget);
      // Screen is in one of three valid states: loading, data, or empty
      final hasLoading = find.byType(LoadingStateWidget).evaluate().isNotEmpty;
      final hasListView = find.byType(ListView).evaluate().isNotEmpty;
      final hasEmpty = find.byType(EmptyStateWidget).evaluate().isNotEmpty;
      expect(hasLoading || hasListView || hasEmpty, isTrue);
    });

    testWidgets('AssignmentListScreen renders correctly with title', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AssignmentProvider()),
          ],
          child: const MaterialApp(
            home: AssignmentListScreen(courseId: 'c-1', courseTitle: 'Flutter 101'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Assignments: Flutter 101'), findsOneWidget);
      final hasLoading = find.byType(LoadingStateWidget).evaluate().isNotEmpty;
      final hasListView = find.byType(ListView).evaluate().isNotEmpty;
      final hasEmpty = find.byType(EmptyStateWidget).evaluate().isNotEmpty;
      expect(hasLoading || hasListView || hasEmpty, isTrue);
    });

    testWidgets('NotificationScreen renders correctly with title', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => NotificationProvider()),
          ],
          child: const MaterialApp(
            home: NotificationScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Notifications'), findsOneWidget);
      final hasLoading = find.byType(LoadingStateWidget).evaluate().isNotEmpty;
      final hasListView = find.byType(ListView).evaluate().isNotEmpty;
      final hasEmpty = find.byType(EmptyStateWidget).evaluate().isNotEmpty;
      expect(hasLoading || hasListView || hasEmpty, isTrue);
    });
  });
}
