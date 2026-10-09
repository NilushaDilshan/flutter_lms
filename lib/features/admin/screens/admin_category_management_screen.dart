import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/confirmation_dialog.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/loading_state_widget.dart';
import '../../courses/models/category_model.dart';
import '../providers/admin_provider.dart';

class AdminCategoryManagementScreen extends StatefulWidget {
  const AdminCategoryManagementScreen({super.key});

  @override
  State<AdminCategoryManagementScreen> createState() => _AdminCategoryManagementScreenState();
}

class _AdminCategoryManagementScreenState extends State<AdminCategoryManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadCategories();
    });
  }

  void _showCategoryDialog({CategoryModel? category}) {
    final isEditing = category != null;
    final nameController = TextEditingController(text: category?.name ?? '');
    final slugController = TextEditingController(text: category?.slug ?? '');
    final descController = TextEditingController(text: category?.description ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isEditing ? 'Edit Category' : 'Create New Category'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Category Name *',
                    hintText: 'e.g. Mobile Development',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Category name is required';
                    return null;
                  },
                  onChanged: (val) {
                    if (!isEditing) {
                      slugController.text = val.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: slugController,
                  decoration: const InputDecoration(
                    labelText: 'Slug *',
                    hintText: 'e.g. mobile-development',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Slug is required';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                    hintText: 'Brief summary of courses in this category...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                final messenger = ScaffoldMessenger.of(context);
                Navigator.of(ctx).pop();
                final provider = context.read<AdminProvider>();
                bool ok;
                if (isEditing) {
                  ok = await provider.updateCategory(
                    category.id,
                    name: nameController.text.trim(),
                    slug: slugController.text.trim(),
                    description: descController.text.trim(),
                  );
                } else {
                  ok = await provider.createCategory(
                    name: nameController.text.trim(),
                    slug: slugController.text.trim(),
                    description: descController.text.trim(),
                  );
                }
                if (mounted && ok) {
                  messenger.showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.success,
                      content: Text(
                        isEditing
                            ? 'Category updated successfully!'
                            : 'Category created successfully!',
                      ),
                    ),
                  );
                }
              }
            },
            child: Text(isEditing ? 'Save Changes' : 'Create Category'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleToggleStatus(CategoryModel category, bool newStatus) async {
    if (!newStatus) {
      final confirmed = await ConfirmationDialog.show(
        context,
        title: 'Deactivate Category',
        message: 'Deactivating "${category.name}" will hide it from public course category filters. Existing courses in this category will remain accessible.',
        confirmText: 'Deactivate',
        confirmColor: Colors.orange.shade800,
        icon: Icons.visibility_off_outlined,
      );
      if (!confirmed) return;
    }

    if (mounted) {
      final provider = context.read<AdminProvider>();
      final success = await provider.toggleCategoryStatus(category.id, newStatus);
      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: newStatus ? AppColors.success : Colors.orange.shade800,
            content: Text(
              '"${category.name}" is now ${newStatus ? "active" : "inactive"}.',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final categories = provider.categories;

    final activeCount = categories.where((c) => c.isActive).length;
    final inactiveCount = categories.length - activeCount;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Course Categories'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Categories',
            onPressed: () => provider.loadCategories(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Category', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => _showCategoryDialog(),
      ),
      body: Column(
        children: [
          // Summary Ribbon
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryBadge(Icons.grid_view_rounded, '${categories.length}', 'Total', AppColors.primary),
                _buildSummaryBadge(Icons.check_circle_outline, '$activeCount', 'Active', AppColors.success),
                _buildSummaryBadge(Icons.visibility_off_outlined, '$inactiveCount', 'Inactive', Colors.orange.shade800),
              ],
            ),
          ),
          const Divider(height: 1),

          // Categories List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => provider.loadCategories(),
              child: provider.isLoading
                  ? const LoadingStateWidget(message: 'Loading categories...')
                  : categories.isEmpty
                      ? EmptyStateWidget(
                          icon: Icons.category_outlined,
                          title: 'No Categories Available',
                          message: 'Create a course category to organize learning modules and curriculum.',
                          actionText: 'Create Category',
                          onAction: () => _showCategoryDialog(),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                          itemCount: categories.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final cat = categories[index];
                            return _buildCategoryCard(cat);
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
        Icon(icon, size: 18, color: color),
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

  Widget _buildCategoryCard(CategoryModel cat) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Icon Badge
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (cat.isActive ? AppColors.secondary : Colors.grey).withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.folder_outlined,
                color: cat.isActive ? AppColors.secondary : Colors.grey,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),

            // Category Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          cat.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: cat.isActive ? AppColors.textPrimary : AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Animated Status Switch (Day 9 AnimatedContainer feature)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: cat.isActive ? Colors.green.shade50 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: cat.isActive ? Colors.green.shade300 : Colors.grey.shade300,
                          ),
                        ),
                        child: Text(
                          cat.isActive ? 'ACTIVE' : 'INACTIVE',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: cat.isActive ? AppColors.success : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Slug: ${cat.slug}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                  if (cat.description != null && cat.description!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      cat.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
                    ),
                  ],
                  const SizedBox(height: 10),

                  // Actions Row: Edit & Status Switch
                  Row(
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.edit_outlined, size: 14),
                        label: const Text('Edit', style: TextStyle(fontSize: 11)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () => _showCategoryDialog(category: cat),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Text(
                            cat.isActive ? 'Active' : 'Hidden',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: cat.isActive ? AppColors.success : Colors.grey,
                            ),
                          ),
                          Switch(
                            value: cat.isActive,
                            // ignore: deprecated_member_use
                            activeColor: AppColors.success,
                            onChanged: (val) => _handleToggleStatus(cat, val),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
