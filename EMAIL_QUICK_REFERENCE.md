# 📧 Email Integration Quick Reference

## Copy-Paste Ready Code Snippets

### 1️⃣ Send Case Update Email

```dart
import 'dart:async';
import 'package:legal_sync/services/email_service.dart';

// In your case update method:
unawaited(
  EmailService().sendCaseUpdateEmail(
    toEmail: clientEmail,
    recipientName: clientName,
    caseTitle: 'Smith v. Johnson',
    caseNumber: 'CASE-2024-001',
    updateType: 'status_updated', // or 'note_added' or 'document_added'
    updateDescription: 'Status changed to In Progress',
    newStatus: 'In Progress',
  ),
);
```

### 2️⃣ Send Hearing Reminder Email

```dart
import 'dart:async';
import 'package:legal_sync/services/email_service.dart';

// When updating hearing date:
unawaited(
  EmailService().sendHearingReminderEmail(
    toEmail: clientEmail,
    recipientName: clientName,
    caseTitle: caseTitle,
    oldHearingDate: '15 Mar 2026, 2:00 PM',
    newHearingDate: '20 Mar 2026',
    hearingTime: '10:00 AM',
    location: 'District Court, Room 204',
    lawyerName: 'Attorney Johnson',
  ),
);
```

### 3️⃣ Send Login Notification

```dart
import 'dart:async';
import 'package:legal_sync/services/email_service.dart';

// After successful login:
unawaited(
  EmailService().sendLoginNotificationEmail(
    toEmail: email,
    userName: userName,
  ),
);
```

### 4️⃣ Send Welcome Email

```dart
import 'dart:async';
import 'package:legal_sync/services/email_service.dart';

// After user registration:
unawaited(
  EmailService().sendWelcomeEmail(
    email: email,
    name: name,
    role: 'client', // or 'lawyer'
  ),
);
```

### 5️⃣ Send Custom Email

```dart
import 'dart:async';
import 'package:legal_sync/services/email_service.dart';

// For any custom email:
unawaited(
  EmailService().sendProfessionalEmail(
    to: recipientEmail,
    subject: 'Your Email Subject',
    htmlContent: '''
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: auto; padding: 20px;">
        <h2 style="color: #FF6B00;">Hello!</h2>
        <p>Your custom email content here</p>
        <p>© 2026 LegalSync Elite</p>
      </div>
    ''',
  ),
);
```

---

## ✅ Checklist Before Sending Email

- [ ] User email exists in Firestore (`users/{uid}/email`)
- [ ] User name exists in Firestore (`users/{uid}/name`)
- [ ] Email address is valid format
- [ ] Using `unawaited()` to avoid blocking UI
- [ ] Using `import 'dart:async'` at top of file
- [ ] HTML is properly formatted and mobile-responsive
- [ ] Email subject is descriptive with emoji if appropriate
- [ ] Try-catch is in place (or using unawaited which handles this)

---

## 🔧 Common Integration Scenarios

### Scenario 1: After Case Status Update
```dart
Future<void> updateCase(String caseId, String newStatus) async {
  try {
    // Update case in database
    await _firestore.collection('cases').doc(caseId).update({
      'status': newStatus,
      'updatedAt': Timestamp.now(),
    });

    // Get case data for email
    final caseDoc = await _firestore.collection('cases').doc(caseId).get();
    final clientId = caseDoc['clientId'];
    final clientDoc = await _firestore.collection('users').doc(clientId).get();
    
    // Send email (fire-and-forget)
    unawaited(
      EmailService().sendCaseUpdateEmail(
        toEmail: clientDoc['email'],
        recipientName: clientDoc['name'],
        caseTitle: caseDoc['title'],
        caseNumber: caseDoc['caseNumber'],
        updateType: 'status_updated',
        updateDescription: 'Case status changed to $newStatus',
        newStatus: newStatus,
      ),
    );
  } catch (e) {
    print('Error: $e');
  }
}
```

### Scenario 2: After Adding Case Note
```dart
Future<void> addCaseNote(String caseId, String note) async {
  try {
    // Add note
    await _firestore
        .collection('cases')
        .doc(caseId)
        .collection('notes')
        .add({
      'content': note,
      'createdAt': Timestamp.now(),
    });

    // Send notification email
    final caseDoc = await _firestore.collection('cases').doc(caseId).get();
    final clientId = caseDoc['clientId'];
    final clientDoc = await _firestore.collection('users').doc(clientId).get();
    
    unawaited(
      EmailService().sendCaseUpdateEmail(
        toEmail: clientDoc['email'],
        recipientName: clientDoc['name'],
        caseTitle: caseDoc['title'],
        caseNumber: caseDoc['caseNumber'],
        updateType: 'note_added',
        updateDescription: 'New case note added: ${note.substring(0, 50)}...',
        newStatus: caseDoc['status'],
      ),
    );
  } catch (e) {
    print('Error: $e');
  }
}
```

