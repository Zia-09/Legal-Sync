import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:legal_sync/config/routes.dart';
import 'package:legal_sync/utils/onboarding_helper.dart';
import 'package:legal_sync/utils/error_handler.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _animationController.forward();

    // Add a minimum delay of 2.5 seconds to show the splash screen
    Future.delayed(const Duration(milliseconds: 2500), () {
      _route();
    });
  }

  Future<void> _route() async {
    if (_navigated || !mounted) return;

    try {
      final user = FirebaseAuth.instance.currentUser;

      // ── No active session ──────────────────────────────────────────────
      if (user == null) {
        final hasSeenOnboarding = await OnboardingHelper.hasSeen();
        if (!mounted || _navigated) return;
        _navigated = true;
        // First-ever launch  → show onboarding
        // Returned after logout → go straight to login
        Navigator.of(context).pushReplacementNamed(
          hasSeenOnboarding
              ? RouteNames.login
              : RouteNames.onboarding1,
        );
        return;
      }

      // ── Active session: route by role ──────────────────────────────────
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (!mounted || _navigated) return;

        final data = doc.exists ? doc.data() : null;
        final role = data?['role'] as String? ?? 'client';

        _navigated = true;
        if (!mounted) return;

        switch (role) {
          case 'lawyer':
            Navigator.of(
              context,
            ).pushReplacementNamed(RouteNames.lawyerDashboard);
            break;
          case 'admin':
            Navigator.of(
              context,
            ).pushReplacementNamed(RouteNames.adminDashboard);
            break;
          default:
            Navigator.of(context).pushReplacementNamed(RouteNames.clientHome);
        }
      } catch (e) {
        AppLogger.error(
          'Failed to load user data',
          tag: 'SplashScreen',
          error: e,
        );
        if (!mounted || _navigated) return;
        _navigated = true;
        // Fallback to client home on error
        Navigator.of(context).pushReplacementNamed(RouteNames.clientHome);
      }
    } catch (e) {
      AppLogger.error('Routing error', tag: 'SplashScreen', error: e);
      if (!mounted || _navigated) return;
      _navigated = true;
      Navigator.of(context).pushReplacementNamed(RouteNames.onboarding1);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Image.asset(
                      'images/main_icon.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Text(
                  'LegalSync',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0A1931),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Your Legal Partner',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFFE67E22),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 50),
                const CircularProgressIndicator(
                  color: Color(0xFFE67E22),
                  strokeWidth: 3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
