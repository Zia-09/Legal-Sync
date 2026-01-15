# 🗂️ Quick Reference Guide - Legal Sync

## File Structure Summary

```
lib/
├── main.dart                          ← App entry point
│
├── app_helper/
│   └── app_helpers.dart              ← Utility functions (DateTimeHelper, AIHelper, RBAC)
│
├── model/                            ← Data Models (11 files)
│   ├── admin_model.dart              ✅ Admin profiles + AI tracking
│   ├── ai_case_prediction_Model.dart ✅ AI prediction results
│   ├── analytics_model.dart          ✅ Dashboard metrics
│   ├── app_user_model.dart           ✅ Base user model
│   ├── appoinment_model.dart         ✅ Appointment scheduling
│   ├── case_Model.dart               ✅ Legal cases + AI predictions
│   ├── chat_Model.dart               ✅ Chat messages (nested)
│   ├── chat_thread_model.dart        ✅ Chat threads with unread tracking
│   ├── client_Model.dart             ✅ Client profiles
│   ├── lawyer_Model.dart             ✅ Lawyer profiles + ratings + AI metrics
│   ├── notification_model.dart       ✅ Push notifications
│   ├── payment_method_model.dart     ✅ Transaction tracking
│   └── review_Model.dart             ✅ Reviews + ratings + moderation
│
├── services/                         ← Business Logic (9 files)
│   ├── admin_service.dart            ✅ Admin operations (approvals, dashboards)
│   ├── analytics_services.dart       ✅ Metrics tracking
│   ├── appoinment_services.dart      ✅ Appointment CRUD
│   ├── auth_services.dart            ✅ Auth + role detection (⚠️ hardcoded admin)
│   ├── case_service.dart             ✅ Case management + workflow
│   ├── chat_service.dart             ✅ Chat operations (in full_services.dart)
│   ├── chat_thread_service.dart      ✅ Thread + message management
│   ├── client_services.dart          ✅ Client operations
│   ├── full_services.dart            ✅ Combined services (legacy)
│   ├── lawyer_services.dart          ✅ Lawyer profiles + recommendations
│   ├── notification_services.dart    ✅ Notification CRUD
│   ├── payment_mothod_services.dart  ✅ Transaction management
│   └── review_service.dart           ✅ Review operations + moderation
│
├── provider/                         ← Riverpod State (5 files)
│   ├── admin_provider.dart           📝 Empty template
│   ├── analytics_provider.dart       📝 Empty template
│   ├── appointment_provider.dart     📝 Empty template
│   ├── auth_provider.dart            ✅ COMPLETE (auth state management)
│   ├── payment_provider.dart         📝 Empty template
│   └── review_provider.dart          📝 Template provided (commented)
│
└── view/                             ← UI Screens
    ├── splash_screen.dart            📝 Splash/loading screen
    ├── login/                        📝 Login screens
    └── widgets/                      📝 Reusable widgets
```

---

## 🔐 Authentication Flow

```
┌─────────────────────────────────────────────────┐
│ User Opens App                                  │
└────────────────┬────────────────────────────────┘
                 │
         ┌───────▼────────┐
         │ Login / SignUp │
         └───────┬────────┘
                 │
         ┌───────▼──────────────────────┐
         │ AuthService.signUpUser()    │
         │ or AuthService.loginUser()  │
         └───────┬──────────────────────┘
                 │
      ┌──────────┼──────────────────┐
      │          │                  │
  ADMIN    CLIENT SIGNUP       LAWYER SIGNUP
      │          │                  │
      │   Create ClientModel   Create LawyerModel
      │          │                  │
      │   Save to              Save to
      │   clients/             lawyers/ + 
      │   {uid}                pending approval
      │
  ┌───▼──────────────┐
  │ LOGIN SUCCESS    │
  │ Role detected:   │
  │ admin/client/    │
  │ lawyer           │
  └──────────────────┘
```

---

## 📊 Data Flow Examples

