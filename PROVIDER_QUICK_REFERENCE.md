# Provider Quick Reference Guide

## All Available Providers in Legal Sync

### 🏢 Core Business Logic

#### Cases
- `allCasesProvider` - Stream all cases
- `casesByLawyerProvider(lawyerId)` - Cases for specific lawyer
- `casesByClientProvider(clientId)` - Cases for specific client
- `getCaseByIdProvider(caseId)` - Get single case
- `activeCasesProvider` - Only active cases
- `closedCasesProvider` - Only closed cases
- `caseStateNotifierProvider` - CRUD operations for cases

#### Lawyers
- `allLawyersProvider` - Stream all lawyers
- `getLawyerByIdProvider(lawyerId)` - Get single lawyer
- `verifiedLawyersProvider` - Only verified lawyers
- `lawyersBySpecializationProvider(specialization)` - Filter by specialization
- `topRatedLawyersProvider` - Top-rated lawyers
- `pendingLawyerApprovalsProvider` - Pending approvals
- `lawyerCasesCountProvider(lawyerId)` - Case count
- `lawyerAvailabilityStatusProvider(lawyerId)` - Check availability
- `lawyerStateNotifierProvider` - CRUD operations for lawyers

#### Clients
- `allClientsProvider` - Stream all clients
- `getClientByIdProvider(clientId)` - Get single client
- `verifiedClientsProvider` - Only verified clients
- `activeClientsProvider` - Only active clients
- `clientsWithPendingPaymentProvider` - Payment tracking
- `clientCasesCountProvider(clientId)` - Case count
- `clientWalletBalanceProvider(clientId)` - Wallet balance
- `clientStateNotifierProvider` - CRUD operations for clients

---

### 💬 Communication

#### Chat & Messaging
- `allMessagesProvider` - Stream all messages
- `messagesBetweenUsersProvider(userId1, userId2)` - Direct messages
- `caseMessagesProvider(caseId)` - Case-specific messages
- `userMessagesProvider(userId)` - User's messages
- `unreadMessagesCountProvider(userId)` - Unread count
- `getMessageByIdProvider(messageId)` - Get single message
- `chatStateNotifierProvider` - CRUD operations for messages

#### Chat Threads
- `allChatThreadsProvider` - Stream all threads
- `chatThreadsForCaseProvider(caseId)` - Threads for case
- `chatThreadsForUserProvider(userId)` - User's threads
- `chatThreadsBetweenUsersProvider(userId1, userId2)` - Direct thread
- `getChatThreadByIdProvider(threadId)` - Get single thread
- `unreadThreadsCountProvider(userId)` - Unread thread count
- `chatThreadStateNotifierProvider` - CRUD operations for threads

#### Notifications
- `allNotificationsProvider` - Stream all notifications
- `userNotificationsProvider(userId)` - User's notifications
- `unreadNotificationsProvider(userId)` - Only unread
- `unreadNotificationsCountProvider(userId)` - Count only
- `getNotificationByIdProvider(notificationId)` - Get single
- `notificationStateNotifierProvider` - CRUD operations

#### Message Templates
- `allMessageTemplatesProvider` - Stream all templates
- `messageTemplatesForLawyerProvider(lawyerId)` - Lawyer's templates
- `messageTemplatesByCategoryProvider(category)` - By category
- `getMessageTemplateByIdProvider(templateId)` - Get single
- `messageTemplateStateNotifierProvider` - CRUD operations

---

### 📋 Case Management

#### Deadlines
- `deadlinesForCaseProvider(caseId)` - Case deadlines
- `deadlinesForLawyerProvider(lawyerId)` - Lawyer's deadlines
- `overdueDeadlinesProvider(lawyerId)` - Overdue deadlines
- `deadlinesByPriorityProvider(lawyerId, priority)` - By priority
- `deadlineStateNotifierProvider` - CRUD operations

#### Hearings
- `streamHearingsByCaseProvider(caseId)` - Case hearings
- `streamUpcomingHearingsProvider(lawyerId)` - Upcoming hearings
- `getHearingByIdProvider(hearingId)` - Get single
- `hearingStateNotifierProvider` - CRUD operations

#### Documents
- `streamDocumentsByCaseProvider(caseId)` - Case documents
- `getDocumentByIdProvider(documentId)` - Get single
- `documentStateNotifierProvider` - CRUD operations

#### Case Status History
- `allStatusHistoryProvider` - Stream all history
- `statusHistoryForCaseProvider(caseId)` - Case history
- `statusHistoryForLawyerProvider(lawyerId)` - Lawyer's changes
- `getStatusHistoryByIdProvider(historyId)` - Get single
- `statusHistoryInDateRangeProvider(caseId, startDate, endDate)` - Date range
- `caseStatusHistoryStateNotifierProvider` - CRUD operations

---

### ⏱️ Time & Billing

#### Time Tracking
- `streamTimeEntriesByCaseProvider(caseId)` - Case time entries
- `streamTimeEntriesByLawyerProvider(lawyerId)` - Lawyer's entries
- `getTotalHoursByCaseProvider(caseId)` - Total hours
- `timerStateProvider` - Timer on/off state
- `currentCaseIdProvider` - Active case
- `currentLawyerIdProvider` - Active lawyer
- `timerElapsedProvider` - Elapsed time
- `timeTrackingStateNotifierProvider` - CRUD operations

