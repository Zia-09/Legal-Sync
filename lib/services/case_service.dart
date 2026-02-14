import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:legal_sync/app_helper/case_status_helper.dart';
import 'package:legal_sync/model/case_Model.dart';
import 'package:legal_sync/model/notification_model.dart';
import 'package:legal_sync/services/case_status_history_service.dart';
import 'package:legal_sync/services/notification_services.dart';

/// 🔹 CaseService handles all Firestore operations for case management
class CaseService {
  CaseService({
    FirebaseFirestore? firestore,
    CaseStatusHistoryService? statusHistoryService,
    NotificationService? notificationService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _statusHistoryService = statusHistoryService ?? CaseStatusHistoryService(),
       _notificationService = notificationService ?? NotificationService();

  final FirebaseFirestore _firestore;
  final CaseStatusHistoryService _statusHistoryService;
  final NotificationService _notificationService;
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

  Future<String> createCaseWithGeneratedId(CaseModel caseModel) async {
    final docRef = _firestore.collection(_collection).doc();
    await docRef.set({
      ...caseModel.toJson(),
      'caseId': docRef.id,
      'createdAt': Timestamp.now(),
    });
    return docRef.id;
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

  Stream<List<CaseModel>> getActiveCases() => _getCasesStream(
    _firestore
        .collection(_collection)
        .where(
          'status',
          whereIn: const ['pending', 'in_progress', 'in-progress', 'ongoing'],
        ),
  );

  Stream<List<CaseModel>> getClosedCases() => _getCasesStream(
    _firestore
        .collection(_collection)
        .where('status', whereIn: const ['closed', 'completed']),
  );

  Stream<List<CaseModel>> streamAllCases() => getAllCases();
  Stream<List<CaseModel>> streamCasesByLawyer(String lawyerId) =>
      getCasesByLawyer(lawyerId);
  Stream<List<CaseModel>> streamCasesByClient(String clientId) =>
      getCasesByClient(clientId);
  Stream<List<CaseModel>> streamActiveCases() => getActiveCases();
  Stream<List<CaseModel>> streamClosedCases() => getClosedCases();

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

  Future<CaseModel?> getCase(String caseId) => getCaseById(caseId);

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
        'status': isApproved ? CaseStatusHelper.pending : CaseStatusHelper.rejected,
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
        'status': CaseStatusHelper.inProgress,
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
        'status': CaseStatusHelper.pending,
        'remarks': reason,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('❌ Failed to reject case: $e');
    }
  }

  Future<void> markCaseAsCompleted(String caseId) async {
    await updateCaseStatus(caseId, CaseStatusHelper.closed);
  }

  Future<void> reassignLawyer({
    required String caseId,
    required String newLawyerId,
    String? adminNote,
  }) async {
    try {
      await _firestore.collection(_collection).doc(caseId).update({
        'lawyerId': newLawyerId,
        'status': CaseStatusHelper.inProgress,
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
        'status': CaseStatusHelper.closed,
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

  Future<void> unarchiveCase(String caseId) async {
    await archiveCase(caseId, false);
  }

  Future<void> updateCaseStatus(
    String caseId,
    String newStatus, {
    String? changedBy,
    String? reason,
    String? notes,
    bool notifyParticipants = true,
  }) async {
    final caseModel = await getCaseById(caseId);
    if (caseModel == null) {
      throw Exception('Case not found');
    }

    final normalizedCurrent = CaseStatusHelper.normalize(caseModel.status);
    final normalizedNext = CaseStatusHelper.normalize(newStatus);

    if (!CaseStatusHelper.isKnownStatus(normalizedNext)) {
      throw Exception('Invalid case status: $newStatus');
    }

    if (!CaseStatusHelper.canTransition(
      currentStatus: normalizedCurrent,
      nextStatus: normalizedNext,
    )) {
      throw Exception(
        'Invalid transition: $normalizedCurrent -> $normalizedNext',
      );
    }

    await _firestore.collection(_collection).doc(caseId).update({
      'status': normalizedNext,
      'updatedAt': Timestamp.now(),
    });

    await _statusHistoryService.logStatusChange(
      caseId: caseId,
      lawyerId: caseModel.lawyerId,
      previousStatus: normalizedCurrent,
      newStatus: normalizedNext,
      changedBy: changedBy ?? caseModel.lawyerId,
      reason: reason,
      notes: notes,
    );

    if (!notifyParticipants) {
      return;
    }

    final title = 'Case Status Updated';
    final message = '${caseModel.title} is now "$normalizedNext".';
    final metadata = <String, dynamic>{
      'caseId': caseId,
      'previousStatus': normalizedCurrent,
      'newStatus': normalizedNext,
    };

    final recipients = <String>{
      if (caseModel.clientId.isNotEmpty) caseModel.clientId,
      if (caseModel.lawyerId.isNotEmpty) caseModel.lawyerId,
    };

    for (final userId in recipients) {
      await _notificationService.addNotification(
        NotificationModel(
          notificationId: _notificationService.generateNotificationId(),
          userId: userId,
          title: title,
          message: message,
          type: 'case_status',
          createdAt: DateTime.now(),
          metadata: metadata,
        ),
      );
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
