import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/loading_state_widget.dart';
import '../../../core/widgets/status_badge.dart';
import '../../assignments/models/assignment_model.dart';
import '../providers/instructor_provider.dart';

class InstructorSubmissionsScreen extends StatefulWidget {
  final String assignmentId;
  final String? assignmentTitle;
  final int maxMarks;

  const InstructorSubmissionsScreen({
    super.key,
    this.assignmentId = '',
    this.assignmentTitle,
    this.maxMarks = 100,
  });

  @override
  State<InstructorSubmissionsScreen> createState() => _InstructorSubmissionsScreenState();
}

class _InstructorSubmissionsScreenState extends State<InstructorSubmissionsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<InstructorProvider>();
      if (widget.assignmentId.isNotEmpty) {
        p.loadAssignmentSubmissions(widget.assignmentId);
      } else if (p.courseAssignments.isNotEmpty) {
        p.loadAssignmentSubmissions(p.courseAssignments.first.id);
      } else {
        p.loadAssignmentSubmissions('demo-assignment-1');
      }
    });
  }

  void _showGradeDialog(BuildContext context, InstructorProvider provider, AssignmentSubmissionModel submission) {
    final marksCtrl = TextEditingController(text: submission.marksAwarded?.toString() ?? '');
    final feedbackCtrl = TextEditingController(text: submission.feedback ?? '');
    String status = submission.isResubmissionRequired ? 'RESUBMISSION_REQUIRED' : 'GRADED';

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: Text('Grade: ${submission.studentName ?? "Student"}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (submission.textAnswer != null) ...[
                  const Text('Student Answer:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(submission.textAnswer!, style: const TextStyle(fontSize: 13)),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: marksCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Marks Awarded (Max ${widget.maxMarks})',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  decoration: InputDecoration(
                    labelText: 'Grading Decision',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'GRADED', child: Text('Accept & Pass (GRADED)')),
                    DropdownMenuItem(value: 'RESUBMISSION_REQUIRED', child: Text('Request Resubmission')),
                  ],
                  onChanged: (val) => setDlgState(() => status = val ?? 'GRADED'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: feedbackCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Instructor Feedback',
                    hintText: 'Explain the evaluation or describe what needs improvement...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              onPressed: () {
                final marks = int.tryParse(marksCtrl.text) ?? 0;
                if (marks > widget.maxMarks) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Marks cannot exceed ${widget.maxMarks}'), backgroundColor: AppColors.error),
                  );
                  return;
                }
                provider.gradeSubmission(
                  submission.id,
                  marksAwarded: marks,
                  status: status,
                  feedback: feedbackCtrl.text.trim(),
                );
                Navigator.pop(dialogCtx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Submission graded successfully!'), backgroundColor: AppColors.success),
                );
              },
              child: const Text('Save Grade'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InstructorProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.assignmentTitle != null ? 'Submissions: ${widget.assignmentTitle}' : 'Student Submissions'),
      ),
      body: provider.isLoading
          ? const LoadingStateWidget(message: 'Loading submissions...')
          : provider.assignmentSubmissions.isEmpty
              ? const EmptyStateWidget(
                  icon: Icons.rate_review_outlined,
                  title: 'No Submissions Yet',
                  message: 'Students have not submitted answers for this assignment yet.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.assignmentSubmissions.length,
                  separatorBuilder: (_, index) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) {
                    final sub = provider.assignmentSubmissions[i];
                    Color statusColor;
                    if (sub.isGraded) {
                      statusColor = AppColors.success;
                    } else if (sub.isResubmissionRequired) {
                      statusColor = AppColors.error;
                    } else {
                      statusColor = AppColors.accent;
                    }

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
                                backgroundColor: AppColors.primary.withAlpha(20),
                                child: Text(
                                  (sub.studentName ?? 'S').substring(0, 1),
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(sub.studentName ?? 'Student', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    Text(
                                      sub.studentEmail ?? 'Submitted ${sub.submittedAt.toString().split('.')[0]}',
                                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              StatusBadge(label: sub.status, color: statusColor),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (sub.textAnswer != null) ...[
                            Text(
                              sub.textAnswer!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 8),
                          ],
                          if (sub.marksAwarded != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.success.withAlpha(20),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Awarded: ${sub.marksAwarded} / ${widget.maxMarks} marks',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.success),
                              ),
                            ),
                          if (sub.feedback != null && sub.feedback!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text('Feedback: ${sub.feedback!}', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.textSecondary)),
                          ],
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.rate_review_outlined, size: 16),
                              label: Text(sub.isGraded ? 'Review / Re-grade' : 'Grade Submission'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              onPressed: () => _showGradeDialog(context, provider, sub),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
