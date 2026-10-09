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
  static const String verifyResetOtp = '/api/v1/auth/verify-password-reset-otp';
  static const String resetPassword = '/api/v1/auth/reset-password';

  // User Profile & Account
  static const String currentUser = '/api/v1/users/me';
  static const String fullProfile = '/api/v1/users/me/full-profile';
  static const String changePassword = '/api/v1/users/me/change-password';
  static const String deactivateAccount = '/api/v1/users/me/deactivate';
  static const String profileImage = '/api/v1/users/me/profile-image';
  static const String studentProfile = '/api/v1/profiles/student/me';
  static const String instructorProfile = '/api/v1/profiles/instructor/me';

  // Course Categories
  static const String categories = '/api/v1/categories';
  static String categoryById(String id) => '/api/v1/categories/$id';
  static String toggleCategoryStatus(String id) => '/api/v1/categories/$id/status';

  // Instructor Dashboard
  static const String instructorDashboard = '/api/v1/dashboard/instructor';

  // Courses
  static const String publishedCourses = '/api/v1/courses';
  static const String instructorCourses = '/api/v1/courses/instructor/me';
  static const String createCourse = '/api/v1/courses';
  static const String adminCourses = '/api/v1/courses/admin/all';
  static String courseById(String id) => '/api/v1/courses/$id';
  static String instructorCourseById(String id) => '/api/v1/courses/instructor/me/$id';
  static String courseThumbnail(String id) => '/api/v1/courses/$id/thumbnail';
  static String publishCourse(String id) => '/api/v1/courses/$id/publish';
  static String archiveCourse(String id) => '/api/v1/courses/$id/archive';

  // Sections & Lessons
  static String courseSections(String courseId) => '/api/v1/courses/$courseId/sections';
  static String createCourseSection(String courseId) => '/api/v1/courses/$courseId/sections';
  static String sectionById(String id) => '/api/v1/sections/$id';
  static String reorderSection(String id) => '/api/v1/sections/$id/reorder';
  static String sectionLessons(String sectionId) => '/api/v1/sections/$sectionId/lessons';
  static String createSectionLesson(String sectionId) => '/api/v1/sections/$sectionId/lessons';
  static String lessonById(String id) => '/api/v1/lessons/$id';
  static String reorderLesson(String id) => '/api/v1/lessons/$id/reorder';
  static String uploadLessonVideo(String id) => '/api/v1/lessons/$id/video';
  static String uploadLessonDocument(String id) => '/api/v1/lessons/$id/document';
  static String lessonMedia(String id) => '/api/v1/lessons/$id/media';
  static String startLesson(String id) => '/api/v1/lessons/$id/start';
  static String completeLesson(String id) => '/api/v1/lessons/$id/complete';

  // Enrollments & Progress
  static const String myEnrollments = '/api/v1/enrollments/me';
  static String enrollCourse(String courseId) => '/api/v1/courses/$courseId/enroll';
  static String courseProgress(String courseId) => '/api/v1/courses/$courseId/progress/me';
  static String courseEnrollments(String courseId) => '/api/v1/courses/$courseId/enrollments';

  // Quizzes & Attempts
  static String courseQuizzes(String courseId) => '/api/v1/courses/$courseId/quizzes';
  static String createCourseQuiz(String courseId) => '/api/v1/courses/$courseId/quizzes';
  static String instructorCourseQuizzes(String courseId) => '/api/v1/courses/$courseId/quizzes/instructor';
  static String sectionQuizzes(String sectionId) => '/api/v1/sections/$sectionId/quizzes';
  static String quizById(String id) => '/api/v1/quizzes/$id';
  static String instructorQuizById(String id) => '/api/v1/quizzes/$id/instructor';
  static String addQuizQuestion(String quizId) => '/api/v1/quizzes/$quizId/questions';
  static String quizQuestionById(String id) => '/api/v1/quiz-questions/$id';
  static String publishQuiz(String id) => '/api/v1/quizzes/$id/publish';
  static String startQuiz(String id) => '/api/v1/quizzes/$id/start';
  static String submitQuizAttempt(String attemptId) => '/api/v1/quiz-attempts/$attemptId/submit';
  static String myQuizAttempts(String quizId) => '/api/v1/quizzes/$quizId/attempts/me';
  static String instructorQuizAttempts(String quizId) => '/api/v1/quizzes/$quizId/attempts/instructor';

  // Assignments & Submissions
  static String courseAssignments(String courseId) => '/api/v1/courses/$courseId/assignments';
  static String createCourseAssignment(String courseId) => '/api/v1/courses/$courseId/assignments';
  static String instructorCourseAssignments(String courseId) => '/api/v1/courses/$courseId/assignments/instructor';
  static String sectionAssignments(String sectionId) => '/api/v1/sections/$sectionId/assignments';
  static String assignmentById(String id) => '/api/v1/assignments/$id';
  static String publishAssignment(String id) => '/api/v1/assignments/$id/publish';
  static String uploadAssignmentAttachment(String id) => '/api/v1/assignments/$id/attachment';
  static String myAssignmentSubmission(String assignmentId) => '/api/v1/assignments/$assignmentId/submission/me';
  static String submitAssignment(String assignmentId) => '/api/v1/assignments/$assignmentId/submissions';
  static String patchMySubmission(String submissionId) => '/api/v1/submissions/$submissionId';
  static String assignmentSubmissions(String id) => '/api/v1/assignments/$id/submissions';
  static String gradeSubmission(String submissionId) => '/api/v1/submissions/$submissionId/grade';

  // Reviews
  static String courseReviews(String courseId) => '/api/v1/courses/$courseId/reviews';
  static String reviewById(String id) => '/api/v1/reviews/$id';
  static String reviewVisibility(String id) => '/api/v1/reviews/$id/visibility';

  // Enrollments & Progress Additions
  static String cancelEnrollment(String enrollmentId) => '/api/v1/enrollments/$enrollmentId/cancel';
  static String enrollmentById(String id) => '/api/v1/enrollments/$id';
  static String enrollmentProgress(String id) => '/api/v1/enrollments/$id/progress';

  // Submission Additions
  static String replaceSubmissionFile(String submissionId) => '/api/v1/submissions/$submissionId/file';

  // Deletion Endpoints for Media, Quizzes & Assignments
  static String deleteCourseThumbnail(String id) => '/api/v1/courses/$id/thumbnail';
  static String deleteLessonVideo(String id) => '/api/v1/lessons/$id/video';
  static String deleteLessonDocument(String id) => '/api/v1/lessons/$id/document';
  static String deleteAssignmentAttachment(String id) => '/api/v1/assignments/$id/attachment';
  static String deleteAssignment(String id) => '/api/v1/assignments/$id';
  static String deleteQuiz(String id) => '/api/v1/quizzes/$id';
  static String deleteQuizQuestion(String id) => '/api/v1/quiz-questions/$id';
  static String deleteReview(String id) => '/api/v1/reviews/$id';

  // Dashboards
  static const String studentDashboard = '/api/v1/dashboard/student';

  // Notifications
  static const String myNotifications = '/api/v1/notifications/me';
  static const String unreadNotificationsCount = '/api/v1/notifications/me/unread-count';
  static const String markAllNotificationsRead = '/api/v1/notifications/me/read-all';
  static String markNotificationRead(String id) => '/api/v1/notifications/$id/read';
  static String deleteNotification(String id) => '/api/v1/notifications/$id';

  // Admin LMS Management
  static const String adminDashboard = '/api/v1/dashboard/admin';
  static const String adminUsers = '/api/v1/users';
  static String adminUserById(String id) => '/api/v1/users/$id';
  static String adminUserStatus(String id) => '/api/v1/users/$id/status';
  static const String adminEnrollments = '/api/v1/enrollments/admin/all';
  static String adminArchiveCourse(String id) => '/api/v1/courses/$id/admin/archive';
  static String adminReviewVisibility(String id) => '/api/v1/reviews/$id/visibility';
}