### Example 1: Case Creation (Client → Lawyer)
```
1. Client creates case
   ClientService.createCase(CaseModel)
     ↓
2. Case saved to Firestore
   cases/{caseId}
   status: "pending"
     ↓
3. Admin approves case
   CaseService.approveOrRejectCase(caseId, true)
   status: "waiting_for_lawyer"
     ↓
4. Lawyer accepts case
   CaseService.acceptCase(caseId, lawyerId)
   status: "ongoing"
     ↓
5. Case completed
   CaseService.markCaseAsCompleted(caseId)
   status: "completed"
```

---

### Example 2: Real-Time Chat
```
1. Create thread
   ChatThreadService.createThread(lawyerId, clientId)
   → chats/{threadId} created with unreadByLawyer=0, unreadByClient=0
     ↓
2. Client sends message
   ChatThreadService.sendMessage(threadId, ChatMessage)
   → messages/{messageId} created
   → thread.unreadByLawyer++
   → thread.lastMessage updated
     ↓
3. Lawyer receives message (real-time stream)
   ChatThreadService.streamMessages(threadId)
   → Message appears instantly (Firestore listener)
     ↓
4. Lawyer marks thread as read
   ChatThreadService.markThreadAsRead(threadId, isLawyer=true)
   → thread.unreadByLawyer = 0
```

---

### Example 3: Lawyer Recommendation
```
Client searches for lawyers in "Criminal Law"
  ↓
LawyerService.recommendLawyers("Criminal Law")
  ↓
1. Query Firestore
   WHERE specialization == "Criminal Law"
     ↓
2. Sort by composite score
   score = (rating × 0.7) + (experienceYears × 0.3)
   
   Example lawyer:
   - Rating: 4.8/5
   - Experience: 8 years
   - Score = (4.8 × 0.7) + (8 × 0.3) = 3.36 + 2.4 = 5.76
     ↓
3. Return top 3 lawyers
   Displayed to client
```

---

### Example 4: AI Case Prediction
```
1. Case created with AI features
   CaseModel {
     aiConfidence: 0.85,
     predictedOutcome: "win",
     aiPredictedAt: timestamp
   }
     ↓
2. Admin reviews prediction
   AdminService.getAllAIPredictions()
   Displays AICasePredictionModel
     ↓
3. Admin confirms/updates
   AICasePredictionModel.copyWith(
     predictionConfirmed: true,
     updatedConfidence: 0.92
   )
     ↓
4. Lawyer sees prediction in case
   Display to support case strategy
```

---

## 🎯 Key Method Locations

### Authentication
- **Sign Up**: `AuthService.signUpUser()`
- **Login**: `AuthService.loginUser()`
- **Logout**: `AuthService.logoutUser()`
- **Lawyer Approval**: `AuthService.updateLawyerApproval()`

### Cases
- **Create**: `CaseService.createCase()`
- **List**: `CaseService.getCasesByLawyer()` / `.getCasesByClient()`
- **Search**: `CaseService.searchCases()`
- **Status Change**: `CaseService.approveOrRejectCase()` / `.acceptCase()`
- **Complete**: `CaseService.markCaseAsCompleted()`

### Chat
- **Create Thread**: `ChatThreadService.createThread()`
- **Send Message**: `ChatThreadService.sendMessage()`
- **Read Messages**: `ChatThreadService.streamMessages()`
- **Mark Read**: `ChatThreadService.markThreadAsRead()`

### Reviews
- **Create**: `ReviewService.createOrUpdateReview()`
- **Get**: `ReviewService.getReviewsByLawyer()`
- **Lawyer Reply**: `ReviewService.replyToReview()`
- **Admin Moderation**: `ReviewService.changeReviewStatus()`

### Lawyers
- **Recommend**: `LawyerService.recommendLawyers(caseType)`
- **Get Reviews**: `LawyerService.getReviewsForLawyer()`
- **Update Rating**: `LawyerService._updateLawyerRating()`
- **AI Metrics**: `LawyerService.updateAIMetrics()`

