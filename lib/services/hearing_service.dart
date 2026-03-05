import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:legal_sync/model/hearing_Model.dart';
import 'package:legal_sync/services/notification_services.dart';

class HearingService {
  HearingService({
    FirebaseFirestore? firestore,
    NotificationService? notificationService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _notificationService = notificationService ?? NotificationService();

  final FirebaseFirestore _firestore;
  final NotificationService _notificationService;
  static const String _collection = 'hearings';

  /// 🔹 Create hearing
  Future<void> createHearing(HearingModel hearing) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(hearing.hearingId)
          .set(hearing.toJson());
    } catch (e) {
      throw Exception('Failed to create hearing: $e');
    }
  }

  Future<void> createHearingWithReminder({
    required HearingModel hearing,
    required List<String> recipientUserIds,
    int hoursBefore = 24,
  }) async {
    await createHearing(hearing);
    await _notificationService.queuePushNotification(
      userIds: recipientUserIds,
      title: 'Upcoming Hearing Reminder',
      message:
          'Hearing for case ${hearing.caseId} at ${hearing.courtName ?? 'court'}',
      data: {
        'type': 'hearing',
        'hearingId': hearing.hearingId,
        'caseId': hearing.caseId,
      },
      scheduledAt: hearing.hearingDate.subtract(Duration(hours: hoursBefore)),
    );
  }

  /// 🔹 Update hearing
  Future<void> updateHearing(
    String hearingId,
    Map<String, dynamic> data,
  ) async {
    try {
      data['updatedAt'] = Timestamp.now();
      await _firestore.collection(_collection).doc(hearingId).update(data);
    } catch (e) {
      throw Exception('Failed to update hearing: $e');
    }
  }

  /// 🔹 Get hearing by ID
  Future<HearingModel?> getHearingById(String hearingId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(hearingId).get();
      if (!doc.exists || doc.data() == null) return null;
      return HearingModel.fromJson({
        ...doc.data() as Map<String, dynamic>,
        'hearingId': doc.id,
      });
    } catch (e) {
      throw Exception('Failed to fetch hearing: $e');
    }
  }

  /// 🔹 Get hearings for a case
  Stream<List<HearingModel>> getHearingsByCase(String caseId) {
    return _firestore
        .collection(_collection)
        .where('caseId', isEqualTo: caseId)
        .snapshots()
        .map((snapshot) {
          final docs = snapshot.docs
              .map(
                (doc) => HearingModel.fromJson({
                  ...doc.data() as Map<String, dynamic>,
                  'hearingId': doc.id,
                }),
              )
              .toList();
          docs.sort(
            (a, b) => a.hearingDate.compareTo(b.hearingDate),
          ); // Ascending
          return docs;
        });
  }

  // Backward-compatible alias used by provider layer.
  Stream<List<HearingModel>> streamHearings(String caseId) =>
      getHearingsByCase(caseId);

  Future<void> addHearing(HearingModel hearing) => createHearing(hearing);

  /// 🔹 Get upcoming hearings for lawyer
  Stream<List<HearingModel>> getUpcomingHearings(String lawyerId) {
    return _firestore
        .collection(_collection)
        .where('createdBy', isEqualTo: lawyerId)
        .snapshots()
        .map((snapshot) {
          final now = DateTime.now();
          final docs = snapshot.docs
              .map(
                (doc) => HearingModel.fromJson({
                  ...doc.data() as Map<String, dynamic>,
                  'hearingId': doc.id,
                }),
              )
              .where((h) {
                final isUpcoming = h.hearingDate.isAfter(now);
                final isActive = ['scheduled', 'ongoing'].contains(h.status);
                return isUpcoming && isActive;
              })
              .toList();
          docs.sort(
            (a, b) => a.hearingDate.compareTo(b.hearingDate),
          ); // Chronological
          return docs;
        });
  }

  /// 🔹 Delete hearing
  Future<void> deleteHearing(String hearingId) async {
    try {
      await _firestore.collection(_collection).doc(hearingId).delete();
    } catch (e) {
      throw Exception('Failed to delete hearing: $e');
    }
  }

  /// 🔹 Mark reminder sent
  Future<void> markReminderSent(String hearingId) async {
    try {
      await _firestore.collection(_collection).doc(hearingId).update({
        'reminderSent': true,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to mark reminder: $e');
    }
  }

  Future<void> triggerReminders([String? lawyerId]) async {
    final now = DateTime.now();
    final nextDay = now.add(const Duration(hours: 24));

    Query<Map<String, dynamic>> query = _firestore
        .collection(_collection)
        .where('status', isEqualTo: 'scheduled')
        .where('reminderSent', isEqualTo: false)
        .where('hearingDate', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
        .where('hearingDate', isLessThanOrEqualTo: Timestamp.fromDate(nextDay));

    if (lawyerId != null && lawyerId.isNotEmpty) {
      query = query.where('createdBy', isEqualTo: lawyerId);
    }

    final snapshot = await query.get();

    for (final doc in snapshot.docs) {
      final hearing = HearingModel.fromJson({
        ...doc.data(),
        'hearingId': doc.id,
      });
      final recipients = <String>{
        if (lawyerId != null && lawyerId.isNotEmpty) lawyerId,
        if (hearing.createdBy != null && hearing.createdBy!.isNotEmpty)
          hearing.createdBy!,
      };
      if (recipients.isEmpty) {
        await markReminderSent(doc.id);
        continue;
      }
      await _notificationService.queuePushNotification(
        userIds: recipients.toList(),
        title: 'Hearing in 24 hours',
        message:
            'Hearing for case ${hearing.caseId} at ${hearing.courtName ?? 'court'}',
        data: {'type': 'hearing', 'hearingId': hearing.hearingId},
      );
      await markReminderSent(doc.id);
    }
  }

  /// 🔹 Complete hearing
  Future<void> completeHearing({
    required String hearingId,
    required String outcome,
    String? judgeNotes,
  }) async {
    try {
      await _firestore.collection(_collection).doc(hearingId).update({
        'status': 'completed',
        'outcome': outcome,
        'judgeNotes': judgeNotes,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to complete hearing: $e');
    }
  }
}
