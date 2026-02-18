// lib/screens/auth/signup_screen.dart
import 'package:flutter/material.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: ListView(
          children: [
            const SizedBox(height: 40),
            const Text(
              "Sign Up",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const TextField(
              decoration: InputDecoration(labelText: "First name"),
            ),
            const SizedBox(height: 12),
            const TextField(
              decoration: InputDecoration(labelText: "Last name"),
            ),
            const SizedBox(height: 12),
            const TextField(decoration: InputDecoration(labelText: "Email")),
            const SizedBox(height: 12),
            const TextField(
              decoration: InputDecoration(labelText: "Phone number"),
            ),
            const SizedBox(height: 12),
            const TextField(
              obscureText: true,
              decoration: InputDecoration(labelText: "Password"),
            ),
            const SizedBox(height: 12),
            const TextField(
              obscureText: true,
              decoration: InputDecoration(labelText: "Confirm password"),
            ),
            const SizedBox(height: 30),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  // 👉 CALL YOUR SIGNUP FUNCTION HERE
                },
                child: const Text("Register"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
