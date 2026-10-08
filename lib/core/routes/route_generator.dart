import 'package:flutter/material.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/otp_verification_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/courses/models/lesson_model.dart';
import '../../features/courses/screens/course_catalog_screen.dart';
import '../../features/courses/screens/course_detail_screen.dart';
import '../../features/courses/screens/lesson_player_screen.dart';
import '../../features/courses/screens/my_courses_screen.dart';
import '../../features/dashboard/screens/admin_dashboard_screen.dart';
import '../../features/dashboard/screens/instructor_dashboard_screen.dart';
import '../../features/dashboard/screens/student_dashboard_screen.dart';
import '../../features/assignments/models/assignment_model.dart';
import '../../features/assignments/screens/assignment_detail_screen.dart';
import '../../features/assignments/screens/assignment_list_screen.dart';
import '../../features/notifications/screens/notification_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/quizzes/models/quiz_model.dart';
import '../../features/quizzes/screens/quiz_attempt_screen.dart';
import '../../features/quizzes/screens/quiz_list_screen.dart';
import '../../features/splash/screens/splash_screen.dart';
import 'app_routes.dart';

class RouteGenerator {
  RouteGenerator._();

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.initial:
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
          settings: settings,
        );

      case AppRoutes.onboarding:
        return MaterialPageRoute(
          builder: (_) => const OnboardingScreen(),
          settings: settings,
        );

      case AppRoutes.login:
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
          settings: settings,
        );

      case AppRoutes.register:
        return MaterialPageRoute(
          builder: (_) => const RegisterScreen(),
          settings: settings,
        );

      case AppRoutes.verifyOtp:
        final args = settings.arguments as Map<String, dynamic>?;
        final email = args?['email'] as String? ?? '';
        final role = args?['role'] as String? ?? 'STUDENT';
        return MaterialPageRoute(
          builder: (_) => OtpVerificationScreen(email: email, role: role),
          settings: settings,
        );

      case AppRoutes.forgotPassword:
        return MaterialPageRoute(
          builder: (_) => const ForgotPasswordScreen(),
          settings: settings,
        );

      case AppRoutes.profile:
        return MaterialPageRoute(
          builder: (_) => const ProfileScreen(),
          settings: settings,
        );

      case AppRoutes.studentDashboard:
        final args = settings.arguments as Map<String, dynamic>?;
        final name = args?['name'] as String? ?? 'Kamal Perera';
        return MaterialPageRoute(
          builder: (_) => StudentDashboardScreen(studentName: name),
          settings: settings,
        );

      case AppRoutes.instructorDashboard:
        final args = settings.arguments as Map<String, dynamic>?;
        final name = args?['name'] as String? ?? 'Nimal Fernando';
        return MaterialPageRoute(
          builder: (_) => InstructorDashboardScreen(instructorName: name),
          settings: settings,
        );

      case AppRoutes.adminDashboard:
        final args = settings.arguments as Map<String, dynamic>?;
        final email = args?['email'] as String? ?? 'admin@lms.com';
        return MaterialPageRoute(
          builder: (_) => AdminDashboardScreen(adminEmail: email),
          settings: settings,
        );

      case AppRoutes.courses:
        return MaterialPageRoute(
          builder: (_) => const CourseCatalogScreen(),
          settings: settings,
        );

      case AppRoutes.courseDetail:
        final args = settings.arguments as Map<String, dynamic>?;
        final courseId = args?['courseId'] as String? ?? '';
        final title = args?['title'] as String?;
        return MaterialPageRoute(
          builder: (_) => CourseDetailScreen(courseId: courseId, initialTitle: title),
          settings: settings,
        );

      case AppRoutes.lessonPlayer:
        final args = settings.arguments as Map<String, dynamic>?;
        final courseId = args?['courseId'] as String? ?? '';
        final lesson = args?['lesson'] as LessonModel?;
        if (lesson == null) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(body: Center(child: Text('Lesson not specified'))),
          );
        }
        return MaterialPageRoute(
          builder: (_) => LessonPlayerScreen(courseId: courseId, lesson: lesson),
          settings: settings,
        );

      case AppRoutes.myCourses:
        return MaterialPageRoute(
          builder: (_) => const MyCoursesScreen(),
          settings: settings,
        );

      case AppRoutes.quizzes:
        final args = settings.arguments as Map<String, dynamic>?;
        final courseId = args?['courseId'] as String?;
        final courseTitle = args?['courseTitle'] as String?;
        return MaterialPageRoute(
          builder: (_) => QuizListScreen(courseId: courseId, courseTitle: courseTitle),
          settings: settings,
        );

      case AppRoutes.quizAttempt:
        final args = settings.arguments as Map<String, dynamic>?;
        final quizId = args?['quizId'] as String? ?? '';
        final quizTitle = args?['quizTitle'] as String?;
        final quiz = args?['quiz'] as QuizModel?;
        return MaterialPageRoute(
          builder: (_) => QuizAttemptScreen(quizId: quizId, quizTitle: quizTitle, initialQuiz: quiz),
          settings: settings,
        );

      case AppRoutes.assignments:
        final args = settings.arguments as Map<String, dynamic>?;
        final courseId = args?['courseId'] as String?;
        final courseTitle = args?['courseTitle'] as String?;
        return MaterialPageRoute(
          builder: (_) => AssignmentListScreen(courseId: courseId, courseTitle: courseTitle),
          settings: settings,
        );

      case AppRoutes.assignmentDetail:
        final args = settings.arguments as Map<String, dynamic>?;
        final assignmentId = args?['assignmentId'] as String? ?? '';
        final assignment = args?['assignment'] as AssignmentModel?;
        return MaterialPageRoute(
          builder: (_) => AssignmentDetailScreen(assignmentId: assignmentId, initialAssignment: assignment),
          settings: settings,
        );

      case AppRoutes.notifications:
        return MaterialPageRoute(
          builder: (_) => const NotificationScreen(),
          settings: settings,
        );

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('Route not found: ${settings.name}'),
            ),
          ),
        );
    }
  }
}
