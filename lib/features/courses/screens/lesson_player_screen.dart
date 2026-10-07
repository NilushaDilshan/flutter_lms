import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../models/lesson_model.dart';
import '../providers/course_provider.dart';

class LessonPlayerScreen extends StatefulWidget {
  final String courseId;
  final LessonModel lesson;

  const LessonPlayerScreen({
    super.key,
    required this.courseId,
    required this.lesson,
  });

  @override
  State<LessonPlayerScreen> createState() => _LessonPlayerScreenState();
}

class _LessonPlayerScreenState extends State<LessonPlayerScreen> {
  late LessonModel _currentLesson;
  bool _isPlayingVideo = false;
  double _videoProgress = 0.25;

  @override
  void initState() {
    super.initState();
    _currentLesson = widget.lesson;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CourseProvider>().startLesson(_currentLesson.id);
    });
  }

  Future<void> _handleCompleteLesson() async {
    final provider = context.read<CourseProvider>();
    final success = await provider.completeLesson(_currentLesson.id, widget.courseId);

    if (mounted) {
      if (success) {
        setState(() {
          _currentLesson = _currentLesson.copyWith(isCompleted: true);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.success,
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Lesson marked as completed! 🎉'),
              ],
            ),
          ),
        );
      }
    }
  }

  void _navigateToNextLesson() {
    final sections = context.read<CourseProvider>().sections;
    final allLessons = sections.expand((s) => s.lessons).toList();
    final currentIndex = allLessons.indexWhere((l) => l.id == _currentLesson.id);

    if (currentIndex != -1 && currentIndex + 1 < allLessons.length) {
      final next = allLessons[currentIndex + 1];
      setState(() {
        _currentLesson = next;
        _isPlayingVideo = false;
        _videoProgress = 0.0;
      });
      context.read<CourseProvider>().startLesson(next.id);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🎉 You reached the end of the course curriculum!')),
      );
    }
  }

  void _navigateToPreviousLesson() {
    final sections = context.read<CourseProvider>().sections;
    final allLessons = sections.expand((s) => s.lessons).toList();
    final currentIndex = allLessons.indexWhere((l) => l.id == _currentLesson.id);

    if (currentIndex > 0) {
      final prev = allLessons[currentIndex - 1];
      setState(() {
        _currentLesson = prev;
        _isPlayingVideo = false;
        _videoProgress = 0.0;
      });
      context.read<CourseProvider>().startLesson(prev.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isActionLoading = context.watch<CourseProvider>().isActionLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_currentLesson.title, style: const TextStyle(fontSize: 15)),
        actions: [
          if (_currentLesson.isCompleted)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Icon(Icons.check_circle, color: AppColors.success),
            ),
        ],
      ),
      body: Column(
        children: [
          // Dynamic Lesson Viewer by LessonType
          if (_currentLesson.isVideo)
            _buildVideoPlayerWidget()
          else if (_currentLesson.isDocument)
            _buildDocumentViewerWidget()
          else
            _buildTextArticleHeader(),

          // Scrollable Lesson Body & Controls
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Lesson Title & Type Badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getTypeColor(_currentLesson.lessonType).withAlpha(30),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _currentLesson.lessonType.name.toUpperCase(),
                          style: TextStyle(
                            color: _getTypeColor(_currentLesson.lessonType),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (_currentLesson.durationMinutes > 0) ...[
                        const SizedBox(width: 10),
                        Text(
                          '${_currentLesson.durationMinutes} minutes',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ],
                      const Spacer(),
                      if (_currentLesson.isCompleted)
                        const Chip(
                          label: Text('Completed', style: TextStyle(color: Colors.white, fontSize: 11)),
                          backgroundColor: AppColors.success,
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Text(
                    _currentLesson.title,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),

                  if (_currentLesson.description != null && _currentLesson.description!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      _currentLesson.description!,
                      style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
                    ),
                  ],

                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Content Body
                  if (_currentLesson.isText)
                    _buildTextArticleBody()
                  else if (_currentLesson.isDocument)
                    _buildDocumentActions()
                  else
                    _buildVideoDetails(),

                  const SizedBox(height: 32),

                  // Complete Lesson Action Button
                  if (!_currentLesson.isCompleted)
                    CustomButton(
                      text: 'Mark Lesson as Completed',
                      isLoading: isActionLoading,
                      backgroundColor: AppColors.success,
                      icon: const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                      onPressed: _handleCompleteLesson,
                    ),

                  const SizedBox(height: 16),

                  // Next / Previous Navigation
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.arrow_back, size: 16),
                          label: const Text('Previous'),
                          onPressed: _navigateToPreviousLesson,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.arrow_forward, size: 16),
                          label: const Text('Next Lesson'),
                          onPressed: _navigateToNextLesson,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(LessonType type) {
    switch (type) {
      case LessonType.video:
        return Colors.red.shade700;
      case LessonType.document:
        return Colors.deepPurple;
      case LessonType.text:
        return Colors.teal;
    }
  }

  // ── VIDEO PLAYER WIDGET ───────────────────────────────────────────────────
  Widget _buildVideoPlayerWidget() {
    return Container(
      height: 220,
      width: double.infinity,
      color: Colors.black,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Video background graphic
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [Colors.grey.shade900, Colors.black],
                radius: 0.8,
              ),
            ),
            child: const Center(
              child: Icon(Icons.movie_creation_outlined, size: 54, color: Colors.white24),
            ),
          ),

          // Big Play/Pause Button
          IconButton(
            iconSize: 64,
            icon: Icon(
              _isPlayingVideo ? Icons.pause_circle_filled : Icons.play_circle_fill,
              color: Colors.white.withAlpha(220),
            ),
            onPressed: () {
              setState(() => _isPlayingVideo = !_isPlayingVideo);
            },
          ),

          // Video Controls Overlay (Bottom)
          Positioned(
            left: 12,
            right: 12,
            bottom: 8,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    trackHeight: 3,
                    thumbColor: AppColors.primary,
                    activeTrackColor: AppColors.primary,
                    inactiveTrackColor: Colors.white30,
                  ),
                  child: Slider(
                    value: _videoProgress,
                    onChanged: (val) {
                      setState(() => _videoProgress = val);
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatVideoTime((_videoProgress * 600).round()),
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                      Row(
                        children: [
                          const Text('10:00', style: TextStyle(color: Colors.white70, fontSize: 11)),
                          const SizedBox(width: 10),
                          Icon(
                            _isPlayingVideo ? Icons.volume_up : Icons.volume_off,
                            color: Colors.white70,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.fullscreen, color: Colors.white70, size: 20),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatVideoTime(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Widget _buildVideoDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Video Stream Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          Text(
            _currentLesson.videoUrl != null && _currentLesson.videoUrl!.isNotEmpty
                ? 'Source: ${_currentLesson.videoUrl}'
                : 'Interactive LMS Video Stream (Quality: 1080p HD)',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  // ── DOCUMENT VIEWER WIDGET ────────────────────────────────────────────────
  Widget _buildDocumentViewerWidget() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      color: Colors.deepPurple.shade900,
      width: double.infinity,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.picture_as_pdf, color: Colors.white, size: 48),
          ),
          const SizedBox(height: 12),
          Text(
            _currentLesson.documentName ?? 'Course Document / Resource',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          const Text(
            'PDF Document • Ready for Reading & Download',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Course Reading Material', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),
          const Text(
            'This lesson includes supplementary documentation and reference material. Review the content thoroughly before proceeding.',
            style: TextStyle(fontSize: 13, height: 1.4, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: const Text('Download PDF'),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Downloading ${_currentLesson.documentName ?? "document"}...'),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text('Open'),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Opening document in built-in PDF viewer...')),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── TEXT ARTICLE WIDGET ───────────────────────────────────────────────────
  Widget _buildTextArticleHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      color: Colors.teal.shade700,
      width: double.infinity,
      child: const Row(
        children: [
          Icon(Icons.menu_book_rounded, color: Colors.white, size: 28),
          SizedBox(width: 12),
          Text(
            'Reading Material & Notes',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildTextArticleBody() {
    final text = _currentLesson.textContent ?? 'No text content available for this lesson.';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              height: 1.7,
              color: AppColors.textPrimary,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
