import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/widgets/confirmation_dialog.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/loading_state_widget.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/status_badge.dart';
import '../../courses/models/course_model.dart';
import '../../instructor/providers/instructor_provider.dart';

class InstructorDashboardScreen extends StatefulWidget {
  final String instructorName;

  const InstructorDashboardScreen({
    super.key,
    this.instructorName = 'Nimal Fernando',
  });

  @override
  State<InstructorDashboardScreen> createState() => _InstructorDashboardScreenState();
}

class _InstructorDashboardScreenState extends State<InstructorDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InstructorProvider>().loadDashboard();
    });
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Logout',
      message: 'Are you sure you want to end your instructor session and log out?',
      confirmText: 'Logout',
      confirmColor: AppColors.error,
      icon: Icons.logout_rounded,
    );

    if (confirmed && context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.login,
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InstructorProvider>();
    final summary = provider.dashboardSummary;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Instructor Studio 👨‍🏫',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              widget.instructorName,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          const Center(
            child: StatusBadge(
              label: 'INSTRUCTOR',
              color: AppColors.instructorRole,
              icon: Icons.co_present_outlined,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined, color: AppColors.instructorRole),
            tooltip: 'My Profile',
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.profile),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.textSecondary),
            tooltip: 'Logout',
            onPressed: () => _handleLogout(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: provider.isLoading && provider.instructorCourses.isEmpty
          ? const LoadingStateWidget(message: 'Loading instructor dashboard...')
          : RefreshIndicator(
              onRefresh: () => provider.loadDashboard(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Create Course Banner Action
                    InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => Navigator.pushNamed(context, AppRoutes.instructorCourseCreate),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.instructorRole.withAlpha(20),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.instructorRole.withAlpha(50)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.instructorRole,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.add_box_rounded, color: Colors.white, size: 28),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'Create New Course',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Build sections, lessons, quizzes & assignments',
                                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.instructorRole),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Metrics Grid
                    Row(
                      children: [
                        _buildMetricCard(
                          'Total Courses',
                          '${summary?.totalCourses ?? provider.instructorCourses.length}',
                          Icons.auto_stories_outlined,
                          AppColors.instructorRole,
                        ),
                        const SizedBox(width: 10),
                        _buildMetricCard(
                          'Enrollments',
                          '${summary?.totalEnrollments ?? 0}',
                          Icons.people_outline,
                          AppColors.primary,
                        ),
                        const SizedBox(width: 10),
                        _buildMetricCard(
                          'To Grade',
                          '${summary?.pendingSubmissions ?? 0}',
                          Icons.assignment_late_outlined,
                          AppColors.accent,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildMetricCard(
                          'Published',
                          '${summary?.publishedCourses ?? provider.instructorCourses.where((c) => c.isPublished).length}',
                          Icons.check_circle_outline,
                          AppColors.success,
                        ),
                        const SizedBox(width: 10),
                        _buildMetricCard(
                          'Drafts',
                          '${summary?.draftCourses ?? provider.instructorCourses.where((c) => c.isDraft).length}',
                          Icons.edit_note_outlined,
                          AppColors.warning,
                        ),
                        const SizedBox(width: 10),
                        _buildMetricCard(
                          'Avg Rating',
                          summary?.averageCourseRating != null && summary!.averageCourseRating > 0
                              ? '${summary.averageCourseRating}★'
                              : 'N/A',
                          Icons.star_outline,
                          Colors.amber,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Course Status Filter Chips
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'My Managed Courses',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        Text(
                          '${provider.filteredCourses.length} courses',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ['ALL', 'PUBLISHED', 'DRAFT', 'ARCHIVED'].map((status) {
                          final isSelected = provider.selectedStatusFilter == status;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(status),
                              selected: isSelected,
                              selectedColor: AppColors.instructorRole,
                              labelStyle: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : AppColors.textSecondary,
                              ),
                              onSelected: (_) => provider.setStatusFilter(status),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Managed Courses List
                    if (provider.filteredCourses.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: EmptyStateWidget(
                          icon: Icons.auto_stories_outlined,
                          title: 'No ${provider.selectedStatusFilter} Courses',
                          message: provider.selectedStatusFilter == 'ALL'
                              ? 'Get started by creating your first course using the banner above!'
                              : 'You have no courses with ${provider.selectedStatusFilter} status.',
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: provider.filteredCourses.length,
                        separatorBuilder: (_, index) => const SizedBox(height: 12),
                        itemBuilder: (ctx, idx) {
                          final course = provider.filteredCourses[idx];
                          return _buildCourseCard(ctx, course);
                        },
                      ),
                    const SizedBox(height: 24),

                    // Instructor Tools Section
                    SectionHeader(
                      title: 'Instructor Studio Tools',
                      subtitle: 'Direct management of curriculum, reviews & learner submissions',
                    ),
                    _buildToolTile(
                      'Curriculum Studio',
                      'Build sections, text/video/PDF lessons and media',
                      Icons.layers_outlined,
                      () {
                        if (provider.instructorCourses.isNotEmpty) {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.instructorCourseStudio,
                            arguments: {
                              'courseId': provider.instructorCourses.first.id,
                              'title': provider.instructorCourses.first.title,
                            },
                          );
                        } else {
                          Navigator.pushNamed(context, AppRoutes.instructorCourseCreate);
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildToolTile(
                      'Assessment Grading',
                      '${summary?.pendingSubmissions ?? 0} student submissions awaiting review',
                      Icons.fact_check_outlined,
                      () {
                        if (provider.instructorCourses.isNotEmpty) {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.instructorCourseStudio,
                            arguments: {
                              'courseId': provider.instructorCourses.first.id,
                              'title': provider.instructorCourses.first.title,
                            },
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildToolTile(
                      'Learners & Progress',
                      'Inspect enrolled students and track course completion',
                      Icons.people_outline,
                      () {
                        if (provider.instructorCourses.isNotEmpty) {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.instructorCourseStudio,
                            arguments: {
                              'courseId': provider.instructorCourses.first.id,
                              'title': provider.instructorCourses.first.title,
                            },
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCourseCard(BuildContext context, CourseModel course) {
    Color statusColor;
    if (course.isPublished) {
      statusColor = AppColors.success;
    } else if (course.isArchived) {
      statusColor = AppColors.textMuted;
    } else {
      statusColor = AppColors.warning;
    }

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRoutes.instructorCourseStudio,
          arguments: {
            'courseId': course.id,
            'title': course.title,
          },
        );
      },
      child: Container(
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail or default icon
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: AppColors.instructorRole.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                    image: course.thumbnailUrl != null
                        ? DecorationImage(image: NetworkImage(course.thumbnailUrl!), fit: BoxFit.cover)
                        : null,
                  ),
                  child: course.thumbnailUrl == null
                      ? const Icon(Icons.auto_stories, color: AppColors.instructorRole, size: 26)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          StatusBadge(label: course.status, color: statusColor),
                          const SizedBox(width: 6),
                          Text(
                            course.level,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        course.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        course.categoryName.isNotEmpty ? course.categoryName : course.shortDescription,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.people_outline, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      '${course.totalEnrollments} learners',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.star, size: 16, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      '${course.averageRating} (${course.reviewCount})',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                TextButton.icon(
                  icon: const Icon(Icons.settings_outlined, size: 14),
                  label: const Text('Manage Studio', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.instructorRole,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.instructorCourseStudio,
                      arguments: {
                        'courseId': course.id,
                        'title': course.title,
                      },
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String count, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              count,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolTile(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.instructorRole.withAlpha(20),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.instructorRole, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
        onTap: onTap,
      ),
    );
  }
}
