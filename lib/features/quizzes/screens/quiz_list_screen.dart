import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/loading_state_widget.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuizProvider>().loadCourseQuizzes(widget.courseId ?? '');
    });
  }

  @override
  Widget build(BuildContext context) {
    final quizProvider = context.watch<QuizProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.courseTitle != null ? 'Quizzes: ${widget.courseTitle}' : 'Available Quizzes'),
      ),
      body: RefreshIndicator(
        onRefresh: () => quizProvider.loadCourseQuizzes(widget.courseId ?? ''),
        child: quizProvider.isLoading
            ? const LoadingStateWidget(message: 'Loading available quizzes...')
            : quizProvider.quizzes.isEmpty
                ? EmptyStateWidget(
                    icon: Icons.quiz_outlined,
                    title: 'No Quizzes Available',
                    message: 'There are no active quizzes published for this course yet.',
                    actionText: 'Back to Courses',
                    onAction: () => Navigator.of(context).pop(),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: quizProvider.quizzes.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final quiz = quizProvider.quizzes[index];
                      return _buildQuizCard(quiz);
                    },
                  ),
      ),
    );
  }

  Widget _buildQuizCard(QuizModel quiz) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                const SizedBox(width: 8),
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
                const Spacer(),
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
                icon: const Icon(Icons.play_arrow_rounded, size: 20),
                label: const Text('Start Quiz Attempt', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
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
