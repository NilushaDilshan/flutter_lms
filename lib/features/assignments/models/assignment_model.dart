class AssignmentModel {
  final String id;
  final String courseId;
  final String? courseTitle;
  final String? sectionId;
  final String title;
  final String description;
  final DateTime? dueDate;
  final int maxMarks;
  final String? attachmentUrl;
  final String? attachmentName;
  final bool isPublished;

  AssignmentModel({
    required this.id,
    required this.courseId,
    this.courseTitle,
    this.sectionId,
    required this.title,
    required this.description,
    this.dueDate,
    this.maxMarks = 100,
    this.attachmentUrl,
    this.attachmentName,
    this.isPublished = true,
  });

  factory AssignmentModel.fromJson(Map<String, dynamic> json) {
    return AssignmentModel(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      courseId: json['courseId'] as String? ?? '',
      courseTitle: json['courseTitle']?.toString() ??
          (json['course'] is Map ? json['course']['title']?.toString() : null),
      sectionId: json['sectionId'] as String?,
      title: json['title'] as String? ?? 'Untitled Assignment',
      description: json['description'] as String? ?? '',
      dueDate: json['dueDate'] != null ? DateTime.tryParse(json['dueDate'].toString()) : null,
      maxMarks: (json['maxMarks'] as num?)?.toInt() ?? 100,
      attachmentUrl: json['attachmentUrl'] as String?,
      attachmentName: json['attachmentName'] as String?,
      isPublished: (json['isPublished'] as bool?) ?? true,
    );
  }
}

class AssignmentSubmissionModel {
  final String id;
  final String assignmentId;
  final String studentId;
  final String? studentName;
  final String? studentEmail;
  final String? studentProfileImageUrl;
  final String? textAnswer;
  final String? fileUrl;
  final String? fileName;
  final String status; // SUBMITTED, PENDING_REVIEW, RESUBMISSION_REQUIRED, GRADED
  final int? marksAwarded;
  final String? feedback;
  final DateTime submittedAt;
  final DateTime? gradedAt;

  AssignmentSubmissionModel({
    required this.id,
    required this.assignmentId,
    required this.studentId,
    this.studentName,
    this.studentEmail,
    this.studentProfileImageUrl,
    this.textAnswer,
    this.fileUrl,
    this.fileName,
    required this.status,
    this.marksAwarded,
    this.feedback,
    required this.submittedAt,
    this.gradedAt,
  });

  bool get isGraded => status.toUpperCase() == 'GRADED';
  bool get isResubmissionRequired => status.toUpperCase() == 'RESUBMISSION_REQUIRED';
  bool get isSubmitted => status.toUpperCase() == 'SUBMITTED' || status.toUpperCase() == 'PENDING_REVIEW';
  bool get canEdit => !isGraded;

  factory AssignmentSubmissionModel.fromJson(Map<String, dynamic> json) {
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

    return AssignmentSubmissionModel(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      assignmentId: json['assignmentId'] as String? ?? '',
      studentId: sId,
      studentName: sName,
      studentEmail: sEmail,
      studentProfileImageUrl: sAvatar,
      textAnswer: json['textAnswer'] as String?,
      fileUrl: json['fileUrl'] as String?,
      fileName: json['fileName'] as String?,
      status: (json['status'] as String? ?? 'SUBMITTED').toUpperCase(),
      marksAwarded: (json['marksAwarded'] as num?)?.toInt(),
      feedback: json['feedback'] as String?,
      submittedAt: json['submittedAt'] != null
          ? DateTime.tryParse(json['submittedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      gradedAt: json['gradedAt'] != null ? DateTime.tryParse(json['gradedAt'].toString()) : null,
    );
  }
}
