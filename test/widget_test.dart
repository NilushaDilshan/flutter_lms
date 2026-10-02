import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_lms/main.dart';
import 'package:flutter_lms/core/constants/app_strings.dart';

void main() {
  testWidgets('Login screen smoke test and role navigation', (WidgetTester tester) async {
    // Build app
    await tester.pumpWidget(const FlutterLmsApp());
    await tester.pumpAndSettle();

    // Verify login screen elements
    expect(find.text(AppStrings.appName), findsOneWidget);
    expect(find.text(AppStrings.signIn), findsOneWidget);
    expect(find.text(AppStrings.email), findsOneWidget);
    expect(find.text(AppStrings.password), findsOneWidget);

    // Tap Sign In button
    await tester.tap(find.text(AppStrings.signIn));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pumpAndSettle();

    // Verify navigated to Student Dashboard
    expect(find.textContaining('Kamal Perera'), findsOneWidget);
    expect(find.text('STUDENT'), findsOneWidget);
    expect(find.text('CONTINUE LEARNING'), findsOneWidget);

    // Tap Logout button in AppBar
    await tester.tap(find.byIcon(Icons.logout_rounded));
    await tester.pumpAndSettle();

    // Verify ConfirmationDialog appeared
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Are you sure you want to end your student session and log out?'), findsOneWidget);
    expect(find.text('Logout'), findsNWidgets(2)); // Dialog title and confirm button
  });
}
