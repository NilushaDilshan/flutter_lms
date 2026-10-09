import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/widgets/confirmation_dialog.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/status_badge.dart';
import '../../admin/providers/admin_provider.dart';

class AdminDashboardScreen extends StatefulWidget {
  final String adminEmail;

  const AdminDashboardScreen({
    super.key,
    this.adminEmail = 'admin@lms.com',
  });

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AdminProvider>();
      provider.loadAdminDashboard();
      provider.loadUsers();
      provider.loadCategories();
      provider.loadAdminCourses();
    });
  }

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
    final adminProvider = context.watch<AdminProvider>();
    final summary = adminProvider.dashboardSummary;

    final totalStudents = summary?.totalStudents ?? 0;
    final totalInstructors = summary?.totalInstructors ?? 0;
    final activeUsers = summary?.activeUsers ?? 0;
    final publishedCourses = summary?.publishedCourses ?? 0;
    final totalCourses = summary?.totalCourses ?? 0;
    final totalEnrollments = summary?.totalEnrollments ?? 0;
    final completedEnrollments = summary?.completedEnrollments ?? 0;
    final categoriesCount = adminProvider.categories.length;

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
              widget.adminEmail,
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
            icon: const Icon(Icons.account_circle_outlined, color: AppColors.adminRole),
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
      body: RefreshIndicator(
        onRefresh: () async {
          await adminProvider.loadAdminDashboard();
          await adminProvider.loadUsers();
          await adminProvider.loadCategories();
          await adminProvider.loadAdminCourses();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.adminRole, Color(0xFFC2185B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.adminRole.withAlpha(60),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(40),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'PLATFORM OVERVIEW',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const Row(
                          children: [
                            Icon(Icons.shield_outlined, color: Colors.white, size: 16),
                            SizedBox(width: 4),
                            Text('Live Server Sync', style: TextStyle(color: Colors.white70, fontSize: 11)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'System Administration',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Manage users, moderate learning curriculum, and monitor enrollments.',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Platform Stats Grid 1: Users & Courses
              Row(
                children: [
                  _buildStatTile(
                    'Total Students',
                    '$totalStudents',
                    Icons.school_outlined,
                    AppColors.studentRole,
                  ),
                  const SizedBox(width: 12),
                  _buildStatTile(
                    'Instructors',
                    '$totalInstructors',
                    Icons.co_present_outlined,
                    AppColors.instructorRole,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Platform Stats Grid 2: Active Users & Courses
              Row(
                children: [
                  _buildStatTile(
                    'Active Users',
                    '$activeUsers',
                    Icons.people_alt_outlined,
                    AppColors.success,
                  ),
                  const SizedBox(width: 12),
                  _buildStatTile(
                    'Published Courses',
                    '$publishedCourses / $totalCourses',
                    Icons.auto_stories_outlined,
                    AppColors.secondary,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Platform Stats Grid 3: Enrollments & Categories
              Row(
                children: [
                  _buildStatTile(
                    'Enrollments',
                    '$totalEnrollments ($completedEnrollments done)',
                    Icons.card_membership_outlined,
                    AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  _buildStatTile(
                    'Categories',
                    '$categoriesCount',
                    Icons.category_outlined,
                    Colors.deepPurple,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Administrative Controls Header
              const SectionHeader(
                title: 'Administration Controls',
                subtitle: 'Platform user management and content moderation',
              ),

              // Action List Tiles
              _buildAdminAction(
                context,
                title: 'User Management',
                subtitle: 'Suspend, reactivate, or inspect user accounts',
                icon: Icons.manage_accounts_outlined,
                color: AppColors.studentRole,
                badgeText: '${adminProvider.users.length} Users',
                onTap: () => Navigator.of(context).pushNamed(AppRoutes.adminUsers),
              ),
              const SizedBox(height: 10),

              _buildAdminAction(
                context,
                title: 'Course Categories',
                subtitle: 'Create, update, activate or deactivate categories',
                icon: Icons.grid_view_rounded,
                color: AppColors.secondary,
                badgeText: '$categoriesCount Categories',
                onTap: () => Navigator.of(context).pushNamed(AppRoutes.adminCategories),
              ),
              const SizedBox(height: 10),

              _buildAdminAction(
                context,
                title: 'Course Moderation',
                subtitle: 'Inspect and archive courses across all statuses',
                icon: Icons.inventory_2_outlined,
                color: AppColors.instructorRole,
                badgeText: '$totalCourses Courses',
                onTap: () => Navigator.of(context).pushNamed(AppRoutes.adminCourses),
              ),
              const SizedBox(height: 10),

              _buildAdminAction(
                context,
                title: 'Platform Enrollments',
                subtitle: 'Review student enrollments across all courses',
                icon: Icons.school_outlined,
                color: AppColors.primary,
                badgeText: '$totalEnrollments Enrollments',
                onTap: () => Navigator.of(context).pushNamed(AppRoutes.adminEnrollments),
              ),
              const SizedBox(height: 10),

              _buildAdminAction(
                context,
                title: 'Review Moderation',
                subtitle: 'Moderate student reviews and manage visibility',
                icon: Icons.star_outline_rounded,
                color: AppColors.accent,
                badgeText: 'Review System',
                onTap: () => Navigator.of(context).pushNamed(AppRoutes.adminReviews),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatTile(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
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
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminAction(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String badgeText,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: ListTile(
        onTap: onTap,
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
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withAlpha(15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                badgeText,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
