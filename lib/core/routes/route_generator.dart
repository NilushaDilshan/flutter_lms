import 'package:flutter/material.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/dashboard/screens/admin_dashboard_screen.dart';
import '../../features/dashboard/screens/instructor_dashboard_screen.dart';
import '../../features/dashboard/screens/student_dashboard_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
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
