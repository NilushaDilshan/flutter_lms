import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/loading_state_widget.dart';
import '../models/enrollment_model.dart';
import '../providers/course_provider.dart';

class MyCoursesScreen extends StatefulWidget {
  const MyCoursesScreen({super.key});

  @override
  State<MyCoursesScreen> createState() => _MyCoursesScreenState();
}

class _MyCoursesScreenState extends State<MyCoursesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CourseProvider>().loadMyEnrollments();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CourseProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Enrolled Courses'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await provider.loadMyEnrollments();
        },
        child: provider.isLoading
            ? const LoadingStateWidget(message: 'Loading your courses...')
            : provider.myEnrollments.isEmpty
                ? EmptyStateWidget(
                    title: 'No Enrolled Courses',
                    message: 'You have not enrolled in any courses yet. Browse our catalog to start learning!',
                    actionText: 'Explore Courses',
                    onAction: () {
                      Navigator.of(context).pushReplacementNamed(AppRoutes.courses);
                    },
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.myEnrollments.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final enrollment = provider.myEnrollments[index];
                      return _buildEnrollmentCard(enrollment);
                    },
                  ),
      ),
    );
  }

  Widget _buildEnrollmentCard(EnrollmentModel enrollment) {
    final course = enrollment.course;
    final title = course?.title ?? 'Course #${enrollment.courseId}';
    final progress = enrollment.progressPercentage;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      shadowColor: Colors.black.withAlpha(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).pushNamed(
            AppRoutes.courseDetail,
            arguments: {
              'courseId': enrollment.courseId,
              'title': title,
            },
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Thumbnail
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 70,
                      height: 70,
                      color: AppColors.primaryDark,
                      child: course?.thumbnailUrl != null && course!.thumbnailUrl!.isNotEmpty
                          ? Image.network(
                              course.thumbnailUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.school, color: Colors.white70),
                            )
                          : const Icon(Icons.school, color: Colors.white70),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          course?.level ?? 'BEGINNER',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Progress Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$progress% Completed',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary),
                  ),
                  Text(
                    progress == 100 ? 'Completed' : 'In Progress',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: progress == 100 ? AppColors.success : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress / 100.0,
                  minHeight: 6,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation(
                    progress == 100 ? AppColors.success : AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
