// lib/screens/lawyers/lawyer_profile_screen.dart
import 'package:flutter/material.dart';

class LawyerProfileScreen extends StatelessWidget {
  const LawyerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: Color(0xFFE3F2FD),
              child: Icon(
                Icons.account_balance,
                size: 44,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Hamad Khan",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const Text("Criminal Lawyer"),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    child: const Text("Book Consultation"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    child: const Text("Message"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              "About\n\nI am a dedicated legal professional with over 8 years of experience in criminal and civil law...",
              textAlign: TextAlign.start,
            ),
          ],
        ),
      ),
    );
  }
}