### Scenario 3: Upon User Login
```dart
Future<String> loginUser({
  required String email,
  required String password,
}) async {
  try {
    final userCredential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    // Get user name
    final userDoc = await _firestore
        .collection('users')
        .doc(userCredential.user!.uid)
        .get();
    final userName = userDoc['name'] ?? 'User';

    // Send login notification (non-blocking)
    unawaited(
      EmailService().sendLoginNotificationEmail(
        toEmail: email.trim(),
        userName: userName,
      ),
    );

    return 'success';
  } catch (e) {
    return e.toString();
  }
}
```

---

## 📊 Email Update Types

When sending case update emails, use these `updateType` values:

| Type | Use When | Example |
|------|----------|---------|
| `status_updated` | Case status changes | "Going from Draft to In Progress" |
| `note_added` | New note added to case | "Lawyer adds case notes" |
| `document_added` | New document uploaded | "Invoice, evidence, etc." |

---

## 🎨 Email HTML Template Structure

For custom emails, follow this structure:

```dart
final htmlContent = '''
<div style="font-family: Arial, sans-serif; max-width: 600px; margin: auto; padding: 20px; border: 1px solid #eee; border-radius: 10px; background: white;">
  <!-- HEADER -->
  <div style="text-align: center; margin-bottom: 30px;">
    <h2 style="color: #FF6B00; margin: 0;">📧 Email Title</h2>
    <p style="color: #666; margin: 10px 0 0 0;">Subtitle</p>
  </div>
  
  <!-- GREETING -->
  <p style="font-size: 16px; color: #333;">Dear <strong>Name</strong>,</p>
  <p style="color: #666; line-height: 1.6;">Main message here.</p>
  
  <!-- MAIN CONTENT (white box with orange border) -->
  <div style="background: white; border: 2px solid #FF6B00; border-radius: 8px; padding: 20px; margin: 20px 0;">
    <h3 style="color: #FF6B00; margin: 0 0 15px 0; border-bottom: 2px solid #FF6B00; padding-bottom: 10px;">Details</h3>
    <p>Your content here</p>
  </div>
  
  <!-- INFO BOX (light blue background) -->
  <div style="background-color: #f0f9ff; padding: 15px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #FF6B00;">
    <h4 style="color: #FF6B00; margin: 0 0 10px 0;">Important Info</h4>
    <p>Additional important info</p>
  </div>
  
  <!-- FOOTER -->
  <hr style="border: 0; border-top: 1px solid #eee; margin: 30px 0;" />
  <p style="text-align: center; font-size: 12px; color: #aaa;">&copy; 2026 LegalSync Elite. All rights reserved.</p>
</div>
''';
```

---

## 🐛 Debugging Tips

### Check if email is being called:
```dart
print('About to send email...');
unawaited(
  EmailService().sendCaseUpdateEmail(...),
);
print('Email call initiated');
```

### Check if recipient email exists:
```dart
final userDoc = await FirebaseFirestore.instance
    .collection('users')
    .doc(userId)
    .get();
    
print('User email: ${userDoc['email']}');
```

### Monitor Supabase Edge Function:
1. Go to Supabase Console
2. Navigate to Edge Functions
3. Click "send-email" function
4. Check recent logs

---

## 🚀 Best Practices

1. **Always use `unawaited()`** - Prevents UI blocking
2. **Always wrap in try-catch** - Or use unawaited which handles errors
3. **Get email before sending** - Don't assume it exists
4. **Use professional templates** - Match LegalSync branding
5. **Test with your email** - Send test emails to yourself
6. **Include branding** - Use #FF6B00 (orange) color
7. **Mobile responsive** - Test on mobile devices
8. **Clear subject lines** - Include emoji for quick scanning
9. **Personalized greeting** - Use user's name
10. **Professional footer** - Include copyright and company info

---

## ⚡ Quick Implementation Checklist

- [ ] Import `dart:async` at top of file
- [ ] Import `EmailService` from email_service.dart
- [ ] Get recipient email from Firestore
- [ ] Call email method with `unawaited()`
- [ ] Use try-catch around data fetching
- [ ] Test locally with your email
- [ ] Verify Supabase Edge Function is deployed
- [ ] Check for any runtime errors in logs
- [ ] Confirm email received in inbox (check spam)

---

## 📞 Need Help?

Refer to `EMAIL_INTEGRATION_GUIDE.md` for complete documentation and troubleshooting.
