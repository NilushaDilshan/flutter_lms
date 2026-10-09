import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  String _selectedRole = 'STUDENT'; // STUDENT or INSTRUCTOR

  // Shared Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Student-specific
  final _dobController = TextEditingController();
  String _educationLevel = 'Undergraduate';
  final _learningGoalsController = TextEditingController();

  // Instructor-specific
  final _headlineController = TextEditingController();
  final _qualificationController = TextEditingController();
  final _experienceYearsController = TextEditingController();
  final _expertiseController = TextEditingController();
  final _bioController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    // Text fields start blank so new users can easily enter their own details
  }

  void _fillDemoStudentData() {
    _firstNameController.text = 'Kamal';
    _lastNameController.text = 'Perera';
    _emailController.text = 'kamal.student@lms.com';
    _passwordController.text = 'Password123!';
    _confirmPasswordController.text = 'Password123!';
  }

  void _fillDemoInstructorData() {
    _firstNameController.text = 'Nimal';
    _lastNameController.text = 'Fernando';
    _emailController.text = 'nimal.instructor@lms.com';
    _passwordController.text = 'Password123!';
    _confirmPasswordController.text = 'Password123!';
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _dobController.dispose();
    _learningGoalsController.dispose();
    _headlineController.dispose();
    _qualificationController.dispose();
    _experienceYearsController.dispose();
    _expertiseController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();

    try {
      if (_selectedRole == 'STUDENT') {
        final goals = _learningGoalsController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();

        await authProvider.registerStudent(
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          email: _emailController.text,
          password: _passwordController.text,
          confirmPassword: _confirmPasswordController.text,
          dateOfBirth: _dobController.text,
          educationLevel: _educationLevel,
          learningGoals: goals.isNotEmpty ? goals : ['Learn Flutter'],
        );
      } else {
        final expertiseList = _expertiseController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();

        await authProvider.registerInstructor(
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          email: _emailController.text,
          password: _passwordController.text,
          confirmPassword: _confirmPasswordController.text,
          headline: _headlineController.text,
          qualification: _qualificationController.text,
          experienceYears: int.tryParse(_experienceYearsController.text) ?? 3,
          expertise: expertiseList.isNotEmpty ? expertiseList : ['Flutter'],
          biography: _bioController.text,
        );
      }

      if (mounted) {
        Navigator.of(context).pushNamed(
          AppRoutes.verifyOtp,
          arguments: {
            'email': _emailController.text.trim(),
            'role': _selectedRole,
          },
        );
      }
    } catch (e) {
      // ── DEMO FALLBACK ─────────────────────────────────────────────────────
      // Backend unavailable (Docker not running). Navigate to OTP screen
      // so the UI flow can still be demonstrated.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
            content: Text(
              '⚠️ Demo Mode: Backend offline. Navigating to OTP screen for demo.',
            ),
          ),
        );
        await Future.delayed(const Duration(milliseconds: 1200));
        if (mounted) {
          Navigator.of(context).pushNamed(
            AppRoutes.verifyOtp,
            arguments: {
              'email': _emailController.text.trim(),
              'role': _selectedRole,
            },
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Create Account'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.bolt_rounded, size: 16, color: AppColors.accent),
            label: const Text('Autofill Demo', style: TextStyle(fontSize: 12, color: AppColors.accent)),
            onPressed: () {
              if (_selectedRole == 'STUDENT') {
                _fillDemoStudentData();
              } else {
                _fillDemoInstructorData();
              }
              setState(() {});
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Role Selector
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      _buildRoleTab('STUDENT', 'Student Account', Icons.school_outlined, AppColors.studentRole),
                      _buildRoleTab('INSTRUCTOR', 'Instructor Account', Icons.co_present_outlined, AppColors.instructorRole),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // First Name & Last Name
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        label: 'First Name',
                        hint: 'Kamal',
                        controller: _firstNameController,
                        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomTextField(
                        label: 'Last Name',
                        hint: 'Perera',
                        controller: _lastNameController,
                        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Email
                CustomTextField(
                  label: AppStrings.email,
                  hint: 'name@example.com',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(Icons.email_outlined, size: 20, color: AppColors.textSecondary),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Enter an email';
                    if (!v.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password
                CustomTextField(
                  label: AppStrings.password,
                  hint: 'Min. 8 characters with symbol',
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  prefixIcon: const Icon(Icons.lock_outline, size: 20, color: AppColors.textSecondary),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter a password';
                    if (v.length < 6) return 'At least 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Confirm Password
                CustomTextField(
                  label: 'Confirm Password',
                  hint: 'Re-enter your password',
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  prefixIcon: const Icon(Icons.lock_outline, size: 20, color: AppColors.textSecondary),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                    onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                  validator: (v) {
                    if (v != _passwordController.text) return 'Passwords do not match';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Role-specific fields
                if (_selectedRole == 'STUDENT') ...[
                  CustomTextField(
                    label: 'Date of Birth (YYYY-MM-DD)',
                    hint: '2002-05-15',
                    controller: _dobController,
                    prefixIcon: const Icon(Icons.calendar_today_outlined, size: 20, color: AppColors.textSecondary),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  const Text('Education Level', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    // ignore: deprecated_member_use
                    value: _educationLevel,
                    decoration: const InputDecoration(),
                    items: const [
                      DropdownMenuItem(value: 'High School', child: Text('High School')),
                      DropdownMenuItem(value: 'Undergraduate', child: Text('Undergraduate')),
                      DropdownMenuItem(value: 'Postgraduate', child: Text('Postgraduate')),
                      DropdownMenuItem(value: 'Professional', child: Text('Professional')),
                    ],
                    onChanged: (val) => setState(() => _educationLevel = val ?? 'Undergraduate'),
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Learning Goals (Comma separated)',
                    hint: 'Learn Flutter, Mobile Apps',
                    controller: _learningGoalsController,
                  ),
                ] else ...[
                  CustomTextField(
                    label: 'Professional Headline',
                    hint: 'Senior Mobile Engineering Lead',
                    controller: _headlineController,
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          label: 'Qualification',
                          hint: 'BSc Software Eng',
                          controller: _qualificationController,
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomTextField(
                          label: 'Years Exp.',
                          hint: '5',
                          controller: _experienceYearsController,
                          keyboardType: TextInputType.number,
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Expertise (Comma separated)',
                    hint: 'Flutter, Dart, Firebase, UI/UX',
                    controller: _expertiseController,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Biography',
                    hint: 'Brief summary of your teaching background',
                    controller: _bioController,
                  ),
                ],
                const SizedBox(height: 28),

                // Register Button
                CustomButton(
                  text: 'Create ${_selectedRole == "STUDENT" ? "Student" : "Instructor"} Account',
                  isLoading: isLoading,
                  backgroundColor: _selectedRole == 'STUDENT' ? AppColors.studentRole : AppColors.instructorRole,
                  onPressed: _handleRegister,
                ),
                const SizedBox(height: 16),

                // Already have account
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account? ', style: TextStyle(color: AppColors.textSecondary)),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Text(
                        'Sign In',
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleTab(String role, String label, IconData icon, Color color) {
    final isSelected = _selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRole = role),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withAlpha(20),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isSelected ? color : AppColors.textMuted),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? color : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
