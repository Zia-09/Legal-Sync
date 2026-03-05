import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:legal_sync/model/time_entry_Model.dart';

class TimeTrackingService {
  TimeTrackingService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const String _collection = 'time_entries';

  // Start timer and create an active entry.
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

  // Stop timer and finalize the duration.
  Future<TimeEntryModel> stopTimer(String timeEntryId) async {
    try {
      final doc = await _firestore
          .collection(_collection)
          .doc(timeEntryId)
          .get();
      if (!doc.exists || doc.data() == null) {
        throw Exception('Time entry not found');
      }

      final data = doc.data()!;
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

  Future<double> getTotalHoursForCase(String caseId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('caseId', isEqualTo: caseId)
          .get();

      double totalMinutes = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (data['isBillable'] == true) {
          totalMinutes += (data['duration'] ?? 0).toDouble();
        }
      }

      return totalMinutes / 60.0;
    } catch (e) {
      throw Exception('Failed to calculate total hours: $e');
    }
  }

  Stream<List<TimeEntryModel>> getTimeEntriesByCase(String caseId) {
    return _firestore
        .collection(_collection)
        .where('caseId', isEqualTo: caseId)
        .snapshots()
        .map((snapshot) {
          final docs = snapshot.docs
              .map(
                (doc) => TimeEntryModel.fromJson({
                  ...doc.data(),
                  'timeEntryId': doc.id,
                }),
              )
              .toList();
          docs.sort((a, b) => b.startTime.compareTo(a.startTime));
          return docs;
        });
  }

  Stream<List<TimeEntryModel>> getTimeEntriesByLawyer(String lawyerId) {
    return _firestore
        .collection(_collection)
        .where('lawyerId', isEqualTo: lawyerId)
        .snapshots()
        .map((snapshot) {
          final docs = snapshot.docs
              .map(
                (doc) => TimeEntryModel.fromJson({
                  ...doc.data(),
                  'timeEntryId': doc.id,
                }),
              )
              .toList();
          docs.sort((a, b) => b.startTime.compareTo(a.startTime));
          return docs;
        });
  }

  Future<TimeEntryModel?> getActiveTimer(String lawyerId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('lawyerId', isEqualTo: lawyerId)
          .get();

      final activeDocs = snapshot.docs.where(
        (doc) => doc.data()['status'] == 'active',
      );

      if (activeDocs.isEmpty) {
        return null;
      }

      final doc = activeDocs.first;
      return TimeEntryModel.fromJson({...doc.data(), 'timeEntryId': doc.id});
    } catch (e) {
      throw Exception('Failed to get active timer: $e');
    }
  }

  Future<void> createTimeEntry(TimeEntryModel entry) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(entry.timeEntryId)
          .set(entry.toJson(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to create time entry: $e');
    }
  }

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

  Future<void> deleteTimeEntry(String timeEntryId) async {
    try {
      await _firestore.collection(_collection).doc(timeEntryId).delete();
    } catch (e) {
      throw Exception('Failed to delete time entry: $e');
    }
  }

  Future<Map<String, dynamic>> getBillableSummary(String lawyerId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('lawyerId', isEqualTo: lawyerId)
          .get();

      double totalMinutes = 0;
      int entriesCount = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (data['isBillable'] == true && data['status'] == 'completed') {
          totalMinutes += (data['duration'] ?? 0).toDouble();
          entriesCount++;
        }
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
