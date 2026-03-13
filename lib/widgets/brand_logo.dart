import 'package:flutter/material.dart';

class BrandLogo extends StatelessWidget {
  final double fontSize;
  final bool showImage;
  final double imageSize;
  final MainAxisAlignment alignment;

  const BrandLogo({
    super.key,
    this.fontSize = 24,
    this.showImage = false,
    this.imageSize = 40,
    this.alignment = MainAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final syncColor = isDark ? Colors.white : Colors.black87;

    if (!showImage) {
      return RichText(
        text: TextSpan(
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
          children: [
            const TextSpan(
              text: 'Legal',
              style: TextStyle(color: Color(0xFFDC2626)), // Red
            ),
            TextSpan(
              text: 'Sync',
              style: TextStyle(color: syncColor),
            ),
          ],
        ),
      );
    }

    // With image - use Row for horizontal spacing
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset('images/logo.png', width: imageSize, height: imageSize),
        const SizedBox(width: 12),
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
            children: [
              const TextSpan(
                text: 'Legal',
                style: TextStyle(color: Color(0xFFDC2626)), // Red
              ),
              TextSpan(
                text: 'Sync',
                style: TextStyle(color: syncColor),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
