class AdminDashboardModel {
  final int totalStudents;
  final int totalInstructors;
  final int activeUsers;
  final int totalUsers;
  final int publishedCourses;
  final int totalCourses;
  final int totalEnrollments;
  final int completedEnrollments;
  final int totalCategories;
  final int pendingReviews;

  AdminDashboardModel({
    this.totalStudents = 0,
    this.totalInstructors = 0,
    this.activeUsers = 0,
    this.totalUsers = 0,
    this.publishedCourses = 0,
    this.totalCourses = 0,
    this.totalEnrollments = 0,
    this.completedEnrollments = 0,
    this.totalCategories = 0,
    this.pendingReviews = 0,
  });

  factory AdminDashboardModel.fromJson(Map<String, dynamic> json) {
    final effectiveJson = (json['dashboard'] is Map)
        ? Map<String, dynamic>.from(json['dashboard'] as Map)
        : json;

    final students = (effectiveJson['totalStudents'] as num?)?.toInt() ?? 0;
    final instructors = (effectiveJson['totalInstructors'] as num?)?.toInt() ?? 0;
    final users = (effectiveJson['totalUsers'] as num?)?.toInt() ?? (students + instructors);
    final pubCourses = (effectiveJson['publishedCourses'] as num?)?.toInt() ?? 0;
    final allCourses = (effectiveJson['totalCourses'] as num?)?.toInt() ?? pubCourses;

    return AdminDashboardModel(
      totalStudents: students,
      totalInstructors: instructors,
      activeUsers: (effectiveJson['activeUsers'] as num?)?.toInt() ?? users,
      totalUsers: users,
      publishedCourses: pubCourses,
      totalCourses: allCourses,
      totalEnrollments: (effectiveJson['totalEnrollments'] as num?)?.toInt() ?? 0,
      completedEnrollments: (effectiveJson['completedEnrollments'] as num?)?.toInt() ?? 0,
      totalCategories: (effectiveJson['totalCategories'] as num?)?.toInt() ?? 0,
      pendingReviews: (effectiveJson['pendingReviews'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalStudents': totalStudents,
      'totalInstructors': totalInstructors,
      'activeUsers': activeUsers,
      'totalUsers': totalUsers,
      'publishedCourses': publishedCourses,
      'totalCourses': totalCourses,
      'totalEnrollments': totalEnrollments,
      'completedEnrollments': completedEnrollments,
      'totalCategories': totalCategories,
      'pendingReviews': pendingReviews,
    };
  }

  AdminDashboardModel copyWith({
    int? totalStudents,
    int? totalInstructors,
    int? activeUsers,
    int? totalUsers,
    int? publishedCourses,
    int? totalCourses,
    int? totalEnrollments,
    int? completedEnrollments,
    int? totalCategories,
    int? pendingReviews,
  }) {
    return AdminDashboardModel(
      totalStudents: totalStudents ?? this.totalStudents,
      totalInstructors: totalInstructors ?? this.totalInstructors,
      activeUsers: activeUsers ?? this.activeUsers,
      totalUsers: totalUsers ?? this.totalUsers,
      publishedCourses: publishedCourses ?? this.publishedCourses,
      totalCourses: totalCourses ?? this.totalCourses,
      totalEnrollments: totalEnrollments ?? this.totalEnrollments,
      completedEnrollments: completedEnrollments ?? this.completedEnrollments,
      totalCategories: totalCategories ?? this.totalCategories,
      pendingReviews: pendingReviews ?? this.pendingReviews,
    );
  }
}
