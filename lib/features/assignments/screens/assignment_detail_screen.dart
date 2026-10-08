import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/loading_state_widget.dart';
import '../models/assignment_model.dart';
import '../providers/assignment_provider.dart';

class AssignmentDetailScreen extends StatefulWidget {
  final String assignmentId;
  final AssignmentModel? initialAssignment;

  const AssignmentDetailScreen({
    super.key,
    required this.assignmentId,
    this.initialAssignment,
  });

  @override
  State<AssignmentDetailScreen> createState() => _AssignmentDetailScreenState();
}

class _AssignmentDetailScreenState extends State<AssignmentDetailScreen> {
  final TextEditingController _textAnswerController = TextEditingController();
  String? _selectedFileName;
  String? _selectedFilePath;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<AssignmentProvider>();
      await provider.loadAssignmentDetails(widget.assignmentId);
      final sub = provider.mySubmission;
      if (sub?.textAnswer != null) {
        _textAnswerController.text = sub!.textAnswer!;
      }
    });
  }

  @override
  void dispose() {
    _textAnswerController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_textAnswerController.text.trim().isEmpty && _selectedFilePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.error,
          content: Text('Please enter your written answer or attach a submission file.'),
        ),
      );
      return;
    }

    final provider = context.read<AssignmentProvider>();
    final success = await provider.submitAssignment(
      assignmentId: widget.assignmentId,
      textAnswer: _textAnswerController.text.trim(),
      filePath: _selectedFilePath,
      fileName: _selectedFileName,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.success,
            content: Text('🎉 Assignment submitted successfully!'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text(provider.errorMessage ?? 'Submission failed.'),
          ),
        );
      }
    }
  }

  void _simulateFileAttachment() {
    setState(() {
      _selectedFileName = 'assignment_solution_${DateTime.now().millisecondsSinceEpoch % 10000}.pdf';
      _selectedFilePath = '/simulated/path/$_selectedFileName';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.blue.shade700,
        content: Text('📎 Attached: $_selectedFileName'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AssignmentProvider>();
    final assignment = provider.selectedAssignment ?? widget.initialAssignment;
    final submission = provider.mySubmission;

    if (provider.isLoading && assignment == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Assignment Details')),
        body: const LoadingStateWidget(message: 'Loading assignment details...'),
      );
    }

    final isGraded = submission?.isGraded ?? false;
    final isResubmission = submission?.isResubmissionRequired ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(assignment?.title ?? 'Assignment Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Assignment Header Card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                            color: Colors.purple.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Max: ${assignment?.maxMarks ?? 100} Marks',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.purple.shade800),
                          ),
                        ),
                        const Spacer(),
                        if (assignment?.dueDate != null)
                          Builder(
                            builder: (context) {
                              final due = assignment!.dueDate!;
                              return Text(
                                'Due: ${due.year}-${due.month.toString().padLeft(2, '0')}-${due.day.toString().padLeft(2, '0')}',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              );
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      assignment?.title ?? 'Assignment',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      assignment?.description ?? '',
                      style: const TextStyle(fontSize: 14, height: 1.4, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Status Banner if submission exists
            if (submission != null) ...[
              if (isResubmission)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.orange.shade800, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Resubmission Required',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade900, fontSize: 14),
                          ),
                        ],
                      ),
                      if (submission.feedback != null && submission.feedback!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Instructor Feedback: "${submission.feedback}"',
                          style: TextStyle(fontSize: 13, color: Colors.orange.shade900, fontStyle: FontStyle.italic),
                        ),
                      ],
                      const SizedBox(height: 4),
                      const Text(
                        'Please make required corrections and submit again below.',
                        style: TextStyle(fontSize: 12, color: Colors.black87),
                      ),
                    ],
                  ),
                )
              else if (isGraded)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.verified_rounded, color: AppColors.success, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Graded by Instructor',
                            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.success, fontSize: 14),
                          ),
                          const Spacer(),
                          Text(
                            '${submission.marksAwarded ?? 0} / ${assignment?.maxMarks ?? 100} marks',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.success),
                          ),
                        ],
                      ),
                      if (submission.feedback != null && submission.feedback!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text('Feedback: "${submission.feedback}"', style: const TextStyle(fontSize: 13)),
                      ],
                      const SizedBox(height: 4),
                      const Text('This submission has been graded and is locked for further editing.',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text('Status: ${submission.status} (Pending grading)',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13)),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
            ],

            // Submission Box Card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isGraded ? 'Your Submission (Locked)' : 'Your Submission',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),

                    // Written answer field
                    TextField(
                      controller: _textAnswerController,
                      enabled: !isGraded,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: isGraded ? 'No submission' : 'Type your written response or code snippet here...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        filled: isGraded,
                        fillColor: isGraded ? Colors.grey.shade100 : Colors.white,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // File attachment row
                    if (!isGraded) ...[
                      Row(
                        children: [
                          OutlinedButton.icon(
                            icon: const Icon(Icons.attach_file, size: 18),
                            label: const Text('Attach File / PDF'),
                            onPressed: _simulateFileAttachment,
                          ),
                          const SizedBox(width: 12),
                          if (_selectedFileName != null)
                            Expanded(
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _selectedFileName!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, size: 16),
                                    onPressed: () => setState(() {
                                      _selectedFileName = null;
                                      _selectedFilePath = null;
                                    }),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Submit button
                      CustomButton(
                        text: isResubmission ? 'Resubmit Corrected Assignment' : 'Submit Assignment (FormData)',
                        isLoading: provider.isSubmitting,
                        onPressed: _handleSubmit,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
