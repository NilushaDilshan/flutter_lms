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
    final students = (json['totalStudents'] as num?)?.toInt() ?? 0;
    final instructors = (json['totalInstructors'] as num?)?.toInt() ?? 0;
    final users = (json['totalUsers'] as num?)?.toInt() ?? (students + instructors);
    final pubCourses = (json['publishedCourses'] as num?)?.toInt() ?? 0;
    final allCourses = (json['totalCourses'] as num?)?.toInt() ?? pubCourses;

    return AdminDashboardModel(
      totalStudents: students,
      totalInstructors: instructors,
      activeUsers: (json['activeUsers'] as num?)?.toInt() ?? users,
      totalUsers: users,
      publishedCourses: pubCourses,
      totalCourses: allCourses,
      totalEnrollments: (json['totalEnrollments'] as num?)?.toInt() ?? 0,
      completedEnrollments: (json['completedEnrollments'] as num?)?.toInt() ?? 0,
      totalCategories: (json['totalCategories'] as num?)?.toInt() ?? 0,
      pendingReviews: (json['pendingReviews'] as num?)?.toInt() ?? 0,
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
