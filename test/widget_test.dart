import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_lms/main.dart';
import 'package:flutter_lms/core/constants/app_strings.dart';

void main() {
  testWidgets('Login screen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const FlutterLmsApp());

    // Verify that login title and sign-in button exist.
    expect(find.text(AppStrings.appName), findsOneWidget);
    expect(find.text(AppStrings.signIn), findsOneWidget);
    expect(find.text(AppStrings.email), findsOneWidget);
    expect(find.text(AppStrings.password), findsOneWidget);
  });
}
