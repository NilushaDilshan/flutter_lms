class InstructorProfileModel {
  final String id;
  final String userId;
  final String headline;
  final String qualification;
  final int experienceYears;
  final List<String> expertise;
  final String biography;

  InstructorProfileModel({
    required this.id,
    required this.userId,
    required this.headline,
    required this.qualification,
    required this.experienceYears,
    this.expertise = const [],
    required this.biography,
  });

  factory InstructorProfileModel.fromJson(Map<String, dynamic> json) {
    return InstructorProfileModel(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      headline: json['headline'] as String? ?? '',
      qualification: json['qualification'] as String? ?? '',
      experienceYears: json['experienceYears'] as int? ?? 0,
      expertise: (json['expertise'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      biography: json['biography'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'headline': headline,
      'qualification': qualification,
      'experienceYears': experienceYears,
      'expertise': expertise,
      'biography': biography,
    };
  }
}
