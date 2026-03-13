import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legal_sync/provider/auth_provider.dart';
import 'package:legal_sync/screens/client%20panel/forgot_password_screen.dart';
import 'package:legal_sync/screens/client%20panel/home_screen.dart';
import 'package:legal_sync/screens/client%20panel/register_screen.dart';
import 'package:legal_sync/widgets/brand_logo.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      final role = await ref
          .read(authNotifierProvider.notifier)
          .login(email: email, password: password);

      if (!mounted) return;

      // ─── Role Validation: Client Portal Only ────────────────────────────────
      if (role != 'client') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: role == 'lawyer'
                ? const Text(
                    'This account is registered as a lawyer. Please use the lawyer login portal instead.',
                  )
                : const Text(
                    'This account is not registered as a client. Please use the correct login portal.',
                  ),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
        return; // Don't proceed with navigation
      }
      // ────────────────────────────────────────────────────────────────────────

      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));

      if (!mounted) return;

      // 🔹 Professional Success Feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Authentication Successful',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Welcome back to LegalSync elite services.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Image
            Stack(
              children: [
                SizedBox(
                  height: 300,
                  width: double.infinity,
                  child: Image.asset(
                    'images/login-screen.png',
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, scaffoldBg],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 40,
                  left: 10,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
                  ),
                ),
              ],
            ),

            // Form
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    const BrandLogo(
                      fontSize: 32,
                      alignment: MainAxisAlignment.start,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Welcome Back',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sign in to continue your legal journey',
                      style: TextStyle(color: subtitleColor, fontSize: 14),
                    ),
                    const SizedBox(height: 28),

                    // Email
                    _fieldLabel('Email Address', labelColor),
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
                          return 'Please enter a valid email address';
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
                        if (v == null || v.isEmpty) {
                          return 'Please enter your password';
                        }
                        if (v.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                      decoration: _inputDecoration(
                        hint: 'Enter your password',
                        icon: Icons.lock_outline,
                        isDark: isDark,
                        suffixIcon: IconButton(
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
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
                    const SizedBox(height: 10),

                    // Forgot Password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ForgotPasswordScreen(),
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(
                            color: Color(0xFFFF6B00),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Login Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _login,
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
                                'Login',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.3,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Register link
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: TextStyle(
                              color: subtitleColor,
                              fontSize: 14,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RegisterScreen(),
                              ),
                            ),
                            child: const Text(
                              'Register',
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
          ],
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
