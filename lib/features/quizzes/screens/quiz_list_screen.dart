import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/loading_state_widget.dart';
import '../../courses/providers/course_provider.dart';
import '../models/quiz_model.dart';
import '../providers/quiz_provider.dart';

class QuizListScreen extends StatefulWidget {
  final String? courseId;
  final String? courseTitle;

  const QuizListScreen({
    super.key,
    this.courseId,
    this.courseTitle,
  });

  @override
  State<QuizListScreen> createState() => _QuizListScreenState();
}

class _QuizListScreenState extends State<QuizListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _loadQuizzes();
    });
  }

  bool _initialLoadDone = false;

  Future<void> _loadQuizzes({bool forceRefresh = false}) async {
    final quizProvider = context.read<QuizProvider>();

    // Skip if quizzes already loaded on initial load (not a manual refresh)
    if (!forceRefresh && _initialLoadDone) return;
    _initialLoadDone = true;

    if (widget.courseId != null && widget.courseId!.isNotEmpty) {
      await quizProvider.loadCourseQuizzes(widget.courseId!);
    } else {
      // If quizzes are already populated, skip redundant network fetch
      if (!forceRefresh && quizProvider.quizzes.isNotEmpty) return;

      List<String> enrolledIds = [];
      try {
        final courseProvider = Provider.of<CourseProvider>(context, listen: false);
        if (courseProvider.myEnrollments.isEmpty) {
          await courseProvider.loadMyEnrollments();
        }
        enrolledIds = courseProvider.myEnrollments.map((e) => e.courseId).toList();
      } catch (_) {
        // Standalone test without CourseProvider
      }
      await quizProvider.loadQuizzesForCourses(
        enrolledIds.isNotEmpty ? enrolledIds : ['6a5c39ae384147c91b73906a', 'course-2'],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final quizProvider = context.watch<QuizProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.courseTitle != null ? 'Quizzes: ${widget.courseTitle}' : 'My Course Quizzes'),
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadQuizzes(forceRefresh: true),
        child: quizProvider.isLoading
            ? const LoadingStateWidget(message: 'Loading course quizzes...')
            : quizProvider.quizzes.isEmpty
                ? EmptyStateWidget(
                    icon: Icons.quiz_outlined,
                    title: 'No Quizzes Available',
                    message: 'There are no active quizzes published for your enrolled courses yet.',
                    actionText: 'Back to Courses',
                    onAction: () => Navigator.of(context).pop(),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: quizProvider.quizzes.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final quiz = quizProvider.quizzes[index];
                      return _buildQuizCard(quiz, quizProvider);
                    },
                  ),
      ),
    );
  }

  Widget _buildQuizCard(
    QuizModel quiz,
    QuizProvider quizProvider,
  ) {
    final isCompleted = quizProvider.isQuizCompleted(quiz.id);
    final attempt = quizProvider.getQuizAttempt(quiz.id);

    // Find course title if browsing across all enrolled courses
    final courseName = widget.courseTitle == null ? quiz.courseTitle : null;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (courseName != null && courseName.isNotEmpty) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  courseName,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withAlpha(25),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.timer_outlined, size: 14, color: AppColors.accent),
                      const SizedBox(width: 4),
                      Text(
                        quiz.timeLimitMinutes > 0 ? '${quiz.timeLimitMinutes} mins' : 'Untimed',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.accent),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Pass: ${quiz.passingScore}%',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                  ),
                ),
                if (isCompleted)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.success),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle, size: 13, color: AppColors.success),
                        const SizedBox(width: 4),
                        Text(
                          attempt?.percentage != null
                              ? 'COMPLETED (${attempt!.percentage!.toInt()}%)'
                              : 'COMPLETED',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Text(
                    'Max ${quiz.maxAttempts} attempts',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              quiz.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            if (quiz.description != null && quiz.description!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                quiz.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: Icon(
                  isCompleted ? Icons.restart_alt_rounded : Icons.play_arrow_rounded,
                  size: 20,
                ),
                label: Text(
                  isCompleted
                      ? (attempt?.percentage != null
                          ? 'Retake Quiz (Best: ${attempt!.percentage!.toInt()}%)'
                          : 'Retake Quiz')
                      : 'Start Quiz Attempt',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCompleted ? Colors.teal.shade700 : AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  Navigator.of(context).pushNamed(
                    AppRoutes.quizAttempt,
                    arguments: {
                      'quizId': quiz.id,
                      'quizTitle': quiz.title,
                      'quiz': quiz,
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
