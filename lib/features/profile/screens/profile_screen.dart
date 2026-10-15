import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/widgets/confirmation_dialog.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/loading_state_widget.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/status_badge.dart';
import '../../auth/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../courses/providers/course_provider.dart';
import '../providers/profile_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().loadFullProfile();
    });
  }

  Future<void> _handleImagePick() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 800,
    );

    if (image != null && mounted) {
      final profileProvider = context.read<ProfileProvider>();
      try {
        await profileProvider.uploadProfileImage(image);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: AppColors.success,
              content: Text('Profile image uploaded successfully!'),
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
            content: Text(
              e is ApiException
                  ? e.message
                  : 'Failed to upload image. Please try again.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _handleDeleteImage() async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Remove Photo',
      message: 'Are you sure you want to remove your profile picture?',
      confirmText: 'Remove',
      confirmColor: AppColors.error,
    );

    if (confirmed && mounted) {
      await context.read<ProfileProvider>().deleteProfileImage();
    }
  }

  void _showEditProfileDialog(BuildContext context, ProfileProvider profileProvider, UserModel? user) {
    if (user == null) return;
    final fNameCtrl = TextEditingController(text: user.firstName);
    final lNameCtrl = TextEditingController(text: user.lastName);
    final bioCtrl = TextEditingController(text: user.bio ?? '');

    final isInstructor = user.isInstructor;
    final isStudent = user.isStudent;

    final instr = profileProvider.instructorProfile;
    final headlineCtrl = TextEditingController(text: instr?.headline ?? '');
    final qualCtrl = TextEditingController(text: instr?.qualification ?? '');
    final expCtrl = TextEditingController(text: (instr?.experienceYears ?? 1).toString());
    final expertiseCtrl = TextEditingController(text: instr?.expertise.join(', ') ?? '');
    final instrBioCtrl = TextEditingController(text: instr?.biography ?? user.bio ?? '');

    final std = profileProvider.studentProfile;
    final eduCtrl = TextEditingController(text: std?.educationLevel ?? 'Undergraduate');
    final goalsCtrl = TextEditingController(text: std?.learningGoals.join(', ') ?? '');

    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: fNameCtrl,
                        decoration: const InputDecoration(labelText: 'First Name', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: lNameCtrl,
                        decoration: const InputDecoration(labelText: 'Last Name', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: bioCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'About / Bio', border: OutlineInputBorder()),
                ),
                if (isInstructor) ...[
                  const SizedBox(height: 16),
                  const Text('Instructor Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: headlineCtrl,
                    decoration: const InputDecoration(labelText: 'Headline', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: qualCtrl,
                    decoration: const InputDecoration(labelText: 'Qualification', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: expCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Experience (Years)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: expertiseCtrl,
                    decoration: const InputDecoration(labelText: 'Expertise (comma-separated)', border: OutlineInputBorder()),
                  ),
                ] else if (isStudent) ...[
                  const SizedBox(height: 16),
                  const Text('Student Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: eduCtrl,
                    decoration: const InputDecoration(labelText: 'Education Level', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: goalsCtrl,
                    decoration: const InputDecoration(labelText: 'Learning Goals (comma-separated)', border: OutlineInputBorder()),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (fNameCtrl.text.trim().isEmpty || lNameCtrl.text.trim().isEmpty) {
                        return;
                      }
                      setDlgState(() => isSubmitting = true);
                      try {
                        await profileProvider.updateUserAccount(
                          firstName: fNameCtrl.text.trim(),
                          lastName: lNameCtrl.text.trim(),
                          bio: bioCtrl.text.trim(),
                        );

                        if (isInstructor) {
                          final expertList = expertiseCtrl.text
                              .split(',')
                              .map((e) => e.trim())
                              .where((e) => e.isNotEmpty)
                              .toList();
                          await profileProvider.updateInstructorProfile(
                            headline: headlineCtrl.text.trim().isNotEmpty ? headlineCtrl.text.trim() : 'Instructor',
                            qualification: qualCtrl.text.trim().isNotEmpty ? qualCtrl.text.trim() : 'Educator',
                            experienceYears: int.tryParse(expCtrl.text.trim()) ?? 1,
                            expertise: expertList.isNotEmpty ? expertList : ['Software Development'],
                            biography: instrBioCtrl.text.trim().isNotEmpty ? instrBioCtrl.text.trim() : bioCtrl.text.trim(),
                          );
                        } else if (isStudent) {
                          final goalsList = goalsCtrl.text
                              .split(',')
                              .map((g) => g.trim())
                              .where((g) => g.isNotEmpty)
                              .toList();
                          await profileProvider.updateStudentProfile(
                            educationLevel: eduCtrl.text.trim().isNotEmpty ? eduCtrl.text.trim() : 'Undergraduate',
                            learningGoals: goalsList.isNotEmpty ? goalsList : ['Flutter Development'],
                          );
                        }

                        if (ctx.mounted) Navigator.pop(dialogCtx);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: AppColors.success,
                              content: Text('Profile updated successfully!'),
                            ),
                          );
                        }
                      } catch (e) {
                        setDlgState(() => isSubmitting = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppColors.error,
                              content: Text(profileProvider.errorMessage ?? 'Failed to update profile: $e'),
                            ),
                          );
                        }
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showChangePasswordDialog() async {
    final currentPassController = TextEditingController();
    final newPassController = TextEditingController();
    final confirmPassController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Change Password', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                label: 'Current Password',
                obscureText: true,
                controller: currentPassController,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                label: 'New Password',
                obscureText: true,
                controller: newPassController,
                validator: (v) => (v == null || v.length < 6) ? 'Min. 6 chars' : null,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                label: 'Confirm New Password',
                obscureText: true,
                controller: confirmPassController,
                validator: (v) => v != newPassController.text ? 'Mismatch' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              // Capture context-sensitive objects BEFORE any async gap
              final messenger = ScaffoldMessenger.of(context);
              final authProvider = context.read<AuthProvider>();
              final navigator = Navigator.of(context);
              try {
                await context.read<ProfileProvider>().changePassword(
                  currentPassword: currentPassController.text,
                  newPassword: newPassController.text,
                  confirmPassword: confirmPassController.text,
                );
                if (ctx.mounted) {
                  Navigator.of(ctx).pop(); // Close the dialog
                }
                // Backend invalidates all tokens after password change.
                // Log out, clear stored tokens, then navigate to login.
                await authProvider.logout();
                messenger.showSnackBar(
                  const SnackBar(
                    backgroundColor: AppColors.success,
                    duration: Duration(seconds: 4),
                    content: Text(
                      '✅ Password changed! Please sign in with your new password.',
                    ),
                  ),
                );
                navigator.pushNamedAndRemoveUntil(
                  AppRoutes.login,
                  (route) => false,
                );

              } catch (e) {
                if (!ctx.mounted) return;
                messenger.showSnackBar(
                  SnackBar(
                    backgroundColor: AppColors.error,
                    duration: const Duration(seconds: 3),
                    content: Text(
                      e is ApiException
                          ? e.message
                          : 'Failed to update password. Please try again.',
                    ),
                  ),
                );
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout(bool allDevices) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: allDevices ? 'Logout All Devices' : 'Logout Session',
      message: allDevices
          ? 'This will terminate all active login sessions across all browsers and devices.'
          : 'Are you sure you want to end your session?',
      confirmText: allDevices ? 'Logout All' : 'Logout',
      confirmColor: AppColors.error,
      icon: Icons.logout_rounded,
    );

    if (confirmed && mounted) {
      final auth = context.read<AuthProvider>();
      if (allDevices) {
        await auth.logoutAll();
      } else {
        await auth.logout();
      }

      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.login,
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();
    final authUser = context.watch<AuthProvider>().currentUser;
    final user = profileProvider.user ?? authUser;
    final isLoading = profileProvider.isLoading;

    if (isLoading && user == null) {
      return const Scaffold(
        body: LoadingStateWidget(message: 'Loading your profile...'),
      );
    }

    final role = user?.role ?? 'STUDENT';
    Color roleColor = AppColors.studentRole;
    if (role == 'INSTRUCTOR') roleColor = AppColors.instructorRole;
    if (role == 'ADMIN') roleColor = AppColors.adminRole;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
            onPressed: () => context.read<ProfileProvider>().loadFullProfile(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Avatar & Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: roleColor.withAlpha(30),
                        backgroundImage: user?.profileImage != null
                            ? NetworkImage(user!.profileImage!)
                            : null,
                        child: user?.profileImage == null
                            ? Text(
                                user != null && user.firstName.isNotEmpty
                                    ? user.firstName[0].toUpperCase()
                                    : 'U',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: roleColor,
                                ),
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _handleImagePick,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.fullName ?? 'User Name',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? 'user@example.com',
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 10),
                  StatusBadge(label: role, color: roleColor),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Edit Profile'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    onPressed: () => _showEditProfileDialog(context, profileProvider, user),
                  ),
                  if (user?.profileImage != null) ...[
                    const SizedBox(height: 10),
                    TextButton.icon(
                      icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.error),
                      label: const Text('Remove Photo', style: TextStyle(color: AppColors.error, fontSize: 12)),
                      onPressed: _handleDeleteImage,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Role Profile Card
            if (role == 'STUDENT' && profileProvider.studentProfile != null)
              _buildStudentProfileCard(profileProvider.studentProfile!)
            else if (role == 'INSTRUCTOR' && profileProvider.instructorProfile != null)
              _buildInstructorProfileCard(profileProvider.instructorProfile!),

            const SizedBox(height: 16),

            // Account Security Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(title: 'Account & Security'),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.lock_outline_rounded, color: AppColors.primary),
                    title: const Text('Change Password', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: _showChangePasswordDialog,
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.devices_outlined, color: AppColors.warning),
                    title: const Text('Sign Out All Devices', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _handleLogout(true),
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.logout_rounded, color: AppColors.error),
                    title: const Text('Logout', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.error)),
                    trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.error),
                    onTap: () => _handleLogout(false),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentProfileCard(dynamic profile) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Student Learning Information'),
          _buildInfoRow('Education Level', profile.educationLevel),
          const SizedBox(height: 8),
          const Text('Learning Goals:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: (profile.learningGoals as List<String>)
                .map((g) => Chip(
                      label: Text(g, style: const TextStyle(fontSize: 11)),
                      backgroundColor: AppColors.studentRole.withAlpha(20),
                      padding: EdgeInsets.zero,
                    ))
                .toList(),
          ),
          const SizedBox(height: 14),
          const Divider(),
          const SizedBox(height: 10),
          Builder(
            builder: (context) {
              final courseProvider = context.watch<CourseProvider>();
              final enrollments = courseProvider.myEnrollments;
              final completed = enrollments.where((e) => e.progressPercentage >= 100).length;
              final inProgress = enrollments.where((e) => e.progressPercentage > 0 && e.progressPercentage < 100).length;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Course Completion Progress:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Column(
                            children: [
                              Text('$completed', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.success)),
                              const Text('Completed', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Column(
                            children: [
                              Text('$inProgress', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                              const Text('In Progress', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.purple.shade200),
                          ),
                          child: Column(
                            children: [
                              Text('${enrollments.length}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.purple)),
                              const Text('Total Enrolled', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInstructorProfileCard(dynamic profile) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Instructor Credentials'),
          _buildInfoRow('Headline', profile.headline),
          _buildInfoRow('Qualification', profile.qualification),
          _buildInfoRow('Experience', '${profile.experienceYears} Years'),
          const SizedBox(height: 8),
          const Text('Expertise:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: (profile.expertise as List<String>)
                .map((e) => Chip(
                      label: Text(e, style: const TextStyle(fontSize: 11)),
                      backgroundColor: AppColors.instructorRole.withAlpha(20),
                      padding: EdgeInsets.zero,
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
