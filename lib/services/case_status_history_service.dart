import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/case_status_history_Model.dart';

class CaseStatusHistoryService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _collection = 'case_status_history';

  // ===============================
  // CREATE STATUS HISTORY ENTRY
  // ===============================
  Future<String> createStatusHistory(CaseStatusHistoryModel history) async {
    final docRef = _db.collection(_collection).doc();
    await docRef.set({...history.toJson(), 'historyId': docRef.id});
    return docRef.id;
  }

  // ===============================
  // LOG STATUS CHANGE
  // ===============================
  Future<void> logStatusChange({
    required String caseId,
    required String lawyerId,
    required String previousStatus,
    required String newStatus,
    required String changedBy,
    String? reason,
    String? notes,
  }) async {
    final history = CaseStatusHistoryModel(
      historyId: '', // Will be set by docRef
      caseId: caseId,
      lawyerId: lawyerId,
      previousStatus: previousStatus,
      newStatus: newStatus,
      reason: reason,
      changedBy: changedBy,
      changedAt: DateTime.now(),
      notes: notes,
    );
    await createStatusHistory(history);
  }

  // ===============================
  // GET CASE STATUS HISTORY
  // ===============================
  Stream<List<CaseStatusHistoryModel>> streamCaseStatusHistory(String caseId) {
    return _db
        .collection(_collection)
        .where('caseId', isEqualTo: caseId)
        .orderBy('changedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => CaseStatusHistoryModel.fromJson(doc.data()))
              .toList(),
        );
  }

  // ===============================
  // GET LAWYER'S CASE HISTORIES
  // ===============================
  Stream<List<CaseStatusHistoryModel>> streamLawyerStatusHistories(
    String lawyerId,
  ) {
    return _db
        .collection(_collection)
        .where('lawyerId', isEqualTo: lawyerId)
        .orderBy('changedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => CaseStatusHistoryModel.fromJson(doc.data()))
              .toList(),
        );
  }

  // ===============================
  // GET LAST STATUS CHANGE
  // ===============================
  Future<CaseStatusHistoryModel?> getLastStatusChange(String caseId) async {
    final snapshot = await _db
        .collection(_collection)
        .where('caseId', isEqualTo: caseId)
        .orderBy('changedAt', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return CaseStatusHistoryModel.fromJson(snapshot.docs.first.data());
    }
    return null;
  }

  // ===============================
  // GET STATUS CHANGE COUNT FOR CASE
  // ===============================
  Future<int> getStatusChangeCount(String caseId) async {
    final snapshot = await _db
        .collection(_collection)
        .where('caseId', isEqualTo: caseId)
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  // ===============================
  // GET STATUS CHANGES IN DATE RANGE
  // ===============================
  Stream<List<CaseStatusHistoryModel>> streamStatusChangesInRange({
    required String caseId,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return _db
        .collection(_collection)
        .where('caseId', isEqualTo: caseId)
        .where(
          'changedAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        )
        .where('changedAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('changedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => CaseStatusHistoryModel.fromJson(doc.data()))
              .toList(),
        );
  }

  // ===============================
  // DELETE HISTORY ENTRY
  // ===============================
  Future<void> deleteStatusHistory(String historyId) async {
    await _db.collection(_collection).doc(historyId).delete();
  }
}
