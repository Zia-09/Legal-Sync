import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legal_sync/provider/auth_provider.dart';
import 'package:legal_sync/screens/client%20panel/home_screen.dart';
import 'package:legal_sync/services/email_service.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final email = _emailController.text.trim();
      final name = _nameController.text.trim();

      await ref
          .read(authNotifierProvider.notifier)
          .registerClient(
            name: name,
            phone: _phoneController.text.trim(),
            email: email,
            password: _passwordController.text,
          );

      // ✅ Send welcome email via Resend
      await emailService.sendWelcomeEmail(
        email: email,
        name: name,
        role: 'client',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created successfully! Welcome to LegalSync.'),
          backgroundColor: Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
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
          'Create Account',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Join LegalSync',
                style: TextStyle(
                  color: textColor,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Create your client account in seconds.',
                style: TextStyle(color: subtitleColor, fontSize: 14),
              ),
              const SizedBox(height: 28),

              // Full Name
              _fieldLabel('Full Name', labelColor),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                style: TextStyle(color: textColor),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                decoration: _inputDecoration(
                  hint: 'Enter your full name',
                  icon: Icons.person_outline,
                  isDark: isDark,
                ),
              ),
              const SizedBox(height: 16),

              // Phone
              _fieldLabel('Phone Number', labelColor),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: TextStyle(color: textColor),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Phone number is required';
                  }
                  if (v.trim().length < 10) {
                    return 'Enter a valid phone number';
                  }
                  return null;
                },
                decoration: _inputDecoration(
                  hint: 'Enter your phone number',
                  icon: Icons.phone_outlined,
                  isDark: isDark,
                ),
              ),
              const SizedBox(height: 16),

              // Email
              _fieldLabel('Email Address', labelColor),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(color: textColor),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Email is required';
                  }
                  if (!RegExp(
                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                  ).hasMatch(v.trim())) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
                decoration: _inputDecoration(
                  hint: 'Enter your email',
                  icon: Icons.email_outlined,
                  isDark: isDark,
                ),
              ),
              const SizedBox(height: 16),

              // Password
              _fieldLabel('Password', labelColor),
              const SizedBox(height: 8),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: TextStyle(color: textColor),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Password is required';
                  if (v.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
                decoration: _inputDecoration(
                  hint: 'Create a password',
                  icon: Icons.lock_outline,
                  isDark: isDark,
                  suffixIcon: IconButton(
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: subtitleColor,
                      size: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Confirm Password
              _fieldLabel('Confirm Password', labelColor),
              const SizedBox(height: 8),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirm,
                style: TextStyle(color: textColor),
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'Please confirm your password';
                  }
                  if (v != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
                decoration: _inputDecoration(
                  hint: 'Re-enter your password',
                  icon: Icons.lock_outline,
                  isDark: isDark,
                  suffixIcon: IconButton(
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                    icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: subtitleColor,
                      size: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Register Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _register,
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
                          'Create Account',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // Back to Login
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: TextStyle(color: subtitleColor, fontSize: 14),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text(
                        'Login',
                        style: TextStyle(
                          color: Color(0xFFFF6B00),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String label, Color color) => Text(
    label,
    style: TextStyle(
      color: color,
      fontSize: 13,
      fontWeight: FontWeight.w500,
    ),
  );

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    required bool isDark,
    Widget? suffixIcon,
  }) {
    final borderSide = BorderSide(color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade300);
    final radius = BorderRadius.circular(12);
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: isDark ? const Color(0xFF5A5A5A) : Colors.grey.shade400),
      prefixIcon: Icon(icon, color: isDark ? const Color(0xFF9E9E9E) : Colors.grey.shade500, size: 20),
      suffixIcon: suffixIcon,
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
