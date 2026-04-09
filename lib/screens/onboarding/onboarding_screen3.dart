import 'package:flutter/material.dart';
import 'package:legal_sync/config/routes.dart';

class OnboardingPage3 extends StatelessWidget {
  const OnboardingPage3({super.key});

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => context.goBack(),
          child: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.black87,
              size: 18,
            ),
          ),
        ),
        title: const Text(
          'Onboarding 3',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
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
                  "Private, Secure,\nConfidential.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  "Chat safely with your lawyer. Your data stays encrypted and protected.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    height: 1.4,
                  ),
                ),
              ),
              Spacer(flex: 3),

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
                  backgroundImage: AssetImage('images/onbaording2.png'),
                ),
              ),

              const Spacer(),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32.0,
                  vertical: 24.0,
                ),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          context.navigateTo(RouteNames.login);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFB800), // yellowish
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "Get started",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
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
