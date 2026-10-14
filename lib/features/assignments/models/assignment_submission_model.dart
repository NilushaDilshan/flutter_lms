/// Represents a student's submission for an assignment.
/// Used by InstructorProvider (to list/grade submissions) and
/// AssignmentProvider (to track the current student's own submission).
class AssignmentSubmissionModel {
  final String id;
  final String assignmentId;
  final String studentId;
  final String? studentName;
  final String? studentEmail;
  final String? textAnswer;
  final String? fileUrl;
  final String? fileName;
  final String status; // SUBMITTED | GRADED | RESUBMISSION_REQUIRED
  final int? marksAwarded;
  final String? feedback;
  final DateTime submittedAt;
  final DateTime? gradedAt;

  const AssignmentSubmissionModel({
    required this.id,
    required this.assignmentId,
    required this.studentId,
    this.studentName,
    this.studentEmail,
    this.textAnswer,
    this.fileUrl,
    this.fileName,
    this.status = 'SUBMITTED',
    this.marksAwarded,
    this.feedback,
    required this.submittedAt,
    this.gradedAt,
  });

  bool get isGraded => status == 'GRADED';
  bool get isResubmissionRequired => status == 'RESUBMISSION_REQUIRED';
  /// Student can still edit if not graded (submitted or resubmission required)
  bool get canEdit => !isGraded;


  factory AssignmentSubmissionModel.fromJson(Map<String, dynamic> json) {
    String readString(List<String> keys, {String fallback = ''}) {
      for (final key in keys) {
        final value = json[key];
        if (value != null && value.toString().trim().isNotEmpty) {
          return value.toString();
        }
      }
      return fallback;
    }

    // Support nested student object — backend may return studentId as a full user document
    final rawStudentId = json['studentId'] ?? json['student_id'];
    final studentObj = rawStudentId is Map
        ? rawStudentId
        : (json['student'] is Map ? json['student'] : null);

    final String studentId = rawStudentId is String && rawStudentId.isNotEmpty
        ? rawStudentId
        : studentObj != null
            ? (studentObj['id'] ?? studentObj['_id'] ?? '').toString()
            : readString(['studentId', 'student_id']);


    final String? studentName = (() {
      final n = readString(['studentName', 'student_name']);
      if (n.isNotEmpty) return n;
      if (studentObj is Map) {
        final first = studentObj['firstName'] ?? studentObj['first_name'] ?? '';
        final last = studentObj['lastName'] ?? studentObj['last_name'] ?? '';
        if (first.toString().isNotEmpty) return '$first $last'.trim();
      }
      return null;
    })();

    final String? studentEmail = (() {
      final e = readString(['studentEmail', 'student_email', 'email']);
      if (e.isNotEmpty) return e;
      if (studentObj is Map) {
        final em = studentObj['email'];
        if (em != null) return em.toString();
      }
      return null;
    })();

    final rawSubmittedAt = readString(['submittedAt', 'submitted_at', 'createdAt', 'created_at']);
    final submittedAt = rawSubmittedAt.isNotEmpty
        ? DateTime.tryParse(rawSubmittedAt) ?? DateTime.now()
        : DateTime.now();

    final rawGradedAt = readString(['gradedAt', 'graded_at']);
    final gradedAt = rawGradedAt.isNotEmpty ? DateTime.tryParse(rawGradedAt) : null;

    final marksRaw = json['marksAwarded'] ?? json['marks_awarded'];
    final int? marks = marksRaw is num
        ? marksRaw.toInt()
        : marksRaw != null
            ? int.tryParse(marksRaw.toString())
            : null;

    return AssignmentSubmissionModel(
      id: readString(['id', '_id', 'submissionId', 'submission_id']),
      assignmentId: readString(['assignmentId', 'assignment_id']),
      studentId: studentId,
      studentName: studentName,
      studentEmail: studentEmail,
      textAnswer: readString(['textAnswer', 'text_answer']).isEmpty
          ? null
          : readString(['textAnswer', 'text_answer']),
      fileUrl: readString(['fileUrl', 'file_url']).isEmpty
          ? null
          : readString(['fileUrl', 'file_url']),
      fileName: readString(['fileName', 'file_name']).isEmpty
          ? null
          : readString(['fileName', 'file_name']),
      status: readString(['status'], fallback: 'SUBMITTED'),
      marksAwarded: marks,
      feedback: readString(['feedback']).isEmpty ? null : readString(['feedback']),
      submittedAt: submittedAt,
      gradedAt: gradedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'assignmentId': assignmentId,
      'studentId': studentId,
      'studentName': studentName,
      'studentEmail': studentEmail,
      'textAnswer': textAnswer,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'status': status,
      'marksAwarded': marksAwarded,
      'feedback': feedback,
      'submittedAt': submittedAt.toIso8601String(),
      'gradedAt': gradedAt?.toIso8601String(),
    };
  }
}
