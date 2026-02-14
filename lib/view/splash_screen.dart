// lib/screens/splash/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:legal_sync/view/onboarding/onboarding_screen.dart';

// import '../home/home_screen.dart'; // You can switch later if you want

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
    // ⏳ Just wait 5 seconds
    await Future.delayed(const Duration(seconds: 5));

    if (!mounted) return;

    // 👉 For now always go to Onboarding (UI only)
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
    );

    // 🔁 Later you can change to:
    // Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1C2D), // Same theme color
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo
            Image.asset("assets/images/logo.png", width: 140, height: 140),
            const SizedBox(height: 20),
            const Text(
              "LegalSync",
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Smart Legal Solutions",
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
