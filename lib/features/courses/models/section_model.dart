import 'lesson_model.dart';

class SectionModel {
  final String id;
  final String courseId;
  final String title;
  final String? description;
  final int order;
  final bool isPublished;
  final List<LessonModel> lessons;

  SectionModel({
    required this.id,
    required this.courseId,
    required this.title,
    this.description,
    this.order = 1,
    this.isPublished = true,
    this.lessons = const [],
  });

  SectionModel copyWith({
    String? title,
    String? description,
    List<LessonModel>? lessons,
  }) {
    return SectionModel(
      id: id,
      courseId: courseId,
      title: title ?? this.title,
      description: description ?? this.description,
      order: order,
      isPublished: isPublished,
      lessons: lessons ?? this.lessons,
    );
  }

  factory SectionModel.fromJson(Map<String, dynamic> json) {
    List<LessonModel> lessonsList = [];
    if (json['lessons'] is List) {
      lessonsList = (json['lessons'] as List)
          .whereType<Map<String, dynamic>>()
          .map((l) => LessonModel.fromJson(l))
          .toList();
    }

    return SectionModel(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      courseId: json['courseId'] as String? ?? '',
      title: json['title'] as String? ?? 'Untitled Section',
      description: json['description'] as String?,
      order: (json['order'] as num?)?.toInt() ?? 1,
      isPublished: json['isPublished'] as bool? ?? true,
      lessons: lessonsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'courseId': courseId,
      'title': title,
      'description': description,
      'order': order,
      'isPublished': isPublished,
      'lessons': lessons.map((l) => l.toJson()).toList(),
    };
  }
}
