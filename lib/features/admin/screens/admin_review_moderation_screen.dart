import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/loading_state_widget.dart';
import '../../courses/models/review_model.dart';
import '../providers/admin_provider.dart';

class AdminReviewModerationScreen extends StatefulWidget {
  const AdminReviewModerationScreen({super.key});

  @override
  State<AdminReviewModerationScreen> createState() => _AdminReviewModerationScreenState();
}

class _AdminReviewModerationScreenState extends State<AdminReviewModerationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadAllReviews();
    });
  }

  Future<void> _handleToggleVisibility(ReviewModel review) async {
    final newVisibility = !review.isVisible;
    final provider = context.read<AdminProvider>();
    final success = await provider.toggleReviewVisibility(review.id, newVisibility);

    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: newVisibility ? AppColors.success : Colors.orange.shade800,
          behavior: SnackBarBehavior.floating,
          content: Text(
            newVisibility
                ? 'Review from ${review.studentName} is now visible to the public.'
                : 'Review from ${review.studentName} is now hidden from public view.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final reviews = provider.reviews;

    final visibleCount = reviews.where((r) => r.isVisible).length;
    final hiddenCount = reviews.length - visibleCount;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Review Moderation'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Reviews',
            onPressed: () => provider.loadAllReviews(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Moderation Statistics Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryBadge(Icons.star_rounded, '${reviews.length}', 'Total Reviews', Colors.amber.shade800),
                _buildSummaryBadge(Icons.visibility_outlined, '$visibleCount', 'Publicly Visible', AppColors.success),
                _buildSummaryBadge(Icons.visibility_off_outlined, '$hiddenCount', 'Moderated/Hidden', Colors.red.shade700),
              ],
            ),
          ),
          const Divider(height: 1),

          // Subtitle / Instruction Ribbon
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.blue.shade50,
            child: const Row(
              children: [
                Icon(Icons.shield_outlined, size: 16, color: AppColors.primary),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Hidden reviews are excluded from public course listings and aggregate rating scores.',
                    style: TextStyle(fontSize: 11, color: AppColors.primaryDark),
                  ),
                ),
              ],
            ),
          ),

          // Reviews List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => provider.loadAllReviews(),
              child: provider.isLoading
                  ? const LoadingStateWidget(message: 'Loading reviews for moderation...')
                  : reviews.isEmpty
                      ? EmptyStateWidget(
                          icon: Icons.rate_review_outlined,
                          title: 'No Reviews Submitted',
                          message: 'There are no student course reviews on the platform at this time.',
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: reviews.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final review = reviews[index];
                            return _buildReviewTile(review);
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBadge(IconData icon, String count, String label, Color color) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(count, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color)),
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ],
    );
  }

  Widget _buildReviewTile(ReviewModel review) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 350),
      opacity: review.isVisible ? 1.0 : 0.65,
      child: Card(
        elevation: review.isVisible ? 1 : 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: review.isVisible ? Colors.transparent : Colors.red.shade200,
          ),
        ),
        color: review.isVisible ? Colors.white : Colors.red.shade50.withAlpha(80),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Student Name + Star Rating + Visibility Badge
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.studentRole.withAlpha(25),
                    child: Text(
                      review.studentName.isNotEmpty ? review.studentName[0].toUpperCase() : 'S',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.studentRole, fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          review.studentName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Row(
                          children: [
                            for (int i = 1; i <= 5; i++)
                              Icon(
                                i <= review.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                                color: Colors.amber,
                                size: 14,
                              ),
                            const SizedBox(width: 6),
                            Text(
                              '${review.rating}.0',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Visibility Badge (AnimatedContainer)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: review.isVisible ? Colors.green.shade50 : Colors.red.shade100,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: review.isVisible ? Colors.green.shade300 : Colors.red.shade300,
                      ),
                    ),
                    child: Text(
                      review.isVisible ? 'PUBLIC' : 'HIDDEN',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: review.isVisible ? AppColors.success : AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Review Comment
              Text(
                review.comment.isNotEmpty ? review.comment : '(No written comment provided)',
                style: const TextStyle(fontSize: 13, height: 1.4, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),

              // Bottom Actions: Date and Visibility Toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${review.createdAt.year}-${review.createdAt.month.toString().padLeft(2, '0')}-${review.createdAt.day.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                  ElevatedButton.icon(
                    icon: Icon(
                      review.isVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      size: 15,
                    ),
                    label: Text(
                      review.isVisible ? 'Hide Review' : 'Show Review',
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: review.isVisible ? Colors.orange.shade800 : AppColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () => _handleToggleVisibility(review),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
