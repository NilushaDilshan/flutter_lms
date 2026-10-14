class AssignmentModel {
  final String id;
  final String courseId;
  final String? sectionId;
  final String title;
  final String description;
  final String instructions;
  final DateTime? dueDate;
  final int maximumMarks; // used by assignment_list_screen
  final int maxMarks;     // alias used by instructor_provider
  final String? status;
  final String? attachmentUrl;
  final String? attachmentName;
  final bool isPublished;

  const AssignmentModel({
    required this.id,
    required this.courseId,
    this.sectionId,
    required this.title,
    this.description = '',
    this.instructions = '',
    this.dueDate,
    int? maximumMarks,
    int? maxMarks,
    this.status,
    this.attachmentUrl,
    this.attachmentName,
    this.isPublished = false,
  })  : maximumMarks = maximumMarks ?? maxMarks ?? 100,
        maxMarks = maxMarks ?? maximumMarks ?? 100;

  factory AssignmentModel.fromJson(Map<String, dynamic> json) {
    final dynamic course = json['course'];

    String readString(List<String> keys, {String fallback = ''}) {
      for (final key in keys) {
        final value = json[key];
        if (value != null && value.toString().trim().isNotEmpty) {
          return value.toString();
        }
      }
      return fallback;
    }

    int readInt(List<String> keys, {int fallback = 100}) {
      for (final key in keys) {
        final value = json[key];
        if (value is num) return value.toInt();
        if (value != null) {
          final parsed = int.tryParse(value.toString());
          if (parsed != null) return parsed;
        }
      }
      return fallback;
    }

    final rawDueDate = readString(['dueDate', 'due_date', 'deadline']);
    final parsedDueDate = rawDueDate.isEmpty ? null : DateTime.tryParse(rawDueDate);

    String parsedCourseId = readString(['courseId', 'course_id']);
    if (parsedCourseId.isEmpty && course is Map) {
      parsedCourseId = (course['id'] ?? course['_id'] ?? '').toString();
    }

    final marks = readInt(['maximumMarks', 'maximum_marks', 'maxMarks', 'totalMarks']);

    final attachmentUrlVal = readString(
      ['attachmentUrl', 'attachment_url', 'fileUrl'],
    ).isEmpty
        ? null
        : readString(['attachmentUrl', 'attachment_url', 'fileUrl']);

    return AssignmentModel(
      id: readString(['id', '_id', 'assignmentId', 'assignment_id']),
      courseId: parsedCourseId,
      sectionId: readString(['sectionId', 'section_id']).isEmpty
          ? null
          : readString(['sectionId', 'section_id']),
      title: readString(['title', 'name'], fallback: 'Untitled Assignment'),
      description: readString(['description']),
      instructions: readString(['instructions']),
      dueDate: parsedDueDate,
      maximumMarks: marks,
      maxMarks: marks,
      status: readString(['status', 'state']).isEmpty ? null : readString(['status', 'state']),
      attachmentUrl: attachmentUrlVal,
      attachmentName: readString(['attachmentName', 'attachment_name']).isEmpty
          ? null
          : readString(['attachmentName', 'attachment_name']),
      isPublished: json['isPublished'] == true || json['is_published'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'courseId': courseId,
      if (sectionId != null) 'sectionId': sectionId,
      'title': title,
      'description': description,
      'instructions': instructions,
      'dueDate': dueDate?.toIso8601String(),
      'maximumMarks': maximumMarks,
      'status': status,
      'attachmentUrl': attachmentUrl,
      'attachmentName': attachmentName,
      'isPublished': isPublished,
    };
  }
}