#### Invoices
- `streamInvoicesByCaseProvider(caseId)` - Case invoices
- `streamInvoicesByLawyerProvider(lawyerId)` - Lawyer's invoices
- `getInvoiceByIdProvider(invoiceId)` - Get single
- `invoiceStateNotifierProvider` - CRUD operations

#### Billing
- `allBillingsProvider` - Stream all billings
- `billingsForCaseProvider(caseId)` - Case billing
- `billingsForLawyerProvider(lawyerId)` - Lawyer's billing
- `getBillingByIdProvider(billingId)` - Get single
- `totalBillingForCaseProvider(caseId)` - Total amount
- `totalBillingForLawyerProvider(lawyerId)` - Lawyer's total
- `pendingBillingsProvider` - Unpaid billing
- `billingStateNotifierProvider` - CRUD operations

---

### 👥 Organization

#### Staff
- `staffForFirmProvider(firmId)` - Firm's staff
- `staffByRoleProvider(firmId, role)` - By role
- `staffWorkloadProvider(staffId)` - Case workload
- `staffStateNotifierProvider` - CRUD operations

#### Leave Management
- `allLeavesProvider` - Stream all leave requests
- `leavesForStaffProvider(staffId)` - Staff's leaves
- `leavesForFirmProvider(firmId)` - Firm's leave requests
- `pendingLeaveApprovalsProvider` - Pending approvals
- `getLeaveByIdProvider(leaveId)` - Get single
- `staffLeaveBalanceProvider(staffId)` - Remaining balance
- `leaveStateNotifierProvider` - CRUD operations

#### Firm Management
- `firmByOwnerProvider(lawyerId)` - Owner's firm
- `firmStatsProvider(firmId)` - Firm statistics
- `firmStateNotifierProvider` - CRUD operations

#### Appointments
- `lawyerAvailabilityProvider(lawyerId)` - Availability slots
- `availableSlotsProvider(lawyerId)` - Available slots count
- `appointmentStateNotifierProvider` - CRUD operations

---

### 🤖 Advanced Features

#### AI Predictions
- `allPredictionsProvider` - Stream all predictions
- `predictionsForCaseProvider(caseId)` - Case predictions
- `predictionsByLawyerProvider(lawyerId)` - Lawyer's predictions
- `getPredictionByIdProvider(predictionId)` - Get single
- `pendingAIPredictionsProvider` - Pending review
- `approvedAIPredictionsProvider` - Approved predictions
- `aiAccuracyStatsProvider` - Accuracy statistics
- `aiCasePredictionStateNotifierProvider` - CRUD operations

#### Audit Logging
- `allAuditLogsProvider` - Stream all audit logs
- `auditLogsForUserProvider(userId)` - User's actions
- `auditLogsForEntityProvider(entityType, entityId)` - Entity changes
- `getAuditLogByIdProvider(logId)` - Get single
- `auditLogsInDateRangeProvider(startDate, endDate)` - Date range
- `auditLogStateNotifierProvider` - CRUD operations

#### Analytics
- `firmDashboardStatsProvider(firmId)` - Dashboard metrics
- `lawyerPerformanceAnalyticsProvider(lawyerId)` - Performance metrics
- `caseAnalyticsProvider(caseId)` - Case metrics
- `monthlyRevenueAnalyticsProvider(firmId)` - Revenue tracking
- `caseSuccessRateProvider(lawyerId)` - Success rate
- `billingAnalyticsProvider(firmId)` - Billing metrics
- `staffWorkloadAnalyticsProvider(firmId)` - Workload metrics
- `firmAnalyticsStateNotifierProvider` - Analytics operations

---

### 🔐 Authentication & Admin

#### Auth
- `authProvider` - Authentication state (ChangeNotifier)

#### Admin
- `adminStateNotifierProvider` - Admin operations

#### Payments
- `paymentStateNotifierProvider` - Payment operations

#### Reviews
- `reviewStateNotifierProvider` - Review operations

---

## Common Usage Patterns

### Reading Data
```dart
// One-time read (Future)
final caseData = ref.watch(getCaseByIdProvider('case123'));
if (caseData.when(
  data: (case) => case != null,
  error: (_, __) => false,
  loading: () => false,
)) {
  // Use case data
}

// Stream data (Real-time)
final cases = ref.watch(allCasesProvider);
cases.when(
  data: (list) => ListView(children: [...]),
  error: (e, st) => ErrorWidget(error: e),
  loading: () => LoadingWidget(),
);
```

### Modifying Data
```dart
// Create
final caseId = await ref.read(caseStateNotifierProvider.notifier)
    .createCase(newCase);

// Update
await ref.read(caseStateNotifierProvider.notifier)
    .updateCase(updatedCase);

// Delete
await ref.read(caseStateNotifierProvider.notifier)
    .deleteCase('case123');

// Custom action
await ref.read(caseStateNotifierProvider.notifier)
    .updateCaseStatus('case123', 'closed');
```

### Listening to Changes
```dart
ref.listen(allCasesProvider, (previous, next) {
  next.whenData((cases) {
    print('Cases updated: ${cases.length}');
  });
});
```

---

## Notes

- All providers are **Riverpod-based** for state management
- **StreamProviders** auto-refresh when Firestore data changes
- **FutureProviders** cache results automatically
- **StateNotifiers** handle CRUD operations
- Use **watch()** for real-time updates
- Use **read()** for one-time operations
- All providers are **fully typed** with null safety

---

**Last Updated:** January 15, 2026  
**Total Providers:** 27 (14 existing + 13 new)
