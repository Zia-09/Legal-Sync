import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:legal_sync/model/time_entry_Model.dart';

class TimeTrackingService {
  TimeTrackingService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const String _collection = 'time_entries';

  /// 🔹 Start timer - create active time entry
  Future<TimeEntryModel> startTimer({
    required String caseId,
    required String lawyerId,
    String? description,
    String? taskType,
  }) async {
    try {
      final timeEntryId = _firestore.collection(_collection).doc().id;
      final now = DateTime.now();

      final entry = TimeEntryModel(
        timeEntryId: timeEntryId,
        caseId: caseId,
        lawyerId: lawyerId,
        startTime: now,
        duration: 0,
        description: description,
        taskType: taskType,
        createdAt: now,
        status: 'active',
      );

      await _firestore
          .collection(_collection)
          .doc(timeEntryId)
          .set(entry.toJson());

      return entry;
    } catch (e) {
      throw Exception('Failed to start timer: $e');
    }
  }

  /// 🔹 Stop timer - calculate duration
  Future<TimeEntryModel> stopTimer(String timeEntryId) async {
    try {
      final doc = await _firestore
          .collection(_collection)
          .doc(timeEntryId)
          .get();
      if (!doc.exists) throw Exception('Time entry not found');

      final data = doc.data() as Map<String, dynamic>;
      final startTime = (data['startTime'] as Timestamp).toDate();
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime).inMinutes;

      final entry = TimeEntryModel.fromJson({
        ...data,
        'timeEntryId': timeEntryId,
        'endTime': endTime,
        'duration': duration,
        'status': 'completed',
        'updatedAt': Timestamp.now(),
      });

      await _firestore.collection(_collection).doc(timeEntryId).update({
        'endTime': Timestamp.fromDate(endTime),
        'duration': duration,
        'status': 'completed',
        'updatedAt': Timestamp.now(),
      });

      return entry;
    } catch (e) {
      throw Exception('Failed to stop timer: $e');
    }
  }

  /// 🔹 Pause timer
  Future<void> pauseTimer(String timeEntryId) async {
    try {
      await _firestore.collection(_collection).doc(timeEntryId).update({
        'status': 'paused',
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to pause timer: $e');
    }
  }

  /// 🔹 Resume timer
  Future<void> resumeTimer(String timeEntryId) async {
    try {
      await _firestore.collection(_collection).doc(timeEntryId).update({
        'status': 'active',
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to resume timer: $e');
    }
  }

  /// 🔹 Get total hours for case
  Future<double> getTotalHoursForCase(String caseId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('caseId', isEqualTo: caseId)
          .where('isBillable', isEqualTo: true)
          .get();

      double totalMinutes = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        totalMinutes += (data['duration'] ?? 0).toDouble();
      }

      return totalMinutes / 60.0;
    } catch (e) {
      throw Exception('Failed to calculate total hours: $e');
    }
  }

  /// 🔹 Get time entries for case
  Stream<List<TimeEntryModel>> getTimeEntriesByCase(String caseId) {
    return _firestore
        .collection(_collection)
        .where('caseId', isEqualTo: caseId)
        .orderBy('startTime', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => TimeEntryModel.fromJson({
                  ...doc.data() as Map<String, dynamic>,
                  'timeEntryId': doc.id,
                }),
              )
              .toList();
        });
  }

  /// 🔹 Get time entries for lawyer
  Stream<List<TimeEntryModel>> getTimeEntriesByLawyer(String lawyerId) {
    return _firestore
        .collection(_collection)
        .where('lawyerId', isEqualTo: lawyerId)
        .orderBy('startTime', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => TimeEntryModel.fromJson({
                  ...doc.data() as Map<String, dynamic>,
                  'timeEntryId': doc.id,
                }),
              )
              .toList();
        });
  }

  /// 🔹 Get active timer for lawyer
  Future<TimeEntryModel?> getActiveTimer(String lawyerId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('lawyerId', isEqualTo: lawyerId)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      final doc = snapshot.docs.first;
      return TimeEntryModel.fromJson({
        ...doc.data() as Map<String, dynamic>,
        'timeEntryId': doc.id,
      });
    } catch (e) {
      throw Exception('Failed to get active timer: $e');
    }
  }

  /// 🔹 Update time entry
  Future<void> updateTimeEntry(
    String timeEntryId,
    Map<String, dynamic> data,
  ) async {
    try {
      data['updatedAt'] = Timestamp.now();
      await _firestore.collection(_collection).doc(timeEntryId).update(data);
    } catch (e) {
      throw Exception('Failed to update time entry: $e');
    }
  }

  /// 🔹 Delete time entry
  Future<void> deleteTimeEntry(String timeEntryId) async {
    try {
      await _firestore.collection(_collection).doc(timeEntryId).delete();
    } catch (e) {
      throw Exception('Failed to delete time entry: $e');
    }
  }

  /// 🔹 Get billable hours summary for lawyer
  Future<Map<String, dynamic>> getBillableSummary(String lawyerId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('lawyerId', isEqualTo: lawyerId)
          .where('isBillable', isEqualTo: true)
          .where('status', isEqualTo: 'completed')
          .get();

      double totalMinutes = 0;
      int entriesCount = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        totalMinutes += (data['duration'] ?? 0).toDouble();
        entriesCount++;
      }

      return {
        'totalHours': totalMinutes / 60.0,
        'totalEntries': entriesCount,
        'averagePerEntry': entriesCount > 0
            ? (totalMinutes / 60.0) / entriesCount
            : 0,
      };
    } catch (e) {
      throw Exception('Failed to get billable summary: $e');
    }
  }
}
