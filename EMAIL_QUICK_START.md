
# 🚀 Email Service Quick Reference

**Copy-paste ready code snippets for each screen**

---

## ⚡ 1-Minute Setup

### Step 1: Set API Key
```bash
supabase secrets set RESEND_API_KEY=re_your_key_here
```

### Step 2: Deploy
```bash
supabase functions deploy send-email
```

### Step 3: Update Flutter Constants
```dart
// In lib/services/email_service.dart
static const String _supabaseProjectRef = 'YOUR_PROJECT_REF';
static const String _supabaseAnonKey = 'YOUR_ANON_KEY';
```

### Step 4: Add http to pubspec.yaml
```yaml
dependencies:
  http: ^1.1.0
```

```bash
flutter pub get
```

---

## 📱 Screen Integration Guide

### Screen 1: Add New Client

**File:** `lib/screens/clients/add_client_screen.dart` (or your client creation screen)

```dart
import 'package:legal_sync/services/email_service.dart';

// In your "Save Client" button handler:
Future<void> _saveNewClient() async {
  // 1. Validate form
  if (!_formKey.currentState!.validate()) return;

  // 2. Get values from form
  final clientName = _nameController.text;
  final clientEmail = _emailController.text;
  final lawyerName = _getCurrentLawyerName(); // Get from auth/state
  final caseRef = _caseRefController.text;

  try {
    // 3. Save to Firestore
    await FirebaseFirestore.instance.collection('clients').add({
      'name': clientName,
      'email': clientEmail,
      'lawyerId': getCurrentUserId(),
      'createdAt': Timestamp.now(),
    });

    // 4. Send welcome email
    final emailSent = await EmailService.sendWelcome(
      clientEmail: clientEmail,
      clientName: clientName,
      lawyerName: lawyerName,
      caseRef: caseRef,
    );

    // 5. Show feedback
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(emailSent 
            ? '✅ Client added and welcome email sent'
            : '✅ Client added (email could not be sent)'),
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.pop(context); // Go back
    }
  } catch (e) {
    print('Error saving client: $e');
    _showErrorDialog('Failed to add client');
  }
}
```

---

### Screen 2: Schedule Hearing

**File:** `lib/screens/hearings/schedule_hearing_screen.dart`

```dart
import 'package:legal_sync/services/email_service.dart';

// In your "Schedule Hearing" button handler:
Future<void> _scheduleHearing() async {
  // 1. Validate form
  if (!_formKey.currentState!.validate()) return;

  // 2. Get values
  final clientName = _selectedClient['name'];
  final clientEmail = _selectedClient['email'];
  final lawyerName = _getCurrentLawyerName();
  final caseTitle = _caseController.text;
  final hearingDate = _selectedDate; // DateTime from date picker
  final hearingTime = _timeController.text; // e.g., "10:00 AM"
  final court = _courtController.text;

  try {
    // 3. Save to Firestore
    await FirebaseFirestore.instance.collection('hearings').add({
      'clientId': _selectedClient['id'],
      'caseTitle': caseTitle,
      'date': Timestamp.fromDate(hearingDate),
      'time': hearingTime,
      'court': court,
      'status': 'scheduled',
      'createdAt': Timestamp.now(),
    });

    // 4. Format date for email
    final formattedDate = _formatDate(hearingDate);

    // 5. Send email to client
    final emailSent = await EmailService.sendHearingScheduled(
      recipientEmail: clientEmail,
      clientName: clientName,
      lawyerName: lawyerName,
      caseTitle: caseTitle,
      date: formattedDate,
      time: hearingTime,
      court: court,
    );

    // 6. Show confirmation
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Hearing scheduled for $formattedDate'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  } catch (e) {
    print('Error scheduling hearing: $e');
    _showErrorDialog('Failed to schedule hearing');
  }
}

// Helper to format date
String _formatDate(DateTime date) {
  const months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}
```

---

### Screen 3: Hearing Reminder (Automatic)

