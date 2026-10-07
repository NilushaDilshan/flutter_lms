import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_lms/features/courses/models/category_model.dart';
import 'package:flutter_lms/features/courses/models/course_model.dart';
import 'package:flutter_lms/features/courses/models/enrollment_model.dart';
import 'package:flutter_lms/features/courses/models/lesson_model.dart';
import 'package:flutter_lms/features/courses/models/progress_model.dart';
import 'package:flutter_lms/features/courses/models/section_model.dart';
import 'package:flutter_lms/features/courses/providers/course_provider.dart';
import 'package:flutter_lms/features/courses/screens/course_catalog_screen.dart';
import 'package:flutter_lms/features/courses/screens/course_detail_screen.dart';
import 'package:flutter_lms/features/courses/screens/lesson_player_screen.dart';
import 'package:flutter_lms/features/courses/screens/my_courses_screen.dart';
import 'package:flutter_lms/features/courses/widgets/course_card.dart';

void main() {
  group('Day 6: Models Unit Tests', () {
    test('CategoryModel deserializes backend category JSON', () {
      final json = {
        '_id': 'cat-101',
        'name': 'Mobile App Development',
        'slug': 'mobile-app-development',
        'description': 'Flutter & iOS development',
        'isActive': true,
      };

      final category = CategoryModel.fromJson(json);
      expect(category.id, 'cat-101');
      expect(category.name, 'Mobile App Development');
      expect(category.isActive, isTrue);
    });

    test('CourseModel deserializes backend course JSON with instructor and outcomes', () {
      final json = {
        'id': 'course-101',
        'title': 'Flutter Mastery',
        'slug': 'flutter-mastery',
        'level': 'BEGINNER',
        'language': 'English',
        'isFree': true,
        'price': 0,
        'averageRating': 4.9,
        'reviewCount': 15,
        'totalEnrollments': 120,
        'categoryId': {'id': 'cat-1', 'name': 'Mobile Development'},
        'instructorId': {'id': 'instr-1', 'firstName': 'Nimal', 'lastName': 'Fernando'},
        'learningOutcomes': ['Build Flutter apps', 'Master widgets'],
      };

      final course = CourseModel.fromJson(json);
      expect(course.id, 'course-101');
      expect(course.title, 'Flutter Mastery');
      expect(course.level, 'BEGINNER');
      expect(course.isFree, isTrue);
      expect(course.categoryName, 'Mobile Development');
      expect(course.instructor?.fullName, 'Nimal Fernando');
      expect(course.learningOutcomes.length, 2);
    });

    test('LessonModel deserializes TEXT, VIDEO, and DOCUMENT lesson types correctly', () {
      final textJson = {
        'id': 'l-1',
        'courseId': 'c-1',
        'sectionId': 's-1',
        'title': 'Dart Basics',
        'lessonType': 'TEXT',
        'textContent': 'Dart is a client-optimized language.',
        'durationMinutes': 10,
        'isPreview': true,
      };

      final textLesson = LessonModel.fromJson(textJson);
      expect(textLesson.isText, isTrue);
      expect(textLesson.isVideo, isFalse);
      expect(textLesson.textContent, contains('Dart is'));
      expect(textLesson.isPreview, isTrue);

      final videoJson = {
        'id': 'l-2',
        'courseId': 'c-1',
        'sectionId': 's-1',
        'title': 'Widget Tour',
        'lessonType': 'VIDEO',
        'videoUrl': 'https://example.com/video.mp4',
        'durationMinutes': 15,
      };

      final videoLesson = LessonModel.fromJson(videoJson);
      expect(videoLesson.isVideo, isTrue);
      expect(videoLesson.videoUrl, 'https://example.com/video.mp4');

      final docJson = {
        'id': 'l-3',
        'courseId': 'c-1',
        'sectionId': 's-1',
        'title': 'Cheatsheet',
        'lessonType': 'DOCUMENT',
        'documentUrl': 'https://example.com/cheatsheet.pdf',
        'documentName': 'cheatsheet.pdf',
        'durationMinutes': 5,
      };

      final docLesson = LessonModel.fromJson(docJson);
      expect(docLesson.isDocument, isTrue);
      expect(docLesson.documentName, 'cheatsheet.pdf');
    });

    test('SectionModel deserializes with nested lessons list', () {
      final json = {
        'id': 'sec-1',
        'courseId': 'c-1',
        'title': 'Introduction',
        'order': 1,
        'lessons': [
          {
            'id': 'l-1',
            'courseId': 'c-1',
            'sectionId': 'sec-1',
            'title': 'Welcome',
            'lessonType': 'TEXT',
          }
        ],
      };

      final section = SectionModel.fromJson(json);
      expect(section.id, 'sec-1');
      expect(section.title, 'Introduction');
      expect(section.lessons.length, 1);
      expect(section.lessons.first.title, 'Welcome');
    });

    test('EnrollmentModel and ProgressModel calculate completion status accurately', () {
      final enrollJson = {
        'id': 'enr-1',
        'studentId': 'std-1',
        'courseId': {'id': 'c-1', 'title': 'Flutter Mastery'},
        'status': 'ACTIVE',
        'progressPercentage': 50,
      };

      final enrollment = EnrollmentModel.fromJson(enrollJson);
      expect(enrollment.id, 'enr-1');
      expect(enrollment.isActive, isTrue);
      expect(enrollment.progressPercentage, 50);
      expect(enrollment.course?.title, 'Flutter Mastery');

      final progressJson = {
        'enrollment': {'progressPercentage': 66},
        'lessons': [
          {'id': 'l-1', 'progress': {'status': 'COMPLETED'}},
          {'id': 'l-2', 'progress': {'status': 'COMPLETED'}},
          {'id': 'l-3', 'progress': {'status': 'IN_PROGRESS'}},
        ],
      };

      final progress = CourseProgressModel.fromJson(progressJson);
      expect(progress.progressPercentage, 66);
      expect(progress.totalLessons, 3);
      expect(progress.completedLessons, 2);
      expect(progress.isLessonCompleted('l-1'), isTrue);
      expect(progress.isLessonCompleted('l-3'), isFalse);
    });
  });

  group('Day 6: Widget Tests for Course Screens', () {
    testWidgets('CourseCatalogScreen renders search, chips and courses', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => CourseProvider(),
          child: const MaterialApp(
            home: CourseCatalogScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Explore Courses'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('All Categories'), findsOneWidget);
      expect(find.text('Level:'), findsOneWidget);
    });

    testWidgets('CourseDetailScreen renders curriculum accordion and enroll button', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => CourseProvider(),
          child: const MaterialApp(
            home: CourseDetailScreen(
              courseId: '6a5c39ae384147c91b73906a',
              initialTitle: 'Flutter Development for Beginners',
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Flutter Development for Beginners'), findsWidgets);
    });

    testWidgets('LessonPlayerScreen renders Text lesson and complete button', (WidgetTester tester) async {
      final sampleLesson = LessonModel(
        id: 'l-test',
        courseId: 'c-test',
        sectionId: 's-test',
        title: 'Introduction to State Management',
        lessonType: LessonType.text,
        textContent: 'Provider is a wrapper around InheritedWidget.',
        durationMinutes: 10,
      );

      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => CourseProvider(),
          child: MaterialApp(
            home: LessonPlayerScreen(
              courseId: 'c-test',
              lesson: sampleLesson,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Introduction to State Management'), findsWidgets);
      expect(find.text('Mark Lesson as Completed'), findsOneWidget);
      expect(find.text('Provider is a wrapper around InheritedWidget.'), findsOneWidget);
      expect(find.text('Next Lesson'), findsOneWidget);
    });

    testWidgets('LessonPlayerScreen renders Video lesson with player controls', (WidgetTester tester) async {
      final videoLesson = LessonModel(
        id: 'l-vid',
        courseId: 'c-test',
        sectionId: 's-test',
        title: 'Building Responsive UI',
        lessonType: LessonType.video,
        videoUrl: 'https://example.com/sample.mp4',
        durationMinutes: 12,
      );

      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => CourseProvider(),
          child: MaterialApp(
            home: LessonPlayerScreen(
              courseId: 'c-test',
              lesson: videoLesson,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Building Responsive UI'), findsWidgets);
      expect(find.byIcon(Icons.play_circle_fill), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);
    });

    testWidgets('MyCoursesScreen renders enrolled courses list', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => CourseProvider(),
          child: const MaterialApp(
            home: MyCoursesScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('My Enrolled Courses'), findsOneWidget);
    });

    testWidgets('CourseCard widget renders course details and responds to tap', (WidgetTester tester) async {
      bool tapped = false;
      final course = CourseModel(
        id: 'c-card-test',
        title: 'Full-Stack Development with Flutter',
        slug: 'full-stack-flutter',
        categoryName: 'Mobile Development',
        level: 'INTERMEDIATE',
        isFree: true,
        price: 0,
        averageRating: 4.8,
        reviewCount: 42,
        totalEnrollments: 350,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CourseCard(
              course: course,
              isEnrolled: false,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Full-Stack Development with Flutter'), findsWidgets);
      expect(find.text('INTERMEDIATE'), findsOneWidget);
      expect(find.text('FREE'), findsOneWidget);
      expect(find.text('350'), findsOneWidget);

      await tester.tap(find.byType(CourseCard));
      expect(tapped, isTrue);
    });

    test('CourseProvider pagination and filters update state correctly', () {
      final provider = CourseProvider();
      expect(provider.currentPage, 1);
      expect(provider.hasNextPage, isFalse);
      expect(provider.isLoadingMore, isFalse);

      provider.setCategoryFilter('cat-1');
      expect(provider.selectedCategoryId, 'cat-1');

      provider.setLevelFilter('BEGINNER');
      expect(provider.selectedLevel, 'BEGINNER');

      provider.setSearchQuery('Flutter');
      expect(provider.searchQuery, 'Flutter');
    });
  });
}
