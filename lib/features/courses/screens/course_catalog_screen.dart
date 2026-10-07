import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/loading_state_widget.dart';
import '../providers/course_provider.dart';
import '../widgets/course_card.dart';

class CourseCatalogScreen extends StatefulWidget {
  const CourseCatalogScreen({super.key});

  @override
  State<CourseCatalogScreen> createState() => _CourseCatalogScreenState();
}

class _CourseCatalogScreenState extends State<CourseCatalogScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<CourseProvider>();
      provider.loadCategories();
      provider.loadCourses();
      provider.loadMyEnrollments();
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final provider = context.read<CourseProvider>();
      if (provider.hasNextPage && !provider.isLoadingMore) {
        provider.loadMoreCourses();
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final courseProvider = context.watch<CourseProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Explore Courses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_outline),
            tooltip: 'My Enrolled Courses',
            onPressed: () {
              Navigator.of(context).pushNamed(AppRoutes.myCourses);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await courseProvider.loadCategories();
          await courseProvider.loadCourses();
          await courseProvider.loadMyEnrollments();
        },
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Search Bar Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search courses, topics, skills...',
                    prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              courseProvider.setSearchQuery('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  onChanged: (val) => courseProvider.setSearchQuery(val),
                ),
              ),
            ),

            // Category Chips Row
            SliverToBoxAdapter(
              child: _buildCategoryChips(courseProvider),
            ),

            // Level Filter Row
            SliverToBoxAdapter(
              child: _buildLevelFilter(courseProvider),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // Courses List or Empty/Loading State
            if (courseProvider.isLoading)
              const SliverFillRemaining(
                child: LoadingStateWidget(message: 'Loading courses...'),
              )
            else if (courseProvider.courses.isEmpty)
              SliverFillRemaining(
                child: EmptyStateWidget(
                  title: 'No Courses Found',
                  message: 'No courses match your search or filter criteria. Try clearing filters.',
                  actionText: 'Reset Filters',
                  onAction: () {
                    _searchController.clear();
                    courseProvider.setSearchQuery('');
                    courseProvider.setCategoryFilter(null);
                    courseProvider.setLevelFilter(null);
                  },
                ),
              )
            else ...[
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final course = courseProvider.courses[index];
                      final isEnrolled = courseProvider.isEnrolled(course.id);
                      return CourseCard(
                        course: course,
                        isEnrolled: isEnrolled,
                        onTap: () {
                          Navigator.of(context).pushNamed(
                            AppRoutes.courseDetail,
                            arguments: {'courseId': course.id, 'title': course.title},
                          );
                        },
                      );
                    },
                    childCount: courseProvider.courses.length,
                  ),
                ),
              ),
              if (courseProvider.isLoadingMore)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChips(CourseProvider provider) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: provider.categories.length + 1,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            final isSelected = provider.selectedCategoryId == null;
            return ChoiceChip(
              label: const Text('All Categories'),
              selected: isSelected,
              onSelected: (_) => provider.setCategoryFilter(null),
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            );
          }

          final cat = provider.categories[index - 1];
          final isSelected = provider.selectedCategoryId == cat.id;

          return ChoiceChip(
            label: Text(cat.name),
            selected: isSelected,
            onSelected: (_) => provider.setCategoryFilter(cat.id),
            selectedColor: AppColors.primary,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : AppColors.textPrimary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          );
        },
      ),
    );
  }

  Widget _buildLevelFilter(CourseProvider provider) {
    final levels = ['BEGINNER', 'INTERMEDIATE', 'ADVANCED'];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          const Text(
            'Level:',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildLevelChip('All', null, provider),
                  for (final lvl in levels)
                    _buildLevelChip(lvl[0] + lvl.substring(1).toLowerCase(), lvl, provider),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelChip(String label, String? levelValue, CourseProvider provider) {
    final isSelected = provider.selectedLevel == levelValue;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => provider.setLevelFilter(levelValue),
        selectedColor: AppColors.primary.withAlpha(40),
        checkmarkColor: AppColors.primary,
        labelStyle: TextStyle(
          fontSize: 12,
          color: isSelected ? AppColors.primary : AppColors.textSecondary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),
    );
  }
}
