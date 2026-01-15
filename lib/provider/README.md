# Legal Sync Provider Layer - README

**Version:** 1.0.0  
**Status:** ✅ Production Ready  
**Last Updated:** January 15, 2026

---

## 📖 Overview

This directory contains **27 Riverpod providers** that manage all state and data operations for the Legal Sync lawyer management application.

**13 New Providers** have been added to complete the application infrastructure and fully align with the project proposal.

---

## 🗂️ Provider Organization

### Core Business Providers (3)
- **case_provider.dart** - Case lifecycle management
- **lawyer_provider.dart** - Lawyer profiles & verification
- **client_provider.dart** - Client account management

### Communication Providers (4)
- **chat_provider.dart** - Real-time messaging
- **chat_thread_provider.dart** - Conversation threads
- **notification_provider.dart** - Alert system
- **message_template_provider.dart** - Message templates

### Case Management Providers (3)
- **deadline_provider.dart** ⭐ - Task deadlines
- **hearing_provider.dart** ⭐ - Court hearings
- **case_status_history_provider.dart** - Status audit trail

### Billing & Time Providers (4)
- **time_tracking_provider.dart** ⭐ - Time entries
- **invoice_provider.dart** ⭐ - Invoice generation
- **billing_provider.dart** - Billing management
- **leave_provider.dart** - Staff leave requests

### Organization Providers (3)
- **staff_provider.dart** ⭐ - Team management
- **firm_provider.dart** ⭐ - Firm information
- **firm_analytics_provider.dart** - Business analytics

### Advanced Providers (2)
- **ai_case_prediction_provider.dart** - AI predictions
- **audit_log_provider.dart** - Comprehensive logging

### System Providers (5)
- **auth_provider.dart** ⭐ - Authentication
- **admin_provider.dart** ⭐ - Admin operations
- **analytics_provider.dart** ⭐ - App analytics
- **appointment_provider.dart** ⭐ - Appointment booking
- **availability_provider.dart** ⭐ - Lawyer availability
- **document_provider.dart** ⭐ - Document management
- **payment_provider.dart** ⭐ - Payment processing
- **review_provider.dart** ⭐ - User reviews

⭐ = Existing providers from previous implementation

---

## 🚀 Quick Start

### 1. Watching Real-Time Data

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legal_sync/provider/case_provider.dart';

class CasesScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final casesAsync = ref.watch(casesByLawyerProvider('lawyer123'));
    
    return casesAsync.when(
      data: (cases) => ListView.builder(
        itemCount: cases.length,
        itemBuilder: (context, index) {
          return ListTile(title: Text(cases[index].title));
        },
      ),
      error: (error, stack) => Text('Error: $error'),
      loading: () => CircularProgressIndicator(),
    );
  }
}
```

### 2. Creating New Items

```dart
import 'package:legal_sync/provider/case_provider.dart';
import 'package:legal_sync/model/case_Model.dart';

final newCaseId = await ref.read(caseStateNotifierProvider.notifier)
    .createCase(
      CaseModel(
        caseId: '',  // Will be auto-generated
        clientId: 'client123',
        lawyerId: 'lawyer456',
        title: 'Contract Dispute',
        description: 'Dispute over service agreement',
        createdAt: DateTime.now(),
      ),
    );
print('Created case: $newCaseId');
```

### 3. Updating Items

```dart
await ref.read(caseStateNotifierProvider.notifier)
    .updateCase(updatedCase);
```

### 4. Deleting Items

```dart
await ref.read(caseStateNotifierProvider.notifier)
    .deleteCase('case123');
```

### 5. Listening to Changes

```dart
ref.listen(casesByLawyerProvider('lawyer123'), (previous, next) {
  next.whenData((cases) {
    print('Cases updated: ${cases.length}');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${cases.length} cases')),
    );
  });
});
```

---

## 📋 Common Patterns

### Pattern 1: Stream Data in Widget

```dart
// Watch changing data
final dataAsync = ref.watch(someStreamProvider);

// Display based on state
dataAsync.when(
  data: (data) => DisplayWidget(data: data),
  error: (error, stack) => ErrorDisplay(error: error),
  loading: () => LoadingSpinner(),
);
```

### Pattern 2: One-Time Fetch

```dart
// Fetch once, cache automatically
final dataAsync = ref.watch(getFutureDataProvider('id'));
```

### Pattern 3: Perform Action

```dart
// Call method on notifier
final notifier = ref.read(stateNotifierProvider.notifier);
await notifier.createItem(newItem);
await notifier.updateItem(item);
await notifier.deleteItem(itemId);
```

### Pattern 4: Invalidate Cache

```dart
// Refresh provider data
ref.refresh(someStreamProvider);

// Invalidate and re-fetch
ref.invalidate(someFutureProvider);
```

---

## 🔌 Provider Types Reference

### StreamProvider
- **Use for:** Real-time data updates
- **Returns:** Stream<T>
- **Auto-refresh:** Yes (Firestore changes)
- **Caching:** Built-in

### FutureProvider
- **Use for:** One-time data fetches
- **Returns:** Future<T>
- **Auto-refresh:** No (manual via refresh/invalidate)
- **Caching:** Automatic

### StateNotifierProvider
- **Use for:** CRUD operations & state management
- **Returns:** T (state)
- **Methods:** Custom actions
- **Mutability:** Full control

### StateProvider
- **Use for:** Simple state values
- **Returns:** T
- **Use case:** UI state (selected item, form input)
- **Mutability:** Direct state updates

### FamilyProvider
- **Use for:** Parameterized queries
- **Returns:** Provider with arguments
- **Example:** `getFutureProvider.family('param123')`

---

## 📚 Provider Examples by Category

### Case Management

```dart
// Get all cases
ref.watch(allCasesProvider);

