import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/leave_Model.dart';

/// 🔹 Leave Service - Manage lawyer leave/time off requests
class LeaveService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'leaves';

  /// Add new leave request
  Future<void> addLeave(LeaveModel leave) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(leave.leaveId)
          .set(leave.toJson());
    } catch (e) {
      print('Error adding leave: $e');
      rethrow;
    }
  }

  /// Get leave by ID
  Future<LeaveModel?> getLeaveById(String leaveId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(leaveId).get();
      if (doc.exists) {
        return LeaveModel.fromJson(doc.data() ?? {});
      }
      return null;
    } catch (e) {
      print('Error getting leave: $e');
      return null;
    }
  }

  /// Update leave request
  Future<void> updateLeave(String leaveId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(_collection).doc(leaveId).update(data);
    } catch (e) {
      print('Error updating leave: $e');
      rethrow;
    }
  }

  /// Delete leave request
  Future<void> deleteLeave(String leaveId) async {
    try {
      await _firestore.collection(_collection).doc(leaveId).delete();
    } catch (e) {
      print('Error deleting leave: $e');
      rethrow;
    }
  }

  /// Get all leave requests for a lawyer
  Future<List<LeaveModel>> getLeavesByLawyer(String lawyerId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('lawyerId', isEqualTo: lawyerId)
          .orderBy('startDate', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => LeaveModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting leaves: $e');
      return [];
    }
  }

  /// Stream leave requests for a lawyer
  Stream<List<LeaveModel>> streamLeavesByLawyer(String lawyerId) {
    return _firestore
        .collection(_collection)
        .where('lawyerId', isEqualTo: lawyerId)
        .orderBy('startDate', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => LeaveModel.fromJson(doc.data()))
              .toList(),
        );
  }

  /// Get pending leave requests (for admin approval)
  Future<List<LeaveModel>> getPendingLeaves() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => LeaveModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting pending leaves: $e');
      return [];
    }
  }

  /// Stream pending leave requests
  Stream<List<LeaveModel>> streamPendingLeaves() {
    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => LeaveModel.fromJson(doc.data()))
              .toList(),
        );
  }

  /// Approve leave request
  Future<void> approveLeave(String leaveId, String approvedBy) async {
    try {
      await _firestore.collection(_collection).doc(leaveId).update({
        'status': 'approved',
        'approvedBy': approvedBy,
        'approvedDate': Timestamp.now(),
      });
    } catch (e) {
      print('Error approving leave: $e');
      rethrow;
    }
  }

  /// Reject leave request
  Future<void> rejectLeave(String leaveId, String reason) async {
    try {
      await _firestore.collection(_collection).doc(leaveId).update({
        'status': 'rejected',
        'notes': reason,
      });
    } catch (e) {
      print('Error rejecting leave: $e');
      rethrow;
    }
  }

  /// Get approved leave dates for a lawyer
  Future<List<DateRange>> getApprovedLeaveDates(String lawyerId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('lawyerId', isEqualTo: lawyerId)
          .where('status', isEqualTo: 'approved')
          .get();

      return snapshot.docs.map((doc) {
        final leave = LeaveModel.fromJson(doc.data());
        return DateRange(start: leave.startDate, end: leave.endDate);
      }).toList();
    } catch (e) {
      print('Error getting approved leave dates: $e');
      return [];
    }
  }

  /// Check if lawyer is on leave on specific date
  Future<bool> isLawyerOnLeave(String lawyerId, DateTime date) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('lawyerId', isEqualTo: lawyerId)
          .where('status', isEqualTo: 'approved')
          .get();

      for (final doc in snapshot.docs) {
        final leave = LeaveModel.fromJson(doc.data());
        if (date.isAfter(leave.startDate) && date.isBefore(leave.endDate)) {
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Error checking leave: $e');
      return false;
    }
  }

  /// Get leave statistics for a lawyer
  Future<LeaveStats> getLeaveStats(String lawyerId, int year) async {
    try {
      final startOfYear = DateTime(year, 1, 1);
      final endOfYear = DateTime(year, 12, 31);

      final snapshot = await _firestore
          .collection(_collection)
          .where('lawyerId', isEqualTo: lawyerId)
          .where('status', isEqualTo: 'approved')
          .where('startDate', isGreaterThanOrEqualTo: startOfYear)
          .where('endDate', isLessThanOrEqualTo: endOfYear)
          .get();

      int totalDays = 0;
      int vacationDays = 0;
      int sickDays = 0;
      int personalDays = 0;
      int trainingDays = 0;

      for (final doc in snapshot.docs) {
        final leave = LeaveModel.fromJson(doc.data());
        final days = leave.leaveDays;
        totalDays += days;

        switch (leave.reason.toLowerCase()) {
          case 'vacation':
            vacationDays += days;
          case 'sick':
            sickDays += days;
          case 'personal':
            personalDays += days;
          case 'training':
            trainingDays += days;
        }
      }

      return LeaveStats(
        totalDays: totalDays,
        vacationDays: vacationDays,
        sickDays: sickDays,
        personalDays: personalDays,
        trainingDays: trainingDays,
      );
    } catch (e) {
      print('Error getting leave stats: $e');
      return LeaveStats(
        totalDays: 0,
        vacationDays: 0,
        sickDays: 0,
        personalDays: 0,
        trainingDays: 0,
      );
    }
  }

  /// Get upcoming leaves
  Future<List<LeaveModel>> getUpcomingLeaves(String lawyerId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('lawyerId', isEqualTo: lawyerId)
          .where('status', isEqualTo: 'approved')
          .where('startDate', isGreaterThanOrEqualTo: Timestamp.now())
          .orderBy('startDate')
          .limit(10)
          .get();

      return snapshot.docs
          .map((doc) => LeaveModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting upcoming leaves: $e');
      return [];
    }
  }
}

/// Helper class for date ranges
class DateRange {
  final DateTime start;
  final DateTime end;

  DateRange({required this.start, required this.end});
}

/// Helper class for leave statistics
class LeaveStats {
  final int totalDays;
  final int vacationDays;
  final int sickDays;
  final int personalDays;
  final int trainingDays;

  LeaveStats({
    required this.totalDays,
    required this.vacationDays,
    required this.sickDays,
    required this.personalDays,
    required this.trainingDays,
  });
}
