import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_lms/core/constants/app_strings.dart';
import 'package:flutter_lms/core/routes/app_routes.dart';
import 'package:flutter_lms/core/widgets/empty_state_widget.dart';
import 'package:flutter_lms/core/widgets/error_state_widget.dart';
import 'package:flutter_lms/core/widgets/loading_state_widget.dart';
import 'package:flutter_lms/core/widgets/success_state_widget.dart';
import 'package:flutter_lms/features/auth/screens/login_screen.dart';
import 'package:flutter_lms/features/onboarding/screens/onboarding_screen.dart';
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

  testWidgets('Login screen and navigation test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: (settings) {
          if (settings.name == '/student/dashboard') {
            return MaterialPageRoute(
              builder: (_) => const Scaffold(body: Text('Student Dashboard Loaded')),
            );
          }
          return MaterialPageRoute(builder: (_) => const LoginScreen());
        },
      ),
    );

    expect(find.text(AppStrings.appName), findsOneWidget);
    expect(find.text(AppStrings.signIn), findsOneWidget);

    await tester.tap(find.text(AppStrings.signIn));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pumpAndSettle();

    expect(find.text('Student Dashboard Loaded'), findsOneWidget);
  });
}
