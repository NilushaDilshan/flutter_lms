import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/loading_state_widget.dart';
import '../models/assignment_model.dart';
import '../providers/assignment_provider.dart';

class AssignmentListScreen extends StatefulWidget {
  final String? courseId;
  final String? courseTitle;

  const AssignmentListScreen({
    super.key,
    this.courseId,
    this.courseTitle,
  });

  @override
  State<AssignmentListScreen> createState() => _AssignmentListScreenState();
}

class _AssignmentListScreenState extends State<AssignmentListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AssignmentProvider>().loadCourseAssignments(widget.courseId ?? '');
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AssignmentProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.courseTitle != null ? 'Assignments: ${widget.courseTitle}' : 'Course Assignments'),
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.loadCourseAssignments(widget.courseId ?? ''),
        child: provider.isLoading
            ? const LoadingStateWidget(message: 'Loading course assignments...')
            : provider.assignments.isEmpty
                ? EmptyStateWidget(
                    icon: Icons.assignment_outlined,
                    title: 'No Assignments',
                    message: 'There are no assignments published for this course yet.',
                    actionText: 'Back to Courses',
                    onAction: () => Navigator.of(context).pop(),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.assignments.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final assignment = provider.assignments[index];
                      return _buildAssignmentCard(assignment);
                    },
                  ),
      ),
    );
  }

  Widget _buildAssignmentCard(AssignmentModel assignment) {

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.of(context).pushNamed(
            AppRoutes.assignmentDetail,
            arguments: {
              'assignmentId': assignment.id,
              'assignment': assignment,
            },
          );
        },
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
                    child: Row(
                      children: [
                        Icon(Icons.assignment_outlined, size: 14, color: Colors.purple.shade700),
                        const SizedBox(width: 4),
                        Text(
                          'Max ${assignment.maxMarks} marks',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.purple.shade700),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (assignment.dueDate != null)
                    Text(
                      'Due ${assignment.dueDate!.year}-${assignment.dueDate!.month.toString().padLeft(2, '0')}-${assignment.dueDate!.day.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                assignment.title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              Text(
                assignment.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: const [
                  Text('View & Submit', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.primary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
