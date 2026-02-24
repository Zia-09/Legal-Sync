// lib/screens/splash/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:legal_sync/view/onboarding/onboarding_screen1.dart';

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
    await Future.delayed(const Duration(seconds: 7));

    if (!mounted) return;

    // 👉 For now always go to Onboarding (UI only)
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const OnboardingScreen1()),
    );

    // 🔁 Later you can change to:
    // Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E), // Same theme color
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset("images/logo.png", width: 250),
                const SizedBox(height: 4),
                const Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: "Legal",
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 38,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      TextSpan(
                        text: "Sync",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 38,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),

            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
