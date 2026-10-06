class StudentProfileModel {
  final String id;
  final String userId;
  final String educationLevel;
  final List<String> learningGoals;

  StudentProfileModel({
    required this.id,
    required this.userId,
    required this.educationLevel,
    this.learningGoals = const [],
  });

  factory StudentProfileModel.fromJson(Map<String, dynamic> json) {
    return StudentProfileModel(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      educationLevel: json['educationLevel'] as String? ?? 'Undergraduate',
      learningGoals: (json['learningGoals'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'educationLevel': educationLevel,
      'learningGoals': learningGoals,
    };
  }
}
