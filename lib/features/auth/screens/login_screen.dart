import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/api/api_exception.dart';
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

        // Determine destination route based on authenticated user's role
        final targetRoute = _getRouteForRole(user.role);
        final arguments = _getArgumentsForRole(user.role, user.fullName, user.email);

        Navigator.of(context).pushReplacementNamed(
          targetRoute,
          arguments: arguments,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);

        // Backend rejected login because email is not verified (403 EMAIL_NOT_VERIFIED)
        final isEmailNotVerified = e is ApiException &&
            e.statusCode == 403 &&
            e.message.toLowerCase().contains('verify');

        if (isEmailNotVerified) {
          // Redirect to OTP verification so user can verify email then log in
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              content: Text(
                '📧 Please verify your email first. Enter the OTP sent to your inbox.',
              ),
            ),
          );
          Navigator.of(context).pushNamed(
            AppRoutes.verifyOtp,
            arguments: {
              'email': email,
              'role': 'STUDENT',
            },
          );
          return;
        }

        // Real server authentication rejection (wrong password, suspended account)
        final isAuthRejection = e is ApiException && e.statusCode == 401;

        if (!isAuthRejection) {
          // Offline / Demo fallback: Determine role based on email address
          final inferredRole = _inferRoleFromEmail(email);
          final names = _getDemoNamesForRole(inferredRole);
          final targetRoute = _getRouteForRole(inferredRole);
          final arguments = _getArgumentsForRole(
            inferredRole,
            '${names[0]} ${names[1]}',
            email,
          );

          context.read<AuthProvider>().setDemoUser(
            firstName: names[0],
            lastName: names[1],
            email: email,
            role: inferredRole,
          );

          Navigator.of(context).pushReplacementNamed(
            targetRoute,
            arguments: arguments,
          );
        } else {
          // Real server error (e.g. wrong password)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              content: Text(
                // isAuthRejection = (e is ApiException && e.statusCode == 401)
                // so e is already promoted to ApiException here
                (e as dynamic).message as String? ?? 'Login failed. Please check your credentials.',
              ),
            ),
          );
        }
      }
    }
  }

  String _inferRoleFromEmail(String email) {
    final lower = email.toLowerCase();
    if (lower.contains('admin')) {
      return 'ADMIN';
    } else if (lower.contains('instructor') ||
        lower.contains('teacher') ||
        lower.contains('nimal')) {
      return 'INSTRUCTOR';
    }
    return 'STUDENT';
  }

  List<String> _getDemoNamesForRole(String role) {
    switch (role) {
      case 'ADMIN':
        return ['Admin', 'User'];
      case 'INSTRUCTOR':
        return ['Nimal', 'Fernando'];
      case 'STUDENT':
      default:
        return ['Kamal', 'Perera'];
    }
  }

  String _getRouteForRole(String role) {
    switch (role.toUpperCase()) {
      case 'ADMIN':
        return AppRoutes.adminDashboard;
      case 'INSTRUCTOR':
        return AppRoutes.instructorDashboard;
      case 'STUDENT':
      default:
        return AppRoutes.studentDashboard;
    }
  }

  Map<String, dynamic> _getArgumentsForRole(
    String role,
    String fullName,
    String email,
  ) {
    switch (role.toUpperCase()) {
      case 'ADMIN':
        return {'email': email};
      case 'INSTRUCTOR':
        return {'name': fullName.isNotEmpty ? fullName : 'Instructor'};
      case 'STUDENT':
      default:
        return {'name': fullName.isNotEmpty ? fullName : 'Student'};
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
                    const SizedBox(height: 32),

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
}
