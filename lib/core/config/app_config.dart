import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class AppConfig {
  AppConfig._();

  // Android emulator points to Windows host at 10.0.2.2:5000
  // Postman on host uses localhost:5000
  // Physical device can use adb reverse tcp:5000 tcp:5000 (localhost:5000) or Wi-Fi IP
  static const String defaultEmulatorBaseUrl = 'http://10.0.2.2:5000';
  static const String defaultLocalhostBaseUrl = 'http://localhost:5000';

  static String get initialBaseUrl {
    if (kIsWeb) return defaultLocalhostBaseUrl;
    try {
      if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        return defaultLocalhostBaseUrl;
      }
    } catch (_) {}
    return defaultEmulatorBaseUrl;
  }

  // Configurable base URL (Auto-detects desktop/web vs Android emulator)
  // Important: Do not append /api/v1 here because endpoints already include /api/v1
  static String baseUrl = initialBaseUrl;

  // Network Timeouts
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
  static const Duration sendTimeout = Duration(seconds: 30);

  // Helper to switch to custom IP or localhost
  static void setBaseUrl(String url) {
    baseUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }
}
