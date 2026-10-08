import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_lms/core/widgets/empty_state_widget.dart';
import 'package:flutter_lms/core/widgets/loading_state_widget.dart';
import 'package:flutter_lms/features/assignments/models/assignment_model.dart';
import 'package:flutter_lms/features/courses/models/course_model.dart';
import 'package:flutter_lms/features/courses/models/enrollment_model.dart';
import 'package:flutter_lms/features/courses/models/lesson_model.dart';
import 'package:flutter_lms/features/courses/models/section_model.dart';
import 'package:flutter_lms/features/dashboard/screens/instructor_dashboard_screen.dart';
import 'package:flutter_lms/features/instructor/models/instructor_dashboard_model.dart';
import 'package:flutter_lms/features/instructor/providers/instructor_provider.dart';
import 'package:flutter_lms/features/instructor/screens/course_create_edit_screen.dart';
import 'package:flutter_lms/features/instructor/screens/course_studio_screen.dart';
import 'package:flutter_lms/features/quizzes/models/quiz_model.dart';

void main() {
  group('Day 8: Instructor Models & Deserialization Unit Tests', () {
    test('InstructorDashboardModel deserializes backend summary JSON', () {
      final json = {
        'totalCourses': 5,
        'publishedCourses': 3,
        'draftCourses': 1,
        'archivedCourses': 1,
        'totalEnrollments': 120,
        'pendingSubmissions': 7,
        'averageCourseRating': 4.85,
      };

      final model = InstructorDashboardModel.fromJson(json);

      expect(model.totalCourses, 5);
      expect(model.publishedCourses, 3);
      expect(model.draftCourses, 1);
      expect(model.archivedCourses, 1);
      expect(model.totalEnrollments, 120);
      expect(model.pendingSubmissions, 7);
      expect(model.averageCourseRating, 4.85);
    });

    test('CourseModel copyWith and lifecycle status helpers work', () {
      final course = CourseModel(
        id: 'c-1',
        title: 'Original Title',
        slug: 'original-title',
        status: 'DRAFT',
      );

      expect(course.isDraft, isTrue);
      expect(course.isPublished, isFalse);
      expect(course.isArchived, isFalse);

      final published = course.copyWith(status: 'PUBLISHED', title: 'Updated Title');
      expect(published.isPublished, isTrue);
      expect(published.isDraft, isFalse);
      expect(published.title, 'Updated Title');

      final archived = course.copyWith(status: 'ARCHIVED');
      expect(archived.isArchived, isTrue);
    });

    test('SectionModel copyWith updates order and isPublished properly', () {
      final section = SectionModel(
        id: 'sec-1',
        courseId: 'c-1',
        title: 'Section 1',
        order: 1,
        isPublished: false,
      );

      final updated = section.copyWith(order: 2, isPublished: true, title: 'Renamed Section');
      expect(updated.order, 2);
      expect(updated.isPublished, isTrue);
      expect(updated.title, 'Renamed Section');
      expect(updated.courseId, 'c-1');
    });

    test('LessonModel copyWith updates lessonType and media state', () {
      final lesson = LessonModel(
        id: 'les-1',
        courseId: 'c-1',
        sectionId: 'sec-1',
        title: 'Intro Lesson',
        lessonType: LessonType.text,
        durationMinutes: 10,
        isPublished: false,
      );

      final updated = lesson.copyWith(
        lessonType: LessonType.video,
        videoUrl: 'https://cdn.example.com/video.mp4',
        durationMinutes: 20,
        isPublished: true,
      );

      expect(updated.lessonType, LessonType.video);
      expect(updated.isVideo, isTrue);
      expect(updated.isPublished, isTrue);
      expect(updated.durationMinutes, 20);
      expect(updated.videoUrl, 'https://cdn.example.com/video.mp4');
    });

    test('EnrollmentModel deserializes populated student object from instructor API', () {
      final json = {
        'id': 'enr-101',
        'courseId': 'c-1',
        'studentId': {
          'id': 'user-std-1',
          'firstName': 'Kamal',
          'lastName': 'Perera',
          'email': 'kamal@student.com',
          'profileImageUrl': 'https://cdn.example.com/avatar.jpg',
        },
        'status': 'ACTIVE',
        'progressPercentage': 75,
      };

      final enr = EnrollmentModel.fromJson(json);

      expect(enr.id, 'enr-101');
      expect(enr.studentId, 'user-std-1');
      expect(enr.studentName, 'Kamal Perera');
      expect(enr.studentEmail, 'kamal@student.com');
      expect(enr.studentProfileImageUrl, 'https://cdn.example.com/avatar.jpg');
      expect(enr.progressPercentage, 75);
      expect(enr.isActive, isTrue);
    });

    test('AssignmentSubmissionModel parses populated student info', () {
      final json = {
        'id': 'sub-201',
        'assignmentId': 'assign-1',
        'studentId': {
          'id': 'user-std-2',
          'firstName': 'Nadeesha',
          'lastName': 'Silva',
          'email': 'nadeesha@student.com',
        },
        'textAnswer': 'Completed all modules.',
        'status': 'GRADED',
        'marksAwarded': 90,
        'feedback': 'Well structured!',
      };

      final sub = AssignmentSubmissionModel.fromJson(json);

      expect(sub.studentId, 'user-std-2');
      expect(sub.studentName, 'Nadeesha Silva');
      expect(sub.studentEmail, 'nadeesha@student.com');
      expect(sub.marksAwarded, 90);
      expect(sub.isGraded, isTrue);
      expect(sub.feedback, 'Well structured!');
    });

    test('QuizAttemptModel parses populated student info', () {
      final json = {
        'id': 'att-301',
        'quizId': 'quiz-1',
        'studentId': {
          'id': 'user-std-3',
          'firstName': 'Amal',
          'lastName': 'Fernando',
          'email': 'amal@student.com',
        },
        'score': 10,
        'totalMarks': 10,
        'percentage': 100.0,
        'passed': true,
        'status': 'SUBMITTED',
        'attemptNumber': 1,
      };

      final attempt = QuizAttemptModel.fromJson(json);

      expect(attempt.studentId, 'user-std-3');
      expect(attempt.studentName, 'Amal Fernando');
      expect(attempt.studentEmail, 'amal@student.com');
      expect(attempt.passed, isTrue);
      expect(attempt.percentage, 100.0);
    });
  });

  group('Day 8: Instructor Studio Widget Tests', () {
    testWidgets('InstructorDashboardScreen renders dashboard title, banner and metrics', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => InstructorProvider()),
          ],
          child: const MaterialApp(
            home: InstructorDashboardScreen(instructorName: 'Dr. Nimal'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Instructor Studio 👨‍🏫'), findsOneWidget);
      expect(find.text('Dr. Nimal'), findsOneWidget);

      final hasLoading = find.byType(LoadingStateWidget).evaluate().isNotEmpty;
      final hasBanner = find.text('Create New Course').evaluate().isNotEmpty;
      final hasScrollView = find.byType(SingleChildScrollView).evaluate().isNotEmpty;
      expect(hasLoading || hasBanner || hasScrollView, isTrue);
    });

    testWidgets('CourseCreateEditScreen renders form inputs and buttons', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => InstructorProvider()),
          ],
          child: const MaterialApp(
            home: CourseCreateEditScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Create New Course'), findsOneWidget);
      expect(find.text('Course Title'), findsOneWidget);
      expect(find.text('Short Summary'), findsOneWidget);
      expect(find.text('Full Description'), findsOneWidget);
      expect(find.text('Create Course Draft'), findsOneWidget);
    });

    testWidgets('CourseStudioScreen mounts with tabs', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => InstructorProvider()),
          ],
          child: const MaterialApp(
            home: CourseStudioScreen(courseId: 'c-1', initialTitle: 'Flutter Pro Studio'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Flutter Pro Studio'), findsOneWidget);
      expect(find.text('Curriculum'), findsOneWidget);
      expect(find.text('Assessments'), findsOneWidget);
      expect(find.text('Learners'), findsOneWidget);

      final hasLoading = find.byType(LoadingStateWidget).evaluate().isNotEmpty;
      final hasTabBarView = find.byType(TabBarView).evaluate().isNotEmpty;
      final hasEmpty = find.byType(EmptyStateWidget).evaluate().isNotEmpty;
      expect(hasLoading || hasTabBarView || hasEmpty, isTrue);
    });
  });
}
