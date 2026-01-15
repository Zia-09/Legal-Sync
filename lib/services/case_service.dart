import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:legal_sync/model/case_Model.dart';

/// 🔹 CaseService handles all Firestore operations for case management
class CaseService {
  CaseService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const String _collection = 'cases';

  // =========================
  // CREATE & UPDATE
  // =========================

  Future<void> createCase(CaseModel caseModel) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(caseModel.caseId)
          .set(caseModel.toJson());
    } catch (e) {
      throw Exception('❌ Failed to create case: $e');
    }
  }

  Future<void> updateCase(String caseId, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = Timestamp.now();
      await _firestore.collection(_collection).doc(caseId).update(data);
    } catch (e) {
      throw Exception('❌ Failed to update case: $e');
    }
  }

  // =========================
  // GET CASES (STREAM)
  // =========================

  Stream<List<CaseModel>> getAllCases() => _getCasesStream(
    _firestore.collection(_collection).orderBy('createdAt', descending: true),
  );

  Stream<List<CaseModel>> getCasesByLawyer(String lawyerId) => _getCasesStream(
    _firestore
        .collection(_collection)
        .where('lawyerId', isEqualTo: lawyerId)
        .orderBy('createdAt', descending: true),
  );

  Stream<List<CaseModel>> getCasesByClient(String clientId) => _getCasesStream(
    _firestore
        .collection(_collection)
        .where('clientId', isEqualTo: clientId)
        .orderBy('createdAt', descending: true),
  );

  Stream<List<CaseModel>> getCasesByStatus(String status) => _getCasesStream(
    _firestore.collection(_collection).where('status', isEqualTo: status),
  );

  Stream<List<CaseModel>> getArchivedCases() => _getCasesStream(
    _firestore.collection(_collection).where('isArchived', isEqualTo: true),
  );

  Stream<List<CaseModel>> getPendingApprovalCases() => _getCasesStream(
    _firestore
        .collection(_collection)
        .where('isApproved', isEqualTo: false)
        .where('status', isEqualTo: 'pending'),
  );

  Stream<List<CaseModel>> searchCases(String query) => _getCasesStream(
    _firestore
        .collection(_collection)
        .where('title', isGreaterThanOrEqualTo: query)
        .where('title', isLessThanOrEqualTo: '$query\uf8ff'),
  );

  Stream<List<CaseModel>> filterCases({
    String? caseType,
    String? status,
    String? priority,
  }) {
    Query query = _firestore.collection(_collection);
    if (caseType != null) query = query.where('caseType', isEqualTo: caseType);
    if (status != null) query = query.where('status', isEqualTo: status);
    if (priority != null) query = query.where('priority', isEqualTo: priority);

    return _getCasesStream(query);
  }

  // =========================
  // SINGLE CASE
  // =========================

  Future<CaseModel?> getCaseById(String caseId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(caseId).get();
      if (!doc.exists || doc.data() == null) return null;
      return CaseModel.fromJson({
        ...doc.data() as Map<String, dynamic>,
        'caseId': doc.id,
      });
    } catch (e) {
      throw Exception('❌ Failed to fetch case: $e');
    }
  }

  // =========================
  // CASE ACTIONS
  // =========================

  Future<void> approveOrRejectCase({
    required String caseId,
    required bool isApproved,
    String? adminNote,
  }) async {
    try {
      await _firestore.collection(_collection).doc(caseId).update({
        'isApproved': isApproved,
        'adminNote': adminNote ?? '',
        'status': isApproved ? 'waiting_for_lawyer' : 'rejected',
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('❌ Failed to approve/reject case: $e');
    }
  }

  Future<void> acceptCase(String caseId, String lawyerId) async {
    try {
      await _firestore.collection(_collection).doc(caseId).update({
        'lawyerId': lawyerId,
        'status': 'ongoing',
        'isApproved': true,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('❌ Lawyer failed to accept case: $e');
    }
  }

  Future<void> rejectCaseByLawyer(String caseId, String reason) async {
    try {
      await _firestore.collection(_collection).doc(caseId).update({
        'status': 'waiting_for_lawyer',
        'remarks': reason,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('❌ Failed to reject case: $e');
    }
  }

  Future<void> markCaseAsCompleted(String caseId) async {
    try {
      await _firestore.collection(_collection).doc(caseId).update({
        'status': 'completed',
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('❌ Failed to complete case: $e');
    }
  }

  Future<void> reassignLawyer({
    required String caseId,
    required String newLawyerId,
    String? adminNote,
  }) async {
    try {
      await _firestore.collection(_collection).doc(caseId).update({
        'lawyerId': newLawyerId,
        'status': 'ongoing',
        'adminNote': adminNote ?? 'Reassigned by admin',
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('❌ Failed to reassign lawyer: $e');
    }
  }

  Future<void> addRemarks(String caseId, String remarks) async {
    try {
      await _firestore.collection(_collection).doc(caseId).update({
        'remarks': remarks,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('❌ Failed to add remarks: $e');
    }
  }

  Future<void> addDocument(String caseId, String documentUrl) async {
    try {
      await _firestore.collection(_collection).doc(caseId).update({
        'documentUrls': FieldValue.arrayUnion([documentUrl]),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('❌ Failed to add document: $e');
    }
  }

  Future<void> addClientFeedback({
    required String caseId,
    required String feedback,
  }) async {
    try {
      await _firestore.collection(_collection).doc(caseId).update({
        'feedback': feedback,
        'status': 'closed',
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('❌ Failed to add feedback: $e');
    }
  }

  Future<void> archiveCase(String caseId, bool isArchived) async {
    try {
      await _firestore.collection(_collection).doc(caseId).update({
        'isArchived': isArchived,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('❌ Failed to archive case: $e');
    }
  }

  Future<void> deleteCase(String caseId) async {
    try {
      await _firestore.collection(_collection).doc(caseId).delete();
    } catch (e) {
      throw Exception('❌ Failed to delete case: $e');
    }
  }

  // =========================
  // PRIVATE HELPERS
  // =========================

  Stream<List<CaseModel>> _getCasesStream(Query query) {
    return query.snapshots().map(
      (snapshot) => snapshot.docs
          .map(
            (doc) => CaseModel.fromJson({
              ...doc.data() as Map<String, dynamic>,
              'caseId': doc.id,
            }),
          )
          .toList(),
    );
  }
}
