import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/widgets/confirmation_dialog.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/loading_state_widget.dart';
import '../../../core/widgets/status_badge.dart';
import '../../courses/models/course_model.dart';
import '../../courses/models/lesson_model.dart';
import '../../courses/models/section_model.dart';
import '../providers/instructor_provider.dart';
import 'course_create_edit_screen.dart';

class CourseStudioScreen extends StatefulWidget {
  final String courseId;
  final String? initialTitle;

  const CourseStudioScreen({
    super.key,
    required this.courseId,
    this.initialTitle,
  });

  @override
  State<CourseStudioScreen> createState() => _CourseStudioScreenState();
}

class _CourseStudioScreenState extends State<CourseStudioScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InstructorProvider>().loadCourseDetails(widget.courseId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Thumbnail Picker
  Future<void> _handleUploadThumbnail() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null || !mounted) return;

    final provider = context.read<InstructorProvider>();
    final success = await provider.uploadCourseThumbnail(widget.courseId, picked);

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Course thumbnail updated!'), backgroundColor: AppColors.success),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Thumbnail upload failed'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // Publish Course
  Future<void> _handlePublishCourse(CourseModel course) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Publish Course',
      message: 'Publishing makes this course visible in the student catalog. Ensure at least one section and lesson are published.',
      confirmText: 'Publish Now',
      confirmColor: AppColors.success,
      icon: Icons.public_rounded,
    );

    if (confirmed && mounted) {
      final provider = context.read<InstructorProvider>();
      final success = await provider.publishCourse(course.id);
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Course is now published!'), backgroundColor: AppColors.success),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Could not publish course'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  // Archive Course
  Future<void> _handleArchiveCourse(CourseModel course) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Archive Course',
      message: 'Archived courses will stop accepting new student enrollments. You cannot easily publish it again.',
      confirmText: 'Archive Course',
      confirmColor: AppColors.error,
      icon: Icons.archive_outlined,
    );

    if (confirmed && mounted) {
      final provider = context.read<InstructorProvider>();
      final success = await provider.archiveCourse(course.id);
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Course has been archived.'), backgroundColor: AppColors.warning),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Could not archive course'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InstructorProvider>();
    final course = provider.selectedCourse;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(course?.title ?? widget.initialTitle ?? 'Course Studio'),
        actions: [
          if (course != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit Details',
              onPressed: () async {
                final updated = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CourseCreateEditScreen(courseToEdit: course),
                  ),
                );
                if (updated == true && mounted) {
                  provider.loadCourseDetails(widget.courseId);
                }
              },
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(icon: Icon(Icons.menu_book_outlined, size: 20), text: 'Curriculum'),
            Tab(icon: Icon(Icons.assignment_turned_in_outlined, size: 20), text: 'Assessments'),
            Tab(icon: Icon(Icons.people_outline, size: 20), text: 'Learners'),
          ],
        ),
      ),
      body: provider.isLoading
          ? const LoadingStateWidget(message: 'Loading course studio...')
          : course == null
              ? const EmptyStateWidget(
                  icon: Icons.error_outline,
                  title: 'Course Not Found',
                  message: 'Could not load details for this course.',
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildCurriculumTab(context, provider, course),
                    _buildAssessmentsTab(context, provider, course),
                    _buildLearnersTab(context, provider, course),
                  ],
                ),
    );
  }

  // 1. CURRICULUM TAB
  Widget _buildCurriculumTab(BuildContext context, InstructorProvider provider, CourseModel course) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Course Header Banner with Status & Publish Action
          _buildCourseHeaderCard(course),
          const SizedBox(height: 16),

          // Sections Accordion Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Course Curriculum',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Section'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                onPressed: () => _showAddSectionDialog(context, provider),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (provider.sections.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: const EmptyStateWidget(
                icon: Icons.layers_clear_outlined,
                title: 'No Sections Yet',
                message: 'Start building your course by adding your first section.',
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: provider.sections.length,
              separatorBuilder: (_, index) => const SizedBox(height: 12),
              itemBuilder: (ctx, index) {
                final section = provider.sections[index];
                return _buildSectionCard(ctx, provider, section);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildCourseHeaderCard(CourseModel course) {
    Color statusColor;
    String statusText = course.status.toUpperCase();
    if (statusText == 'PUBLISHED') {
      statusColor = AppColors.success;
    } else if (statusText == 'ARCHIVED') {
      statusColor = AppColors.textMuted;
    } else {
      statusColor = AppColors.warning;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              Stack(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                      image: course.thumbnailUrl != null
                          ? DecorationImage(image: NetworkImage(course.thumbnailUrl!), fit: BoxFit.cover)
                          : null,
                    ),
                    child: course.thumbnailUrl == null
                        ? const Icon(Icons.image_outlined, color: AppColors.primary, size: 32)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: InkWell(
                      onTap: _handleUploadThumbnail,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        StatusBadge(
                          label: statusText,
                          color: statusColor,
                          icon: statusText == 'PUBLISHED' ? Icons.check_circle : Icons.edit_note,
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            course.level,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      course.title,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      course.shortDescription,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // Publishing Actions
          Row(
            children: [
              if (course.isDraft) ...[
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.publish_rounded, size: 18),
                    label: const Text('Publish Course'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => _handlePublishCourse(course),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (course.isPublished) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.archive_outlined, size: 18),
                    label: const Text('Archive Course'),
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.warning),
                    onPressed: () => _handleArchiveCourse(course),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(BuildContext context, InstructorProvider provider, SectionModel section) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: section.isPublished ? AppColors.success.withAlpha(20) : AppColors.warning.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              section.isPublished ? Icons.check_circle_outline : Icons.visibility_off_outlined,
              color: section.isPublished ? AppColors.success : AppColors.warning,
              size: 20,
            ),
          ),
          title: Text(
            section.title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          subtitle: Text(
            '${section.lessons.length} lessons • ${section.isPublished ? 'Published' : 'Draft'}',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          trailing: PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 20),
            onSelected: (val) {
              if (val == 'edit') {
                _showEditSectionDialog(context, provider, section);
              } else if (val == 'toggle_publish') {
                provider.updateSection(section.id, isPublished: !section.isPublished);
              } else if (val == 'delete') {
                _handleDeleteSection(context, provider, section);
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'toggle_publish',
                child: Row(
                  children: [
                    Icon(section.isPublished ? Icons.visibility_off : Icons.visibility, size: 18),
                    const SizedBox(width: 8),
                    Text(section.isPublished ? 'Unpublish Section' : 'Publish Section'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('Edit Section'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                    SizedBox(width: 8),
                    Text('Delete Section', style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            ],
          ),
          children: [
            const Divider(height: 1),
            // Lessons list inside section
            if (section.lessons.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('No lessons yet in this section.', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: section.lessons.length,
                itemBuilder: (ctx, lIdx) {
                  final lesson = section.lessons[lIdx];
                  return _buildLessonTile(ctx, provider, section, lesson);
                },
              ),
            // Add lesson button at bottom of section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              color: AppColors.background.withAlpha(80),
              child: TextButton.icon(
                icon: const Icon(Icons.add_circle_outline, size: 16),
                label: const Text('Add Lesson to Section', style: TextStyle(fontSize: 13)),
                onPressed: () => _showAddLessonDialog(context, provider, section),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonTile(
    BuildContext context,
    InstructorProvider provider,
    SectionModel section,
    LessonModel lesson,
  ) {
    IconData typeIcon;
    Color iconColor;
    if (lesson.isVideo) {
      typeIcon = Icons.play_circle_fill_rounded;
      iconColor = AppColors.error;
    } else if (lesson.isDocument) {
      typeIcon = Icons.picture_as_pdf_rounded;
      iconColor = AppColors.warning;
    } else {
      typeIcon = Icons.article_rounded;
      iconColor = AppColors.primary;
    }

    return ListTile(
      dense: true,
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: iconColor.withAlpha(20),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(typeIcon, color: iconColor, size: 18),
      ),
      title: Text(
        lesson.title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      ),
      subtitle: Row(
        children: [
          Text('${lesson.lessonType.toBackendString()} • ${lesson.durationMinutes} mins', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(width: 6),
          if (lesson.isPreview)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(color: AppColors.accent.withAlpha(30), borderRadius: BorderRadius.circular(4)),
              child: const Text('PREVIEW', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.accent)),
            ),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: lesson.isPublished ? AppColors.success.withAlpha(20) : AppColors.textMuted.withAlpha(20),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              lesson.isPublished ? 'PUBLISHED' : 'DRAFT',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: lesson.isPublished ? AppColors.success : AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
      trailing: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, size: 18),
        onSelected: (val) {
          if (val == 'toggle_publish') {
            _handleToggleLessonPublish(provider, lesson);
          } else if (val == 'upload_media') {
            _handleUploadLessonMedia(provider, lesson);
          } else if (val == 'delete') {
            _handleDeleteLesson(context, provider, lesson);
          }
        },
        itemBuilder: (_) => [
          PopupMenuItem(
            value: 'toggle_publish',
            child: Text(lesson.isPublished ? 'Unpublish Lesson' : 'Publish Lesson'),
          ),
          if (lesson.isVideo || lesson.isDocument)
            PopupMenuItem(
              value: 'upload_media',
              child: Text(lesson.isVideo ? 'Upload Video File' : 'Upload Document PDF'),
            ),
          const PopupMenuItem(
            value: 'delete',
            child: Text('Delete Lesson', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  // 2. ASSESSMENTS TAB
  Widget _buildAssessmentsTab(BuildContext context, InstructorProvider provider, CourseModel course) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quizzes Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Course Quizzes 📝',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Create Quiz'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                onPressed: () => _showCreateQuizDialog(context, provider),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (provider.courseQuizzes.isEmpty)
            _buildEmptyAssessmentCard('No Quizzes Created', 'Add quizzes to test student understanding.')
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: provider.courseQuizzes.length,
              separatorBuilder: (_, index) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) {
                final quiz = provider.courseQuizzes[i];
                return _buildQuizCard(ctx, provider, quiz);
              },
            ),
          const SizedBox(height: 24),

          // Assignments Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Course Assignments 📑',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Create Assignment'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                onPressed: () => _showCreateAssignmentDialog(context, provider),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (provider.courseAssignments.isEmpty)
            _buildEmptyAssessmentCard('No Assignments Created', 'Add practical tasks for student submissions.')
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: provider.courseAssignments.length,
              separatorBuilder: (_, index) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) {
                final assignment = provider.courseAssignments[i];
                return _buildAssignmentCard(ctx, provider, assignment);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyAssessmentCard(String title, String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Center(
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
            const SizedBox(height: 2),
            Text(message, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizCard(BuildContext context, InstructorProvider provider, dynamic quiz) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(quiz.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
              StatusBadge(
                label: quiz.isPublished ? 'PUBLISHED' : 'DRAFT',
                color: quiz.isPublished ? AppColors.success : AppColors.warning,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Pass score: ${quiz.passingScore}% • Time: ${quiz.timeLimitMinutes > 0 ? '${quiz.timeLimitMinutes}m' : 'Unlimited'} • ${quiz.questions.length} questions',
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (!quiz.isPublished)
                TextButton.icon(
                  icon: const Icon(Icons.publish, size: 14),
                  label: const Text('Publish', style: TextStyle(fontSize: 11)),
                  onPressed: () => provider.publishQuiz(quiz.id),
                ),
              TextButton.icon(
                icon: const Icon(Icons.add, size: 14),
                label: const Text('Add Question', style: TextStyle(fontSize: 11)),
                onPressed: () => _showAddQuizQuestionDialog(context, provider, quiz.id),
              ),
              TextButton.icon(
                icon: const Icon(Icons.people_alt_outlined, size: 14),
                label: const Text('View Attempts', style: TextStyle(fontSize: 11)),
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.instructorQuizAttempts,
                    arguments: {'quizId': quiz.id, 'quizTitle': quiz.title},
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentCard(BuildContext context, InstructorProvider provider, dynamic assignment) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(assignment.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
              StatusBadge(
                label: assignment.isPublished ? 'PUBLISHED' : 'DRAFT',
                color: assignment.isPublished ? AppColors.success : AppColors.warning,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Max Marks: ${assignment.maxMarks} • Due: ${assignment.dueDate != null ? assignment.dueDate!.toString().split(' ')[0] : 'No deadline'}',
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (!assignment.isPublished)
                TextButton.icon(
                  icon: const Icon(Icons.publish, size: 14),
                  label: const Text('Publish', style: TextStyle(fontSize: 11)),
                  onPressed: () => provider.publishAssignment(assignment.id),
                ),
              TextButton.icon(
                icon: const Icon(Icons.rate_review_outlined, size: 14),
                label: const Text('Review Submissions', style: TextStyle(fontSize: 11)),
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.instructorSubmissions,
                    arguments: {
                      'assignmentId': assignment.id,
                      'assignmentTitle': assignment.title,
                      'maxMarks': assignment.maxMarks,
                    },
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 3. LEARNERS TAB
  Widget _buildLearnersTab(BuildContext context, InstructorProvider provider, CourseModel course) {
    if (provider.courseEnrollments.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.people_outline,
        title: 'No Enrolled Students',
        message: 'Students will appear here once they enroll in your published course.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: provider.courseEnrollments.length,
      separatorBuilder: (_, index) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) {
        final enr = provider.courseEnrollments[i];
        final name = enr.studentName ?? 'Student ${i + 1}';
        final email = enr.studentEmail ?? 'Enrolled student';

        return Container(
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
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primary.withAlpha(30),
                    child: Text(name.isNotEmpty ? name[0] : 'S', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text(email, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  StatusBadge(
                    label: enr.status.toUpperCase(),
                    color: enr.isCompleted ? AppColors.success : AppColors.primary,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Course Completion Progress:', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  Text('${enr.progressPercentage}%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                ],
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: enr.progressPercentage / 100,
                backgroundColor: AppColors.cardBorder,
                valueColor: AlwaysStoppedAnimation<Color>(enr.isCompleted ? AppColors.success : AppColors.primary),
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        );
      },
    );
  }

  // DIALOGS & ACTION HANDLERS

  void _showAddSectionDialog(BuildContext context, InstructorProvider provider) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    bool isPub = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: const Text('Add Course Section'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Section Title', hintText: 'e.g. Section 1: Intro'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Description (Optional)'),
              ),
              const SizedBox(height: 10),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Publish Immediately'),
                value: isPub,
                onChanged: (val) => setDlgState(() => isPub = val),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (titleCtrl.text.trim().isNotEmpty) {
                  provider.createSection(
                    widget.courseId,
                    title: titleCtrl.text.trim(),
                    description: descCtrl.text.trim(),
                    isPublished: isPub,
                  );
                  Navigator.pop(dialogCtx);
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditSectionDialog(BuildContext context, InstructorProvider provider, SectionModel section) {
    final titleCtrl = TextEditingController(text: section.title);
    final descCtrl = TextEditingController(text: section.description ?? '');

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Edit Section'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Section Title')),
            const SizedBox(height: 10),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              provider.updateSection(
                section.id,
                title: titleCtrl.text.trim(),
                description: descCtrl.text.trim(),
              );
              Navigator.pop(dialogCtx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDeleteSection(BuildContext context, InstructorProvider provider, SectionModel section) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Delete Section',
      message: 'Are you sure you want to delete "${section.title}" and all its lessons?',
      confirmText: 'Delete',
      confirmColor: AppColors.error,
      icon: Icons.delete_outline,
    );
    if (confirmed) {
      provider.deleteSection(section.id);
    }
  }

  void _showAddLessonDialog(BuildContext context, InstructorProvider provider, SectionModel section) {
    final titleCtrl = TextEditingController();
    final textContentCtrl = TextEditingController();
    final durationCtrl = TextEditingController(text: '10');
    LessonType type = LessonType.text;
    bool isPreview = false;
    bool isPub = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: const Text('Add Lesson'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Lesson Title', hintText: 'e.g. Widget Fundamentals'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<LessonType>(
                  initialValue: type,
                  decoration: const InputDecoration(labelText: 'Lesson Type'),
                  items: const [
                    DropdownMenuItem(value: LessonType.text, child: Text('TEXT (Markdown / Article)')),
                    DropdownMenuItem(value: LessonType.video, child: Text('VIDEO')),
                    DropdownMenuItem(value: LessonType.document, child: Text('DOCUMENT (PDF)')),
                  ],
                  onChanged: (val) => setDlgState(() => type = val ?? LessonType.text),
                ),
                if (type == LessonType.text) ...[
                  const SizedBox(height: 10),
                  TextField(
                    controller: textContentCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: 'Lesson Text Content', hintText: 'Write the lesson content here...'),
                  ),
                ],
                const SizedBox(height: 10),
                TextField(
                  controller: durationCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Duration (Minutes)'),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Free Preview Lesson'),
                  value: isPreview,
                  onChanged: (val) => setDlgState(() => isPreview = val),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Publish Immediately'),
                  value: isPub,
                  onChanged: (val) => setDlgState(() => isPub = val),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (titleCtrl.text.trim().isNotEmpty) {
                  provider.createLesson(
                    section.id,
                    title: titleCtrl.text.trim(),
                    lessonType: type,
                    textContent: textContentCtrl.text.trim(),
                    durationMinutes: int.tryParse(durationCtrl.text) ?? 10,
                    isPreview: isPreview,
                    isPublished: isPub,
                  );
                  Navigator.pop(dialogCtx);
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleToggleLessonPublish(InstructorProvider provider, LessonModel lesson) async {
    final nextState = !lesson.isPublished;
    final success = await provider.updateLesson(lesson.id, {'isPublished': nextState});
    if (!mounted) return;
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Validation failed'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _handleUploadLessonMedia(InstructorProvider provider, LessonModel lesson) async {
    final picker = ImagePicker();
    XFile? picked;
    if (lesson.isVideo) {
      picked = await picker.pickVideo(source: ImageSource.gallery);
    } else {
      picked = await picker.pickMedia();
    }
    if (picked == null || !mounted) return;

    final success = await provider.uploadLessonMedia(lesson.id, picked, isVideo: lesson.isVideo);
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lesson media uploaded!'), backgroundColor: AppColors.success),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.errorMessage ?? 'Media upload failed'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _handleDeleteLesson(BuildContext context, InstructorProvider provider, LessonModel lesson) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Delete Lesson',
      message: 'Are you sure you want to delete "${lesson.title}"?',
      confirmText: 'Delete',
      confirmColor: AppColors.error,
      icon: Icons.delete_outline,
    );
    if (confirmed) {
      provider.deleteLesson(lesson.id);
    }
  }

  void _showCreateQuizDialog(BuildContext context, InstructorProvider provider) {
    final titleCtrl = TextEditingController();
    final passCtrl = TextEditingController(text: '70');
    final timeCtrl = TextEditingController(text: '15');

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Create Quiz'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Quiz Title')),
            const SizedBox(height: 10),
            TextField(controller: passCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Passing Score (%)')),
            const SizedBox(height: 10),
            TextField(controller: timeCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Time Limit (Minutes)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (titleCtrl.text.trim().isNotEmpty) {
                provider.createQuiz(
                  widget.courseId,
                  title: titleCtrl.text.trim(),
                  passingScore: int.tryParse(passCtrl.text) ?? 70,
                  timeLimitMinutes: int.tryParse(timeCtrl.text) ?? 15,
                );
                Navigator.pop(dialogCtx);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showAddQuizQuestionDialog(BuildContext context, InstructorProvider provider, String quizId) {
    final qCtrl = TextEditingController();
    final opt1Ctrl = TextEditingController(text: 'Option A');
    final opt2Ctrl = TextEditingController(text: 'Option B');
    String correct = 'opt1';

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: const Text('Add Quiz Question'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: qCtrl, decoration: const InputDecoration(labelText: 'Question Text')),
              const SizedBox(height: 10),
              TextField(controller: opt1Ctrl, decoration: const InputDecoration(labelText: 'Option 1')),
              const SizedBox(height: 8),
              TextField(controller: opt2Ctrl, decoration: const InputDecoration(labelText: 'Option 2')),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: correct,
                decoration: const InputDecoration(labelText: 'Correct Option'),
                items: const [
                  DropdownMenuItem(value: 'opt1', child: Text('Option 1 is Correct')),
                  DropdownMenuItem(value: 'opt2', child: Text('Option 2 is Correct')),
                ],
                onChanged: (val) => setDlgState(() => correct = val ?? 'opt1'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (qCtrl.text.trim().isNotEmpty) {
                  provider.addQuizQuestion(
                    quizId,
                    questionText: qCtrl.text.trim(),
                    questionType: 'SINGLE_CHOICE',
                    options: [
                      {'id': 'opt1', 'text': opt1Ctrl.text.trim()},
                      {'id': 'opt2', 'text': opt2Ctrl.text.trim()},
                    ],
                    correctOptionIds: [correct],
                    marks: 5,
                  );
                  Navigator.pop(dialogCtx);
                }
              },
              child: const Text('Add Question'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateAssignmentDialog(BuildContext context, InstructorProvider provider) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final instrCtrl = TextEditingController(text: 'Submit your solution via PDF or text link.');
    final marksCtrl = TextEditingController(text: '100');

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Create Assignment'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Assignment Title')),
              const SizedBox(height: 10),
              TextField(controller: descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Description')),
              const SizedBox(height: 10),
              TextField(controller: instrCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Instructions')),
              const SizedBox(height: 10),
              TextField(controller: marksCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Max Marks')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (titleCtrl.text.trim().isNotEmpty) {
                provider.createAssignment(
                  widget.courseId,
                  title: titleCtrl.text.trim(),
                  description: descCtrl.text.trim(),
                  instructions: instrCtrl.text.trim(),
                  maximumMarks: int.tryParse(marksCtrl.text) ?? 100,
                  dueDate: DateTime.now().add(const Duration(days: 7)),
                );
                Navigator.pop(dialogCtx);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
