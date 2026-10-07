enum LessonType {
  text,
  video,
  document;

  static LessonType fromString(String type) {
    switch (type.toUpperCase()) {
      case 'VIDEO':
        return LessonType.video;
      case 'DOCUMENT':
        return LessonType.document;
      case 'TEXT':
      default:
        return LessonType.text;
    }
  }

  String toBackendString() {
    switch (this) {
      case LessonType.video:
        return 'VIDEO';
      case LessonType.document:
        return 'DOCUMENT';
      case LessonType.text:
        return 'TEXT';
    }
  }
}

class LessonModel {
  final String id;
  final String courseId;
  final String sectionId;
  final String title;
  final String? description;
  final LessonType lessonType;
  final String? textContent;
  final String? videoUrl;
  final String? documentUrl;
  final String? documentName;
  final int durationMinutes;
  final int order;
  final bool isPreview;
  final bool isPublished;
  final bool isCompleted;

  LessonModel({
    required this.id,
    required this.courseId,
    required this.sectionId,
    required this.title,
    this.description,
    required this.lessonType,
    this.textContent,
    this.videoUrl,
    this.documentUrl,
    this.documentName,
    this.durationMinutes = 0,
    this.order = 1,
    this.isPreview = false,
    this.isPublished = true,
    this.isCompleted = false,
  });

  bool get isVideo => lessonType == LessonType.video;
  bool get isText => lessonType == LessonType.text;
  bool get isDocument => lessonType == LessonType.document;

  LessonModel copyWith({
    String? title,
    String? description,
    bool? isCompleted,
    String? textContent,
    String? videoUrl,
    String? documentUrl,
  }) {
    return LessonModel(
      id: id,
      courseId: courseId,
      sectionId: sectionId,
      title: title ?? this.title,
      description: description ?? this.description,
      lessonType: lessonType,
      textContent: textContent ?? this.textContent,
      videoUrl: videoUrl ?? this.videoUrl,
      documentUrl: documentUrl ?? this.documentUrl,
      documentName: documentName,
      durationMinutes: durationMinutes,
      order: order,
      isPreview: isPreview,
      isPublished: isPublished,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  factory LessonModel.fromJson(Map<String, dynamic> json) {
    return LessonModel(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      courseId: json['courseId'] as String? ?? '',
      sectionId: json['sectionId'] as String? ?? '',
      title: json['title'] as String? ?? 'Untitled Lesson',
      description: json['description'] as String?,
      lessonType: LessonType.fromString(json['lessonType']?.toString() ?? 'TEXT'),
      textContent: json['textContent'] as String?,
      videoUrl: json['videoUrl'] as String?,
      documentUrl: json['documentUrl'] as String?,
      documentName: json['documentName'] as String?,
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 0,
      order: (json['order'] as num?)?.toInt() ?? 1,
      isPreview: json['isPreview'] as bool? ?? false,
      isPublished: json['isPublished'] as bool? ?? true,
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'courseId': courseId,
      'sectionId': sectionId,
      'title': title,
      'description': description,
      'lessonType': lessonType.toBackendString(),
      'textContent': textContent,
      'videoUrl': videoUrl,
      'documentUrl': documentUrl,
      'documentName': documentName,
      'durationMinutes': durationMinutes,
      'order': order,
      'isPreview': isPreview,
      'isPublished': isPublished,
    };
  }
}
