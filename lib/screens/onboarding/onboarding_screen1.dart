import 'package:flutter/material.dart';
import 'package:legal_sync/screens/onboarding/onboarding_screen2.dart';
import 'package:legal_sync/screens/onboarding/onboarding_screen3.dart';

class OnboardingPage1 extends StatelessWidget {
  const OnboardingPage1({super.key});

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          /// Bottom Black Background
          Container(color: Colors.black),

          /// Top White Section with Bottom Curve
          ClipPath(
            clipper: BottomCurveClipper(),
            child: Container(
              height: height * 0.6,
              decoration: const BoxDecoration(color: Colors.white),
            ),
          ),

          /// Main Content
          Column(
            children: [
              SizedBox(height: height * 0.12),

              /// Title
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  "Verified Lawyers.\nReal Expertise",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  "Discover experienced lawyers you can trust — all verified and reviewed for you.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 17,
                    height: 1.4,
                  ),
                ),
              ),

              const Spacer(),

              /// Center Image (Half in White, Half in Black)
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black45,
                      blurRadius: 25,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const CircleAvatar(
                  radius: 135,
                  backgroundImage: AssetImage('images/welcome.png'),
                ),
              ),

              const Spacer(),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32.0,
                  vertical: 30.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const OnboardingPage3(),
                          ),
                        );
                      },
                      child: const Text(
                        "Skip",
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const OnboardingPage2(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFB800),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                      ),
                      child: const Text(
                        "Next",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Bottom Curve Clipper
class BottomCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();

    path.lineTo(0, size.height - 100);

    path.quadraticBezierTo(
      size.width / 2,
      size.height + 80,
      size.width,
      size.height - 100,
    );

    path.lineTo(size.width, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
}
