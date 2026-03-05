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
        .snapshots()
        .map((snapshot) {
          final docs = snapshot.docs
              .map((doc) => DeadlineModel.fromJson(doc.data()))
              .toList();
          docs.sort((a, b) => a.dueDate.compareTo(b.dueDate)); // Chronological
          return docs;
        });
  }

  // ===============================
  // STREAM DEADLINES FOR LAWYER
  // ===============================
  Stream<List<DeadlineModel>> streamDeadlinesForLawyer(String lawyerId) {
    return _db
        .collection(_collection)
        .where('lawyerId', isEqualTo: lawyerId)
        .snapshots()
        .map((snapshot) {
          final docs = snapshot.docs
              .map((doc) => DeadlineModel.fromJson(doc.data()))
              .toList();
          docs.sort((a, b) => a.dueDate.compareTo(b.dueDate)); // Chronological
          return docs;
        });
  }

  // ===============================
  // GET OVERDUE DEADLINES
  // ===============================
  Stream<List<DeadlineModel>> streamOverdueDeadlines(String lawyerId) {
    return streamDeadlinesForLawyer(lawyerId).map((deadlines) {
      return deadlines
          .where(
            (deadline) => deadline.status != 'completed' && deadline.isOverdue,
          )
          .toList();
    });
  }

  // ===============================
  // STREAM DEADLINES BY PRIORITY
  // ===============================
  Stream<List<DeadlineModel>> streamDeadlinesByPriority(
    String lawyerId,
    String priority,
  ) {
    return _db
        .collection(_collection)
        .where('lawyerId', isEqualTo: lawyerId)
        .snapshots()
        .map((snapshot) {
          final docs = snapshot.docs
              .map((doc) => DeadlineModel.fromJson(doc.data()))
              .where((deadline) => deadline.priority == priority)
              .toList();
          docs.sort((a, b) => a.dueDate.compareTo(b.dueDate)); // Chronological
          return docs;
        });
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
        .get();

    final relevantDeadlines = snapshot.docs
        .map((doc) => DeadlineModel.fromJson(doc.data()))
        .where((deadline) {
          return deadline.status != 'completed' &&
              deadline.notificationSent == false &&
              (deadline.dueDate.isAfter(now) ||
                  deadline.dueDate.isAtSameMomentAs(now)) &&
              (deadline.dueDate.isBefore(until) ||
                  deadline.dueDate.isAtSameMomentAs(until));
        });

    for (final deadline in relevantDeadlines) {
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

  Future<void> bulkUpdateStatus(
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
