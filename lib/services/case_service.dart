import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'dart:async';
import 'package:legal_sync/app_helper/case_status_helper.dart';
import 'package:legal_sync/model/case_Model.dart';
import 'package:legal_sync/model/notification_model.dart';
import 'package:legal_sync/services/case_status_history_service.dart';
import 'package:legal_sync/services/notification_services.dart';
import 'package:legal_sync/services/activity_service.dart';
import 'package:legal_sync/services/email_service.dart';
import 'package:legal_sync/services/lawyer_services.dart';

/// 🔹 CaseService handles all Firestore operations for case management
class CaseService {
  CaseService({
    FirebaseFirestore? firestore,
    CaseStatusHistoryService? statusHistoryService,
    NotificationService? notificationService,
    ActivityService? activityService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _statusHistoryService =
           statusHistoryService ?? CaseStatusHistoryService(),
       _notificationService = notificationService ?? NotificationService(),
       _activityService = activityService ?? ActivityService();

  final FirebaseFirestore _firestore;
  final CaseStatusHistoryService _statusHistoryService;
  final NotificationService _notificationService;
  final ActivityService _activityService;
  static const String _collection = 'cases';

  // =========================
  // CREATE & UPDATE
  // =========================

  Future<void> createCase(CaseModel caseModel) async {
    try {
      await _firestore
          .collection('cases')
          .doc(caseModel.caseId)
          .set(caseModel.toJson());

      // Log Activity
      await _activityService.logActivity(
        caseId: caseModel.caseId,
        userId: caseModel.lawyerId,
        userName: 'Lawyer',
        userRole: 'lawyer',
        actionType: 'case_created',
        actionDescription: 'Lawyer created case',
      );
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

    // Log Activity
    await _activityService.logActivity(
      caseId: docRef.id,
      userId: caseModel.lawyerId,
      userName: 'Lawyer',
      userRole: 'lawyer',
      actionType: 'case_created',
      actionDescription: 'Lawyer created case',
    );
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

  /// 🔹 Update case and send email notification to client
  Future<void> updateCaseWithEmailNotification({
    required String caseId,
    required Map<String, dynamic> updateData,
    required String
    updateType, // 'status_updated', 'note_added', 'document_added'
    required String updateDescription,
  }) async {
    try {
      // First update the case
      updateData['updatedAt'] = Timestamp.now();
      await _firestore.collection(_collection).doc(caseId).update(updateData);

      // Get case and client data for email
      final caseDoc = await _firestore
          .collection(_collection)
          .doc(caseId)
          .get();
      if (!caseDoc.exists) return;

      final caseData = caseDoc.data() as Map<String, dynamic>;
      final clientId = caseData['clientId'] as String?;
      final caseTitle = caseData['title'] as String? ?? 'Your Case';
      final caseNumber = caseData['caseNumber'] as String? ?? 'N/A';
      final newStatus =
          updateData['status'] as String? ??
          caseData['status'] as String? ??
          'Updated';

      if (clientId != null && clientId.isNotEmpty) {
        // Get client email
        final clientDoc = await _firestore
            .collection('users')
            .doc(clientId)
            .get();
        if (clientDoc.exists) {
          final clientData = clientDoc.data() as Map<String, dynamic>;
          final clientEmail = clientData['email'] as String?;
          final clientName = clientData['name'] as String? ?? 'Client';

          if (clientEmail != null && clientEmail.isNotEmpty) {
            // Send email notification (fire-and-forget to avoid blocking)
            unawaited(
              EmailService().sendCaseUpdateEmail(
                toEmail: clientEmail,
                recipientName: clientName,
                caseTitle: caseTitle,
                caseNumber: caseNumber,
                updateType: updateType,
                updateDescription: updateDescription,
                newStatus: newStatus,
              ),
            );
          }
        }
      }
    } catch (e) {
      print('⚠️ Case updated but email notification failed: $e');
      // Don't throw - case was updated successfully even if email failed
    }
  }

  // =========================
  // GET CASES (STREAM)
  // =========================

  Stream<List<CaseModel>> getAllCases() =>
      _getCasesStream(_firestore.collection(_collection));

  Stream<List<CaseModel>> getCasesByLawyer(String lawyerId) => _getCasesStream(
    _firestore.collection(_collection).where('lawyerId', isEqualTo: lawyerId),
  );

  Stream<List<CaseModel>> getCasesByClient(String clientId) => _getCasesStream(
    _firestore.collection(_collection).where('clientId', isEqualTo: clientId),
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

  Stream<List<CaseModel>> getPendingApprovalCases() => getAllCases().map(
    (cases) => cases
        .where((c) => c.isApproved == false && c.status == 'pending')
        .toList(),
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
    return getAllCases().map((cases) {
      return cases.where((c) {
        if (caseType != null && c.caseType != caseType) return false;
        if (status != null && c.status != status) return false;
        if (priority != null && c.priority != priority) return false;
        return true;
      }).toList();
    });
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
        'status': isApproved
            ? CaseStatusHelper.pending
            : CaseStatusHelper.rejected,
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

  Future<String> uploadCaseDocument(String caseId, File file) async {
    try {
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      final ref = FirebaseStorage.instance
          .ref()
          .child('cases')
          .child(caseId)
          .child('documents')
          .child(fileName);

      await ref.putFile(file);
      final downloadUrl = await ref.getDownloadURL();
      await addDocument(caseId, downloadUrl);
      return downloadUrl;
    } catch (e) {
      throw Exception('❌ Failed to upload document: $e');
    }
  }

  Future<void> addCaseNote(String caseId, String note) async {
    try {
      await _firestore.collection(_collection).doc(caseId).update({
        'notes': FieldValue.arrayUnion([note]),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('❌ Failed to add note: $e');
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
      await _firestore.collection('cases').doc(caseId).delete();
    } catch (e) {
      throw Exception('❌ Failed to delete case: $e');
    }
  }

  // =========================
  // CASE COMPLETION & OUTCOME
  // =========================

  /// 🔹 Mark case with final outcome (won, lost, settled, dismissed, appealed)
  /// Sends completion email to client with outcome details
  Future<void> markCaseWithOutcome({
    required String caseId,
    required String
    outcome, // 'won', 'lost', 'settled', 'dismissed', 'appealed'
    required String outcomeNotes,
    String? lawyerId,
  }) async {
    try {
      // Get case and client data
      final caseDoc = await _firestore
          .collection(_collection)
          .doc(caseId)
          .get();
      if (!caseDoc.exists) throw Exception('Case not found');

      final caseData = caseDoc.data() as Map<String, dynamic>;
      final clientId = caseData['clientId'] as String;
      final lawyerIdVal = lawyerId ?? (caseData['lawyerId'] as String?);
      final caseTitle = caseData['title'] as String? ?? 'Your Case';

      // Update case with outcome
      await _firestore.collection(_collection).doc(caseId).update({
        'status': 'closed',
        'caseOutcome': outcome,
        'outcomeNotes': outcomeNotes,
        'completedAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      // Log status history
      await _statusHistoryService.logStatusChange(
        caseId: caseId,
        lawyerId: lawyerIdVal ?? '',
        previousStatus: caseData['status'] as String? ?? 'pending',
        newStatus: 'closed',
        changedBy: lawyerIdVal ?? 'system',
        reason: 'Case completed with outcome: $outcome',
        notes: outcomeNotes,
      );

      // Get client email and send notification
      final clientDoc = await _firestore
          .collection('users')
          .doc(clientId)
          .get();
      if (clientDoc.exists) {
        final clientData = clientDoc.data() as Map<String, dynamic>;
        final clientEmail = clientData['email'] as String?;
        final clientName = clientData['name'] as String? ?? 'Client';

        if (clientEmail != null && clientEmail.isNotEmpty) {
          // Send appropriate completion email based on outcome
          unawaited(
            _sendCaseCompletionEmail(
              clientEmail: clientEmail,
              clientName: clientName,
              lawyerName: caseData['lawyerName'] as String? ?? 'Your Lawyer',
              caseTitle: caseTitle,
              outcome: outcome,
              outcomeNotes: outcomeNotes,
            ),
          );
        }
      }

      // Add notification
      if (clientId.isNotEmpty) {
        await _notificationService.addNotification(
          NotificationModel(
            notificationId: _notificationService.generateNotificationId(),
            userId: clientId,
            title: 'Case Completed',
            message:
                'Your case "$caseTitle" has been completed. Outcome: $outcome',
            type: 'case_completed',
            createdAt: DateTime.now(),
            metadata: {'caseId': caseId, 'outcome': outcome},
          ),
        );
      }

      // Update lawyer case statistics
      if (lawyerIdVal != null && lawyerIdVal.isNotEmpty) {
        try {
          final lawyerService = LawyerService();
          await lawyerService.updateCaseStatistics(
            lawyerId: lawyerIdVal,
            outcome: outcome,
          );
        } catch (e) {
          print('⚠️ Failed to update lawyer statistics: $e');
          // Don't throw - case was already marked complete
        }
      }
    } catch (e) {
      throw Exception('❌ Failed to mark case with outcome: $e');
    }
  }

  /// 🔹 Complete a hearing for a case
  /// Increments hearing count and tracks hearing completion
  Future<void> completeHearing({
    required String caseId,
    required String hearingId,
  }) async {
    try {
      final caseDoc = await _firestore
          .collection(_collection)
          .doc(caseId)
          .get();
      if (!caseDoc.exists) throw Exception('Case not found');

      final caseData = caseDoc.data() as Map<String, dynamic>;
      final completedHearings =
          (caseData['completedHearings'] as num?)?.toInt() ?? 0;
      final completedIds =
          (caseData['completedHearingIds'] as List?)?.cast<String>() ?? [];

      // Add hearing ID if not already present
      if (!completedIds.contains(hearingId)) {
        completedIds.add(hearingId);

        // Update case with completed hearing
        await _firestore.collection(_collection).doc(caseId).update({
          'completedHearings': completedHearings + 1,
          'completedHearingIds': completedIds,
          'updatedAt': Timestamp.now(),
        });
      }

      // Notify if case is now ready for completion
      final hearingsList =
          (caseData['hearings'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      if (completedIds.length == hearingsList.length &&
          hearingsList.isNotEmpty) {
        // All hearings completed - notify lawyer
        final lawyerId = caseData['lawyerId'] as String?;
        if (lawyerId != null && lawyerId.isNotEmpty) {
          await _notificationService.addNotification(
            NotificationModel(
              notificationId: _notificationService.generateNotificationId(),
              userId: lawyerId,
              title: 'Case Ready for Completion',
              message:
                  'All hearings for "${caseData['title']}" have been completed. You can now close the case.',
              type: 'case_ready_for_completion',
              createdAt: DateTime.now(),
              metadata: {'caseId': caseId},
            ),
          );
        }
      }
    } catch (e) {
      throw Exception('❌ Failed to complete hearing: $e');
    }
  }

  /// 🔹 Get case progress percentage based on completed hearings
  Stream<int> streamCaseProgressPercentage(String caseId) {
    return _firestore.collection(_collection).doc(caseId).snapshots().map((
      snapshot,
    ) {
      if (!snapshot.exists) return 0;

      final data = snapshot.data() as Map<String, dynamic>;
      final hearings =
          (data['hearings'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      final completedHearings =
          (data['completedHearings'] as num?)?.toInt() ?? 0;

      if (hearings.isEmpty) return 0;
      return ((completedHearings / hearings.length) * 100).toInt();
    });
  }

  /// 🔹 Check if case is ready for completion (all hearings done)
  Future<bool> checkIfCaseReadyForCompletion(String caseId) async {
    try {
      final caseDoc = await _firestore
          .collection(_collection)
          .doc(caseId)
          .get();
      if (!caseDoc.exists) return false;

      final data = caseDoc.data() as Map<String, dynamic>;
      final hearings =
          (data['hearings'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      final completedHearings =
          (data['completedHearings'] as num?)?.toInt() ?? 0;

      return hearings.isNotEmpty && completedHearings == hearings.length;
    } catch (e) {
      print('❌ Error checking case completion: $e');
      return false;
    }
  }

  /// 🔹 Stream cases that are ready for completion
  Stream<List<CaseModel>> streamCasesReadyForCompletion(String lawyerId) {
    return _firestore
        .collection(_collection)
        .where('lawyerId', isEqualTo: lawyerId)
        .where('status', isEqualTo: 'in_progress')
        .snapshots()
        .map((snapshot) {
          final cases = snapshot.docs
              .map(
                (doc) => CaseModel.fromJson({
                  ...doc.data() as Map<String, dynamic>,
                  'caseId': doc.id,
                }),
              )
              .toList();

          // Filter to only include cases where all hearings are completed
          return cases.where((caseModel) {
            final hearings = caseModel.hearings;
            final completedHearings = caseModel.completedHearings;
            return hearings.isNotEmpty && completedHearings == hearings.length;
          }).toList();
        });
  }

  /// 🔹 Get case completion metrics
  Future<Map<String, dynamic>> getCaseCompletionMetrics(String caseId) async {
    try {
      final caseDoc = await _firestore
          .collection(_collection)
          .doc(caseId)
          .get();
      if (!caseDoc.exists) throw Exception('Case not found');

      final data = caseDoc.data() as Map<String, dynamic>;
      final hearings =
          (data['hearings'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      final completedHearings =
          (data['completedHearings'] as num?)?.toInt() ?? 0;
      final caseOutcome = data['caseOutcome'] as String?;
      final completedAt = data['completedAt'];

      final percentage = hearings.isEmpty
          ? 0
          : ((completedHearings / hearings.length) * 100).toInt();

      return {
        'totalHearings': hearings.length,
        'completedHearings': completedHearings,
        'percentageComplete': percentage,
        'isReadyForCompletion':
            hearings.isNotEmpty && completedHearings == hearings.length,
        'isCompleted': caseOutcome != null,
        'outcome': caseOutcome,
        'completedAt': completedAt,
      };
    } catch (e) {
      throw Exception('❌ Failed to get completion metrics: $e');
    }
  }

  // =========================
  // PRIVATE HELPERS
  // =========================

  /// 🔹 Send case completion email with outcome
  Future<void> _sendCaseCompletionEmail({
    required String clientEmail,
    required String clientName,
    required String lawyerName,
    required String caseTitle,
    required String outcome,
    required String outcomeNotes,
  }) async {
    try {
      final subject = 'Case Completed: $caseTitle';
      final outcomeText = outcome.toUpperCase();

      final htmlContent =
          '''
        <html>
          <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
            <div style="max-width: 600px; margin: 0 auto; padding: 20px;">
              <h2 style="color: #0066cc;">Case Completion Notification</h2>
              
              <p>Dear $clientName,</p>
              
              <p>We are pleased to inform you that your case has been completed.</p>
              
              <div style="background-color: #f5f5f5; padding: 15px; border-left: 4px solid #0066cc; margin: 20px 0;">
                <p><strong>Case Title:</strong> $caseTitle</p>
                <p><strong>Outcome:</strong> <span style="color: #28a745; font-weight: bold;">$outcomeText</span></p>
                <p><strong>Details:</strong> $outcomeNotes</p>
              </div>
              
              <p>Your lawyer, <strong>$lawyerName</strong>, is available if you have any follow-up questions or need further assistance.</p>
              
              <p>Thank you for trusting us with your legal matter.</p>
              
              <p>Best regards,<br>LegalSync Team</p>
              
              <hr style="border: none; border-top: 1px solid #ddd; margin: 20px 0;">
              <footer style="font-size: 12px; color: #666;">
                <p>This is an automated email from LegalSync. Please do not reply directly.</p>
              </footer>
            </div>
          </body>
        </html>
      ''';

      await EmailService().sendProfessionalEmail(
        to: clientEmail,
        subject: subject,
        htmlContent: htmlContent,
      );
    } catch (e) {
      print('⚠️ Failed to send case completion email: $e');
    }
  }

  Stream<List<CaseModel>> _getCasesStream(Query query) {
    return query.snapshots().map(
      (snapshot) =>
          snapshot.docs
              .map(
                (doc) => CaseModel.fromJson({
                  ...doc.data() as Map<String, dynamic>,
                  'caseId': doc.id,
                }),
              )
              .toList()
            ..sort(
              (a, b) => b.createdAt.compareTo(a.createdAt),
            ), // Newest first
    );
  }
}
