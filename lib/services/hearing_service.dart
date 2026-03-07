import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:legal_sync/model/hearing_Model.dart';
import 'package:legal_sync/services/notification_services.dart';
import 'package:intl/intl.dart';

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

    // 1. Send immediate in-app notification to all recipients (Client + Lawyer if needed)
    for (final userId in recipientUserIds) {
      await _notificationService.createNotification(
        userId: userId,
        title: 'New Hearing Scheduled',
        message:
            'A new ${hearing.hearingType ?? 'hearing'} has been scheduled for case ${hearing.caseId} at ${hearing.courtName ?? 'the court'}.',
        type: 'hearing',
        metadata: {'hearingId': hearing.hearingId, 'caseId': hearing.caseId},
      );
    }

    // 2. Queue push notification for the future reminder
    await _notificationService.queuePushNotification(
      userIds: recipientUserIds,
      title: 'Upcoming Hearing Reminder',
      message:
          'Hearing for case ${hearing.caseId} at ${hearing.courtName ?? 'court'} in $hoursBefore hours.',
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

  /// 🔹 Get all hearings for a client by clientId field (may miss old docs)
  Stream<List<HearingModel>> getUpcomingHearingsForClient(String clientId) {
    return _firestore
        .collection(_collection)
        .where('clientId', isEqualTo: clientId)
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
          // Sort descending — most recent/upcoming first
          docs.sort((a, b) => b.hearingDate.compareTo(a.hearingDate));
          return docs;
        });
  }

  /// 🔹 Robust: get ALL hearings for a list of caseIds.
  /// This works even on old hearing docs that have no clientId stored.
  /// Each caseId produces a stream; results are merged client-side.
  Stream<List<HearingModel>> streamHearingsByCaseIds(List<String> caseIds) {
    if (caseIds.isEmpty) {
      return Stream.value([]);
    }

    // Firestore 'whereIn' supports max 30 values; chunk if needed.
    final chunks = <List<String>>[];
    for (var i = 0; i < caseIds.length; i += 30) {
      chunks.add(
        caseIds.sublist(i, i + 30 > caseIds.length ? caseIds.length : i + 30),
      );
    }

    // One stream per chunk, then merge all.
    final streams = chunks.map((chunk) {
      return _firestore
          .collection(_collection)
          .where('caseId', whereIn: chunk)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map(
                  (doc) => HearingModel.fromJson({
                    ...doc.data() as Map<String, dynamic>,
                    'hearingId': doc.id,
                  }),
                )
                .toList(),
          );
    }).toList();

    // Combine all chunk-streams into one list stream.
    if (streams.length == 1) {
      return streams.first.map((list) {
        list.sort((a, b) => b.hearingDate.compareTo(a.hearingDate));
        return list;
      });
    }

    // For multiple chunks use rxdart-free merging via periodic polling-combiner.
    // We accumulate state per chunk index.
    return _mergeHearingStreams(streams);
  }

  /// Client-side merge of multiple bearing-list streams.
  Stream<List<HearingModel>> _mergeHearingStreams(
    List<Stream<List<HearingModel>>> streams,
  ) async* {
    final state = List<List<HearingModel>>.generate(streams.length, (_) => []);
    int done = 0;

    // Use a controller to merge.
    await for (final _ in Stream.periodic(const Duration(milliseconds: 300))) {
      // Always break — we use a different approach below.
      break;
    }

    // Simpler: just combine with StreamZip-style via transform.
    // We'll use the first chunk's stream as the base and listen to others.
    // Easiest no-dep approach: combine into one flat stream via async generator.
    final controller = StreamController<List<HearingModel>>(sync: false);

    void emit() {
      final merged = state.expand((l) => l).toList();
      merged.sort((a, b) => b.hearingDate.compareTo(a.hearingDate));
      if (!controller.isClosed) controller.add(merged);
    }

    final subs = <StreamSubscription>[];
    for (var i = 0; i < streams.length; i++) {
      final idx = i;
      subs.add(
        streams[idx].listen(
          (list) {
            state[idx] = list;
            emit();
          },
          onError: controller.addError,
          onDone: () {
            done++;
            if (done == streams.length) controller.close();
          },
        ),
      );
    }

    controller.onCancel = () {
      for (final s in subs) {
        s.cancel();
      }
    };

    yield* controller.stream;
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
        if (hearing.clientId != null && hearing.clientId!.isNotEmpty)
          hearing.clientId!,
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

  Future<void> sendManualReminder({
    required HearingModel hearing,
    required String clientId,
  }) async {
    final title = 'Hearing Reminder: ${hearing.hearingType ?? 'Hearing'}';
    final message =
        'Your hearing for case ${hearing.caseId} is scheduled at ${hearing.courtName ?? 'the court'} on ${DateFormat('dd MMM yyyy, h:mm a').format(hearing.hearingDate)}.';

    // 1. In-app notification
    await _notificationService.createNotification(
      userId: clientId,
      title: title,
      message: message,
      type: 'hearing',
      metadata: {'hearingId': hearing.hearingId, 'caseId': hearing.caseId},
    );

    // 2. Push notification (queued)
    await _notificationService.queuePushNotification(
      userIds: [clientId],
      title: title,
      message: message,
      data: {
        'type': 'hearing',
        'hearingId': hearing.hearingId,
        'caseId': hearing.caseId,
      },
    );

    // 3. Mark as reminder sent in the hearing document
    await markReminderSent(hearing.hearingId);
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
