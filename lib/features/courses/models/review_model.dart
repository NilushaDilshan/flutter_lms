class ReviewModel {
  final String id;
  final String courseId;
  final String studentId;
  final String studentName;
  final int rating;
  final String comment;
  final DateTime createdAt;

  ReviewModel({
    required this.id,
    required this.courseId,
    required this.studentId,
    required this.studentName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    String name = 'Student';
    if (json['studentId'] is Map) {
      final user = json['studentId'] as Map<String, dynamic>;
      final first = user['firstName'] ?? '';
      final last = user['lastName'] ?? '';
      name = '$first $last'.trim();
      if (name.isEmpty) name = user['fullName'] ?? 'Student';
    } else if (json['studentName'] != null) {
      name = json['studentName'] as String;
    }

    return ReviewModel(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      courseId: json['courseId'] as String? ?? '',
      studentId: json['studentId'] is Map
          ? (json['studentId']['id'] ?? json['studentId']['_id'] ?? '')
          : (json['studentId'] as String? ?? ''),
      studentName: name.isNotEmpty ? name : 'Student',
      rating: (json['rating'] as num?)?.toInt() ?? 5,
      comment: json['comment'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
