import 'package:flutter/material.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/otp_verification_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/dashboard/screens/admin_dashboard_screen.dart';
import '../../features/dashboard/screens/instructor_dashboard_screen.dart';
import '../../features/dashboard/screens/student_dashboard_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
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
