import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/confirmation_dialog.dart';
import '../../../core/widgets/loading_state_widget.dart';
import '../models/quiz_model.dart';
import '../providers/quiz_provider.dart';

class QuizAttemptScreen extends StatefulWidget {
  final String quizId;
  final String? quizTitle;
  final QuizModel? initialQuiz;

  const QuizAttemptScreen({
    super.key,
    required this.quizId,
    this.quizTitle,
    this.initialQuiz,
  });

  @override
  State<QuizAttemptScreen> createState() => _QuizAttemptScreenState();
}

class _QuizAttemptScreenState extends State<QuizAttemptScreen> {
  // Map of questionId -> list of selected option IDs
  final Map<String, List<String>> _answers = {};

  int _remainingSeconds = 0;
  Timer? _timer;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeQuiz());
  }

  Future<void> _initializeQuiz() async {
    final quizProvider = context.read<QuizProvider>();
    await quizProvider.loadQuizDetails(widget.quizId);
    await quizProvider.startQuizAttempt(widget.quizId);

    final quiz = quizProvider.selectedQuiz ?? widget.initialQuiz;
    if (quiz != null && quiz.timeLimitMinutes > 0) {
      setState(() {
        _remainingSeconds = quiz.timeLimitMinutes * 60;
      });
      _startTimer();
    }

    if (mounted) {
      setState(() => _isInitialized = true);
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        t.cancel();
        _handleAutoSubmit();
      }
    });
  }

  void _handleAutoSubmit() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Colors.orange,
        content: Text('⏳ Time expired! Auto-submitting your quiz attempt...'),
      ),
    );
    _submitQuiz(force: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _selectOption(String questionId, String optionId, bool isSingleChoice) {
    setState(() {
      if (isSingleChoice) {
        _answers[questionId] = [optionId];
      } else {
        final current = List<String>.from(_answers[questionId] ?? []);
        if (current.contains(optionId)) {
          current.remove(optionId);
        } else {
          current.add(optionId);
        }
        _answers[questionId] = current;
      }
    });
  }

  Future<void> _submitQuiz({bool force = false}) async {
    if (!force) {
      final confirmed = await ConfirmationDialog.show(
        context,
        title: 'Submit Quiz',
        message: 'Are you sure you want to submit your answers? You cannot change them after submission.',
        confirmText: 'Submit Quiz',
        confirmColor: AppColors.primary,
        icon: Icons.check_circle_outline,
      );
      if (!confirmed) return;
    }

    if (!mounted) return;
    final quizProvider = context.read<QuizProvider>();
    final attemptId = quizProvider.activeAttempt?.id ?? 'attempt-${widget.quizId}';

    final result = await quizProvider.submitQuizAttempt(attemptId, _answers);
    _timer?.cancel();

    if (mounted && result != null) {
      _showResultDialog(result);
    }
  }

  void _showResultDialog(QuizAttemptModel result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              result.passed ? Icons.verified_rounded : Icons.cancel_rounded,
              color: result.passed ? AppColors.success : AppColors.error,
              size: 32,
            ),
            const SizedBox(width: 10),
            Text(result.passed ? 'Quiz Passed! 🎉' : 'Quiz Not Passed'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              result.passed
                  ? 'Congratulations! You met the passing requirements.'
                  : 'You did not reach the passing score this time.',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: (result.passed ? AppColors.success : AppColors.error).withAlpha(15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Official Score:', style: TextStyle(fontWeight: FontWeight.w600)),
                      Text('${result.score ?? 0} / ${result.totalMarks ?? 0} marks',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Percentage:', style: TextStyle(fontWeight: FontWeight.w600)),
                      Text('${result.percentage?.toStringAsFixed(1) ?? "0"}%',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: result.passed ? AppColors.success : AppColors.error,
                            fontSize: 16,
                          )),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Attempt Status:', style: TextStyle(fontWeight: FontWeight.w600)),
                      Text(result.status, style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Return to Course'),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final quizProvider = context.watch<QuizProvider>();
    final quiz = quizProvider.selectedQuiz ?? widget.initialQuiz;

    if (!_isInitialized || quizProvider.isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.quizTitle ?? 'Quiz Assessment')),
        body: const LoadingStateWidget(message: 'Preparing your quiz questions...'),
      );
    }

    final questions = quiz?.questions ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(quiz?.title ?? 'Quiz Assessment', style: const TextStyle(fontSize: 16)),
        actions: [
          if (_remainingSeconds > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _remainingSeconds < 60 ? Colors.red.shade100 : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.timer_outlined,
                          size: 14,
                          color: _remainingSeconds < 60 ? Colors.red : AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        _formatTime(_remainingSeconds),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: _remainingSeconds < 60 ? Colors.red : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      body: questions.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.quiz_outlined, size: 56, color: AppColors.textSecondary),
                    const SizedBox(height: 12),
                    const Text('No questions available in this quiz.',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Back'),
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: questions.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final q = questions[index];
                return _buildQuestionCard(index + 1, q);
              },
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 8, offset: const Offset(0, -2)),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.send_rounded, size: 18),
            label: quizProvider.isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Submit Quiz Attempt', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: quizProvider.isSubmitting ? null : () => _submitQuiz(),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionCard(int number, QuizQuestionModel question) {
    final selectedIds = _answers[question.id] ?? [];

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('Q$number',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 12)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    question.questionText,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                ),
                Text(
                  '${question.marks} pt${question.marks > 1 ? "s" : ""}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 14),
            for (final option in question.options)
              _buildOptionTile(question, option, selectedIds.contains(option.id)),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile(QuizQuestionModel question, QuizOptionModel option, bool isSelected) {
    return InkWell(
      onTap: () => _selectOption(question.id, option.id, question.isSingleChoice),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withAlpha(15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            Icon(
              question.isSingleChoice
                  ? (isSelected ? Icons.radio_button_checked : Icons.radio_button_off)
                  : (isSelected ? Icons.check_box : Icons.check_box_outline_blank),
              color: isSelected ? AppColors.primary : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                option.text,
                style: TextStyle(
                  fontSize: 14,
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
