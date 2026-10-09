import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/widgets/confirmation_dialog.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/loading_state_widget.dart';
import '../../courses/models/course_model.dart';
import '../providers/admin_provider.dart';

class AdminCourseModerationScreen extends StatefulWidget {
  const AdminCourseModerationScreen({super.key});

  @override
  State<AdminCourseModerationScreen> createState() => _AdminCourseModerationScreenState();
}

class _AdminCourseModerationScreenState extends State<AdminCourseModerationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadAdminCourses();
    });
  }

  Future<void> _handleArchiveCourse(CourseModel course) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Administrative Archive',
      message: 'Are you sure you want to administratively archive "${course.title}"? This will remove the course from public browsing while preserving historical records and student enrollment data.',
      confirmText: 'Archive Course',
      confirmColor: Colors.deepOrange.shade800,
      icon: Icons.archive_outlined,
    );

    if (confirmed && mounted) {
      final provider = context.read<AdminProvider>();
      final success = await provider.archiveCourseAsAdmin(course.id);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.deepOrange.shade800,
              behavior: SnackBarBehavior.floating,
              content: Text('Course "${course.title}" has been archived administratively.'),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.error,
              content: Text(provider.errorMessage ?? 'Failed to archive course.'),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final courses = provider.filteredCourses;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Course Moderation'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Courses',
            onPressed: () => provider.loadAdminCourses(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Status Filter Tabs
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildStatusChip('All Courses', 'ALL', provider),
                  _buildStatusChip('Published', 'PUBLISHED', provider),
                  _buildStatusChip('Drafts', 'DRAFT', provider),
                  _buildStatusChip('Archived', 'ARCHIVED', provider),
                ],
              ),
            ),
          ),
          const Divider(height: 1),

          // Course Count Indicator
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey.shade100,
            child: Text(
              'Showing ${courses.length} course${courses.length == 1 ? "" : "s"}',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
            ),
          ),

          // Courses List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => provider.loadAdminCourses(),
              child: provider.isLoading
                  ? const LoadingStateWidget(message: 'Loading platform courses...')
                  : courses.isEmpty
                      ? EmptyStateWidget(
                          icon: Icons.inventory_2_outlined,
                          title: 'No Courses in this Status',
                          message: 'No platform courses match the selected status filter.',
                          actionText: 'View All Courses',
                          onAction: () => provider.setCourseStatusFilter('ALL'),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: courses.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final course = courses[index];
                            return _buildCourseCard(course);
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, String value, AdminProvider provider) {
    final isSelected = provider.selectedCourseStatusFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => provider.setCourseStatusFilter(value),
        selectedColor: AppColors.adminRole,
        labelStyle: TextStyle(
          fontSize: 12,
          color: isSelected ? Colors.white : AppColors.textPrimary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6),
      ),
    );
  }

  Widget _buildCourseCard(CourseModel course) {
    Color statusColor;
    switch (course.status.toUpperCase()) {
      case 'PUBLISHED':
        statusColor = AppColors.success;
        break;
      case 'DRAFT':
        statusColor = Colors.orange.shade800;
        break;
      default:
        statusColor = Colors.grey.shade600;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status and Meta Row
            Row(
              children: [
                // Animated Status Badge (Day 9 AnimatedContainer)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: statusColor.withAlpha(80)),
                  ),
                  child: Text(
                    course.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    course.level,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue.shade800),
                  ),
                ),
                const Spacer(),
                Text(
                  course.isFree ? 'FREE' : '\$${course.price.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Course Title
            Text(
              course.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),

            // Short Description
            Text(
              course.shortDescription,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
            ),
            const SizedBox(height: 12),

            // Meta Info: Rating, Enrollments, Instructor
            Row(
              children: [
                const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                const SizedBox(width: 4),
                Text(
                  '${course.averageRating} (${course.reviewCount})',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 14),
                const Icon(Icons.people_outline, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  '${course.totalEnrollments} enrolled',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const Spacer(),
                if (course.instructor != null)
                  Text(
                    course.instructor!.fullName,
                    style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.textMuted),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),

            // Actions Row
            Row(
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.visibility_outlined, size: 16),
                  label: const Text('Inspect Details', style: TextStyle(fontSize: 12)),
                  onPressed: () {
                    Navigator.of(context).pushNamed(
                      AppRoutes.courseDetail,
                      arguments: {'courseId': course.id, 'title': course.title},
                    );
                  },
                ),
                const Spacer(),
                if (!course.isArchived)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.archive_outlined, size: 16),
                    label: const Text('Archive Course', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange.shade800,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _handleArchiveCourse(course),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('ARCHIVED', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