// Get cases for lawyer
ref.watch(casesByLawyerProvider('lawyer123'));

// Get specific case
ref.watch(getCaseByIdProvider('case123'));

// Create case
ref.read(caseStateNotifierProvider.notifier).createCase(case);

// Update case
ref.read(caseStateNotifierProvider.notifier).updateCase(case);

// Change status
ref.read(caseStateNotifierProvider.notifier)
    .updateCaseStatus('case123', 'closed');
```

### Lawyer Management

```dart
// List all lawyers
ref.watch(allLawyersProvider);

// Get verified only
ref.watch(verifiedLawyersProvider);

// Filter by specialization
ref.watch(lawyersBySpecializationProvider('Criminal Law'));

// Get specific lawyer
ref.watch(getLawyerByIdProvider('lawyer123'));

// Create lawyer
ref.read(lawyerStateNotifierProvider.notifier).createLawyer(lawyer);

// Approve lawyer
ref.read(lawyerStateNotifierProvider.notifier)
    .approveLawyer('lawyer123');
```

### Messaging

```dart
// Get messages between users
ref.watch(messagesBetweenUsersProvider(
  userId1: 'user1',
  userId2: 'user2',
));

// Get case messages
ref.watch(caseMessagesProvider('case123'));

// Unread count
ref.watch(unreadMessagesCountProvider('user123'));

// Send message
ref.read(chatStateNotifierProvider.notifier)
    .sendMessage(message);

// Mark as read
ref.read(chatStateNotifierProvider.notifier)
    .markAsRead('message123');
```

### Notifications

```dart
// Get user notifications
ref.watch(userNotificationsProvider('user123'));

// Unread only
ref.watch(unreadNotificationsProvider('user123'));

// Count unread
ref.watch(unreadNotificationsCountProvider('user123'));

// Create notification
ref.read(notificationStateNotifierProvider.notifier)
    .createNotification(notification);

// Mark as read
ref.read(notificationStateNotifierProvider.notifier)
    .markAsRead('notification123');
```

---

## 🔒 Error Handling

### Handling Errors in Widgets

```dart
final dataAsync = ref.watch(someProvider);

dataAsync.when(
  data: (data) => SuccessWidget(data: data),
  error: (error, stackTrace) {
    print('Error: $error');
    return ErrorWidget(
      error: error.toString(),
      retry: () => ref.refresh(someProvider),
    );
  },
  loading: () => LoadingWidget(),
);
```

### Try-Catch in Services

```dart
try {
  await ref.read(caseStateNotifierProvider.notifier).createCase(case);
} catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Error: ${e.toString()}')),
  );
}
```

---

## 🔄 Refreshing Data

### Refresh Provider

```dart
// Refresh specific provider
ref.refresh(casesByLawyerProvider('lawyer123'));

// Refresh all providers of same type
ref.refresh(allCasesProvider);
```

### Invalidate Cache

```dart
// Invalidate (clear cache and re-fetch)
ref.invalidate(getFutureDataProvider('id'));

// Invalidate all of same type
ref.invalidate(someStreamProvider);
```

---

## 📊 Available Providers Summary

| Provider | Type | Parameters | Returns |
|----------|------|-----------|---------|
| allCasesProvider | Stream | - | List<CaseModel> |
| casesByLawyerProvider | Stream | lawyerId | List<CaseModel> |
| casesByClientProvider | Stream | clientId | List<CaseModel> |
| getCaseByIdProvider | Future | caseId | CaseModel? |
| activeCasesProvider | Stream | - | List<CaseModel> |
| closedCasesProvider | Stream | - | List<CaseModel> |
| caseStateNotifierProvider | StateNotifier | - | CaseModel? |
| ... | ... | ... | ... |

*See PROVIDER_QUICK_REFERENCE.md for complete list of all 27 providers*

---

## 🛠️ Troubleshooting

### Provider Not Updating
- Check if watching the correct provider
- Verify Firestore permissions
- Try `ref.refresh()` to manually update

### Type Errors
- Ensure model types match provider return type
- Check null safety (?? for optional)
- Verify imports are correct

### State Not Persisting
- Use StateNotifierProvider for mutable state
- Don't mutate data directly
- Always use the notifier methods

### Performance Issues
- Use `.family` for parameterized queries
- Cache streams when possible
- Avoid watching too many providers

---

## 📖 Documentation

**For more information, see:**
- `PROVIDER_QUICK_REFERENCE.md` - All providers with examples
- `PROVIDERS_IMPLEMENTATION_REPORT.md` - Detailed implementation
- `VERIFICATION_CHECKLIST.md` - Complete verification

---

## ✅ Checklist for Integration

- [ ] Import provider in widget
- [ ] Use `ConsumerWidget` or `ConsumerStatefulWidget`
- [ ] Call `ref.watch()` or `ref.read()`
- [ ] Handle AsyncValue states (data/error/loading)
- [ ] Test with sample data
- [ ] Verify Firestore connection
- [ ] Check error messages
- [ ] Test CRUD operations

---

## 🚀 Best Practices

1. **Always use `ConsumerWidget`** for widgets accessing providers
2. **Watch streams** for real-time updates
3. **Read futures** for one-time data
4. **Use notifiers** for mutations
5. **Handle errors** in UI
6. **Cache where possible** with providers
7. **Test thoroughly** before deploying
8. **Monitor performance** in production

---

## 📞 Support

**Issues or Questions:**
- Review provider documentation
- Check PROVIDER_QUICK_REFERENCE.md
- Verify Firestore security rules
- Check Firebase initialization
- Review logs for errors

---

**Status:** ✅ Production Ready  
**Last Updated:** January 15, 2026  
**Total Providers:** 27 (14 existing + 13 new)
