import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/widgets/confirmation_dialog.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/status_badge.dart';

class AdminDashboardScreen extends StatelessWidget {
  final String adminEmail;

  const AdminDashboardScreen({
    super.key,
    this.adminEmail = 'admin@lms.com',
  });

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Admin Sign Out',
      message: 'Are you sure you want to end your administrative session?',
      confirmText: 'Sign Out',
      confirmColor: AppColors.adminRole,
      icon: Icons.admin_panel_settings_outlined,
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
            const Text(
              'Admin Console 🛡️',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              adminEmail,
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
              label: 'ADMIN',
              color: AppColors.adminRole,
              icon: Icons.security_rounded,
            ),
          ),
          const SizedBox(width: 8),
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
            // Platform Stats Grid
            Row(
              children: [
                _buildStatTile('Total Users', '256', Icons.people_alt_outlined, AppColors.studentRole),
                const SizedBox(width: 12),
                _buildStatTile('Active Courses', '18', Icons.auto_stories_outlined, AppColors.instructorRole),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatTile('Categories', '8', Icons.category_outlined, AppColors.secondary),
                const SizedBox(width: 12),
                _buildStatTile('Pending Reviews', '14', Icons.rate_review_outlined, AppColors.accent),
              ],
            ),
            const SizedBox(height: 24),

            // Administrative Operations
            SectionHeader(
              title: 'Administration Controls',
              subtitle: 'Platform user management and content moderation',
            ),
            _buildAdminAction(
              'User Management',
              'Suspend, reactivate, or inspect user accounts',
              Icons.manage_accounts_outlined,
              AppColors.studentRole,
            ),
            const SizedBox(height: 10),
            _buildAdminAction(
              'Course Categories',
              'Create, update, activate or deactivate categories',
              Icons.grid_view_rounded,
              AppColors.secondary,
            ),
            const SizedBox(height: 10),
            _buildAdminAction(
              'Course Moderation',
              'Inspect and archive courses across all statuses',
              Icons.inventory_2_outlined,
              AppColors.instructorRole,
            ),
            const SizedBox(height: 10),
            _buildAdminAction(
              'Reviews & Ratings',
              'Moderate course reviews and manage visibility',
              Icons.star_outline_rounded,
              AppColors.accent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatTile(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminAction(String title, String subtitle, IconData icon, Color color) {
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
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 22),
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
        onTap: () {},
      ),
    );
  }
}
