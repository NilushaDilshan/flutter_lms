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

  // Day 7: Assessments & Communication
  static const String quizzes = '/quizzes';
  static const String quizAttempt = '/quiz-attempt';
  static const String assignments = '/assignments';
  static const String assignmentDetail = '/assignment-detail';
  static const String notifications = '/notifications';

  // Day 8: Instructor Course Building and Management
  static const String instructorCourses = '/instructor/courses';
  static const String instructorCourseCreate = '/instructor/courses/create';
  static const String instructorCourseStudio = '/instructor/courses/studio';
  static const String instructorSubmissions = '/instructor/submissions';
  static const String instructorQuizAttempts = '/instructor/quiz-attempts';

  // Day 9: Admin Management & Navigation Shells
  static const String studentMain = '/student/main';
  static const String instructorMain = '/instructor/main';
  static const String adminMain = '/admin/main';
  static const String adminUsers = '/admin/users';
  static const String adminCategories = '/admin/categories';
  static const String adminCourses = '/admin/courses';
  static const String adminEnrollments = '/admin/enrollments';
  static const String adminReviews = '/admin/reviews';
}
