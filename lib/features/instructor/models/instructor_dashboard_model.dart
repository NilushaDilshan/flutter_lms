class InstructorDashboardModel {
  final int totalCourses;
  final int publishedCourses;
  final int draftCourses;
  final int archivedCourses;
  final int totalEnrollments;
  final int pendingSubmissions;
  final double averageCourseRating;

  InstructorDashboardModel({
    this.totalCourses = 0,
    this.publishedCourses = 0,
    this.draftCourses = 0,
    this.archivedCourses = 0,
    this.totalEnrollments = 0,
    this.pendingSubmissions = 0,
    this.averageCourseRating = 0.0,
  });

  factory InstructorDashboardModel.fromJson(Map<String, dynamic> json) {
    final effectiveJson = (json['dashboard'] is Map)
        ? Map<String, dynamic>.from(json['dashboard'] as Map)
        : json;

    return InstructorDashboardModel(
      totalCourses: (effectiveJson['totalCourses'] as num?)?.toInt() ?? 0,
      publishedCourses: (effectiveJson['publishedCourses'] as num?)?.toInt() ?? 0,
      draftCourses: (effectiveJson['draftCourses'] as num?)?.toInt() ?? 0,
      archivedCourses: (effectiveJson['archivedCourses'] as num?)?.toInt() ?? 0,
      totalEnrollments: (effectiveJson['totalEnrollments'] as num?)?.toInt() ?? 0,
      pendingSubmissions: (effectiveJson['pendingSubmissions'] as num?)?.toInt() ?? 0,
      averageCourseRating: (effectiveJson['averageCourseRating'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalCourses': totalCourses,
      'publishedCourses': publishedCourses,
      'draftCourses': draftCourses,
      'archivedCourses': archivedCourses,
      'totalEnrollments': totalEnrollments,
      'pendingSubmissions': pendingSubmissions,
      'averageCourseRating': averageCourseRating,
    };
  }
}
