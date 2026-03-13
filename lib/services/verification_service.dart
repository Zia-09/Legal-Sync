import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class VerificationService {
  final TextRecognizer _textRecognizer = TextRecognizer();

  /// 🔹 Verifies if the picked image is a valid lawyer identity card.
  /// Checks for keywords like "BAR COUNCIL", "ADVOCATE", "LAWYER", "LICENCE NO".
  Future<bool> verifyLawyerCard(File imageFile) async {
    try {
      final InputImage inputImage = InputImage.fromFile(imageFile);
      final RecognizedText recognizedText = await _textRecognizer.processImage(
        inputImage,
      );

      String text = recognizedText.text.toUpperCase();

      // Define keywords that should be present on a lawyer card
      final List<String> requiredKeywords = [
        'BAR COUNCIL',
        'ADVOCATE',
        'LAWYER',
        'LICENCE NO',
        'MEMBER',
        'ENROLMENT',
      ];

      // Check if at least two of the primary keywords are present
      // We use a threshold because OCR might miss some text depending on quality
      int matchCount = 0;
      for (var keyword in requiredKeywords) {
        if (text.contains(keyword)) {
          matchCount++;
        }
      }

      // If at least 2 key terms are found, we consider it likely a valid card
      return matchCount >= 2;
    } catch (e) {
      print('Verification Error: $e');
      return false;
    }
  }

  void dispose() {
    _textRecognizer.close();
  }
}

final verificationService = VerificationService();
