class ApiEndpoints {
  ApiEndpoints._();

  // Authentication & Session
  static const String registerStudent = '/api/v1/auth/register/student';
  static const String registerInstructor = '/api/v1/auth/register/instructor';
  static const String verifyEmail = '/api/v1/auth/verify-email';
  static const String resendVerificationOtp = '/api/v1/auth/resend-verification-otp';
  static const String login = '/api/v1/auth/login';
  static const String refreshToken = '/api/v1/auth/refresh-token';
  static const String logout = '/api/v1/auth/logout';
  static const String logoutAll = '/api/v1/auth/logout-all';

  // Password Recovery
  static const String forgotPassword = '/api/v1/auth/forgot-password';
  static const String verifyResetOtp = '/api/v1/auth/verify-reset-otp';
  static const String resetPassword = '/api/v1/auth/reset-password';

  // User Profile
  static const String currentUser = '/api/v1/users/me';
  static const String updateStudentProfile = '/api/v1/users/profile/student';
  static const String updateInstructorProfile = '/api/v1/users/profile/instructor';
  static const String uploadProfileImage = '/api/v1/users/profile/image';
  static const String deleteProfileImage = '/api/v1/users/profile/image';

  // Course Categories
  static const String categories = '/api/v1/categories';
  static String categoryById(String id) => '/api/v1/categories/$id';
  static String toggleCategoryStatus(String id) => '/api/v1/categories/$id/status';

  // Courses
  static const String publishedCourses = '/api/v1/courses';
  static const String instructorCourses = '/api/v1/courses/instructor/my-courses';
  static const String adminCourses = '/api/v1/courses/admin/all';
  static String courseById(String id) => '/api/v1/courses/$id';
  static String courseThumbnail(String id) => '/api/v1/courses/$id/thumbnail';
  static String publishCourse(String id) => '/api/v1/courses/$id/publish';
  static String archiveCourse(String id) => '/api/v1/courses/$id/archive';

  // Sections & Lessons
  static String courseSections(String courseId) => '/api/v1/courses/$courseId/sections';
  static String sectionById(String id) => '/api/v1/sections/$id';
  static String sectionLessons(String sectionId) => '/api/v1/sections/$sectionId/lessons';
  static String lessonById(String id) => '/api/v1/lessons/$id';
  static String lessonMedia(String id) => '/api/v1/lessons/$id/media';
  static String startLesson(String id) => '/api/v1/lessons/$id/start';
  static String completeLesson(String id) => '/api/v1/lessons/$id/complete';

  // Enrollments & Progress
  static const String myEnrollments = '/api/v1/enrollments/my-courses';
  static const String enrollCourse = '/api/v1/enrollments';
  static String courseProgress(String courseId) => '/api/v1/enrollments/$courseId/progress';
  static String courseEnrollments(String courseId) => '/api/v1/enrollments/course/$courseId';

  // Quizzes & Attempts
  static String sectionQuizzes(String sectionId) => '/api/v1/sections/$sectionId/quizzes';
  static String quizById(String id) => '/api/v1/quizzes/$id';
  static String startQuiz(String id) => '/api/v1/quizzes/$id/start';
  static String submitQuiz(String id) => '/api/v1/quizzes/$id/submit';
  static String quizAttempts(String id) => '/api/v1/quizzes/$id/attempts';

  // Assignments & Submissions
  static String sectionAssignments(String sectionId) => '/api/v1/sections/$sectionId/assignments';
  static String assignmentById(String id) => '/api/v1/assignments/$id';
  static String submitAssignment(String id) => '/api/v1/assignments/$id/submit';
  static String assignmentSubmissions(String id) => '/api/v1/assignments/$id/submissions';
  static String gradeSubmission(String submissionId) => '/api/v1/submissions/$submissionId/grade';

  // Reviews
  static String courseReviews(String courseId) => '/api/v1/courses/$courseId/reviews';
  static String reviewById(String id) => '/api/v1/reviews/$id';

  // Notifications
  static const String notifications = '/api/v1/notifications';
  static const String unreadNotificationsCount = '/api/v1/notifications/unread-count';
  static const String markAllNotificationsRead = '/api/v1/notifications/mark-all-read';
  static String markNotificationRead(String id) => '/api/v1/notifications/$id/read';
  static String deleteNotification(String id) => '/api/v1/notifications/$id';

  // Admin User Management
  static const String adminUsers = '/api/v1/users';
  static String adminUserStatus(String id) => '/api/v1/users/$id/status';
}