**File:** `lib/provider/hearing_reminder_provider.dart` (Create this file if it doesn't exist)

```dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:legal_sync/services/email_service.dart';
import 'dart:async';

class HearingReminderProvider extends ChangeNotifier {
  Timer? _reminderTimer;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Start checking for hearings that need reminders
  void startHearingReminderCheck() {
    print('🔔 Starting hearing reminder service...');
    
    // Check every hour for hearings tomorrow
    _reminderTimer = Timer.periodic(Duration(hours: 1), (_) async {
      await _checkAndSendReminders();
    });

    // Also check immediately on startup
    _checkAndSendReminders();
  }

  Future<void> _checkAndSendReminders() async {
    try {
      // Get tomorrow's date
      final tomorrow = DateTime.now().add(Duration(days: 1));
      final startOfDay = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
      final endOfDay = startOfDay.add(Duration(days: 1)).subtract(Duration(seconds: 1));

      // Query Firestore for hearings tomorrow
      final hearings = await _firestore
          .collection('hearings')
          .where('date', 
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
            isLessThan: Timestamp.fromDate(endOfDay))
          .where('reminderSent', isEqualTo: false)
          .get();

      print('Found ${hearings.docs.length} hearings for tomorrow');

      // Send reminders
      for (var hearingDoc in hearings.docs) {
        final hearing = hearingDoc.data();
        
        await EmailService.sendHearingReminder(
          recipientEmail: hearing['clientEmail'],
          clientName: hearing['clientName'],
          lawyerName: hearing['lawyerName'],
          date: _formatDate(hearing['date'].toDate()),
          time: hearing['time'],
          court: hearing['court'],
        );

        // Mark as sent
        await hearingDoc.reference.update({'reminderSent': true});
        print('✅ Reminder sent for ${hearing["caseTitle"]}');
      }
    } catch (e) {
      print('❌ Error checking reminders: $e');
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  void dispose() {
    _reminderTimer?.cancel();
    super.dispose();
  }
}
```

**Add to main.dart** (in your providers list):
```dart
ChangeNotifierProvider(
  create: (_) => HearingReminderProvider()..startHearingReminderCheck(),
)
```

---

### Screen 4: Case Update

**File:** `lib/screens/cases/case_detail_screen.dart` (or update screen)

```dart
import 'package:legal_sync/services/email_service.dart';

// In your "Update Status" button handler:
Future<void> _updateCaseStatus(String newStatus, String updateNotes) async {
  try {
    // 1. Update in Firestore
    await FirebaseFirestore.instance
        .collection('cases')
        .doc(_caseId)
        .update({
          'status': newStatus,
          'lastUpdate': Timestamp.now(),
          'updates': FieldValue.arrayUnion([
            {
              'status': newStatus,
              'notes': updateNotes,
              'timestamp': Timestamp.now(),
            }
          ]),
        });

    // 2. Get case and client info
    final caseDoc = await FirebaseFirestore.instance
        .collection('cases')
        .doc(_caseId)
        .get();

    final caseData = caseDoc.data()!;
    final clientDoc = await FirebaseFirestore.instance
        .collection('clients')
        .doc(caseData['clientId'])
        .get();

    final clientData = clientDoc.data()!;

    // 3. Send update email
    await EmailService.sendCaseUpdate(
      recipientEmail: clientData['email'],
      clientName: clientData['name'],
      lawyerName: _getCurrentLawyerName(),
      caseTitle: caseData['title'],
      updateText: '''
Case Status: $newStatus

Update Details:
$updateNotes

Your lawyer will be in touch if further action is needed.
      ''',
    );

    // 4. Show confirmation
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Case status updated and client notified'),
          backgroundColor: Colors.green,
        ),
      );
    }
  } catch (e) {
    print('Error updating case: $e');
    _showErrorDialog('Failed to update case');
  }
}
```

---

### Screen 5: Document Upload/Share

**File:** `lib/screens/documents/upload_document_screen.dart`

```dart
import 'package:legal_sync/services/email_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// In your "Share Document" button handler:
Future<void> _shareDocument(File selectedDocument) async {
  try {
    // 1. Upload to Supabase Storage
    final fileName = selectedDocument.path.split('/').last;
    final path = 'cases/$_caseId/$fileName';

    await Supabase.instance.client.storage
        .from('documents')
        .upload(
          path,
          selectedDocument,
          fileOptions: FileOptions(upsert: false),
        );

    print('✅ Document uploaded to Storage');

    // 2. Get client info
    final caseDoc = await FirebaseFirestore.instance
        .collection('cases')
        .doc(_caseId)
        .get();

    final caseData = caseDoc.data()!;
    final clientDoc = await FirebaseFirestore.instance
        .collection('clients')
        .doc(caseData['clientId'])
        .get();

    final clientData = clientDoc.data()!;

    // 3. Save metadata to Firestore
    await FirebaseFirestore.instance
        .collection('case_documents')
        .add({
          'caseId': _caseId,
          'clientId': clientData['id'],
          'fileName': fileName,
          'storagePath': path,
          'uploadedBy': _getCurrentLawyerId(),
          'uploadedAt': Timestamp.now(),
          'shared': true,
        });

    // 4. Send email notification
    await EmailService.sendDocumentShared(
      recipientEmail: clientData['email'],
      clientName: clientData['name'],
      lawyerName: _getCurrentLawyerName(),
      documentName: fileName,
    );

    // 5. Show confirmation
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Document shared with client'),
          backgroundColor: Colors.green,
        ),
      );
    }
  } catch (e) {
    print('Error sharing document: $e');
    _showErrorDialog('Failed to share document');
  }
}
```

---

## 🧪 Quick Test

Copy-paste this into any screen to test:

```dart
import 'package:legal_sync/services/email_service.dart';

// Test any email type
Future<void> _testEmail() async {
  final sent = await EmailService.sendWelcome(
    clientEmail: 'test@example.com',
    clientName: 'Test Client',
    lawyerName: 'Your Name',
    caseRef: 'TEST-001',
  );
  
  print(sent ? '✅ Test email sent!' : '❌ Test email failed');
}
```

---

## ✅ Checklist Before Production

- [ ] `supabase secrets set RESEND_API_KEY=...` ✓
- [ ] `supabase functions deploy send-email` ✓
- [ ] Updated `_supabaseProjectRef` and `_supabaseAnonKey` in email_service.dart
- [ ] `flutter pub get` to get http package
- [ ] Tested email from Flutter app to real inbox
- [ ] Error handling shows user-friendly messages
- [ ] No API keys in code (only constants at top of email_service.dart)

---

**You're all set! 🎉**
