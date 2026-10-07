import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_lms/core/constants/app_strings.dart';
import 'package:flutter_lms/core/routes/app_routes.dart';
import 'package:flutter_lms/core/widgets/custom_text_field.dart';
import 'package:flutter_lms/core/widgets/empty_state_widget.dart';
import 'package:flutter_lms/core/widgets/error_state_widget.dart';
import 'package:flutter_lms/core/widgets/loading_state_widget.dart';
import 'package:flutter_lms/core/widgets/success_state_widget.dart';
import 'package:flutter_lms/features/auth/providers/auth_provider.dart';
import 'package:flutter_lms/features/auth/screens/forgot_password_screen.dart';
import 'package:flutter_lms/features/auth/screens/login_screen.dart';
import 'package:flutter_lms/features/auth/screens/otp_verification_screen.dart';
import 'package:flutter_lms/features/auth/screens/register_screen.dart';
import 'package:flutter_lms/features/onboarding/screens/onboarding_screen.dart';
import 'package:flutter_lms/features/profile/providers/profile_provider.dart';
import 'package:flutter_lms/features/splash/screens/splash_screen.dart';

void main() {
  testWidgets('Splash Screen smoke test and navigation to onboarding', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const SplashScreen(),
        routes: {
          AppRoutes.onboarding: (_) => const Scaffold(body: Text('Onboarding Loaded')),
        },
      ),
    );

    expect(find.text(AppStrings.appName), findsOneWidget);
    expect(find.text(AppStrings.appTagline), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Advance timer past the 2.2s splash timer
    await tester.pump(const Duration(milliseconds: 2300));
    await tester.pumpAndSettle();

    expect(find.text('Onboarding Loaded'), findsOneWidget);
  });

  testWidgets('Onboarding Screen 3-page flow test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: OnboardingScreen(),
      ),
    );

    // Page 1
    expect(find.text('Learn Anywhere, Anytime'), findsOneWidget);
    expect(find.text('1 of 3'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);

    // Tap Next -> Page 2
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Assessments, Quizzes & Feedback'), findsOneWidget);
    expect(find.text('2 of 3'), findsOneWidget);

    // Tap Next -> Page 3
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Unified Academy Experience'), findsOneWidget);
    expect(find.text('3 of 3'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
  });

  testWidgets('Standard UI State Widgets test', (WidgetTester tester) async {
    bool retryPressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                const LoadingStateWidget(message: 'Loading courses...'),
                const EmptyStateWidget(
                  title: 'No Items',
                  message: 'Nothing to display',
                  actionText: 'Add New',
                ),
                ErrorStateWidget(
                  message: 'Network timeout',
                  onRetry: () => retryPressed = true,
                ),
                const SuccessStateWidget(
                  title: 'Success!',
                  message: 'Operation completed',
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Loading courses...'), findsOneWidget);
    expect(find.text('No Items'), findsOneWidget);
    expect(find.text('Network timeout'), findsOneWidget);
    expect(find.text('Success!'), findsOneWidget);

    // Test retry callback
    await tester.tap(find.text('Try Again'));
    expect(retryPressed, isTrue);
  });

  testWidgets('Register screen renders role tabs and student fields', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ],
        child: const MaterialApp(
          home: RegisterScreen(),
        ),
      ),
    );

    expect(find.text('Create Account'), findsOneWidget);
    expect(find.text('Student Account'), findsOneWidget);
    expect(find.text('Instructor Account'), findsOneWidget);
    expect(find.text('Date of Birth (YYYY-MM-DD)'), findsOneWidget);
    expect(find.text('Education Level'), findsOneWidget);

    // Switch to Instructor tab
    await tester.tap(find.text('Instructor Account'));
    await tester.pumpAndSettle();

    expect(find.text('Professional Headline'), findsOneWidget);
    expect(find.text('Qualification'), findsOneWidget);
  });

  testWidgets('OtpVerificationScreen renders verification UI and timer', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
        ],
        child: const MaterialApp(
          home: OtpVerificationScreen(email: 'test@lms.com'),
        ),
      ),
    );

    expect(find.text('Verify Your Email Address'), findsOneWidget);
    expect(find.textContaining('test@lms.com'), findsOneWidget);
    expect(find.text('Verify & Activate Account'), findsOneWidget);
    expect(find.textContaining('Resend code in'), findsOneWidget);
  });

  testWidgets('ForgotPasswordScreen renders step 1 email input', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
        ],
        child: const MaterialApp(
          home: ForgotPasswordScreen(),
        ),
      ),
    );

    expect(find.text('Forgot Your Password?'), findsOneWidget);
    expect(find.text('Send Reset Code'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Code'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
  });

  testWidgets('Login screen and navigation test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ],
        child: MaterialApp(
          onGenerateRoute: (settings) {
            if (settings.name == '/student/dashboard') {
              return MaterialPageRoute(
                builder: (_) => const Scaffold(body: Text('Student Dashboard Loaded')),
              );
            }
            return MaterialPageRoute(builder: (_) => const LoginScreen());
          },
        ),
      ),
    );

    expect(find.text(AppStrings.appName), findsOneWidget);
    expect(find.text(AppStrings.signIn), findsOneWidget);

    await tester.enterText(find.byType(CustomTextField).first, 'kamal.perera@example.com');
    await tester.enterText(find.byType(CustomTextField).last, 'Password123!');

    await tester.tap(find.text(AppStrings.signIn));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pumpAndSettle();

    expect(find.text('Student Dashboard Loaded'), findsOneWidget);
  });

  testWidgets('Login redirects to Instructor dashboard when instructor email is entered', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ],
        child: MaterialApp(
          onGenerateRoute: (settings) {
            if (settings.name == '/instructor/dashboard') {
              return MaterialPageRoute(
                builder: (_) => const Scaffold(body: Text('Instructor Dashboard Loaded')),
              );
            }
            return MaterialPageRoute(builder: (_) => const LoginScreen());
          },
        ),
      ),
    );

    await tester.enterText(find.byType(CustomTextField).first, 'nimal.instructor@example.com');
    await tester.enterText(find.byType(CustomTextField).last, 'Password123!');

    await tester.tap(find.text(AppStrings.signIn));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pumpAndSettle();

    expect(find.text('Instructor Dashboard Loaded'), findsOneWidget);
  });

  testWidgets('Login redirects to Admin dashboard when admin email is entered', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ],
        child: MaterialApp(
          onGenerateRoute: (settings) {
            if (settings.name == '/admin/dashboard') {
              return MaterialPageRoute(
                builder: (_) => const Scaffold(body: Text('Admin Dashboard Loaded')),
              );
            }
            return MaterialPageRoute(builder: (_) => const LoginScreen());
          },
        ),
      ),
    );

    await tester.enterText(find.byType(CustomTextField).first, 'admin@lms.com');
    await tester.enterText(find.byType(CustomTextField).last, 'AdminPass123!');

    await tester.tap(find.text(AppStrings.signIn));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pumpAndSettle();

    expect(find.text('Admin Dashboard Loaded'), findsOneWidget);
  });
}
