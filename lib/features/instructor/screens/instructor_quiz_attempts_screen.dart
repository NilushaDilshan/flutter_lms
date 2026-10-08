import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/loading_state_widget.dart';
import '../../../core/widgets/status_badge.dart';
import '../providers/instructor_provider.dart';

class InstructorQuizAttemptsScreen extends StatefulWidget {
  final String quizId;
  final String? quizTitle;

  const InstructorQuizAttemptsScreen({
    super.key,
    required this.quizId,
    this.quizTitle,
  });

  @override
  State<InstructorQuizAttemptsScreen> createState() => _InstructorQuizAttemptsScreenState();
}

class _InstructorQuizAttemptsScreenState extends State<InstructorQuizAttemptsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InstructorProvider>().loadQuizAttempts(widget.quizId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InstructorProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.quizTitle != null ? 'Quiz Attempts: ${widget.quizTitle}' : 'Student Quiz Attempts'),
      ),
      body: provider.isLoading
          ? const LoadingStateWidget(message: 'Loading student attempts...')
          : provider.quizAttempts.isEmpty
              ? const EmptyStateWidget(
                  icon: Icons.quiz_outlined,
                  title: 'No Quiz Attempts',
                  message: 'No students have attempted this quiz yet.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.quizAttempts.length,
                  separatorBuilder: (_, index) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) {
                    final att = provider.quizAttempts[i];
                    final studentName = att.studentName ?? 'Student';
                    final studentEmail = att.studentEmail ?? '';
                    final scoreText = att.score != null && att.totalMarks != null
                        ? '${att.score} / ${att.totalMarks}'
                        : 'Score pending';

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: att.passed ? AppColors.success.withAlpha(20) : AppColors.error.withAlpha(20),
                                child: Icon(
                                  att.passed ? Icons.check_circle : Icons.cancel_outlined,
                                  color: att.passed ? AppColors.success : AppColors.error,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(studentName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    if (studentEmail.isNotEmpty)
                                      Text(studentEmail, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                    Text(
                                      'Attempt #${att.attemptNumber} • ${att.status}',
                                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                    ),
                                  ],
                                ),
                              ),
                              StatusBadge(
                                label: att.passed ? 'PASSED' : 'FAILED',
                                color: att.passed ? AppColors.success : AppColors.error,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Divider(height: 1),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Score: $scoreText',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                              ),
                              if (att.percentage != null)
                                Text(
                                  '${att.percentage!.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: att.passed ? AppColors.success : AppColors.error,
                                  ),
                                ),
                            ],
                          ),
                          if (att.submittedAt != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Submitted: ${att.submittedAt!.toString().split('.')[0]}',
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
