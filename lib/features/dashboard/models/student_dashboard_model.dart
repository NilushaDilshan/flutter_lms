class StudentRecentQuiz {
  final String id;
  final String quizTitle;
  final num score;
  final bool passed;
  final DateTime? submittedAt;

  const StudentRecentQuiz({
    required this.id,
    required this.quizTitle,
    required this.score,
    required this.passed,
    this.submittedAt,
  });

  factory StudentRecentQuiz.fromJson(Map<String, dynamic> json) {
    String title = 'Quiz';
    if (json['quizId'] is Map) {
      title = (json['quizId']['title'] ?? 'Quiz').toString();
    } else if (json['quizTitle'] != null) {
      title = json['quizTitle'].toString();
    }
    return StudentRecentQuiz(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      quizTitle: title,
      score: (json['score'] as num?) ?? 0,
      passed: json['passed'] == true,
      submittedAt: json['submittedAt'] != null
          ? DateTime.tryParse(json['submittedAt'].toString())
          : null,
    );
  }
}

class StudentRecentEnrollment {
  final String id;
  final String courseId;
  final String courseTitle;
  final String? thumbnailUrl;
  final int progressPercentage;
  final DateTime? enrolledAt;
  final DateTime? lastAccessedAt;

  const StudentRecentEnrollment({
    required this.id,
    required this.courseId,
    required this.courseTitle,
    this.thumbnailUrl,
    required this.progressPercentage,
    this.enrolledAt,
    this.lastAccessedAt,
  });

  factory StudentRecentEnrollment.fromJson(Map<String, dynamic> json) {
    String cId = '';
    String cTitle = 'Course';
    String? thumb;
    if (json['courseId'] is Map) {
      final cMap = Map<String, dynamic>.from(json['courseId'] as Map);
      cId = cMap['id']?.toString() ?? cMap['_id']?.toString() ?? '';
      cTitle = cMap['title']?.toString() ?? 'Course';
      thumb = cMap['thumbnailUrl']?.toString();
    } else {
      cId = json['courseId']?.toString() ?? '';
    }

    return StudentRecentEnrollment(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      courseId: cId,
      courseTitle: cTitle,
      thumbnailUrl: thumb,
      progressPercentage: (json['progressPercentage'] as num?)?.toInt() ?? 0,
      enrolledAt: json['enrolledAt'] != null
          ? DateTime.tryParse(json['enrolledAt'].toString())
          : null,
      lastAccessedAt: json['lastAccessedAt'] != null
          ? DateTime.tryParse(json['lastAccessedAt'].toString())
          : null,
    );
  }
}

class StudentDashboardModel {
  final int totalEnrollments;
  final int activeCourses;
  final int completedCourses;
  final int pendingAssignments;
  final List<StudentRecentEnrollment> recentEnrollments;
  final List<StudentRecentQuiz> recentQuizResults;

  const StudentDashboardModel({
    this.totalEnrollments = 0,
    this.activeCourses = 0,
    this.completedCourses = 0,
    this.pendingAssignments = 0,
    this.recentEnrollments = const [],
    this.recentQuizResults = const [],
  });

  factory StudentDashboardModel.fromJson(Map<String, dynamic> json) {
    final effectiveJson = (json['dashboard'] is Map)
        ? Map<String, dynamic>.from(json['dashboard'] as Map)
        : json;

    List<StudentRecentEnrollment> enrollments = [];
    if (effectiveJson['recentEnrollments'] is List) {
      enrollments = (effectiveJson['recentEnrollments'] as List)
          .whereType<Map>()
          .map((e) => StudentRecentEnrollment.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    List<StudentRecentQuiz> quizzes = [];
    if (effectiveJson['recentQuizResults'] is List) {
      quizzes = (effectiveJson['recentQuizResults'] as List)
          .whereType<Map>()
          .map((q) => StudentRecentQuiz.fromJson(Map<String, dynamic>.from(q)))
          .toList();
    }

    return StudentDashboardModel(
      totalEnrollments: (effectiveJson['totalEnrollments'] as num?)?.toInt() ?? 0,
      activeCourses: (effectiveJson['activeCourses'] as num?)?.toInt() ?? 0,
      completedCourses: (effectiveJson['completedCourses'] as num?)?.toInt() ?? 0,
      pendingAssignments: (effectiveJson['pendingAssignments'] as num?)?.toInt() ?? 0,
      recentEnrollments: enrollments,
      recentQuizResults: quizzes,
    );
  }
}
