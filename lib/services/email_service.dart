import 'package:cloud_firestore/cloud_firestore.dart';

class EmailService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _mailCollection = 'mail';

  /// 🔹 Trigger a professional login email
  /// This works with the Firebase "Trigger Email" extension.
  Future<void> sendLoginSuccessEmail({
    required String email,
    required String name,
  }) async {
    try {
      await _firestore.collection(_mailCollection).add({
        'to': email,
        'message': {
          'subject': 'Login Successful - LegalSync Elite Services',
          'html':
              '''
            <div style="font-family: Arial, sans-serif; max-width: 600px; margin: auto; padding: 20px; border: 1px solid #eee; border-radius: 10px;">
              <h2 style="color: #FF6B00; text-align: center;">Welcome Back, $name!</h2>
              <p style="font-size: 16px; color: #333;">You have successfully logged into your <strong>LegalSync</strong> account.</p>
              <div style="background-color: #f9f9f9; padding: 15px; border-radius: 5px; margin: 20px 0;">
                <p style="margin: 0; color: #666;"><strong>Account:</strong> $email</p>
                <p style="margin: 5px 0 0 0; color: #666;"><strong>Status:</strong> Active & Professional</p>
              </div>
              <p style="font-size: 14px; color: #777;">If this wasn't you, please secure your account immediately by resetting your password.</p>
              <hr style="border: 0; border-top: 1px solid #eee; margin: 30px 0;" />
              <p style="text-align: center; font-size: 12px; color: #aaa;">&copy; 2026 LegalSync Elite. All Professional Rights Reserved.</p>
            </div>
          ''',
        },
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Warning: Failed to queue login email: $e');
    }
  }

  /// 🔹 Trigger a custom professional email
  Future<void> sendProfessionalEmail({
    required String to,
    required String subject,
    required String htmlContent,
  }) async {
    try {
      await _firestore.collection(_mailCollection).add({
        'to': to,
        'message': {'subject': subject, 'html': htmlContent},
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Warning: Failed to queue email: $e');
    }
  }
}

final emailService = EmailService();
