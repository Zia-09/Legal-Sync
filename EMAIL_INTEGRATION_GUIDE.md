# 📧 LegalSync Email Integration Guide

## Overview

This document describes the complete email notification system integrated throughout the LegalSync app. All emails are sent via **Supabase Edge Functions** (Resend) and follow a **fire-and-forget pattern** to ensure the app never blocks on email failures.

---

## ✅ Email Types Implemented

### 1. **Welcome Email (Registration)**
- **Trigger:** When a new client or lawyer successfully registers
- **Recipient:** The registered user's email
- **Subject:** "Welcome to LegalSync! 🎉"
- **Content:** Professional welcome message with user name and account status
- **File:** `lib/services/email_service.dart` → `sendWelcomeEmail()`
- **Integration:** `lib/services/auth_services.dart` → `signUpUser()` (lines ~120)

### 2. **Login Notification Email**
- **Trigger:** When a user successfully logs in to their account
- **Recipient:** The logged-in user's email
- **Subject:** "🔐 New Login to LegalSync"
- **Content:** Security notification with login date, time, and security tips
- **File:** `lib/services/email_service.dart` → `sendLoginNotificationEmail()`
- **Integration:** `lib/services/auth_services.dart` → `loginUser()` (lines ~30-55)

### 3. **Hearing Scheduled Email**
- **Trigger:** When a lawyer schedules a new hearing
- **Recipients:** Both client and lawyer
- **Subject:** "⚖️ Hearing Scheduled" / "📅 Your Hearing is Scheduled"
- **Content:** Complete hearing details (date, time, location, case info, parties involved)
- **File:** `lib/services/email_service.dart` → `sendHearingScheduledEmail()`
- **Integration:** `lib/services/hearing_service.dart` → `createHearing()` (already implemented)

### 4. **Hearing Reminder/Update Email**
- **Trigger:** When a lawyer updates/changes the hearing date
- **Recipient:** Client's email
- **Subject:** "⚠️ Hearing Date Updated - LegalSync"
- **Content:** Old date, new date, time, location, action required checklist
- **File:** `lib/services/email_service.dart` → `sendHearingReminderEmail()`
- **Integration:** `lib/services/hearing_service.dart` → `updateHearingDateWithEmailNotification()` (new method)

### 5. **Case Update Email**
- **Trigger:** When lawyer updates case status, adds notes, or uploads documents
- **Recipient:** Client's email (associated with the case)
- **Subject:** "📋 Case Update: [Case Title]" or specific update type icon
- **Content:** Case details, update type, new status, what changed
- **File:** `lib/services/email_service.dart` → `sendCaseUpdateEmail()`
- **Integration:** `lib/services/case_service.dart` → `updateCaseWithEmailNotification()` (new method)

---

## 🔧 How to Use Email Methods

### Using the Email Service

All email methods in `EmailService` follow the same pattern and include proper error handling:

```dart
// Example 1: Send Case Update Email
await EmailService().sendCaseUpdateEmail(
  toEmail: 'client@example.com',
  recipientName: 'John Doe',
  caseTitle: 'Smith v. Johnson',
  caseNumber: 'CASE-2024-001',
  updateType: 'status_updated', // 'status_updated', 'note_added', 'document_added'
  updateDescription: 'Case status changed to "In Progress"',
  newStatus: 'In Progress',
);

// Example 2: Send Hearing Reminder Email
await EmailService().sendHearingReminderEmail(
  toEmail: 'client@example.com',
  recipientName: 'Jane Smith',
  caseTitle: 'Smith v. Johnson',
  oldHearingDate: '15 Mar 2026, 2:00 PM',
  newHearingDate: '20 Mar 2026',
  hearingTime: '10:00 AM',
  location: 'District Court, Room 204',
  lawyerName: 'Attorney Johnson',
);

// Example 3: Send Case Update Email with fire-and-forget pattern
unawaited(
  EmailService().sendCaseUpdateEmail(...)
);
```

### Fire-and-Forget Pattern

All email calls are **non-blocking** using `unawaited()`:

```dart
// This doesn't block the UI - email sends in background
unawaited(
  EmailService().sendLoginNotificationEmail(
    toEmail: email,
    userName: userName,
  ),
);
```

**Benefits:**
- ✅ App never crashes if email service is down
- ✅ UI remains responsive regardless of email speed
- ✅ User experience not affected by email failures
- ✅ Graceful error handling with try-catch

