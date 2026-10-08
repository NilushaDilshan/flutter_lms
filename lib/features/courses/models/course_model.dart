class CourseInstructor {
  final String id;
  final String fullName;
  final String? profileImageUrl;

  CourseInstructor({
    required this.id,
    required this.fullName,
    this.profileImageUrl,
  });

  factory CourseInstructor.fromJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      final first = json['firstName']?.toString() ?? '';
      final last = json['lastName']?.toString() ?? '';
      final name = '$first $last'.trim();
      return CourseInstructor(
        id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
        fullName: name.isNotEmpty ? name : (json['name']?.toString() ?? 'Instructor'),
        profileImageUrl: json['profileImageUrl']?.toString() ?? json['profileImage']?.toString(),
      );
    }
    return CourseInstructor(
      id: json?.toString() ?? '',
      fullName: 'Instructor',
    );
  }
}

class CourseModel {
  final String id;
  final String title;
  final String slug;
  final String shortDescription;
  final String description;
  final String level; // BEGINNER, INTERMEDIATE, ADVANCED
  final String language;
  final bool isFree;
  final num price;
  final String? thumbnailUrl;
  final double averageRating;
  final int reviewCount;
  final int totalEnrollments;
  final String categoryId;
  final String categoryName;
  final CourseInstructor? instructor;
  final List<String> learningOutcomes;
  final List<String> requirements;
  final String status;

  CourseModel({
    required this.id,
    required this.title,
    required this.slug,
    this.shortDescription = '',
    this.description = '',
    this.level = 'BEGINNER',
    this.language = 'English',
    this.isFree = true,
    this.price = 0,
    this.thumbnailUrl,
    this.averageRating = 0.0,
    this.reviewCount = 0,
    this.totalEnrollments = 0,
    this.categoryId = '',
    this.categoryName = '',
    this.instructor,
    this.learningOutcomes = const [],
    this.requirements = const [],
    this.status = 'PUBLISHED',
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    // Category extraction
    String catId = '';
    String catName = '';
    if (json['categoryId'] is Map<String, dynamic>) {
      catId = json['categoryId']['id']?.toString() ?? json['categoryId']['_id']?.toString() ?? '';
      catName = json['categoryId']['name']?.toString() ?? '';
    } else {
      catId = json['categoryId']?.toString() ?? '';
    }

    // Instructor extraction
    CourseInstructor? instr;
    if (json['instructorId'] != null) {
      instr = CourseInstructor.fromJson(json['instructorId']);
    }

    // Outcomes & Requirements extraction
    List<String> outcomes = [];
    if (json['learningOutcomes'] is List) {
      outcomes = (json['learningOutcomes'] as List).map((e) => e.toString()).toList();
    }

    List<String> reqs = [];
    if (json['requirements'] is List) {
      reqs = (json['requirements'] as List).map((e) => e.toString()).toList();
    }

    final ratingNum = json['averageRating'];
    final double rating = (ratingNum is num) ? ratingNum.toDouble() : 0.0;

    return CourseModel(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      title: json['title'] as String? ?? 'Untitled Course',
      slug: json['slug'] as String? ?? '',
      shortDescription: json['shortDescription'] as String? ?? '',
      description: json['description'] as String? ?? '',
      level: (json['level'] as String? ?? 'BEGINNER').toUpperCase(),
      language: json['language'] as String? ?? 'English',
      isFree: json['isFree'] as bool? ?? true,
      price: json['price'] as num? ?? 0,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      averageRating: rating,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      totalEnrollments: (json['totalEnrollments'] as num?)?.toInt() ?? 0,
      categoryId: catId,
      categoryName: catName,
      instructor: instr,
      learningOutcomes: outcomes,
      requirements: reqs,
      status: json['status'] as String? ?? 'PUBLISHED',
    );
  }

  bool get isDraft => status.toUpperCase() == 'DRAFT';
  bool get isPublished => status.toUpperCase() == 'PUBLISHED';
  bool get isArchived => status.toUpperCase() == 'ARCHIVED';

  CourseModel copyWith({
    String? id,
    String? title,
    String? slug,
    String? shortDescription,
    String? description,
    String? level,
    String? language,
    bool? isFree,
    num? price,
    String? thumbnailUrl,
    double? averageRating,
    int? reviewCount,
    int? totalEnrollments,
    String? categoryId,
    String? categoryName,
    CourseInstructor? instructor,
    List<String>? learningOutcomes,
    List<String>? requirements,
    String? status,
  }) {
    return CourseModel(
      id: id ?? this.id,
      title: title ?? this.title,
      slug: slug ?? this.slug,
      shortDescription: shortDescription ?? this.shortDescription,
      description: description ?? this.description,
      level: level ?? this.level,
      language: language ?? this.language,
      isFree: isFree ?? this.isFree,
      price: price ?? this.price,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      averageRating: averageRating ?? this.averageRating,
      reviewCount: reviewCount ?? this.reviewCount,
      totalEnrollments: totalEnrollments ?? this.totalEnrollments,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      instructor: instructor ?? this.instructor,
      learningOutcomes: learningOutcomes ?? this.learningOutcomes,
      requirements: requirements ?? this.requirements,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'slug': slug,
      'shortDescription': shortDescription,
      'description': description,
      'level': level,
      'language': language,
      'isFree': isFree,
      'price': price,
      'thumbnailUrl': thumbnailUrl,
      'averageRating': averageRating,
      'reviewCount': reviewCount,
      'totalEnrollments': totalEnrollments,
      'categoryId': categoryId,
      'status': status,
    };
  }
}
