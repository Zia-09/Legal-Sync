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
