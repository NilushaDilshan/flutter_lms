import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/loading_state_widget.dart';
import '../models/course_model.dart';
import '../models/lesson_model.dart';
import '../models/section_model.dart';
import '../providers/course_provider.dart';

class CourseDetailScreen extends StatefulWidget {
  final String courseId;
  final String? initialTitle;

  const CourseDetailScreen({
    super.key,
    required this.courseId,
    this.initialTitle,
  });

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  int _selectedTab = 0; // 0 = Overview, 1 = Curriculum

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CourseProvider>().loadCourseDetails(widget.courseId);
    });
  }

  Future<void> _handleEnroll() async {
    final provider = context.read<CourseProvider>();
    final success = await provider.enrollInCourse(widget.courseId);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.success,
            content: Text('🎉 Successfully enrolled in this course!'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text(provider.errorMessage ?? 'Failed to enroll in course.'),
          ),
        );
      }
    }
  }

  void _openLesson(LessonModel lesson, bool isEnrolled) {
    if (!isEnrolled && !lesson.isPreview) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: const Row(
            children: [
              Icon(Icons.lock_outline, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text('🔒 Enrollment required: Please enroll to unlock this lesson.'),
              ),
            ],
          ),
          action: SnackBarAction(
            label: 'ENROLL',
            textColor: Colors.white,
            onPressed: _handleEnroll,
          ),
        ),
      );
      return;
    }

    Navigator.of(context).pushNamed(
      AppRoutes.lessonPlayer,
      arguments: {
        'courseId': widget.courseId,
        'lesson': lesson,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CourseProvider>();
    final course = provider.selectedCourse;
    final isEnrolled = provider.isEnrolled(widget.courseId);
    final progress = provider.currentProgress;

    if (provider.isLoadingDetails && course == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.initialTitle ?? 'Course Details')),
        body: const LoadingStateWidget(message: 'Loading course syllabus...'),
      );
    }

    if (course == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Course Details')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Could not load course details.'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => provider.loadCourseDetails(widget.courseId),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Collapsible Header Banner
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            title: Text(course.title, style: const TextStyle(fontSize: 16)),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (course.thumbnailUrl != null && course.thumbnailUrl!.isNotEmpty)
                    Image.network(
                      course.thumbnailUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _buildFallbackBanner(course.title),
                    )
                  else
                    _buildFallbackBanner(course.title),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withAlpha(80),
                          Colors.black.withAlpha(200),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            course.level,
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          course.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Course Meta Row
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMetaItem(Icons.star_rounded, Colors.amber, '${course.averageRating} (${course.reviewCount})', 'Rating'),
                  _buildMetaItem(Icons.people_outline, AppColors.primary, '${course.totalEnrollments}', 'Students'),
                  _buildMetaItem(Icons.language_outlined, AppColors.textSecondary, course.language, 'Language'),
                  _buildMetaItem(Icons.layers_outlined, AppColors.secondary, '${provider.sections.length} Sec', 'Content'),
                ],
              ),
            ),
          ),

          // Overview / Curriculum Tabs
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Curriculum & Lessons')),
                      selected: _selectedTab == 0,
                      onSelected: (_) => setState(() => _selectedTab = 0),
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: _selectedTab == 0 ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Overview & Info')),
                      selected: _selectedTab == 1,
                      onSelected: (_) => setState(() => _selectedTab = 1),
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: _selectedTab == 1 ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Tab Content
          if (_selectedTab == 0)
            _buildCurriculumSliver(provider.sections, isEnrolled)
          else
            _buildOverviewSliver(course),

          // Space for bottom sticky bar
          const SliverToBoxAdapter(child: SizedBox(height: 90)),
        ],
      ),
      bottomSheet: _buildBottomBar(course, isEnrolled, progress, provider.isActionLoading),
    );
  }

  Widget _buildMetaItem(IconData icon, Color iconColor, String title, String subtitle) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 22),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
      ],
    );
  }

  Widget _buildCurriculumSliver(List<SectionModel> sections, bool isEnrolled) {
    if (sections.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: Text('No curriculum sections available yet.')),
        ),
      );
    }

    final totalLessons = sections.fold<int>(0, (sum, s) => sum + s.lessons.length);
    final totalDuration = sections.fold<int>(
      0,
      (sum, s) => sum + s.lessons.fold<int>(0, (lSum, l) => lSum + l.durationMinutes),
    );

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index == 0) {
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 0,
                color: Colors.blue.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.blue.shade100),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSummaryStat(Icons.view_module_outlined, '${sections.length}', 'Sections'),
                      _buildSummaryStat(Icons.play_lesson_outlined, '$totalLessons', 'Lessons'),
                      _buildSummaryStat(Icons.schedule_outlined, '$totalDuration min', 'Duration'),
                    ],
                  ),
                ),
              );
            }
            final section = sections[index - 1];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ExpansionTile(
                initiallyExpanded: index == 1,
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withAlpha(30),
                  radius: 16,
                  child: Text('$index', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
                title: Text(
                  section.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: Text(
                  '${section.lessons.length} lessons',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                children: [
                  for (final lesson in section.lessons)
                    _buildLessonTile(lesson, isEnrolled),
                ],
              ),
            );
          },
          childCount: sections.length + 1,
        ),
      ),
    );
  }

  Widget _buildSummaryStat(IconData icon, String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryDark)),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildLessonTile(LessonModel lesson, bool isEnrolled) {
    IconData typeIcon;
    Color typeColor;
    if (lesson.isVideo) {
      typeIcon = Icons.play_circle_fill_rounded;
      typeColor = Colors.red.shade600;
    } else if (lesson.isDocument) {
      typeIcon = Icons.description_rounded;
      typeColor = Colors.deepPurple;
    } else {
      typeIcon = Icons.article_rounded;
      typeColor = Colors.teal;
    }

    final canAccess = isEnrolled || lesson.isPreview;

    return ListTile(
      dense: true,
      onTap: () => _openLesson(lesson, isEnrolled),
      leading: Icon(
        lesson.isCompleted ? Icons.check_circle_rounded : typeIcon,
        color: lesson.isCompleted ? AppColors.success : typeColor,
        size: 22,
      ),
      title: Text(
        lesson.title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: canAccess ? AppColors.textPrimary : AppColors.textMuted,
        ),
      ),
      subtitle: Row(
        children: [
          Text(
            lesson.lessonType.name.toUpperCase(),
            style: TextStyle(fontSize: 10, color: typeColor, fontWeight: FontWeight.bold),
          ),
          if (lesson.durationMinutes > 0) ...[
            const SizedBox(width: 8),
            Text('• ${lesson.durationMinutes} min', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ],
      ),
      trailing: canAccess
          ? (lesson.isPreview && !isEnrolled
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(4)),
                  child: const Text('PREVIEW', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                )
              : const Icon(Icons.chevron_right, size: 18, color: AppColors.textSecondary))
          : const Icon(Icons.lock_outline, size: 18, color: AppColors.textMuted),
    );
  }

  Widget _buildOverviewSliver(CourseModel course) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Description
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('About This Course', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 8),
                    Text(
                      course.description.isNotEmpty ? course.description : course.shortDescription,
                      style: const TextStyle(fontSize: 14, height: 1.5, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Instructor Information
            if (course.instructor != null)
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Course Instructor', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: AppColors.primary.withAlpha(30),
                            backgroundImage: (course.instructor!.profileImageUrl != null &&
                                    course.instructor!.profileImageUrl!.isNotEmpty)
                                ? NetworkImage(course.instructor!.profileImageUrl!)
                                : null,
                            child: (course.instructor!.profileImageUrl == null ||
                                    course.instructor!.profileImageUrl!.isEmpty)
                                ? Text(
                                    course.instructor!.fullName.isNotEmpty
                                        ? course.instructor!.fullName[0].toUpperCase()
                                        : 'I',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 18),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  course.instructor!.fullName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Lead Instructor & Course Author',
                                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),

            // Learning Outcomes
            if (course.learningOutcomes.isNotEmpty)
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('What You Will Learn', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 10),
                      for (final outcome in course.learningOutcomes)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.check_circle_outline, color: AppColors.success, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(outcome, style: const TextStyle(fontSize: 13, height: 1.3)),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),

            // Requirements
            if (course.requirements.isNotEmpty)
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Prerequisites & Requirements', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 10),
                      for (final req in course.requirements)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.circle, color: AppColors.textSecondary, size: 6),
                              const SizedBox(width: 8),
                              Expanded(child: Text(req, style: const TextStyle(fontSize: 13))),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(CourseModel course, bool isEnrolled, dynamic progress, bool isActionLoading) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: isEnrolled
            ? Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${progress?.progressPercentage ?? 0}% Completed',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: ((progress?.progressPercentage ?? 0) as int) / 100.0,
                            minHeight: 6,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {
                      final sections = context.read<CourseProvider>().sections;
                      if (sections.isNotEmpty && sections.first.lessons.isNotEmpty) {
                        _openLesson(sections.first.lessons.first, true);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    ),
                    child: const Text('Resume Lesson'),
                  ),
                ],
              )
            : Row(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Course Access', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      Text(
                        course.isFree ? 'FREE' : '\$${course.price}',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                      ),
                    ],
                  ),
                  const Spacer(),
                  CustomButton(
                    text: 'Enroll Now',
                    isLoading: isActionLoading,
                    onPressed: _handleEnroll,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildFallbackBanner(String title) {
    return Container(
      color: AppColors.primaryDark,
      child: Center(
        child: Icon(Icons.school, size: 64, color: Colors.white.withAlpha(100)),
      ),
    );
  }
}
