import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/deadline_Model.dart';

class DeadlineService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
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
    final now = DateTime.now();
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
