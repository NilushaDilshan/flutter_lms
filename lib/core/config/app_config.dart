class AppConfig {
  AppConfig._();

  // Android emulator points to Windows host at 10.0.2.2:5000
  // Postman on host uses localhost:5000
  // Physical device can use adb reverse tcp:5000 tcp:5000 (localhost:5000) or Wi-Fi IP
  static const String defaultEmulatorBaseUrl = 'http://10.0.2.2:5000';
  static const String defaultLocalhostBaseUrl = 'http://localhost:5000';

  // Configurable base URL (Defaults to Android emulator per task specifications)
  // Important: Do not append /api/v1 here because endpoints already include /api/v1
  // ADB reverse tunnel active: adb reverse tcp:5000 tcp:5000
  // Phone localhost:5000 → PC Docker backend
  static String baseUrl = defaultLocalhostBaseUrl;

  // Network Timeouts
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
  static const Duration sendTimeout = Duration(seconds: 30);

  // Helper to switch to custom IP or localhost
  static void setBaseUrl(String url) {
    baseUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }
}
