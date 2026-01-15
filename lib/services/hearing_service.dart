import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:legal_sync/model/hearing_Model.dart';

class HearingService {
  HearingService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
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
        .orderBy('hearingDate', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => HearingModel.fromJson({
                  ...doc.data() as Map<String, dynamic>,
                  'hearingId': doc.id,
                }),
              )
              .toList();
        });
  }

  /// 🔹 Get upcoming hearings for lawyer
  Stream<List<HearingModel>> getUpcomingHearings(String lawyerId) {
    final now = DateTime.now();
    return _firestore
        .collection(_collection)
        .where('createdBy', isEqualTo: lawyerId)
        .where('hearingDate', isGreaterThan: Timestamp.fromDate(now))
        .where('status', whereIn: ['scheduled', 'ongoing'])
        .orderBy('hearingDate', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => HearingModel.fromJson({
                  ...doc.data() as Map<String, dynamic>,
                  'hearingId': doc.id,
                }),
              )
              .toList();
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
