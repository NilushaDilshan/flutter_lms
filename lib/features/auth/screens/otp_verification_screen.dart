import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../providers/auth_provider.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  final String role;

  const OtpVerificationScreen({
    super.key,
    required this.email,
    this.role = 'STUDENT',
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  int _resendCountdown = 60;
  Timer? _timer;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    setState(() {
      _resendCountdown = 60;
      _canResend = false;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
      } else {
        setState(() => _canResend = true);
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();

    try {
      final success = await authProvider.verifyEmail(
        email: widget.email,
        otp: _otpController.text.trim(),
      );

      if (success && mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: const [
                Icon(Icons.check_circle_rounded, color: AppColors.success, size: 28),
                SizedBox(width: 10),
                Text('Email Verified!'),
              ],
            ),
            content: const Text(
              'Your account has been verified successfully. You can now sign in to your LMS portal.',
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    AppRoutes.login,
                    (route) => false,
                  );
                },
                child: const Text('Proceed to Login'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text(authProvider.errorMessage ?? 'Verification failed. Please check OTP.'),
          ),
        );
      }
    }
  }

  Future<void> _handleResend() async {
    if (!_canResend) return;

    final authProvider = context.read<AuthProvider>();
    try {
      await authProvider.resendVerificationOtp(widget.email);
      _startTimer();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.success,
            content: Text('A fresh verification code has been sent to your email.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text(authProvider.errorMessage ?? 'Failed to resend OTP.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Email Verification'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(20),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.mark_email_read_outlined,
                      size: 56,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Verify Your Email Address',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'We have sent a verification code to\n${widget.email}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 36),

                // OTP Input
                CustomTextField(
                  label: 'Verification Code (OTP)',
                  hint: 'Enter 6-digit code',
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  prefixIcon: const Icon(Icons.pin_outlined, color: AppColors.textSecondary),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Enter the OTP code';
                    if (v.trim().length < 4) return 'Enter complete OTP';
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Verify Button
                CustomButton(
                  text: 'Verify & Activate Account',
                  isLoading: isLoading,
                  onPressed: _handleVerify,
                ),
                const SizedBox(height: 24),

                // Resend Timer
                Center(
                  child: _canResend
                      ? TextButton.icon(
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('Resend Verification Code'),
                          onPressed: _handleResend,
                        )
                      : Text(
                          'Resend code in ${_resendCountdown}s',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
