import 'course_model.dart';

class EnrollmentModel {
  final String id;
  final String studentId;
  final String? studentName;
  final String? studentEmail;
  final String? studentProfileImageUrl;
  final String courseId;
  final CourseModel? course;
  final String status; // ACTIVE, COMPLETED, CANCELLED
  final int progressPercentage;
  final DateTime? enrolledAt;
  final DateTime? lastAccessedAt;

  EnrollmentModel({
    required this.id,
    required this.studentId,
    this.studentName,
    this.studentEmail,
    this.studentProfileImageUrl,
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

    String sId = '';
    String? sName;
    String? sEmail;
    String? sAvatar;
    if (json['studentId'] is Map<String, dynamic>) {
      final sMap = json['studentId'] as Map<String, dynamic>;
      sId = sMap['id']?.toString() ?? sMap['_id']?.toString() ?? '';
      final first = sMap['firstName']?.toString() ?? '';
      final last = sMap['lastName']?.toString() ?? '';
      final full = '$first $last'.trim();
      sName = full.isNotEmpty ? full : 'Student';
      sEmail = sMap['email']?.toString();
      sAvatar = sMap['profileImageUrl']?.toString() ?? sMap['profileImage']?.toString();
    } else {
      sId = json['studentId']?.toString() ?? '';
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
      studentId: sId,
      studentName: sName,
      studentEmail: sEmail,
      studentProfileImageUrl: sAvatar,
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

  EnrollmentModel copyWith({
    String? id,
    String? studentId,
    String? courseId,
    CourseModel? course,
    String? status,
    int? progressPercentage,
    DateTime? enrolledAt,
    DateTime? lastAccessedAt,
  }) {
    return EnrollmentModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      courseId: courseId ?? this.courseId,
      course: course ?? this.course,
      status: status ?? this.status,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      enrolledAt: enrolledAt ?? this.enrolledAt,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
    );
  }
}
