import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/loading_state_widget.dart';
import '../../courses/models/enrollment_model.dart';
import '../providers/admin_provider.dart';

class AdminEnrollmentManagementScreen extends StatefulWidget {
  const AdminEnrollmentManagementScreen({super.key});

  @override
  State<AdminEnrollmentManagementScreen> createState() => _AdminEnrollmentManagementScreenState();
}

class _AdminEnrollmentManagementScreenState extends State<AdminEnrollmentManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AdminProvider>();
      provider.loadAdminEnrollments();
      provider.loadAdminCourses();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final enrollments = provider.filteredEnrollments;
    final courses = provider.adminCourses;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Platform Enrollments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Enrollments',
            onPressed: () => provider.loadAdminEnrollments(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter by Course Header
          if (courses.isNotEmpty)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.filter_list_rounded, size: 20, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  const Text('Filter by Course:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        value: provider.enrollmentCourseFilter,
                        isExpanded: true,
                        hint: const Text('All Courses', style: TextStyle(fontSize: 12)),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('All Courses', style: TextStyle(fontSize: 12)),
                          ),
                          for (final c in courses)
                            DropdownMenuItem<String?>(
                              value: c.id,
                              child: Text(
                                c.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                        ],
                        onChanged: (val) => provider.setEnrollmentCourseFilter(val),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const Divider(height: 1),

          // Count Ribbon
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey.shade100,
            child: Text(
              'Showing ${enrollments.length} active enrollment${enrollments.length == 1 ? "" : "s"}',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
            ),
          ),

          // Enrollments List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => provider.loadAdminEnrollments(),
              child: provider.isLoading
                  ? const LoadingStateWidget(message: 'Loading platform enrollments...')
                  : enrollments.isEmpty
                      ? EmptyStateWidget(
                          icon: Icons.school_outlined,
                          title: 'No Enrollments Found',
                          message: 'No student enrollments match the selected course filter.',
                          actionText: 'Clear Filter',
                          onAction: () => provider.setEnrollmentCourseFilter(null),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: enrollments.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final enr = enrollments[index];
                            return _buildEnrollmentCard(enr);
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnrollmentCard(EnrollmentModel enr) {
    final name = enr.studentName ?? 'Learner';
    final email = enr.studentEmail ?? 'student@lms.com';
    final progress = enr.progressPercentage;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.studentRole.withAlpha(25),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'L',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.studentRole),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(email, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: progress >= 100 ? Colors.green.shade50 : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    progress >= 100 ? 'COMPLETED' : 'IN PROGRESS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: progress >= 100 ? AppColors.success : AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Progress Bar
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress / 100.0,
                      minHeight: 6,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation(
                        progress >= 100 ? AppColors.success : AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '$progress%',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Enrolled Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Course ID: ${enr.courseId}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
                Text(
                  enr.enrolledAt != null
                      ? 'Enrolled: ${enr.enrolledAt!.year}-${enr.enrolledAt!.month.toString().padLeft(2, '0')}-${enr.enrolledAt!.day.toString().padLeft(2, '0')}'
                      : 'Enrolled: N/A',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
