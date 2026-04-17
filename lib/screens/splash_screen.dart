// lib/screens/splash/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:legal_sync/widgets/brand_logo.dart';
import 'package:legal_sync/config/routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _pulseController;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _logoSlide;
  late Animation<double> _pulseScale;

  @override
  void initState() {
    super.initState();

    // Logo entrance animation
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );
    _logoSlide = Tween<double>(begin: 40.0, end: 0.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutCubic),
    );

    // Subtle pulse after entrance
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _pulseScale = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _logoController.forward().then((_) {
      if (mounted) _pulseController.repeat(reverse: true);
    });

    _goNext();
  }

  @override
  void dispose() {
    _logoController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _goNext() async {
    // ⏳ Wait for logo animation + navigation check
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    // 🔍 Check authentication status
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // ❌ Not authenticated → Go to Onboarding
      context.navigateAndReplace(RouteNames.onboarding1);
    } else {
      // ✅ Authenticated → Check if first time user
      try {
        final uid = user.uid;
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();

        if (userDoc.exists) {
          final isFirstTime = userDoc.data()?['isFirstTimeUser'] ?? true;

          if (!mounted) return;

          if (isFirstTime) {
            // 👉 First time → Show Onboarding
            context.navigateAndReplace(RouteNames.onboarding1);
          } else {
            // 👉 Returning user → Go directly to Home
            context.navigateAndReplace(RouteNames.clientHome);
          }
        } else {
          // User doc doesn't exist → Go to Onboarding
          context.navigateAndReplace(RouteNames.onboarding1);
        }
      } catch (e) {
        // Error checking user status → Go to Home (safe default)
        if (!mounted) return;
        context.navigateAndReplace(RouteNames.clientHome);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: Stack(
        children: [
          // Radial ambient glow background
          Center(
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFF6B00).withAlpha(40),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Centered animated logo
          Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([_logoController, _pulseController]),
              builder: (context, child) {
                return Opacity(
                  opacity: _logoOpacity.value,
                  child: Transform.translate(
                    offset: Offset(0, _logoSlide.value),
                    child: ScaleTransition(
                      scale: _pulseController.isAnimating
                          ? _pulseScale
                          : _logoScale,
                      child: child,
                    ),
                  ),
                );
              },
              child: const BrandLogo(
                fontSize: 38,
                showImage: true,
                imageSize: 150,
              ),
            ),
          ),
          // Loading dots at bottom
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: _AnimatedLoadingDots(),
          ),
        ],
      ),
    );
  }
}

/// Animated dot loader
class _AnimatedLoadingDots extends StatefulWidget {
  @override
  State<_AnimatedLoadingDots> createState() => _AnimatedLoadingDotsState();
}

class _AnimatedLoadingDotsState extends State<_AnimatedLoadingDots>
    with TickerProviderStateMixin {
  final List<AnimationController> _controllers = [];
  final List<Animation<double>> _animations = [];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 3; i++) {
      final ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      );
      _controllers.add(ctrl);
      _animations.add(
        Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(parent: ctrl, curve: Curves.easeInOut)),
      );
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) ctrl.repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _animations[i],
          builder: (_, _) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color.lerp(
                  const Color(0xFFFF6B00).withAlpha(80),
                  const Color(0xFFFF6B00),
                  _animations[i].value,
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
