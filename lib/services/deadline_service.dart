import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/deadline_Model.dart';
import 'notification_services.dart';

class DeadlineService {
  DeadlineService({
    FirebaseFirestore? firestore,
    NotificationService? notificationService,
  }) : _db = firestore ?? FirebaseFirestore.instance,
       _notificationService = notificationService ?? NotificationService();

  final FirebaseFirestore _db;
  final NotificationService _notificationService;
  static const String _collection = 'deadlines';

  // ===============================
  // CREATE DEADLINE
  // ===============================
  Future<String> createDeadline(DeadlineModel deadline) async {
    final docRef = _db.collection(_collection).doc();
    final deadlineWithId = deadline.copyWith();
    await docRef.set({...deadlineWithId.toJson(), 'deadlineId': docRef.id});
    return docRef.id;
  }

  Future<String> createDeadlineWithReminder({
    required DeadlineModel deadline,
    required List<String> recipientUserIds,
  }) async {
    final deadlineId = await createDeadline(deadline);
    final scheduleAt = deadline.remindAt ?? deadline.dueDate;

    await _notificationService.queuePushNotification(
      userIds: recipientUserIds,
      title: 'Deadline Reminder',
      message: '${deadline.title} is due on ${deadline.dueDate.toLocal()}',
      data: {
        'type': 'deadline',
        'deadlineId': deadlineId,
        'caseId': deadline.caseId,
      },
      scheduledAt: scheduleAt,
    );

    return deadlineId;
  }

  // ===============================
  // GET DEADLINE BY ID
  // ===============================
  Future<DeadlineModel?> getDeadline(String deadlineId) async {
    final doc = await _db.collection(_collection).doc(deadlineId).get();
    if (doc.exists) {
      return DeadlineModel.fromJson(doc.data()!);
    }
    return null;
  }

  // ===============================
  // UPDATE DEADLINE
  // ===============================
  Future<void> updateDeadline(DeadlineModel deadline) async {
    await _db
        .collection(_collection)
        .doc(deadline.deadlineId)
        .update(deadline.toJson());
  }

  // ===============================
  // DELETE DEADLINE
  // ===============================
  Future<void> deleteDeadline(String deadlineId) async {
    await _db.collection(_collection).doc(deadlineId).delete();
  }

  // ===============================
  // STREAM DEADLINES FOR CASE
  // ===============================
  Stream<List<DeadlineModel>> streamDeadlinesForCase(String caseId) {
    return _db
        .collection(_collection)
        .where('caseId', isEqualTo: caseId)
        .orderBy('dueDate', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => DeadlineModel.fromJson(doc.data()))
              .toList(),
        );
  }

  // ===============================
  // STREAM DEADLINES FOR LAWYER
  // ===============================
  Stream<List<DeadlineModel>> streamDeadlinesForLawyer(String lawyerId) {
    return _db
        .collection(_collection)
        .where('lawyerId', isEqualTo: lawyerId)
        .orderBy('dueDate', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => DeadlineModel.fromJson(doc.data()))
              .toList(),
        );
  }

  // ===============================
  // GET OVERDUE DEADLINES
  // ===============================
  Stream<List<DeadlineModel>> streamOverdueDeadlines(String lawyerId) {
    return _db
        .collection(_collection)
        .where('lawyerId', isEqualTo: lawyerId)
        .where('status', isNotEqualTo: 'completed')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => DeadlineModel.fromJson(doc.data()))
              .where((deadline) => deadline.isOverdue)
              .toList(),
        );
  }

  // ===============================
  // MARK DEADLINE AS COMPLETED
  // ===============================
  Future<void> completeDeadline(String deadlineId) async {
    await _db.collection(_collection).doc(deadlineId).update({
      'status': 'completed',
      'completedAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    });
  }

  // ===============================
  // UPDATE NOTIFICATION STATUS
  // ===============================
  Future<void> markNotificationSent(String deadlineId) async {
    await _db.collection(_collection).doc(deadlineId).update({
      'notificationSent': true,
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> triggerUpcomingDeadlineReminders({
    required String lawyerId,
    Duration within = const Duration(days: 1),
  }) async {
    final now = DateTime.now();
    final until = now.add(within);
    final snapshot = await _db
        .collection(_collection)
        .where('lawyerId', isEqualTo: lawyerId)
        .where('status', isNotEqualTo: 'completed')
        .where('notificationSent', isEqualTo: false)
        .where('dueDate', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
        .where('dueDate', isLessThanOrEqualTo: Timestamp.fromDate(until))
        .get();

    for (final doc in snapshot.docs) {
      final deadline = DeadlineModel.fromJson(doc.data());
      await _notificationService.queuePushNotification(
        userIds: [lawyerId],
        title: 'Upcoming Deadline',
        message: '${deadline.title} is due soon.',
        data: {
          'type': 'deadline',
          'deadlineId': deadline.deadlineId,
          'caseId': deadline.caseId,
        },
      );
      await markNotificationSent(deadline.deadlineId);
    }
  }

  // ===============================
  // GET DEADLINES BY PRIORITY
  // ===============================
  Stream<List<DeadlineModel>> streamDeadlinesByPriority(
    String lawyerId,
    String priority,
  ) {
    return _db
        .collection(_collection)
        .where('lawyerId', isEqualTo: lawyerId)
        .where('priority', isEqualTo: priority)
        .orderBy('dueDate', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => DeadlineModel.fromJson(doc.data()))
              .toList(),
        );
  }

  // ===============================
  // BATCH UPDATE STATUS
  // ===============================
  Future<void> batchUpdateStatus(
    List<String> deadlineIds,
    String newStatus,
  ) async {
    final batch = _db.batch();
    for (final id in deadlineIds) {
      batch.update(_db.collection(_collection).doc(id), {
        'status': newStatus,
        'updatedAt': Timestamp.now(),
      });
    }
    await batch.commit();
  }
}
