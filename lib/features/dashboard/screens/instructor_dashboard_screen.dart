import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/widgets/confirmation_dialog.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/status_badge.dart';

class InstructorDashboardScreen extends StatelessWidget {
  final String instructorName;

  const InstructorDashboardScreen({
    super.key,
    this.instructorName = 'Nimal Fernando',
  });

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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Instructor Studio 👨‍🏫',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              instructorName,
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Create Course Banner Action
            Container(
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
            const SizedBox(height: 20),

            // Summary Metrics
            Row(
              children: [
                _buildMetricCard('My Courses', '4', Icons.auto_stories_outlined, AppColors.instructorRole),
                const SizedBox(width: 12),
                _buildMetricCard('Active Students', '128', Icons.people_outline, AppColors.primary),
                const SizedBox(width: 12),
                _buildMetricCard('To Grade', '6', Icons.assignment_late_outlined, AppColors.accent),
              ],
            ),
            const SizedBox(height: 24),

            // Quick Shortcuts Section
            SectionHeader(
              title: 'Instructor Tools',
              subtitle: 'Manage curriculum, assessments & grades',
            ),
            _buildToolTile('Course Builder', 'Sections, Text/Video/PDF lessons', Icons.layers_outlined, () {}),
            const SizedBox(height: 10),
            _buildToolTile('Assessment Grading', '6 submissions awaiting review', Icons.fact_check_outlined, () {}),
            const SizedBox(height: 10),
            _buildToolTile('Student Attempts', 'Inspect quiz results and scores', Icons.quiz_outlined, () {}),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String count, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              count,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
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
