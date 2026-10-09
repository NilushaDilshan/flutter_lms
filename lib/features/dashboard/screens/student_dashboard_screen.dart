import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/widgets/confirmation_dialog.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/error_state_widget.dart';
import '../../../core/widgets/loading_state_widget.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/status_badge.dart';
import '../../courses/providers/course_provider.dart';

class StudentDashboardScreen extends StatefulWidget {
  final String studentName;

  const StudentDashboardScreen({
    super.key,
    this.studentName = 'Kamal Perera',
  });

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  // 0: Content, 1: Loading Preview, 2: Empty Preview, 3: Error Preview
  int _viewStateMode = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final courseProvider = context.read<CourseProvider>();
      courseProvider.loadStudentDashboard();
      courseProvider.loadMyEnrollments();
      courseProvider.loadCourses();
    });
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Logout',
      message: 'Are you sure you want to end your student session and log out?',
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
              'Hi, ${widget.studentName} 👋',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const Text(
              'Ready to continue your learning?',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          const Center(
            child: StatusBadge(
              label: 'STUDENT',
              color: AppColors.studentRole,
              icon: Icons.school_outlined,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.explore_outlined, color: AppColors.primary),
            tooltip: 'Explore Courses',
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.courses),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: AppColors.primary),
            tooltip: 'Notifications',
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.notifications),
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined, color: AppColors.primary),
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
      body: Column(
        children: [
          // UI State Simulator Bar (Day 3 Feature)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.blue.shade50,
            child: Row(
              children: [
                const Icon(Icons.preview_rounded, size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                const Text(
                  'State View:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildStateChip(0, 'Normal'),
                        _buildStateChip(1, 'Loading'),
                        _buildStateChip(2, 'Empty'),
                        _buildStateChip(3, 'Error'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Main Screen Body depending on state
          Expanded(
            child: _buildBodyContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildStateChip(int mode, String label) {
    final isSelected = _viewStateMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _viewStateMode = mode),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.cardBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildBodyContent() {
    switch (_viewStateMode) {
      case 1:
        return const LoadingStateWidget(
          message: 'Loading enrolled courses & learning progress...',
        );
      case 2:
        return EmptyStateWidget(
          icon: Icons.school_outlined,
          title: 'No Enrolled Courses Yet',
          message: 'Explore published courses to begin your learning journey and start gaining certifications.',
          actionText: 'Browse Courses',
          onAction: () {
            Navigator.of(context).pushNamed(AppRoutes.courses);
          },
        );
      case 3:
        return ErrorStateWidget(
          title: 'Failed to Load Courses',
          message: 'Unable to connect to the learning server. Please verify your network connection and retry.',
          retryText: 'Retry Connection',
          onRetry: () {
            setState(() => _viewStateMode = 0);
          },
        );
      default:
        return _buildNormalDashboard();
    }
  }

  Widget _buildNormalDashboard() {
    final courseProvider = context.watch<CourseProvider>();
    final enrollments = courseProvider.myEnrollments;
    final enrolledCount = enrollments.length;
    final inProgressCount = enrollments.where((e) => e.progressPercentage > 0 && e.progressPercentage < 100).length;
    final completedCount = enrollments.where((e) => e.progressPercentage >= 100).length;

    final firstEnrollment = enrollments.isNotEmpty ? enrollments.first : null;
    final continueTitle = firstEnrollment?.course?.title ?? 'Browse & Enroll in Courses';
    final continueProgress = (firstEnrollment?.progressPercentage ?? 0) / 100.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Continue Learning Featured Card
          GestureDetector(
            onTap: () {
              if (firstEnrollment != null) {
                Navigator.of(context).pushNamed(
                  AppRoutes.courseDetail,
                  arguments: {
                    'courseId': firstEnrollment.courseId,
                    'title': firstEnrollment.course?.title,
                  },
                );
              } else {
                Navigator.of(context).pushNamed(AppRoutes.courses);
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(60),
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
                        child: Text(
                          firstEnrollment != null ? 'CONTINUE LEARNING' : 'START LEARNING',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      Text(
                        firstEnrollment != null ? '${firstEnrollment.progressPercentage}% Completed' : 'Tap to Browse',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    continueTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    firstEnrollment != null
                        ? 'Active Enrollment • Tap to resume lessons'
                        : 'Explore published courses and start your journey',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: continueProgress,
                      backgroundColor: Colors.white24,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Quick Action Navigation Buttons
          Row(
            children: [
              _buildQuickActionBtn(
                icon: Icons.search_rounded,
                label: 'Courses',
                color: AppColors.primary,
                onTap: () => Navigator.of(context).pushNamed(AppRoutes.courses),
              ),
              const SizedBox(width: 8),
              _buildQuickActionBtn(
                icon: Icons.bookmark_added_outlined,
                label: 'My Courses',
                color: AppColors.studentRole,
                onTap: () => Navigator.of(context).pushNamed(AppRoutes.myCourses),
              ),
              const SizedBox(width: 8),
              _buildQuickActionBtn(
                icon: Icons.quiz_outlined,
                label: 'Quizzes',
                color: AppColors.accent,
                onTap: () => Navigator.of(context).pushNamed(AppRoutes.quizzes),
              ),
              const SizedBox(width: 8),
              _buildQuickActionBtn(
                icon: Icons.assignment_outlined,
                label: 'Assignments',
                color: Colors.purple,
                onTap: () => Navigator.of(context).pushNamed(AppRoutes.assignments),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Summary Stats Cards (Live Data)
          Row(
            children: [
              _buildStatCard('Enrolled', '$enrolledCount', Icons.book_outlined, AppColors.studentRole),
              const SizedBox(width: 12),
              _buildStatCard('In Progress', '$inProgressCount', Icons.trending_up, AppColors.accent),
              const SizedBox(width: 12),
              _buildStatCard('Completed', '$completedCount', Icons.verified_outlined, AppColors.success),
            ],
          ),
          const SizedBox(height: 24),

          // My Courses Section
          SectionHeader(
            title: 'My Enrolled Courses',
            subtitle: 'Courses you are currently learning',
            actionText: 'View All',
            onAction: () => Navigator.of(context).pushNamed(AppRoutes.myCourses),
          ),
          if (enrollments.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                children: [
                  const Icon(Icons.school_outlined, size: 40, color: AppColors.primary),
                  const SizedBox(height: 10),
                  const Text(
                    'No Enrolled Courses Yet',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Select a published course from our catalog and click "Enroll Now" to get started.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.explore_rounded, size: 16),
                    label: const Text('Explore Courses Catalog'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.studentRole,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => Navigator.of(context).pushNamed(AppRoutes.courses),
                  ),
                ],
              ),
            )
          else ...[
            for (final enroll in enrollments.take(3)) ...[
              _buildCourseItem(
                title: enroll.course?.title ?? 'Course #${enroll.courseId}',
                instructor: enroll.course?.instructor?.fullName ?? 'Lead Instructor',
                progressText: '${enroll.progressPercentage}% Completed',
                progress: enroll.progressPercentage / 100.0,
                onTap: () {
                  Navigator.of(context).pushNamed(
                    AppRoutes.courseDetail,
                    arguments: {
                      'courseId': enroll.courseId,
                      'title': enroll.course?.title,
                    },
                  );
                },
              ),
              const SizedBox(height: 12),
            ],
          ],

          const SizedBox(height: 24),

          // Recent Activity Section
          const SectionHeader(
            title: 'Recent Activity',
            subtitle: 'Your recent submissions and quiz attempts',
          ),
          _buildActivityTile(
            title: 'Quiz 2: State Management Passed',
            subtitle: 'Score: 92% • 2 hours ago',
            icon: Icons.quiz_outlined,
            color: AppColors.success,
          ),
          const SizedBox(height: 10),
          _buildActivityTile(
            title: 'Assignment 1 Submitted',
            subtitle: 'Status: Pending Grading • Yesterday',
            icon: Icons.upload_file_rounded,
            color: AppColors.studentRole,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String count, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
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

  Widget _buildCourseItem({
    required String title,
    required String instructor,
    required String progressText,
    required double progress,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.school_rounded, color: AppColors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    instructor,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.studentRole),
                            minHeight: 4,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        progressText,
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