---

## 📍 Integration Points in Your App

### 1. **Authentication (auth_services.dart)**

**Login:**
```dart
Future<String> loginUser({...}) async {
  // ... firebase auth code ...
  
  // Send login notification (fire-and-forget)
  unawaited(
    EmailService().sendLoginNotificationEmail(
      toEmail: email.trim(),
      userName: userName,
    ),
  );
  
  return 'success';
}
```

**Registration:**
```dart
Future<String> signUpUser({...}) async {
  // ... create user code ...
  
  if (role == 'client') {
    // ... create client ...
    
    // Send welcome email (fire-and-forget)
    unawaited(
      EmailService().sendWelcomeEmail(
        email: email.trim(),
        name: name,
        role: 'client',
      ),
    );
  }
  
  return 'success';
}
```

### 2. **Case Management (case_service.dart)**

When updating case status or adding notes:

```dart
// New method: updateCaseWithEmailNotification()
await caseService.updateCaseWithEmailNotification(
  caseId: 'case-123',
  updateData: {'status': 'In Progress'},
  updateType: 'status_updated',
  updateDescription: 'Case status changed to "In Progress"',
);
```

### 3. **Hearing Management (hearing_service.dart)**

When scheduling a hearing:
- Already implemented in `createHearing()` ✅
- Automatically sends to both client and lawyer

When updating hearing date:
```dart
// New method: updateHearingDateWithEmailNotification()
await hearingService.updateHearingDateWithEmailNotification(
  hearingId: 'hearing-123',
  oldHearingDate: DateTime.parse('2026-03-15 14:00'),
  newHearingDate: DateTime.parse('2026-03-20 10:00'),
);
```

---

## 🎨 Email Template Features

All emails include:

