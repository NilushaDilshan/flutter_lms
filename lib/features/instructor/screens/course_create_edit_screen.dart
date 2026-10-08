import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../courses/models/course_model.dart';
import '../providers/instructor_provider.dart';

class CourseCreateEditScreen extends StatefulWidget {
  final CourseModel? courseToEdit;

  const CourseCreateEditScreen({super.key, this.courseToEdit});

  @override
  State<CourseCreateEditScreen> createState() => _CourseCreateEditScreenState();
}

class _CourseCreateEditScreenState extends State<CourseCreateEditScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _shortDescController;
  late TextEditingController _descController;
  late TextEditingController _languageController;

  final TextEditingController _outcomeController = TextEditingController();
  final TextEditingController _requirementController = TextEditingController();

  String? _selectedCategoryId;
  String _selectedLevel = 'BEGINNER';

  final List<String> _learningOutcomes = [];
  final List<String> _requirements = [];
  final List<String> _targetAudience = [];

  bool get isEditing => widget.courseToEdit != null;

  @override
  void initState() {
    super.initState();
    final c = widget.courseToEdit;
    _titleController = TextEditingController(text: c?.title ?? '');
    _shortDescController = TextEditingController(text: c?.shortDescription ?? '');
    _descController = TextEditingController(text: c?.description ?? '');
    _languageController = TextEditingController(text: c?.language ?? 'English');

    _selectedLevel = c != null ? c.level : 'BEGINNER';
    _selectedCategoryId = c?.categoryId;

    if (c != null) {
      _learningOutcomes.addAll(c.learningOutcomes);
      _requirements.addAll(c.requirements);
      _targetAudience.add('Students & professionals aiming to master modern development');
    } else {
      _learningOutcomes.addAll([
        'Build complete production-grade applications',
        'Master responsive UI and clean architecture',
      ]);
      _requirements.addAll([
        'Basic programming knowledge',
        'A computer with Flutter installed',
      ]);
      _targetAudience.addAll([
        'Beginner and intermediate developers',
      ]);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<InstructorProvider>();
      if (provider.categories.isEmpty) {
        provider.loadCategories();
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _shortDescController.dispose();
    _descController.dispose();
    _languageController.dispose();
    _outcomeController.dispose();
    _requirementController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<InstructorProvider>();
    final catId = _selectedCategoryId ??
        (provider.categories.isNotEmpty ? provider.categories.first.id : 'cat-mobile');

    if (isEditing) {
      final success = await provider.updateCourse(widget.courseToEdit!.id, {
        'title': _titleController.text.trim(),
        'shortDescription': _shortDescController.text.trim(),
        'description': _descController.text.trim(),
        'level': _selectedLevel,
        'language': _languageController.text.trim(),
        'categoryId': catId,
      });

      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Course updated successfully!'), backgroundColor: AppColors.success),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Failed to update course'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } else {
      final created = await provider.createCourse(
        categoryId: catId,
        title: _titleController.text.trim(),
        shortDescription: _shortDescController.text.trim(),
        description: _descController.text.trim(),
        level: _selectedLevel,
        language: _languageController.text.trim(),
        requirements: _requirements,
        learningOutcomes: _learningOutcomes,
        targetAudience: _targetAudience,
      );

      if (!mounted) return;
      if (created != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Course draft created successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, created);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Failed to create course'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InstructorProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Course Details' : 'Create New Course'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (provider.errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.error.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.error.withAlpha(80)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          provider.errorMessage!,
                          style: const TextStyle(color: AppColors.error, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),

              // Title Field
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Course Title',
                  hintText: 'e.g. Master Modern Flutter & Dart',
                  prefixIcon: const Icon(Icons.title, color: AppColors.primary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                validator: (val) {
                  if (val == null || val.trim().length < 3) {
                    return 'Title must be at least 3 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Category & Level Row
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedCategoryId ??
                          (provider.categories.isNotEmpty ? provider.categories.first.id : null),
                      decoration: InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                      items: provider.categories.map((c) {
                        return DropdownMenuItem<String>(
                          value: c.id,
                          child: Text(c.name, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedCategoryId = val),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedLevel,
                      decoration: InputDecoration(
                        labelText: 'Difficulty Level',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'BEGINNER', child: Text('Beginner')),
                        DropdownMenuItem(value: 'INTERMEDIATE', child: Text('Intermediate')),
                        DropdownMenuItem(value: 'ADVANCED', child: Text('Advanced')),
                        DropdownMenuItem(value: 'ALL_LEVELS', child: Text('All Levels')),
                      ],
                      onChanged: (val) => setState(() => _selectedLevel = val ?? 'BEGINNER'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Language Field
              TextFormField(
                controller: _languageController,
                decoration: InputDecoration(
                  labelText: 'Course Language',
                  hintText: 'e.g. English, Sinhala',
                  prefixIcon: const Icon(Icons.language, color: AppColors.primary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Language is required';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Short Description
              TextFormField(
                controller: _shortDescController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Short Summary',
                  hintText: 'Brief summary displayed on cards (10-250 characters)',
                  prefixIcon: const Icon(Icons.short_text, color: AppColors.primary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                validator: (val) {
                  if (val == null || val.trim().length < 10) {
                    return 'Short summary must be at least 10 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Full Description
              TextFormField(
                controller: _descController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Full Description',
                  hintText: 'Detailed course description and overview (min 20 characters)',
                  prefixIcon: const Icon(Icons.description_outlined, color: AppColors.primary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                validator: (val) {
                  if (val == null || val.trim().length < 20) {
                    return 'Full description must be at least 20 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Learning Outcomes Chip Section
              _buildListSection(
                title: 'Learning Outcomes 🎯',
                subtitle: 'What will students learn in this course?',
                items: _learningOutcomes,
                controller: _outcomeController,
                onAdd: (text) {
                  if (text.trim().isNotEmpty) {
                    setState(() {
                      _learningOutcomes.add(text.trim());
                      _outcomeController.clear();
                    });
                  }
                },
                onDelete: (index) {
                  setState(() => _learningOutcomes.removeAt(index));
                },
              ),
              const SizedBox(height: 20),

              // Requirements Section
              _buildListSection(
                title: 'Course Requirements 📋',
                subtitle: 'Prerequisites needed before taking this course',
                items: _requirements,
                controller: _requirementController,
                onAdd: (text) {
                  if (text.trim().isNotEmpty) {
                    setState(() {
                      _requirements.add(text.trim());
                      _requirementController.clear();
                    });
                  }
                },
                onDelete: (index) {
                  setState(() => _requirements.removeAt(index));
                },
              ),
              const SizedBox(height: 24),

              // Submit Button
              CustomButton(
                text: isEditing ? 'Save Changes' : 'Create Course Draft',
                isLoading: provider.isSaving,
                icon: Icon(isEditing ? Icons.check_circle_outline : Icons.add_circle_outline, color: Colors.white, size: 20),
                onPressed: _handleSubmit,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListSection({
    required String title,
    required String subtitle,
    required List<String> items,
    required TextEditingController controller,
    required ValueChanged<String> onAdd,
    required ValueChanged<int> onDelete,
  }) {
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
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: 'Add an item...',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onSubmitted: onAdd,
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                icon: const Icon(Icons.add, size: 20),
                onPressed: () => onAdd(controller.text),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: items.asMap().entries.map((entry) {
              return Chip(
                label: Text(entry.value, style: const TextStyle(fontSize: 12)),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () => onDelete(entry.key),
                backgroundColor: AppColors.primary.withAlpha(20),
                side: BorderSide.none,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
