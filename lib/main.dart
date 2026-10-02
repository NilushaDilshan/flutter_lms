import 'package:flutter/material.dart';
import 'core/constants/app_strings.dart';
import 'core/routes/app_routes.dart';
import 'core/routes/route_generator.dart';
import 'core/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FlutterLmsApp());
}

class FlutterLmsApp extends StatelessWidget {
  const FlutterLmsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.initial,
      onGenerateRoute: RouteGenerator.generateRoute,
    );
  }
}