- ✅ **Professional Branding:** LegalSync branding with orange (#FF6B00) color scheme
- ✅ **Mobile Responsive:** HTML designed for all screen sizes
- ✅ **Clear Information Hierarchy:** Important details emphasized
- ✅ **Dark Theme Compatible:** Works on light and dark email clients
- ✅ **Action Items:** Clear calls-to-action and checklists where appropriate
- ✅ **Security Reminders:** Warnings about account security
- ✅ **Icons & Emojis:** Visual indicators for easy scanning

Example sections included in emails:
- Header with branded title
- Personalized greeting
- Main content with key information
- Highlighted sections for important details
- Action items/checklists (when applicable)
- Security or helpfulness tips
- Footer with copyright

---

## 🚨 Error Handling

All email methods include comprehensive error handling:

```dart
Future<void> sendCaseUpdateEmail({...}) async {
  try {
    // Email sending logic
    await _supabase.functions.invoke('send-email', body: {...});
    print('✅ Email sent');
  } catch (e) {
    // Graceful error handling - never crashes app
    print('❌ Email failed: $e');
  }
}
```

**Key Points:**
- ✅ Errors are caught and logged
- ✅ App continues functioning even if email fails
- ✅ No UI blocking
- ✅ Silent failure with logging for debugging

---

## 📊 Email Fields Used

The following user fields are used for email sending:

| Field | Source | Used For |
|-------|--------|----------|
| `email` | Firestore `/users/{uid}` | Recipient address |
| `name` | Firestore `/users/{uid}` | Personalized greeting |
| `caseTitle` | Firestore `/cases/{caseId}` | Case information |
| `status` | Firestore `/cases/{caseId}` | Current status |
| `clientId` | Firestore `/cases/{caseId}` | Client lookup |
| `lawyerId` | Firestore `/cases/{caseId}` | Lawyer lookup |
| `hearingDate` | Firestore `/hearings/{hearingId}` | Hearing schedule |
| `courtName` | Firestore `/hearings/{hearingId}` | Hearing location |

---

## 🔄 Workflow Examples

### Example 1: New User Registration

```
1. User signs up via app
   ↓
2. signUpUser() creates user in Firebase Auth and Firestore
   ↓
3. Welcome email sent (fire-and-forget) ← NEW
   ↓
4. User receives email within seconds
   ↓
5. User can now log in
```

### Example 2: Lawyer Updates Case Status

```
1. Lawyer opens case details
   ↓
2. Lawyer changes status to "In Progress"
   ↓
3. updateCaseWithEmailNotification() called ← NEW
   ↓
4. Case updated in Firestore
   ↓
5. Email sent to client (fire-and-forget)
   ↓
6. Client receives notification of case progress
```

### Example 3: Hearing Date Changed

```
1. Lawyer reschedules hearing due to court conflict
   ↓
2. updateHearingDateWithEmailNotification() called ← NEW
   ↓
3. Hearing date updated in Firestore
   ↓
4. Hearing reminder email sent to client (fire-and-forget)
   ↓
5. Client notified immediately of date change
   ↓
6. Client updates calendar
```

---

## 🛠️ Adding New Email Types

To add a new email type:

1. **Add method to EmailService:**
```dart
Future<void> sendMyCustomEmail({
  required String toEmail,
  required String userName,
  // ... other parameters ...
}) async {
  try {
    final htmlContent = '''...your HTML template...''';
    
    await sendProfessionalEmail(
      to: toEmail,
      subject: 'Your Subject Here',
      htmlContent: htmlContent,
    );
    print('✅ Custom email sent to $toEmail');
  } catch (e) {
    print('❌ Failed to send custom email: $e');
  }
}
```

2. **Integrate at desired location** (e.g., in a service method):
```dart
// Fire-and-forget pattern
unawaited(
  EmailService().sendMyCustomEmail(
    toEmail: email,
    userName: userName,
  ),
);
```

3. **Test by triggering the action** in your app

---

## 📝 Important Notes

### ⚠️ DO's:
- ✅ Always use `unawaited()` for email calls
- ✅ Get user email from Firestore before sending
- ✅ Include try-catch to prevent crashes
- ✅ Use professional HTML templates
- ✅ Test emails in your email client
- ✅ Include UTC timestamps for time-zone awareness

### ⛔ DON'Ts:
- ❌ Don't await email calls directly (blocks UI)
- ❌ Don't assume email always succeeds
- ❌ Don't send to hardcoded email addresses
- ❌ Don't use plain text emails
- ❌ Don't forget to import `dart:async` for `unawaited`

---

## 🧪 Testing Email Integration

1. **Create a test account** with your email
2. **Trigger each email action:**
   - Register: Creates account → Check welcome email
   - Login: Sign in → Check login notification
   - Create Case: Create case → Check with client involved
   - Update Case: Change status → Check case update email
   - Schedule Hearing: Add hearing → Check hearing email
   - Update Hearing: Change date → Check hearing reminder

3. **Monitor Firestore:**
   - Check `/users` collection for email addresses
   - Verify `/cases` and `/hearings` data is correct

4. **Debug if needed:**
   - Check Firebase Logs
   - Check Supabase Function Logs
   - Use `print()` statements for debugging

---

## 📞 Support & Troubleshooting

### Email not sending?
1. ✅ Verify Supabase Edge Function is deployed
2. ✅ Check Resend is configured in Edge Function
3. ✅ Verify recipient email exists in Firestore
4. ✅ Check Supabase Function Logs for errors
5. ✅ Check email address format is valid

### Email sending but not received?
1. ✅ Check spam/junk folder
2. ✅ Verify email address is correct in Firestore
3. ✅ Check Resend account has sufficient credits
4. ✅ Verify sender email is verified in Resend

### UI blocking?
1. ✅ Ensure using `unawaited()` for email calls
2. ✅ Check for missing `import 'dart:async'`
3. ✅ Verify email method is not being awaited

---

## 📚 Files Modified

- ✅ `lib/services/email_service.dart` - Added 3 new email methods
- ✅ `lib/services/auth_services.dart` - Integrated login & welcome emails
- ✅ `lib/services/case_service.dart` - Added case update email method
- ✅ `lib/services/hearing_service.dart` - Added hearing date update email method

---

## 🎯 Summary

Your LegalSync app now has a **complete, professional email notification system** that:

✅ Sends welcome emails on registration  
✅ Sends login notifications for security  
✅ Sends hearing scheduled alerts to both parties  
✅ Sends hearing date change reminders to clients  
✅ Sends case update notifications to clients  
✅ Never blocks the UI  
✅ Gracefully handles failures  
✅ Follows professional email templates  
✅ Integrates with Resend via Supabase Edge Functions  

**All emails are non-blocking and the app will never crash if email sending fails!** 🚀
