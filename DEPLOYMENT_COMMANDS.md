
# 🔧 Deployment Commands - Copy & Paste

## Prerequisites

1. Have Supabase CLI installed:
   ```bash
   npm install -g supabase
   ```

2. Get your credentials:
   - **Resend API Key**: https://resend.dev/settings/api-keys
   - **Supabase Project Ref**: Your Supabase project dashboard → Settings → General
   - **Supabase Anon Key**: Your Supabase project dashboard → Settings → API

---

## STEP 1: Set Resend API Key

Replace `YOUR_RESEND_API_KEY` with your actual key from Resend:

```bash
supabase secrets set RESEND_API_KEY=YOUR_RESEND_API_KEY
```

**Example:**
```bash
supabase secrets set RESEND_API_KEY=re_abcdef123456789ghi
```

---

## STEP 2: Deploy Edge Function

From your project root (`e:\legal_sync`):

```bash
supabase functions deploy send-email
```

Expected output:
```
✓ Deploying function 'send-email'
✓ Function 'send-email' deployed successfully
```

---

## STEP 3: Test Locally (Optional)

To test the function before deploying:

```bash
supabase functions serve send-email
```

The function will be available at: `http://localhost:54321/functions/v1/send-email`

---

## STEP 4: Update Flutter Constants

**File:** `lib/services/email_service.dart`

Find these lines and replace the values:

```dart
static const String _supabaseProjectRef = 'YOUR_PROJECT_REF';
static const String _supabaseAnonKey = 'YOUR_ANON_KEY';
```

Replace with your actual values from Supabase dashboard:
- `YOUR_PROJECT_REF` → e.g., `abcdefghijklmnopqrst`
- `YOUR_ANON_KEY` → e.g., `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`

---

## STEP 5: Add http Package

### Option A: Using terminal
```bash
flutter pub add http
```

### Option B: Manual
Edit `pubspec.yaml`:
```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0
```

Then run:
```bash
flutter pub get
```

---

## Verify Deployment

Check if deployment was successful:

```bash
# List all edge functions
supabase functions list

# Check if secret was set
supabase secrets get RESEND_API_KEY
```

---

## Test Email Sending

### Test 1: Using cURL

Copy and replace `YOUR_PROJECT_REF` and `YOUR_ANON_KEY`:

```bash
curl -X POST \
  https://YOUR_PROJECT_REF.supabase.co/functions/v1/send-email \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -d '{
    "to": "test@example.com",
    "subject": "Test",
    "type": "welcome",
    "data": {
      "clientName": "Test User",
      "lawyerName": "Test Lawyer",
      "caseRef": "TEST-001"
    }
  }'
```

### Test 2: From Flutter App

Add to any screen:

```dart
import 'package:legal_sync/services/email_service.dart';

// Call this to test
Future<void> testEmail() async {
  final success = await EmailService.sendWelcome(
    clientEmail: 'your-test-email@example.com',
    clientName: 'Test Client',
    lawyerName: 'Test Lawyer',
    caseRef: 'TEST-001',
  );
  
  print(success ? '✅ Email sent!' : '❌ Email failed');
}
```

---

## Quick Command Reference

```bash
# Full deployment sequence (copy & paste)
supabase secrets set RESEND_API_KEY=YOUR_KEY_HERE
supabase functions deploy send-email
flutter pub get

# Test function locally
supabase functions serve send-email

# List deployed functions
supabase functions list

# View secrets
supabase secrets list
supabase secrets get RESEND_API_KEY
```

---

## ✅ Completed Setup Checklist

After running the commands above:

- [ ] Resend API key set: ✓ (STEP 1)
- [ ] Edge function deployed: ✓ (STEP 2)
- [ ] Flutter constants updated: ✓ (STEP 4)
- [ ] http package added: ✓ (STEP 5)
- [ ] Test email sent successfully: ✓

---

## ❌ Troubleshooting Commands

```bash
# Check if secrets are set correctly
supabase secrets list
supabase secrets get RESEND_API_KEY

# Re-deploy edge function
supabase functions deploy send-email

# Force refresh Flutter dependencies
flutter clean
flutter pub get
flutter pub upgrade

# Check Flutter has http package
flutter pub list-package-names | grep http
```

---

**That's it! Your email system is ready.** 🎉
