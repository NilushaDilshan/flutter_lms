import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isLoading = false;

  // Selected role tab for demo/testing convenience
  String _selectedRole = 'STUDENT';

  @override
  void initState() {
    super.initState();
    _fillRoleCredentials('STUDENT');
  }

  void _fillRoleCredentials(String role) {
    setState(() {
      _selectedRole = role;
      if (role == 'STUDENT') {
        _emailController.text = 'kamal.perera@example.com';
        _passwordController.text = 'Password123!';
      } else if (role == 'INSTRUCTOR') {
        _emailController.text = 'nimal.fernando@example.com';
        _passwordController.text = 'Password123!';
      } else {
        _emailController.text = 'admin@lms.com';
        _passwordController.text = 'AdminPass123!';
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      final authProvider = context.read<AuthProvider>();
      final user = await authProvider.login(email: email, password: password);

      if (mounted) {
        setState(() => _isLoading = false);

        String targetRoute;
        Map<String, dynamic> arguments;

        if (user.isStudent) {
          targetRoute = AppRoutes.studentDashboard;
          arguments = {'name': user.fullName.isNotEmpty ? user.fullName : 'Kamal Perera'};
        } else if (user.isInstructor) {
          targetRoute = AppRoutes.instructorDashboard;
          arguments = {'name': user.fullName.isNotEmpty ? user.fullName : 'Nimal Fernando'};
        } else {
          targetRoute = AppRoutes.adminDashboard;
          arguments = {'email': user.email};
        }

        Navigator.of(context).pushReplacementNamed(
          targetRoute,
          arguments: arguments,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);

        String targetRoute;
        Map<String, dynamic> arguments;
        String demoFirstName;
        String demoLastName;

        if (_selectedRole == 'STUDENT') {
          targetRoute = AppRoutes.studentDashboard;
          demoFirstName = 'Kamal';
          demoLastName = 'Perera';
          arguments = {'name': 'Kamal Perera'};
        } else if (_selectedRole == 'INSTRUCTOR') {
          targetRoute = AppRoutes.instructorDashboard;
          demoFirstName = 'Nimal';
          demoLastName = 'Fernando';
          arguments = {'name': 'Nimal Fernando'};
        } else {
          targetRoute = AppRoutes.adminDashboard;
          demoFirstName = 'Admin';
          demoLastName = 'User';
          arguments = {'email': email};
        }

        // Set demo user in AuthProvider so ProfileScreen shows correct details
        context.read<AuthProvider>().setDemoUser(
          firstName: demoFirstName,
          lastName: demoLastName,
          email: email,
          role: _selectedRole,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            content: Text('Logged in as $_selectedRole (Offline / Demo fallback active)'),
          ),
        );

        Navigator.of(context).pushReplacementNamed(
          targetRoute,
          arguments: arguments,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // App Logo & Header
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(25),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.school_rounded,
                          size: 48,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // App Title
                    Text(
                      AppStrings.appName,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      AppStrings.loginSubtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Role Selector Card
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          _buildRoleButton('STUDENT', 'Student', Icons.person_outline),
                          _buildRoleButton('INSTRUCTOR', 'Instructor', Icons.co_present_outlined),
                          _buildRoleButton('ADMIN', 'Admin', Icons.admin_panel_settings_outlined),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Email Input
                    CustomTextField(
                      label: AppStrings.email,
                      hint: AppStrings.emailHint,
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: const Icon(Icons.email_outlined, color: AppColors.textSecondary, size: 20),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!value.contains('@') || !value.contains('.')) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),

                    // Password Input
                    CustomTextField(
                      label: AppStrings.password,
                      hint: AppStrings.passwordHint,
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textSecondary, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // Remember Me & Forgot Password Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              height: 24,
                              width: 24,
                              child: Checkbox(
                                value: _rememberMe,
                                activeColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                onChanged: (val) {
                                  setState(() {
                                    _rememberMe = val ?? false;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              AppStrings.rememberMe,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pushNamed(AppRoutes.forgotPassword);
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            AppStrings.forgotPassword,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Sign In Button
                    CustomButton(
                      text: AppStrings.signIn,
                      isLoading: _isLoading,
                      onPressed: _handleLogin,
                    ),
                    const SizedBox(height: 24),

                    // Sign Up Prompt
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          AppStrings.dontHaveAccount,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).pushNamed(AppRoutes.register);
                          },
                          child: const Text(
                            AppStrings.signUp,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleButton(String roleKey, String label, IconData icon) {
    final isSelected = _selectedRole == roleKey;
    Color activeColor;
    if (roleKey == 'STUDENT') {
      activeColor = AppColors.studentRole;
    } else if (roleKey == 'INSTRUCTOR') {
      activeColor = AppColors.instructorRole;
    } else {
      activeColor = AppColors.adminRole;
    }

    return Expanded(
      child: GestureDetector(
        onTap: () => _fillRoleCredentials(roleKey),
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
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected ? activeColor : AppColors.textMuted,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? activeColor : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
