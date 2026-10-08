class QuizOptionModel {
  final String id;
  final String text;

  QuizOptionModel({
    required this.id,
    required this.text,
  });

  factory QuizOptionModel.fromJson(Map<String, dynamic> json) {
    return QuizOptionModel(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      text: json['text'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
      };
}

class QuizQuestionModel {
  final String id;
  final String quizId;
  final String questionText;
  final String questionType; // SINGLE_CHOICE, MULTIPLE_CHOICE, TRUE_FALSE
  final List<QuizOptionModel> options;
  final int marks;

  QuizQuestionModel({
    required this.id,
    required this.quizId,
    required this.questionText,
    required this.questionType,
    required this.options,
    this.marks = 1,
  });

  bool get isSingleChoice => questionType == 'SINGLE_CHOICE' || questionType == 'TRUE_FALSE';

  factory QuizQuestionModel.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'] as List? ?? [];
    return QuizQuestionModel(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      quizId: json['quizId'] as String? ?? '',
      questionText: json['questionText'] as String? ?? '',
      questionType: json['questionType'] as String? ?? 'SINGLE_CHOICE',
      options: rawOptions.map((e) => QuizOptionModel.fromJson(e as Map<String, dynamic>)).toList(),
      marks: (json['marks'] as num?)?.toInt() ?? 1,
    );
  }
}

class QuizModel {
  final String id;
  final String courseId;
  final String? sectionId;
  final String title;
  final String? description;
  final int passingScore;
  final int timeLimitMinutes;
  final int maxAttempts;
  final bool isPublished;
  final List<QuizQuestionModel> questions;

  QuizModel({
    required this.id,
    required this.courseId,
    this.sectionId,
    required this.title,
    this.description,
    required this.passingScore,
    this.timeLimitMinutes = 0,
    this.maxAttempts = 1,
    this.isPublished = true,
    this.questions = const [],
  });

  factory QuizModel.fromJson(Map<String, dynamic> json) {
    final rawQuestions = json['questions'] as List? ?? [];
    return QuizModel(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      courseId: json['courseId'] as String? ?? '',
      sectionId: json['sectionId'] as String?,
      title: json['title'] as String? ?? 'Untitled Quiz',
      description: json['description'] as String?,
      passingScore: (json['passingScore'] as num?)?.toInt() ?? 70,
      timeLimitMinutes: (json['timeLimitMinutes'] as num?)?.toInt() ?? 0,
      maxAttempts: (json['maxAttempts'] as num?)?.toInt() ?? 1,
      isPublished: (json['isPublished'] as bool?) ?? true,
      questions: rawQuestions.map((q) => QuizQuestionModel.fromJson(q as Map<String, dynamic>)).toList(),
    );
  }

  QuizModel copyWith({
    List<QuizQuestionModel>? questions,
  }) {
    return QuizModel(
      id: id,
      courseId: courseId,
      sectionId: sectionId,
      title: title,
      description: description,
      passingScore: passingScore,
      timeLimitMinutes: timeLimitMinutes,
      maxAttempts: maxAttempts,
      isPublished: isPublished,
      questions: questions ?? this.questions,
    );
  }
}

class QuizAttemptModel {
  final String id;
  final String quizId;
  final String studentId;
  final int? score;
  final int? totalMarks;
  final double? percentage;
  final bool passed;
  final String status; // IN_PROGRESS, SUBMITTED
  final int attemptNumber;
  final DateTime startedAt;
  final DateTime? submittedAt;

  QuizAttemptModel({
    required this.id,
    required this.quizId,
    required this.studentId,
    this.score,
    this.totalMarks,
    this.percentage,
    this.passed = false,
    required this.status,
    required this.attemptNumber,
    required this.startedAt,
    this.submittedAt,
  });

  bool get isSubmitted => status == 'SUBMITTED';

  factory QuizAttemptModel.fromJson(Map<String, dynamic> json) {
    return QuizAttemptModel(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      quizId: json['quizId'] as String? ?? '',
      studentId: json['studentId'] as String? ?? '',
      score: (json['score'] as num?)?.toInt(),
      totalMarks: (json['totalMarks'] as num?)?.toInt(),
      percentage: (json['percentage'] as num?)?.toDouble(),
      passed: json['passed'] as bool? ?? false,
      status: json['status'] as String? ?? 'IN_PROGRESS',
      attemptNumber: (json['attemptNumber'] as num?)?.toInt() ?? 1,
      startedAt: json['startedAt'] != null
          ? DateTime.tryParse(json['startedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      submittedAt: json['submittedAt'] != null
          ? DateTime.tryParse(json['submittedAt'].toString())
          : null,
    );
  }
}
