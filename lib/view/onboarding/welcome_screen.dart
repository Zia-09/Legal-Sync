// lib/screens/auth/welcome_screen.dart
import 'package:flutter/material.dart';
import 'package:legal_sync/view/auth/login_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Spacer(),
            const Icon(Icons.gavel_rounded, size: 140, color: Colors.black87),
            const SizedBox(height: 30),
            const Text(
              "Welcome to LegalSync",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "Find trusted lawyers, book consultations, and track your case updates in one place.",
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                child: const Text("Get started"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
