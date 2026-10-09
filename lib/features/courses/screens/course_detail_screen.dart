import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/widgets/loading_state_widget.dart';
import '../models/course_model.dart';
import '../models/lesson_model.dart';
import '../models/review_model.dart';
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
      final provider = context.read<CourseProvider>();
      provider.loadCourseDetails(widget.courseId);
      provider.loadCourseReviews(widget.courseId);
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
                children: [
                  Expanded(child: _buildMetaItem(Icons.star_rounded, Colors.amber, '${course.averageRating} (${course.reviewCount})', 'Rating')),
                  Expanded(child: _buildMetaItem(Icons.people_outline, AppColors.primary, '${course.totalEnrollments}', 'Students')),
                  Expanded(child: _buildMetaItem(Icons.language_outlined, AppColors.textSecondary, course.language, 'Language')),
                  Expanded(child: _buildMetaItem(Icons.layers_outlined, AppColors.secondary, '${provider.sections.length} Sec', 'Content')),
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
                      label: const Center(child: Text('Curriculum')),
                      selected: _selectedTab == 0,
                      onSelected: (_) => setState(() => _selectedTab = 0),
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: _selectedTab == 0 ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Overview')),
                      selected: _selectedTab == 1,
                      onSelected: (_) => setState(() => _selectedTab = 1),
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: _selectedTab == 1 ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: Center(child: Text('Reviews (${provider.courseReviews.length})')),
                      selected: _selectedTab == 2,
                      onSelected: (_) => setState(() => _selectedTab = 2),
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: _selectedTab == 2 ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Tab Content
          if (_selectedTab == 0)
            _buildCurriculumSliver(provider.sections, isEnrolled, course)
          else if (_selectedTab == 1)
            _buildOverviewSliver(course)
          else
            _buildReviewsSliver(provider.courseReviews, isEnrolled),

          // Space for bottom sticky bar
          const SliverToBoxAdapter(child: SizedBox(height: 90)),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(course, isEnrolled, progress, provider.isActionLoading),
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

  Widget _buildCurriculumSliver(List<SectionModel> sections, bool isEnrolled, CourseModel course) {
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
              return Column(
                children: [
                  Card(
                    margin: const EdgeInsets.only(bottom: 10),
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
                  ),

                  // Assessments Quick Actions Row
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.quiz_outlined, size: 16, color: AppColors.accent),
                            label: const Text('Quizzes', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            onPressed: () {
                              Navigator.of(context).pushNamed(
                                AppRoutes.quizzes,
                                arguments: {
                                  'courseId': widget.courseId,
                                  'courseTitle': course.title,
                                },
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.assignment_outlined, size: 16, color: Colors.purple),
                            label: const Text('Assignments', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            onPressed: () {
                              Navigator.of(context).pushNamed(
                                AppRoutes.assignments,
                                arguments: {
                                  'courseId': widget.courseId,
                                  'courseTitle': course.title,
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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

  Widget _buildBottomBar(
    CourseModel course,
    bool isEnrolled,
    dynamic progress,
    bool isActionLoading,
  ) {
    // Keep the sticky action area vertically stacked.  A horizontal Row with
    // a Spacer + button can become too tight on small Android screens and
    // causes cascading "RenderBox was not laid out" errors.
    final progressValue = ((progress?.progressPercentage ?? 0) as num)
        .clamp(0, 100)
        .toDouble();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
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
        top: false,
        child: isEnrolled
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.green.shade300),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle, color: AppColors.success, size: 12),
                            SizedBox(width: 4),
                            Text(
                              'ENROLLED',
                              style: TextStyle(
                                color: AppColors.success,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${progressValue.toInt()}% Complete',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progressValue / 100.0,
                      minHeight: 6,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.play_circle_fill, size: 18),
                      onPressed: () {
                        final sections = context.read<CourseProvider>().sections;
                        if (sections.isNotEmpty && sections.first.lessons.isNotEmpty) {
                          _openLesson(sections.first.lessons.first, true);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      label: const Text('Start / Resume'),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Course Access',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              course.isFree ? 'FREE' : '\$${course.price}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.how_to_reg, size: 18),
                      label: isActionLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Enroll Now',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.studentRole,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: isActionLoading ? null : _handleEnroll,
                    ),
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

  Widget _buildReviewsSliver(List<ReviewModel> reviews, bool isEnrolled) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.star_rounded, color: Colors.amber, size: 28),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Course Reviews', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('${reviews.length} student review${reviews.length == 1 ? "" : "s"}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                  const Spacer(),
                  if (isEnrolled)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.rate_review_outlined, size: 16),
                      label: const Text('Add Review'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onPressed: () => _showReviewDialog(context),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          if (reviews.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Text('No reviews yet. Be the first to review this course!'),
              ),
            )
          else
            for (final review in reviews)
              Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: AppColors.primary.withAlpha(25),
                            child: Text(
                              review.studentName.isNotEmpty ? review.studentName[0].toUpperCase() : 'S',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              review.studentName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                          Row(
                            children: [
                              for (int i = 1; i <= 5; i++)
                                Icon(
                                  i <= review.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                                  color: Colors.amber,
                                  size: 16,
                                ),
                            ],
                          ),
                        ],
                      ),
                      if (review.comment.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(review.comment, style: const TextStyle(fontSize: 13, height: 1.3)),
                      ],
                    ],
                  ),
                ),
              ),
        ]),
      ),
    );
  }

  void _showReviewDialog(BuildContext context) {
    int rating = 5;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Rate & Review Course'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int i = 1; i <= 5; i++)
                    IconButton(
                      icon: Icon(
                        i <= rating ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: Colors.amber,
                        size: 32,
                      ),
                      onPressed: () => setModalState(() => rating = i),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: commentController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Share your feedback about this course...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                Navigator.of(ctx).pop();
                final provider = context.read<CourseProvider>();
                final ok = await provider.submitCourseReview(
                  widget.courseId,
                  rating: rating,
                  comment: commentController.text,
                );
                if (ok && mounted) {
                  messenger.showSnackBar(
                    const SnackBar(
                      backgroundColor: AppColors.success,
                      content: Text('Thank you! Your review has been submitted.'),
                    ),
                  );
                }
              },
              child: const Text('Submit Review'),
            ),
          ],
        ),
      ),
    );
  }
}
