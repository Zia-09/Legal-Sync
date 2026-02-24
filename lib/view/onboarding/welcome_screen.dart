import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),

      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),

          const Text(
            "Welcome to\nLegalSync",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),

          const SizedBox(height: 16),

          const Text(
            "Find trusted lawyers and make smarter legal decisions powered by AI",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 18, height: 1.4),
          ),

          const Spacer(flex: 3),

          Image.asset(
            'images/welcome.png',
            height: 340,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.gavel, size: 120, color: Colors.white70),
          ),

          const Spacer(flex: 5),
        ],
      ),
    );
  }
}
