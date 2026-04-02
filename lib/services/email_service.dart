import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Email Service for LegalSync
/// Sends emails via Supabase Edge Function and Resend API
class EmailService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _mailCollection = 'mail';

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // NEW: Configuration Constants for Edge Function
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  static const String _supabaseProjectRef = 'agzqautnshxgactnthxx';
  static const String _supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFnenFhdXRuc2h4Z2FjdG50aHh4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI1NDk3MTYsImV4cCI6MjA4ODEyNTcxNn0.fi_GSGQCFzP5Ki7qI_1VnJ2oPPRYMhIHIVA9krJmSrE';
  static const String _edgeFunctionUrl =
      'https://$_supabaseProjectRef.supabase.co/functions/v1/send-email';

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Base Email Method
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// Base method to send emails
  /// Returns true if email was sent successfully, false otherwise
  static Future<bool> sendEmail({
    required String to,
    required String subject,
    required String type,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_edgeFunctionUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_supabaseAnonKey',
        },
        body: jsonEncode({
          'to': to,
          'subject': subject,
          'type': type,
          'data': data,
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['success'] == true) {
          print('✅ Email sent successfully to $to');
          return true;
        }
      }

      print('❌ Failed to send email: ${response.statusCode}');
      return false;
    } catch (e) {
      print('❌ Error sending email: $e');
      return false;
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Specific Email Methods
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// Send welcome email when lawyer adds a new client
  static Future<bool> sendWelcome({
    required String clientEmail,
    required String clientName,
    required String lawyerName,
    required String caseRef,
  }) async {
    return sendEmail(
      to: clientEmail,
      subject: 'Welcome to LegalSync',
      type: 'welcome',
      data: {
        'clientName': clientName,
        'lawyerName': lawyerName,
        'caseRef': caseRef,
      },
    );
  }

  /// Send hearing scheduled email
  static Future<bool> sendHearingScheduled({
    required String recipientEmail,
    required String clientName,
    required String lawyerName,
    required String caseTitle,
    required String date,
    required String time,
    required String court,
  }) async {
    return sendEmail(
      to: recipientEmail,
      subject: 'Hearing Scheduled — $date',
      type: 'hearing_scheduled',
      data: {
        'clientName': clientName,
        'lawyerName': lawyerName,
        'caseTitle': caseTitle,
        'date': date,
        'time': time,
        'court': court,
      },
    );
  }

  /// Send hearing reminder email (day before hearing)
  static Future<bool> sendHearingReminder({
    required String recipientEmail,
    required String clientName,
    required String lawyerName,
    required String date,
    required String time,
    required String court,
  }) async {
    return sendEmail(
      to: recipientEmail,
      subject: 'Reminder — Hearing Tomorrow',
      type: 'hearing_reminder',
      data: {
        'clientName': clientName,
        'lawyerName': lawyerName,
        'date': date,
        'time': time,
        'court': court,
      },
    );
  }

  /// Send case update email
  static Future<bool> sendCaseUpdate({
    required String recipientEmail,
    required String clientName,
    required String lawyerName,
    required String caseTitle,
    required String updateText,
  }) async {
    return sendEmail(
      to: recipientEmail,
      subject: 'Case Update — $caseTitle',
      type: 'case_update',
      data: {
        'clientName': clientName,
        'lawyerName': lawyerName,
        'caseTitle': caseTitle,
        'updateText': updateText,
      },
    );
  }

  /// Send document shared email
  static Future<bool> sendDocumentShared({
    required String recipientEmail,
    required String clientName,
    required String lawyerName,
    required String documentName,
  }) async {
    return sendEmail(
      to: recipientEmail,
      subject: 'New Document Shared',
      type: 'document_shared',
      data: {
        'clientName': clientName,
        'lawyerName': lawyerName,
        'documentName': documentName,
      },
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // LEGACY METHODS (Existing Code Compatibility)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// Send Login Success Email
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
          'html': _generateLoginSuccessHtml(email, name),
        },
      );
      print('✅ Login email sent to $email');
    } catch (e) {
      print('❌ Failed to send login email: $e');
    }
  }

  /// Send Welcome Email (Registration)
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
          'html': _generateWelcomeHtml(email, name, isLawyer),
        },
      );
      print('✅ Welcome email sent to $email');
    } catch (e) {
      print('❌ Failed to send welcome email: $e');
    }
  }

  /// Send Hearing Scheduled Email
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

      await _supabase.functions.invoke(
        'send-email',
        body: {
          'to': toEmail,
          'subject': subject,
          'html': _generateHearingScheduledHtml(
            recipientName,
            caseTitle,
            hearingDate,
            hearingTime,
            hearingType,
            location,
            lawyerName,
            clientName,
            isForLawyer,
          ),
        },
      );
      print('✅ Hearing email sent to $toEmail');
    } catch (e) {
      print('❌ Failed to send hearing email: $e');
    }
  }

  /// Send Custom Professional Email
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

  /// Send Scheduled Professional Email
  Future<void> sendScheduledProfessionalEmail({
    required String to,
    required String subject,
    required String htmlContent,
    required DateTime scheduledAt,
  }) async {
    try {
      await _supabase.functions.invoke(
        'send-email',
        body: {'to': to, 'subject': subject, 'html': htmlContent},
      );
      print('✅ Scheduled email sent to $to');
    } catch (e) {
      print('⚠️ Resend failed: $e');
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
        print('✅ Email queued in Firebase');
      } catch (firebaseError) {
        print('❌ Failed: $firebaseError');
      }
    }
  }

  /// Send Invoice Email
  Future<void> sendInvoiceEmail({
    required String toEmail,
    required String clientName,
    required String lawyerName,
    required String invoiceNumber,
    required String invoiceId,
    required double totalAmount,
    required String dueDate,
    required String caseNumber,
    required String description,
  }) async {
    try {
      final htmlContent = _generateInvoiceHtml(
        clientName,
        lawyerName,
        invoiceNumber,
        totalAmount,
        dueDate,
        caseNumber,
        description,
      );
      await sendProfessionalEmail(
        to: toEmail,
        subject: '📄 Invoice $invoiceNumber - Professional Services',
        htmlContent: htmlContent,
      );
      print('✅ Invoice email sent to $toEmail');
    } catch (e) {
      print('❌ Failed to send invoice email: $e');
    }
  }

  /// Send Invoice Reminder Email
  Future<void> sendInvoiceReminderEmail({
    required String toEmail,
    required String clientName,
    required String invoiceNumber,
    required double totalAmount,
    required String dueDate,
  }) async {
    try {
      final htmlContent = _generateInvoiceReminderHtml(
        clientName,
        invoiceNumber,
        totalAmount,
        dueDate,
      );
      await sendProfessionalEmail(
        to: toEmail,
        subject: '⏰ Payment Reminder - Invoice $invoiceNumber',
        htmlContent: htmlContent,
      );
      print('✅ Invoice reminder sent to $toEmail');
    } catch (e) {
      print('❌ Failed to send invoice reminder: $e');
    }
  }

  /// Send Case Update Email
  Future<void> sendCaseUpdateEmail({
    required String toEmail,
    required String recipientName,
    required String caseTitle,
    required String caseNumber,
    required String updateType,
    required String updateDescription,
    required String newStatus,
  }) async {
    try {
      final htmlContent = _generateCaseUpdateHtml(
        recipientName,
        caseTitle,
        caseNumber,
        updateType,
        updateDescription,
        newStatus,
      );
      await sendProfessionalEmail(
        to: toEmail,
        subject: 'Case Update: $caseTitle',
        htmlContent: htmlContent,
      );
      print('✅ Case update email sent to $toEmail');
    } catch (e) {
      print('❌ Failed to send case update email: $e');
    }
  }

  /// Send Hearing Reminder Email
  Future<void> sendHearingReminderEmail({
    required String toEmail,
    required String recipientName,
    required String caseTitle,
    required String oldHearingDate,
    required String newHearingDate,
    required String hearingTime,
    required String location,
    required String lawyerName,
  }) async {
    try {
      final htmlContent = _generateHearingReminderHtml(
        recipientName,
        caseTitle,
        oldHearingDate,
        newHearingDate,
        hearingTime,
        location,
        lawyerName,
      );
      await sendProfessionalEmail(
        to: toEmail,
        subject: '⚠️ Hearing Date Updated - $caseTitle',
        htmlContent: htmlContent,
      );
      print('✅ Hearing reminder email sent to $toEmail');
    } catch (e) {
      print('❌ Failed to send hearing reminder email: $e');
    }
  }

  /// Send Login Notification Email
  Future<void> sendLoginNotificationEmail({
    required String toEmail,
    required String userName,
  }) async {
    try {
      final htmlContent = _generateLoginNotificationHtml(userName);
      await sendProfessionalEmail(
        to: toEmail,
        subject: '🔐 New Login to LegalSync',
        htmlContent: htmlContent,
      );
      print('✅ Login notification sent to $toEmail');
    } catch (e) {
      print('❌ Failed to send login notification: $e');
    }
  }

  /// Send Billing Notification Email
  Future<void> sendBillingNotificationEmail({
    required String toEmail,
    required String clientName,
    required String notificationType,
    required Map<String, dynamic> billingDetails,
  }) async {
    try {
      final htmlContent = _generateBillingNotificationHtml(
        clientName,
        notificationType,
        billingDetails,
      );

      String subject = 'Billing Notification - LegalSync';
      if (notificationType.toLowerCase() == 'payment_received') {
        subject = '✅ Payment Received - Invoice Confirmed';
      } else if (notificationType.toLowerCase() == 'billing_ready') {
        subject = '📋 New Invoice Ready';
      }

      await sendProfessionalEmail(
        to: toEmail,
        subject: subject,
        htmlContent: htmlContent,
      );
      print('✅ Billing notification sent to $toEmail');
    } catch (e) {
      print('❌ Failed to send billing notification: $e');
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // HTML Template Generators
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  String _generateLoginSuccessHtml(String email, String name) {
    return '''
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: auto; padding: 20px; border: 1px solid #eee; border-radius: 10px; background: white;">
        <div style="text-align: center; margin-bottom: 30px;">
          <h2 style="color: #FF6B00; margin: 0;">Welcome Back, $name!</h2>
        </div>
        <p style="font-size: 16px; color: #333;">You have successfully logged in.</p>
        <div style="background-color: #f9f9f9; padding: 15px; border-radius: 8px; margin: 20px 0;">
          <p style="margin: 0; color: #666;"><strong>Account:</strong> $email</p>
        </div>
        <p style="color: #666; font-size: 12px;">© 2026 LegalSync Elite.</p>
      </div>
    ''';
  }

  String _generateWelcomeHtml(String email, String name, bool isLawyer) {
    return '''
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: auto; padding: 20px; border: 1px solid #eee; border-radius: 10px; background: white;">
        <h2 style="color: #FF6B00; text-align: center;">Welcome to LegalSync!</h2>
        <p>Hi $name,</p>
        <p>Your account has been created successfully.</p>
        <div style="background: #f9f9f9; padding: 15px; border-radius: 8px; margin: 20px 0;">
          <p><strong>Email:</strong> $email</p>
          <p><strong>Role:</strong> ${isLawyer ? '⚖️ Lawyer' : '👤 Client'}</p>
        </div>
        <p style="color: #666; font-size: 12px;">© 2026 LegalSync Elite.</p>
      </div>
    ''';
  }

  String _generateHearingScheduledHtml(
    String recipientName,
    String caseTitle,
    String hearingDate,
    String hearingTime,
    String hearingType,
    String location,
    String lawyerName,
    String clientName,
    bool isForLawyer,
  ) {
    return '''
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: auto; padding: 20px;">
        <h2 style="color: #FF6B00;">⚖️ Hearing Scheduled</h2>
        <p>Hi $recipientName,</p>
        <div style="border: 2px solid #FF6B00; padding: 20px; border-radius: 8px; margin: 20px 0;">
          <table style="width: 100%;">
            <tr><td><strong>Case:</strong></td><td>$caseTitle</td></tr>
            <tr><td><strong>Date:</strong></td><td>$hearingDate</td></tr>
            <tr><td><strong>Time:</strong></td><td>$hearingTime</td></tr>
            <tr><td><strong>Location:</strong></td><td>$location</td></tr>
          </table>
        </div>
        <p style="color: #666; font-size: 12px;">© 2026 LegalSync Elite.</p>
      </div>
    ''';
  }

  String _generateInvoiceHtml(
    String clientName,
    String lawyerName,
    String invoiceNumber,
    double totalAmount,
    String dueDate,
    String caseNumber,
    String description,
  ) {
    return '''
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: auto; padding: 20px;">
        <h2 style="color: #FF6B00;">📄 Invoice</h2>
        <p>Dear $clientName,</p>
        <div style="border: 2px solid #FF6B00; padding: 20px; border-radius: 8px; margin: 20px 0;">
          <table style="width: 100%; border-collapse: collapse;">
            <tr style="border-bottom: 1px solid #eee;">
              <td><strong>Invoice:</strong></td><td>$invoiceNumber</td>
            </tr>
            <tr style="border-bottom: 1px solid #eee;">
              <td><strong>Amount:</strong></td><td>\$${totalAmount.toStringAsFixed(2)}</td>
            </tr>
            <tr style="border-bottom: 1px solid #eee;">
              <td><strong>Due Date:</strong></td><td>$dueDate</td>
            </tr>
            <tr>
              <td><strong>Case:</strong></td><td>$caseNumber</td>
            </tr>
          </table>
        </div>
        <p style="color: #666; font-size: 12px;">© 2026 LegalSync Elite.</p>
      </div>
    ''';
  }

  String _generateInvoiceReminderHtml(
    String clientName,
    String invoiceNumber,
    double totalAmount,
    String dueDate,
  ) {
    return '''
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: auto; padding: 20px;">
        <h2 style="color: #FF6B00;">⏰ Payment Reminder</h2>
        <p>Dear $clientName,</p>
        <p>Invoice <strong>$invoiceNumber</strong> for <strong>\$${totalAmount.toStringAsFixed(2)}</strong> is due by <strong>$dueDate</strong>.</p>
        <p style="color: #666; font-size: 12px;">© 2026 LegalSync Elite.</p>
      </div>
    ''';
  }

  String _generateCaseUpdateHtml(
    String recipientName,
    String caseTitle,
    String caseNumber,
    String updateType,
    String updateDescription,
    String newStatus,
  ) {
    return '''
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: auto; padding: 20px;">
        <h2 style="color: #FF6B00;">📋 Case Update</h2>
        <p>Hi $recipientName,</p>
        <div style="border: 2px solid #FF6B00; padding: 20px; border-radius: 8px; margin: 20px 0;">
          <table style="width: 100%;">
            <tr><td><strong>Case:</strong></td><td>$caseTitle</td></tr>
            <tr><td><strong>Number:</strong></td><td>$caseNumber</td></tr>
            <tr><td><strong>Update:</strong></td><td>$updateType</td></tr>
            <tr><td><strong>Status:</strong></td><td style="color: #FF6B00;"><strong>$newStatus</strong></td></tr>
          </table>
        </div>
        <p>$updateDescription</p>
        <p style="color: #666; font-size: 12px;">© 2026 LegalSync Elite.</p>
      </div>
    ''';
  }

  String _generateHearingReminderHtml(
    String recipientName,
    String caseTitle,
    String oldHearingDate,
    String newHearingDate,
    String hearingTime,
    String location,
    String lawyerName,
  ) {
    return '''
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: auto; padding: 20px;">
        <h2 style="color: #FF6B00;">⚠️ Hearing Date Updated</h2>
        <p>Hi $recipientName,</p>
        <div style="border: 2px solid #FF6B00; padding: 20px; border-radius: 8px; margin: 20px 0;">
          <p><strong>Previous Date:</strong> <span style="text-decoration: line-through;">$oldHearingDate</span></p>
          <p><strong>New Date:</strong> <strong style="color: #FF6B00;">$newHearingDate</strong></p>
          <p><strong>Time:</strong> $hearingTime</p>
          <p><strong>Location:</strong> $location</p>
        </div>
        <p style="color: #666; font-size: 12px;">© 2026 LegalSync Elite.</p>
      </div>
    ''';
  }

  String _generateLoginNotificationHtml(String userName) {
    final now = DateTime.now();
    return '''
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: auto; padding: 20px;">
        <h2 style="color: #FF6B00;">🔐 New Login Detected</h2>
        <p>Hi $userName,</p>
        <p>A new login was detected on your account on ${now.toString().split('.')[0]}.</p>
        <p style="color: #666; font-size: 12px;">© 2026 LegalSync Elite.</p>
      </div>
    ''';
  }

  String _generateBillingNotificationHtml(
    String clientName,
    String notificationType,
    Map<String, dynamic> billingDetails,
  ) {
    String title = 'Billing Update';
    String icon = '📧';

    if (notificationType.toLowerCase() == 'payment_received') {
      title = 'Payment Confirmed';
      icon = '✅';
    }

    return '''
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: auto; padding: 20px;">
        <h2 style="color: #FF6B00;">$icon $title</h2>
        <p>Dear $clientName,</p>
        <div style="background: #f9f9f9; padding: 15px; border-radius: 8px; margin: 20px 0;">
          <p>${billingDetails.entries.map((e) => '<strong>${e.key}:</strong> ${e.value}').join('<br/>')}</p>
        </div>
        <p style="color: #666; font-size: 12px;">© 2026 LegalSync Elite.</p>
      </div>
    ''';
  }
}

// Instance for convenience
final emailService = EmailService();
