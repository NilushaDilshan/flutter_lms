import 'course_model.dart';

class EnrollmentModel {
  final String id;
  final String studentId;
  final String courseId;
  final CourseModel? course;
  final String status; // ACTIVE, COMPLETED, CANCELLED
  final int progressPercentage;
  final DateTime? enrolledAt;
  final DateTime? lastAccessedAt;

  EnrollmentModel({
    required this.id,
    required this.studentId,
    required this.courseId,
    this.course,
    this.status = 'ACTIVE',
    this.progressPercentage = 0,
    this.enrolledAt,
    this.lastAccessedAt,
  });

  bool get isActive => status.toUpperCase() == 'ACTIVE';
  bool get isCompleted => status.toUpperCase() == 'COMPLETED';

  factory EnrollmentModel.fromJson(Map<String, dynamic> json) {
    CourseModel? courseObj;
    String cId = '';

    if (json['courseId'] is Map<String, dynamic>) {
      courseObj = CourseModel.fromJson(json['courseId'] as Map<String, dynamic>);
      cId = courseObj.id;
    } else {
      cId = json['courseId']?.toString() ?? '';
    }

    DateTime? enrolled;
    if (json['enrolledAt'] != null) {
      enrolled = DateTime.tryParse(json['enrolledAt'].toString());
    }

    DateTime? lastAccessed;
    if (json['lastAccessedAt'] != null) {
      lastAccessed = DateTime.tryParse(json['lastAccessedAt'].toString());
    }

    return EnrollmentModel(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      studentId: json['studentId']?.toString() ?? '',
      courseId: cId,
      course: courseObj,
      status: json['status'] as String? ?? 'ACTIVE',
      progressPercentage: (json['progressPercentage'] as num?)?.toInt() ?? 0,
      enrolledAt: enrolled,
      lastAccessedAt: lastAccessed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentId': studentId,
      'courseId': courseId,
      'status': status,
      'progressPercentage': progressPercentage,
      'enrolledAt': enrolledAt?.toIso8601String(),
      'lastAccessedAt': lastAccessedAt?.toIso8601String(),
    };
  }
}
