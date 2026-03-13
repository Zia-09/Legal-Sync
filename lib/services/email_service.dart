import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EmailService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _mailCollection = 'mail';

  /// 🔹 Send Login Success Email via Resend
  Future<void> sendLoginSuccessEmail({
    required String email,
    required String name,
  }) async {
    try {
      await _supabase.functions.invoke(
        'send-email',
        body: {
          'to': email,
          'subject': 'Login Successful - LegalSync Elite Services',
          'html':
              '''
            <div style="font-family: Arial, sans-serif; max-width: 600px; margin: auto; padding: 20px; border: 1px solid #eee; border-radius: 10px; background: white;">
              <div style="text-align: center; margin-bottom: 30px;">
                <h2 style="color: #FF6B00; margin: 0;">Welcome Back, $name!</h2>
              </div>
              
              <p style="font-size: 16px; color: #333;">You have successfully logged into your <strong>LegalSync</strong> account.</p>
              
              <div style="background-color: #f9f9f9; padding: 15px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #FF6B00;">
                <p style="margin: 0; color: #666;"><strong>Account:</strong> $email</p>
                <p style="margin: 10px 0 0 0; color: #666;"><strong>Status:</strong> ✓ Active & Professional</p>
              </div>
              
              <p style="font-size: 14px; color: #777;">If this wasn't you, please <a href="#" style="color: #FF6B00; text-decoration: none;"><strong>secure your account</strong></a> immediately.</p>
              
              <hr style="border: 0; border-top: 1px solid #eee; margin: 30px 0;" />
              <p style="text-align: center; font-size: 12px; color: #aaa;">&copy; 2026 LegalSync Elite. All Professional Rights Reserved.</p>
            </div>
          ''',
        },
      );
      print('✅ Login email sent to $email');
    } catch (e) {
      print('❌ Failed to send login email: $e');
    }
  }

  /// 🔹 Send Welcome Email (Registration) via Resend
  Future<void> sendWelcomeEmail({
    required String email,
    required String name,
    required String role,
  }) async {
    try {
      final isLawyer = role == 'lawyer';
      final subject = isLawyer
          ? 'Welcome to LegalSync - Lawyer Dashboard'
          : 'Welcome to LegalSync - Find Your Perfect Lawyer';

      await _supabase.functions.invoke(
        'send-email',
        body: {
          'to': email,
          'subject': subject,
          'html':
              '''
            <div style="font-family: Arial, sans-serif; max-width: 600px; margin: auto; padding: 20px; border: 1px solid #eee; border-radius: 10px; background: white;">
              <div style="text-align: center; margin-bottom: 30px;">
                <h2 style="color: #FF6B00; margin: 0;">🎉 Welcome to LegalSync!</h2>
              </div>
              
              <p style="font-size: 16px; color: #333;">Hi <strong>$name</strong>,</p>
              <p style="color: #666; line-height: 1.6;">Your account has been successfully created. We're thrilled to have you on board as a ${isLawyer ? 'professional lawyer' : 'valued client'}.</p>
              
              <div style="background: linear-gradient(135deg, #FF6B00 0%, #FF8C42 100%); color: white; padding: 20px; border-radius: 8px; margin: 20px 0; text-align: center;">
                <h3 style="margin: 0 0 10px 0;">Get Started Today</h3>
                <p style="margin: 0; font-size: 14px;">${isLawyer ? 'Complete your profile and start accepting cases' : 'Browse lawyers and discover your perfect legal match'}</p>
              </div>
              
              <div style="background-color: #f9f9f9; padding: 15px; border-radius: 8px; margin: 20px 0;">
                <p style="margin: 0; color: #333;"><strong>Email:</strong> $email</p>
                <p style="margin: 10px 0 0 0; color: #333;"><strong>Role:</strong> ${isLawyer ? '⚖️ Lawyer' : '👤 Client'}</p>
              </div>
              
              <p style="color: #666; font-size: 14px;">If you have any questions, our support team is here to help!</p>
              
              <hr style="border: 0; border-top: 1px solid #eee; margin: 30px 0;" />
              <p style="text-align: center; font-size: 12px; color: #aaa;">&copy; 2026 LegalSync Elite. Excellence in legal management.</p>
            </div>
          ''',
        },
      );
      print('✅ Welcome email sent to $email');
    } catch (e) {
      print('❌ Failed to send welcome email: $e');
    }
  }

  /// 🔹 Send Hearing Scheduled Email via Resend
  Future<void> sendHearingScheduledEmail({
    required String toEmail,
    required String recipientName,
    required String caseTitle,
    required String hearingDate,
    required String hearingTime,
    required String hearingType,
    required String location,
    required String lawyerName,
    required String clientName,
    bool isForLawyer = false,
  }) async {
    try {
      final subject = isForLawyer
          ? '⚖️ Hearing Confirmed - $hearingDate'
          : '📅 Your Hearing is Scheduled - $hearingDate';

      final recipientRole = isForLawyer ? 'Lawyer' : 'Client';

      await _supabase.functions.invoke(
        'send-email',
        body: {
          'to': toEmail,
          'subject': subject,
          'html':
              '''
            <div style="font-family: Arial, sans-serif; max-width: 600px; margin: auto; padding: 20px; border: 1px solid #eee; border-radius: 10px; background: white;">
              <div style="text-align: center; margin-bottom: 30px;">
                <h2 style="color: #FF6B00; margin: 0;">⚖️ Hearing Scheduled</h2>
                <p style="color: #666; margin: 10px 0 0 0; font-size: 14px;">$recipientRole Confirmation</p>
              </div>
              
              <p style="font-size: 16px; color: #333;">Hi <strong>$recipientName</strong>,</p>
              <p style="color: #666; line-height: 1.6;">A hearing has been scheduled for your case. Please see the details below:</p>
              
              <div style="background: white; border: 2px solid #FF6B00; border-radius: 8px; padding: 20px; margin: 20px 0;">
                <h3 style="color: #FF6B00; margin: 0 0 15px 0; border-bottom: 2px solid #FF6B00; padding-bottom: 10px;">Hearing Details</h3>
                
                <table style="width: 100%; border-collapse: collapse;">
                  <tr style="border-bottom: 1px solid #eee;">
                    <td style="padding: 10px 0; color: #666; font-weight: bold;">Case:</td>
                    <td style="padding: 10px 0; color: #333;">$caseTitle</td>
                  </tr>
                  <tr style="border-bottom: 1px solid #eee;">
                    <td style="padding: 10px 0; color: #666; font-weight: bold;">📅 Date:</td>
                    <td style="padding: 10px 0; color: #333; font-size: 16px; font-weight: bold;">$hearingDate</td>
                  </tr>
                  <tr style="border-bottom: 1px solid #eee;">
                    <td style="padding: 10px 0; color: #666; font-weight: bold;">⏰ Time:</td>
                    <td style="padding: 10px 0; color: #333; font-size: 16px; font-weight: bold;">$hearingTime</td>
                  </tr>
                  <tr style="border-bottom: 1px solid #eee;">
                    <td style="padding: 10px 0; color: #666; font-weight: bold;">Type:</td>
                    <td style="padding: 10px 0; color: #333;">$hearingType</td>
                  </tr>
                  <tr>
                    <td style="padding: 10px 0; color: #666; font-weight: bold;">📍 Location:</td>
                    <td style="padding: 10px 0; color: #333;">$location</td>
                  </tr>
                </table>
              </div>
              
              <div style="background-color: #f0f9ff; padding: 15px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #FF6B00;">
                <h4 style="color: #FF6B00; margin: 0 0 10px 0;">📋 Parties Involved</h4>
                <p style="margin: 0; color: #333;"><strong>Lawyer:</strong> $lawyerName</p>
                <p style="margin: 10px 0 0 0; color: #333;"><strong>Client:</strong> $clientName</p>
              </div>
              
              ${isForLawyer ? '''
              <div style="background-color: #fff3cd; padding: 15px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #FF6B00;">
                <h4 style="color: #FF6B00; margin: 0 0 10px 0;">✓ Checklist</h4>
                <ul style="margin: 0; padding-left: 20px; color: #333;">
                  <li>Review case documents</li>
                  <li>Prepare legal arguments</li>
                  <li>Confirm client availability</li>
                  <li>Arrange transportation if needed</li>
                </ul>
              </div>
              ''' : '''
              <div style="background-color: #e8f5e9; padding: 15px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #FF6B00;">
                <h4 style="color: #FF6B00; margin: 0 0 10px 0;">💡 Preparation Tips</h4>
                <ul style="margin: 0; padding-left: 20px; color: #333;">
                  <li>Mark this date on your calendar</li>
                  <li>Prepare required documents</li>
                  <li>Contact your lawyer a day before</li>
                  <li>Arrive 15 minutes early</li>
                </ul>
              </div>
              '''}
              
              <p style="color: #666; font-size: 14px; margin-top: 20px;">For any questions, please contact your legal team or our support.</p>
              
              <hr style="border: 0; border-top: 1px solid #eee; margin: 30px 0;" />
              <p style="text-align: center; font-size: 12px; color: #aaa;">&copy; 2026 LegalSync Elite. Serving justice with excellence.</p>
            </div>
          ''',
        },
      );
      print('✅ Hearing email sent to $toEmail');
    } catch (e) {
      print('❌ Failed to send hearing email: $e');
    }
  }

  /// 🔹 Send Custom Professional Email via Resend
  Future<void> sendProfessionalEmail({
    required String to,
    required String subject,
    required String htmlContent,
  }) async {
    try {
      await _supabase.functions.invoke(
        'send-email',
        body: {'to': to, 'subject': subject, 'html': htmlContent},
      );
      print('✅ Professional email sent to $to');
    } catch (e) {
      print('❌ Failed to send professional email: $e');
    }
  }

  /// 🔹 Send Scheduled Professional Email via Resend or Firebase
  /// Note: Resend doesn't support scheduling, so we queue it with Firebase
  Future<void> sendScheduledProfessionalEmail({
    required String to,
    required String subject,
    required String htmlContent,
    required DateTime scheduledAt,
  }) async {
    try {
      // First try Resend (it will send immediately)
      await _supabase.functions.invoke(
        'send-email',
        body: {'to': to, 'subject': subject, 'html': htmlContent},
      );
      print('✅ Scheduled email sent immediately to $to');
    } catch (e) {
      print('⚠️ Resend failed for scheduled email, trying Firebase: $e');
      // Fallback to Firebase with scheduling
      try {
        await _firestore.collection(_mailCollection).add({
          'to': to,
          'message': {'subject': subject, 'html': htmlContent},
          'delivery': {
            'startTime': Timestamp.fromDate(scheduledAt),
            'state': 'PENDING',
          },
          'createdAt': FieldValue.serverTimestamp(),
        });
        print('✅ Email queued in Firebase with scheduling');
      } catch (firebaseError) {
        print('❌ Failed to queue Firebase email: $firebaseError');
      }
    }
  }

  /// 🔹 Trigger Traditional Firebase Email (Fallback)
  Future<void> sendViaFirebase({
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
      print('✅ Email queued in Firebase');
    } catch (e) {
      print('❌ Failed to queue Firebase email: $e');
    }
  }
}

final emailService = EmailService();
