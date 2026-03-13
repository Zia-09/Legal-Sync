// lib/screens/splash/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:legal_sync/screens/onboarding/onboarding_screen1.dart';
import 'package:legal_sync/widgets/brand_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _goNext();
  }

  Future<void> _goNext() async {
    // ⏳ Just wait 7 seconds
    await Future.delayed(const Duration(seconds: 7));

    if (!mounted) return;

    // 👉 For now always go to Onboarding (UI only)
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const OnboardingPage1()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF1E1E1E), // Same theme color
      body: Center(
        child: BrandLogo(
          fontSize: 38,
          showImage: true,
          imageSize: 150,
          // alignment: MainAxisAlignment.center,
        ),
      ),
    );
  }
}
