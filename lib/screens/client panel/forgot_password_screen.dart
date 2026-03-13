import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legal_sync/provider/auth_provider.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await ref
          .read(authNotifierProvider.notifier)
          .forgotPassword(email: _emailController.text.trim());

      if (!mounted) return;
      setState(() => _emailSent = true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState is AsyncLoading;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF7F9FC);
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? const Color(0xFF9E9E9E) : Colors.grey.shade600;
    final labelColor = isDark ? const Color(0xFFCCCCCC) : Colors.grey.shade700;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: scaffoldBg,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
        elevation: 0,
        title: Text(
          'Forgot Password',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: _emailSent
            ? _buildSuccessView(textColor, subtitleColor)
            : _buildFormView(isLoading, textColor, subtitleColor, labelColor, isDark),
      ),
    );
  }

  Widget _buildFormView(bool isLoading, Color textColor, Color subtitleColor, Color labelColor, bool isDark) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reset Your Password',
            style: TextStyle(
              color: textColor,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter your registered email and we\'ll send you a password reset link.',
            style: TextStyle(
              color: subtitleColor,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),

          Text(
            'Email Address',
            style: TextStyle(
              color: labelColor,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: TextStyle(color: textColor),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Please enter your email';
              }
              if (!RegExp(
                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
              ).hasMatch(v.trim())) {
                return 'Enter a valid email address';
              }
              return null;
            },
            decoration: _inputDecoration(isDark),
          ),
          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: isLoading ? null : _sendResetEmail,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B00),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(
                  0xFFFF6B00,
                ).withValues(alpha: 0.6),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Text(
                      'Send Reset Link',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Back to Login',
                style: TextStyle(
                  color: Color(0xFFFF6B00),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView(Color textColor, Color subtitleColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF16A34A).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.mark_email_read_outlined,
              color: Color(0xFF16A34A),
              size: 40,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Email Sent!',
            style: TextStyle(
              color: textColor,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'A password reset link has been sent to\n${_emailController.text.trim()}',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: subtitleColor,
              fontSize: 14,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please check your inbox (and spam folder).',
            textAlign: TextAlign.center,
            style: TextStyle(color: subtitleColor, fontSize: 13),
          ),
          const SizedBox(height: 36),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B00),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Back to Login',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(bool isDark) {
    final borderSide = BorderSide(color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade300);
    final radius = BorderRadius.circular(12);
    return InputDecoration(
      hintText: 'Enter your registered email',
      hintStyle: TextStyle(color: isDark ? const Color(0xFF5A5A5A) : Colors.grey.shade400),
      prefixIcon: Icon(
        Icons.email_outlined,
        color: isDark ? const Color(0xFF9E9E9E) : Colors.grey.shade500,
        size: 20,
      ),
      filled: true,
      fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      border: OutlineInputBorder(borderRadius: radius, borderSide: borderSide),
      enabledBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: borderSide,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: Color(0xFFFF6B00), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: Color(0xFFDC2626)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
      ),
      errorStyle: const TextStyle(color: Color(0xFFDC2626)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
