import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/loading_state_widget.dart';
import '../../courses/providers/course_provider.dart';
import '../models/assignment_model.dart';
import '../providers/assignment_provider.dart';
import 'assignment_detail_screen.dart';

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
  bool _hasEnrolledCourses = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadAssignments();
    });
  }

  Future<void> _loadAssignments({bool forceRefresh = false}) async {
    if (!mounted) return;
    final assignmentProvider = context.read<AssignmentProvider>();
    final courseId = widget.courseId?.trim() ?? '';

    // If assignments already populated (e.g. from seedDemoAssignments or cache), skip fetch on initial load
    if (!forceRefresh && assignmentProvider.assignments.isNotEmpty) {
      return;
    }

    if (courseId.isNotEmpty) {
      await assignmentProvider.loadCourseAssignments(
        courseId,
        forceRefresh: forceRefresh,
      );
      return;
    }

    // No courseId specified: load assignments across all enrolled courses
    List<String> enrolledIds = [];
    try {
      final courseProvider = Provider.of<CourseProvider>(context, listen: false);
      if (courseProvider.myEnrollments.isEmpty) {
        await courseProvider.loadMyEnrollments();
      }
      enrolledIds = courseProvider.myEnrollments
          .map((e) => e.courseId.trim())
          .where((id) => id.isNotEmpty)
          .toList();
    } catch (_) {
      // Standalone test without CourseProvider
    }

    if (!mounted) return;

    if (enrolledIds.isEmpty) {
      setState(() {
        _hasEnrolledCourses = false;
      });
      if (assignmentProvider.assignments.isEmpty) {
        assignmentProvider.clearAssignments();
      }
    } else {
      setState(() {
        _hasEnrolledCourses = true;
      });
      await assignmentProvider.loadAssignmentsForCourses(
        enrolledIds,
        forceRefresh: forceRefresh,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final courseId = widget.courseId?.trim() ?? '';
    final title = widget.courseTitle?.trim().isNotEmpty == true
        ? 'Assignments: ${widget.courseTitle}'
        : courseId.isNotEmpty
            ? 'Course Assignments'
            : 'My Assignments';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Consumer<AssignmentProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.assignments.isEmpty) {
            return const LoadingStateWidget(
              message: 'Loading assignments...',
            );
          }

          if (provider.errorMessage != null && provider.assignments.isEmpty) {
            return _errorView(provider.errorMessage!);
          }

          if (provider.assignments.isEmpty) {
            if (courseId.isEmpty && !_hasEnrolledCourses) {
              return RefreshIndicator(
                onRefresh: () => _loadAssignments(forceRefresh: true),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 60),
                      child: EmptyStateWidget(
                        icon: Icons.school_outlined,
                        title: 'No Enrolled Courses',
                        message:
                            'Enroll in courses to see assignments and submit your coursework.',
                        actionText: 'Explore Courses',
                        onAction: () =>
                            Navigator.pushNamed(context, AppRoutes.courses),
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () => _loadAssignments(forceRefresh: true),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  Padding(
                    padding: EdgeInsets.only(top: 60),
                    child: EmptyStateWidget(
                      icon: Icons.assignment_outlined,
                      title: 'No assignments available',
                      message:
                          'There are no assignments published for your courses yet. Pull down to refresh.',
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => _loadAssignments(forceRefresh: true),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: provider.assignments.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final assignment = provider.assignments[index];
                return _assignmentCard(assignment, provider);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _assignmentCard(
      AssignmentModel assignment, AssignmentProvider provider) {
    final theme = Theme.of(context);
    final isSubmitted = provider.isAssignmentSubmitted(assignment.id) ||
        assignment.status == 'SUBMITTED';

    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.assignment,
                  size: 30,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    assignment.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isSubmitted)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.success),
                    ),
                    child: const Text(
                      'COMPLETED',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                  ),
              ],
            ),
            if (assignment.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(assignment.description),
            ],
            if (assignment.instructions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                assignment.instructions,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.grade_outlined, size: 19),
                const SizedBox(width: 6),
                Text('Maximum marks: ${assignment.maximumMarks}'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_month_outlined, size: 19),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    assignment.dueDate == null
                        ? 'Due date not specified'
                        : 'Due: ${_formatDate(assignment.dueDate!)}',
                  ),
                ),
              ],
            ),
            if (assignment.status != null) ...[
              const SizedBox(height: 8),
              Text('Status: ${assignment.status}'),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AssignmentDetailScreen(
                        assignmentId: assignment.id,
                        initialAssignment: assignment,
                      ),
                    ),
                  );
                },
                child: Text(
                  isSubmitted
                      ? 'Completed • View Submission'
                      : 'View & Submit',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorView(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('enrollment')) {
      return RefreshIndicator(
        onRefresh: () => _loadAssignments(forceRefresh: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 60),
              child: EmptyStateWidget(
                icon: Icons.school_outlined,
                title: 'Enrollment Required',
                message:
                    'An active course enrollment is required to view and submit assignments for this course.',
                actionText: 'Explore Courses',
                onAction: () => Navigator.pushNamed(context, AppRoutes.courses),
              ),
            ),
          ],
        ),
      );
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 56,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'Unable to load assignments',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _loadAssignments(forceRefresh: true),
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final localDate = date.toLocal();

    final day = localDate.day.toString().padLeft(2, '0');
    final month = localDate.month.toString().padLeft(2, '0');
    final year = localDate.year.toString();

    final hour = localDate.hour.toString().padLeft(2, '0');
    final minute = localDate.minute.toString().padLeft(2, '0');

    return '$day/$month/$year $hour:$minute';
  }
}