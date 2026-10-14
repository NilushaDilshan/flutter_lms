class LessonProgressModel {
  final String? id;
  final String lessonId;
  final String status; // NOT_STARTED, IN_PROGRESS, COMPLETED
  final DateTime? startedAt;
  final DateTime? completedAt;

  LessonProgressModel({
    this.id,
    required this.lessonId,
    required this.status,
    this.startedAt,
    this.completedAt,
  });

  bool get isCompleted => status.toUpperCase() == 'COMPLETED';
  bool get isInProgress => status.toUpperCase() == 'IN_PROGRESS';

  factory LessonProgressModel.fromJson(Map<String, dynamic> json) {
    return LessonProgressModel(
      id: json['id']?.toString() ?? json['_id']?.toString(),
      lessonId: json['lessonId']?.toString() ?? '',
      status: json['status']?.toString() ?? 'NOT_STARTED',
      startedAt: json['startedAt'] != null ? DateTime.tryParse(json['startedAt'].toString()) : null,
      completedAt: json['completedAt'] != null ? DateTime.tryParse(json['completedAt'].toString()) : null,
    );
  }
}

class CourseProgressModel {
  final int progressPercentage;
  final int totalLessons;
  final int completedLessons;
  final Map<String, String> lessonStatusMap;

  CourseProgressModel({
    required this.progressPercentage,
    required this.totalLessons,
    required this.completedLessons,
    this.lessonStatusMap = const {},
  });

  bool isLessonCompleted(String lessonId) {
    return lessonStatusMap[lessonId]?.toUpperCase() == 'COMPLETED';
  }

  factory CourseProgressModel.fromJson(Map<String, dynamic> json) {
    int progress = 0;
    int total = 0;
    int completed = 0;
    final Map<String, String> statusMap = {};

    if (json['enrollment'] is Map) {
      final enr = Map<String, dynamic>.from(json['enrollment'] as Map);
      progress = (enr['progressPercentage'] as num?)?.toInt() ?? 0;
    } else if (json['progressPercentage'] is num) {
      progress = (json['progressPercentage'] as num).toInt();
    }

    if (json['lessons'] is List) {
      final list = json['lessons'] as List;
      total = list.length;
      for (final item in list) {
        if (item is Map) {
          final lMap = Map<String, dynamic>.from(item);
          final lId = lMap['id']?.toString() ?? lMap['_id']?.toString() ?? '';
          if (lMap['progress'] is Map) {
            final pMap = Map<String, dynamic>.from(lMap['progress'] as Map);
            final st = pMap['status']?.toString() ?? 'NOT_STARTED';
            statusMap[lId] = st;
            if (st.toUpperCase() == 'COMPLETED') completed++;
          }
        }
      }
    }

    if (json['courseProgress'] is Map) {
      final cp = Map<String, dynamic>.from(json['courseProgress'] as Map);
      progress = (cp['progressPercentage'] as num?)?.toInt() ?? progress;
      total = (cp['totalLessons'] as num?)?.toInt() ?? total;
      completed = (cp['completedLessons'] as num?)?.toInt() ?? completed;
    }

    return CourseProgressModel(
      progressPercentage: progress,
      totalLessons: total,
      completedLessons: completed,
      lessonStatusMap: statusMap,
    );
  }
}
