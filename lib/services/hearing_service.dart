import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:legal_sync/model/hearing_Model.dart';
import 'package:legal_sync/services/notification_services.dart';
import 'package:legal_sync/services/activity_service.dart';
import 'package:legal_sync/services/email_service.dart';
import 'package:intl/intl.dart';

class HearingService {
  HearingService({
    FirebaseFirestore? firestore,
    NotificationService? notificationService,
    ActivityService? activityService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _notificationService = notificationService ?? NotificationService(),
       _activityService = activityService ?? ActivityService();

  final FirebaseFirestore _firestore;
  final NotificationService _notificationService;
  final ActivityService _activityService;
  static const String _collection = 'hearings';

  /// 🔹 Create hearing
  Future<void> createHearing(HearingModel hearing) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(hearing.hearingId)
          .set(hearing.toJson());

      // Log Activity
      final String uId = hearing.createdBy ?? hearing.clientId ?? '';
      final String uRole =
          (hearing.createdBy != null && hearing.createdBy!.contains('lawyer'))
          ? 'lawyer'
          : 'client';
      final String roleDisplay = uRole == 'lawyer' ? 'Lawyer' : 'Client';

      await _activityService.logActivity(
        caseId: hearing.caseId,
        userId: uId,
        userName: roleDisplay,
        userRole: uRole,
        actionType: 'hearing_added',
        actionDescription: '$roleDisplay scheduled hearing',
      );

      try {
        final usersCollection = _firestore.collection('users');
        final List<Map<String, String>> recipients = [];

        if (hearing.clientId != null && hearing.clientId!.isNotEmpty) {
          final clientDoc = await usersCollection.doc(hearing.clientId).get();
          final clientData = clientDoc.data() as Map<String, dynamic>?;
          if (clientData != null) {
            final email = (clientData['email'] ?? '').toString();
            if (email.isNotEmpty) {
              recipients.add({
                'email': email,
                'name': (clientData['name'] ?? 'Client').toString(),
                'role': 'client',
              });
            }
          }
        }

        if (hearing.createdBy != null && hearing.createdBy!.isNotEmpty) {
          final lawyerDoc = await usersCollection.doc(hearing.createdBy).get();
          final lawyerData = lawyerDoc.data() as Map<String, dynamic>?;
          if (lawyerData != null) {
            final email = (lawyerData['email'] ?? '').toString();
            if (email.isNotEmpty) {
              recipients.add({
                'email': email,
                'name': (lawyerData['name'] ?? 'Lawyer').toString(),
                'role': 'lawyer',
              });
            }
          }
        }

        if (recipients.isNotEmpty) {
          final hearingDateStr = DateFormat(
            'dd MMM yyyy, h:mm a',
          ).format(hearing.hearingDate);

          for (final recipient in recipients) {
            final String email = recipient['email']!;
            final String name = recipient['name']!;
            final String role = recipient['role']!;
            final bool isClient = role == 'client';

            await emailService.sendProfessionalEmail(
              to: email,
              subject: isClient
                  ? 'New Hearing Scheduled for Your Case'
                  : 'Hearing Scheduled for Assigned Case',
              htmlContent:
                  '''
              <div style="font-family: Arial, sans-serif; max-width: 600px; margin: auto; padding: 20px; border: 1px solid #eee; border-radius: 10px;">
                <h2 style="color: #131D31; text-align: center;">New Hearing Scheduled</h2>
                <p style="font-size: 16px; color: #333;">Dear $name,</p>
                <p style="font-size: 15px; color: #444;">
                  A new ${hearing.hearingType ?? 'hearing'} has been scheduled for case
                  <strong>${hearing.caseId}</strong>.
                </p>
                <div style="background-color: #f9f9f9; padding: 15px; border-radius: 5px; margin: 20px 0;">
                  <p style="margin: 0; color: #666;"><strong>Date & Time:</strong> $hearingDateStr</p>
                  <p style="margin: 5px 0 0 0; color: #666;"><strong>Court:</strong> ${hearing.courtName ?? 'Assigned court'}</p>
                  <p style="margin: 5px 0 0 0; color: #666;"><strong>Mode:</strong> ${hearing.modeOfConduct ?? 'In-person / As per court'}</p>
                </div>
                <p style="font-size: 14px; color: #777;">
                  Please log in to your LegalSync account for full details and any further updates.
                </p>
                <hr style="border: 0; border-top: 1px solid #eee; margin: 30px 0;" />
                <p style="text-align: center; font-size: 12px; color: #aaa;">&copy; 2026 LegalSync Elite. Secure case & hearing management.</p>
              </div>
              ''',
            );

            // Schedule 12-hour reminder
            final reminderDate = hearing.hearingDate.subtract(
              const Duration(hours: 12),
            );
            if (reminderDate.isAfter(DateTime.now())) {
              await emailService.sendScheduledProfessionalEmail(
                to: email,
                subject: isClient
                    ? 'Reminder: Upcoming Hearing in 12 Hours'
                    : 'Reminder: Scheduled Hearing in 12 Hours',
                htmlContent:
                    '''
                <div style="font-family: Arial, sans-serif; max-width: 600px; margin: auto; padding: 20px; border: 1px solid #eee; border-radius: 10px;">
                  <h2 style="color: #FF6B00; text-align: center;">Hearing Reminder</h2>
                  <p style="font-size: 16px; color: #333;">Dear $name,</p>
                  <p style="font-size: 15px; color: #444;">
                    This is a reminder that you have a ${hearing.hearingType ?? 'hearing'} approaching in approximately 12 hours.
                  </p>
                  <div style="background-color: #f9f9f9; padding: 15px; border-radius: 5px; margin: 20px 0;">
                    <p style="margin: 0; color: #666;"><strong>Date & Time:</strong> $hearingDateStr</p>
                    <p style="margin: 5px 0 0 0; color: #666;"><strong>Court:</strong> ${hearing.courtName ?? 'Assigned court'}</p>
                    <p style="margin: 5px 0 0 0; color: #666;"><strong>Mode:</strong> ${hearing.modeOfConduct ?? 'In-person / As per court'}</p>
                  </div>
                  <p style="font-size: 14px; color: #777;">
                    Please ensure you are prepared and log in to your LegalSync account for any last-minute updates.
                  </p>
                  <hr style="border: 0; border-top: 1px solid #eee; margin: 30px 0;" />
                  <p style="text-align: center; font-size: 12px; color: #aaa;">&copy; 2026 LegalSync Elite. Secure case & hearing management.</p>
                </div>
                ''',
                scheduledAt: reminderDate,
              );
            }
          }
        }
      } catch (e) {
        // Ignore email errors so hearing creation is not blocked
      }
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

  /// 🔹 Update hearing date and send reminder email to client
  Future<void> updateHearingDateWithEmailNotification({
    required String hearingId,
    required DateTime oldHearingDate,
    required DateTime newHearingDate,
  }) async {
    try {
      // Update hearing date
      await _firestore.collection(_collection).doc(hearingId).update({
        'hearingDate': Timestamp.fromDate(newHearingDate),
        'updatedAt': Timestamp.now(),
      });

      // Get hearing details
      final hearingDoc = await _firestore
          .collection(_collection)
          .doc(hearingId)
          .get();
      if (!hearingDoc.exists) return;

      final hearingData = hearingDoc.data() as Map<String, dynamic>;
      final clientId = hearingData['clientId'] as String?;
      final lawyerId = hearingData['createdBy'] as String?;
      final caseId = hearingData['caseId'] as String?;
      final location = (hearingData['courtName'] as String?) ?? 'Court';
      final hearingTime = DateFormat('h:mm a').format(newHearingDate);
      final usersCollection = _firestore.collection('users');

      // Get case title
      String caseTitle = 'Your Case';
      if (caseId != null) {
        final caseDoc = await _firestore.collection('cases').doc(caseId).get();
        if (caseDoc.exists) {
          caseTitle =
              (caseDoc.data() as Map<String, dynamic>?)?['title'] ?? caseTitle;
        }
      }

      // Get old and new dates formatted
      final oldDateStr = DateFormat(
        'dd MMM yyyy, h:mm a',
      ).format(oldHearingDate);
      final newDateStr = DateFormat('dd MMM yyyy').format(newHearingDate);

      // Send email to client
      if (clientId != null && clientId.isNotEmpty) {
        try {
          final clientDoc = await usersCollection.doc(clientId).get();
          if (clientDoc.exists) {
            final clientData = clientDoc.data() as Map<String, dynamic>;
            final clientEmail = clientData['email'] as String?;
            final clientName = clientData['name'] as String? ?? 'Client';

            if (clientEmail != null && clientEmail.isNotEmpty) {
              // Get lawyer name
              String lawyerName = 'Your Lawyer';
              if (lawyerId != null) {
                final lawyerDoc = await usersCollection.doc(lawyerId).get();
                if (lawyerDoc.exists) {
                  lawyerName =
                      (lawyerDoc.data() as Map<String, dynamic>?)?['name'] ??
                      lawyerName;
                }
              }

              unawaited(
                EmailService().sendHearingReminderEmail(
                  toEmail: clientEmail,
                  recipientName: clientName,
                  caseTitle: caseTitle,
                  oldHearingDate: oldDateStr,
                  newHearingDate: newDateStr,
                  hearingTime: hearingTime,
                  location: location,
                  lawyerName: lawyerName,
                ),
              );
            }
          }
        } catch (e) {
          print('⚠️ Failed to send hearing update email to client: $e');
        }
      }
    } catch (e) {
      print('⚠️ Hearing date updated but email notification failed: $e');
    }
  }

  // =========================
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

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // HEARING PARTICIPATION TRACKING
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// 🔹 Client/Lawyer confirms attendance status for hearing
  /// status: 'accepted', 'declined', 'busy', 'pending'
  Future<void> updateParticipationStatus({
    required String hearingId,
    required String userId,
    required String status, // 'accepted', 'declined', 'busy'
  }) async {
    try {
      await _firestore.collection(_collection).doc(hearingId).update({
        'participationStatus.$userId': status,
        'updatedAt': Timestamp.now(),
      });

      // Create notification for lawyer/client
      final hearing = await getHearingById(hearingId);
      if (hearing != null) {
        final userDoc = await _firestore.collection('users').doc(userId).get();
        final userData = userDoc.data() as Map<String, dynamic>?;
        final userName = (userData?['name'] ?? 'User').toString();

        // Notify lawyer
        if (hearing.createdBy != null && hearing.createdBy!.isNotEmpty) {
          final statusText = status == 'accepted'
              ? 'confirmed attendance'
              : status == 'declined'
              ? 'declined'
              : 'marked as busy';
          await _notificationService.createNotification(
            userId: hearing.createdBy!,
            title: 'Hearing Participation Update',
            message:
                '$userName has $statusText for hearing on ${DateFormat('dd MMM').format(hearing.hearingDate)}',
            type: 'hearing_response',
            metadata: {'hearingId': hearingId, 'caseId': hearing.caseId},
          );
        }
      }
    } catch (e) {
      throw Exception('Failed to update participation status: $e');
    }
  }

  /// 🔹 Mark participant attendance on hearing day
  /// Called after hearing time arrives to confirm who attended
  Future<void> markAttendance({
    required String hearingId,
    required String userId,
    required bool attended,
  }) async {
    try {
      final hearing = await getHearingById(hearingId);
      if (hearing == null) throw Exception('Hearing not found');

      final isClient = userId == hearing.clientId;

      await _firestore.collection(_collection).doc(hearingId).update({
        'clientAttended': isClient ? attended : hearing.clientAttended,
        'lawyerAttended': isClient ? hearing.lawyerAttended : attended,
        'updatedAt': Timestamp.now(),
      });

      // Notify the other party
      final otherUserId = isClient ? hearing.createdBy : hearing.clientId;
      if (otherUserId != null && otherUserId.isNotEmpty) {
        final userDoc = await _firestore.collection('users').doc(userId).get();
        final userData = userDoc.data() as Map<String, dynamic>?;
        final userName = (userData?['name'] ?? 'Participant').toString();
        final attendanceText = attended ? 'joined' : 'did not join';

        await _notificationService.createNotification(
          userId: otherUserId,
          title: 'Hearing Attendance Confirmed',
          message: '$userName $attendanceText the hearing',
          type: 'hearing_attendance',
          metadata: {'hearingId': hearingId, 'caseId': hearing.caseId},
        );
      }
    } catch (e) {
      throw Exception('Failed to mark attendance: $e');
    }
  }

  /// 🔹 Submit post-hearing feedback/notes
  /// Called after hearing concludes - both lawyer and client can provide feedback
  Future<void> submitHearingFeedback({
    required String hearingId,
    required String userId,
    required String feedback, // Description of hearing outcome/notes
    int? qualityRating, // Optional 1-5 rating
  }) async {
    try {
      final hearing = await getHearingById(hearingId);
      if (hearing == null) throw Exception('Hearing not found');

      await _firestore.collection(_collection).doc(hearingId).update({
        'hearingFeedback': feedback,
        'feedbackProvidedAt': Timestamp.now(),
        'feedbackProvidedBy': userId,
        if (qualityRating != null) 'hearingQualityRating': qualityRating,
        'status': 'completed',
        'updatedAt': Timestamp.now(),
      });

      // Log activity
      await _activityService.logActivity(
        caseId: hearing.caseId,
        userId: userId,
        userName: 'User',
        userRole: 'user',
        actionType: 'hearing_feedback_submitted',
        actionDescription: 'Submitted post-hearing feedback',
      );

      // Notify case participants
      if (hearing.clientId != null && hearing.clientId != userId) {
        await _notificationService.createNotification(
          userId: hearing.clientId!,
          title: 'Hearing Feedback Received',
          message:
              'Feedback has been submitted for hearing on ${DateFormat('dd MMM').format(hearing.hearingDate)}',
          type: 'hearing_feedback',
          metadata: {'hearingId': hearingId, 'caseId': hearing.caseId},
        );
      }

      if (hearing.createdBy != null && hearing.createdBy != userId) {
        await _notificationService.createNotification(
          userId: hearing.createdBy!,
          title: 'Hearing Feedback Received',
          message:
              'Feedback has been submitted for hearing on ${DateFormat('dd MMM').format(hearing.hearingDate)}',
          type: 'hearing_feedback',
          metadata: {'hearingId': hearingId, 'caseId': hearing.caseId},
        );
      }
    } catch (e) {
      throw Exception('Failed to submit hearing feedback: $e');
    }
  }

  /// 🔹 Get hearing participation summary
  /// Shows who accepted/declined/is busy
  Future<Map<String, dynamic>> getParticipationSummary(String hearingId) async {
    try {
      final hearing = await getHearingById(hearingId);
      if (hearing == null) throw Exception('Hearing not found');

      return hearing.participationStatus;
    } catch (e) {
      throw Exception('Failed to get participation summary: $e');
    }
  }
}
