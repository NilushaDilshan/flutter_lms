class AppRoutes {
  AppRoutes._();

  static const String initial = '/';
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String verifyOtp = '/verify-otp';
  static const String forgotPassword = '/forgot-password';
  static const String profile = '/profile';

  // Role Dashboards
  static const String studentDashboard = '/student/dashboard';
  static const String instructorDashboard = '/instructor/dashboard';
  static const String adminDashboard = '/admin/dashboard';

  // Courses & Curriculum
  static const String courses = '/courses';
  static const String courseDetail = '/course-detail';
  static const String lessonPlayer = '/lesson-player';
  static const String myCourses = '/my-courses';
}