### Admin
- **Approve Lawyer**: `AdminService.approveLawyer()`
- **Dashboard**: `AdminService.getDashboardSummary()`
- **AI Predictions**: `AdminService.getAllAIPredictions()`

---

## 🔗 Service Dependencies

```
AuthService
├── Creates: ClientModel, LawyerModel
└── Writes to: clients/, lawyers/, admins/

ClientService
├── Uses: ClientModel, CaseModel
└── Writes to: clients/, cases/

LawyerService
├── Uses: LawyerModel, ReviewModel
└── Reads from: lawyers/, reviews/

CaseService
├── Uses: CaseModel, AICasePredictionModel
└── Reads from: cases/

ChatThreadService
├── Uses: ChatThread, ChatMessage
└── Reads from: chats/ + messages/ subcollection

ReviewService
├── Uses: ReviewModel
└── Reads from: reviews/

AdminService
├── Uses: All models
└── Reads from: All collections

AppointmentService
├── Uses: AppointmentModel
└── Reads from: appointments/
```

---

## 📌 Important Notes

### Model Patterns
All models follow this pattern:
```dart
class MyModel {
  const MyModel({...});
  
  // From Firestore
  factory MyModel.fromJson(Map<String, dynamic> json) { ... }
  
  // To Firestore
  Map<String, dynamic> toJson() { ... }
  
  // Update with partial changes
  MyModel copyWith({...}) { ... }
}
```

### Service Patterns
All services follow this pattern:
```dart
class MyService {
  // Dependency injection
  MyService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;
  
  // Stream for real-time data
  Stream<List<MyModel>> getAll() { ... }
  
  // One-time fetch
  Future<MyModel?> getById(String id) { ... }
  
  // CRUD operations
  Future<void> create/update/delete(...) { ... }
}
```

### Collection Naming
- Plural form: `clients`, `lawyers`, `cases`, `reviews`
- Timestamps: Use `Timestamp.fromDate()` / `.toDate()`
- Timestamps in timestamps: Always Firestore `Timestamp` type
- Arrays: Use `FieldValue.arrayUnion()` / `arrayRemove()`

---

## ⚡ Quick Commands

### To use a service:
```dart
// 1. Import
import 'package:legal_sync/services/case_service.dart';

// 2. Create instance
final caseService = CaseService();

// 3. Use
await caseService.createCase(myCase);

// 4. Stream (real-time)
caseService.getCasesByLawyer(lawyerId).listen((cases) {
  // Update UI
});
```

### To use Riverpod:
```dart
// 1. Import provider
import 'package:legal_sync/provider/auth_provider.dart';

// 2. Read in widget
final authProvider = Provider((ref) => AuthProvider());

// 3. Watch in ConsumerWidget
consumer.watch(authProvider).currentUser // Gets user

// 4. Mutate
consumer.read(authProvider).login(email, password);
```

---

## 🎓 Learning Path for Developers

1. **Start with Models** - Understand data structure
2. **Learn Services** - How data is fetched/saved
3. **Study Providers** - State management (AuthProvider is complete)
4. **Build Screens** - UI that uses services
5. **Add Tests** - Ensure reliability

---

## 🚨 Critical Warnings

⚠️ **Hardcoded Admin Credentials**
- File: `lib/services/auth_services.dart`
- Lines: 18-19
- Fix: Move to Remote Config or environment variables

⚠️ **Print Statements** (14 instances)
- Location: Multiple services
- Fix: Replace with Firebase Crashlytics

⚠️ **File Naming Issues** (8 files)
- Examples: `case_Model.dart` should be `case_model.dart`
- Fix: Rename to snake_case

---

## 📞 Support

For questions about:
- **Data Model**: Check `lib/model/*.dart`
- **Operations**: Check corresponding `lib/services/*.dart`
- **Authentication**: See `AuthProvider` in `lib/provider/auth_provider.dart`
- **Firestore Schema**: See COMPLETE_CODEBASE_OVERVIEW.md

