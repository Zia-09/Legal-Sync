import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/audit_log_Model.dart';

/// 🔹 Audit Log Service - Log all user activities for compliance and security
class AuditLogService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'audit_logs';

  /// Log user action
  Future<void> logAction({
    required String userId,
    required String userRole,
    required String action,
    required String resourceType,
    required String resourceId,
    String? description,
    String? ipAddress,
    String? userAgent,
    Map<String, dynamic>? changeDetails,
  }) async {
    try {
      final logId = _firestore.collection(_collection).doc().id;

      final auditLog = AuditLogModel(
        logId: logId,
        userId: userId,
        userRole: userRole,
        action: action,
        resourceType: resourceType,
        resourceId: resourceId,
        changeDetails: changeDetails,
        description: description,
        ipAddress: ipAddress ?? 'Unknown',
        userAgent: userAgent,
        timestamp: DateTime.now(),
        status: 'success',
      );

      await _firestore
          .collection(_collection)
          .doc(logId)
          .set(auditLog.toJson());
    } catch (e) {
      print('Error logging action: $e');
      rethrow;
    }
  }

  /// Log failed action
  Future<void> logFailedAction({
    required String userId,
    required String userRole,
    required String action,
    required String resourceType,
    required String resourceId,
    required String errorMessage,
    String? ipAddress,
    String? userAgent,
  }) async {
    try {
      final logId = _firestore.collection(_collection).doc().id;

      final auditLog = AuditLogModel(
        logId: logId,
        userId: userId,
        userRole: userRole,
        action: action,
        resourceType: resourceType,
        resourceId: resourceId,
        ipAddress: ipAddress ?? 'Unknown',
        userAgent: userAgent,
        timestamp: DateTime.now(),
        status: 'failure',
        errorMessage: errorMessage,
      );

      await _firestore
          .collection(_collection)
          .doc(logId)
          .set(auditLog.toJson());
    } catch (e) {
      print('Error logging failed action: $e');
      rethrow;
    }
  }

  /// Get audit logs for a user
  Future<List<AuditLogModel>> getLogsByUser(
    String userId, {
    int limit = 50,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => AuditLogModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting user logs: $e');
      return [];
    }
  }

  /// Stream audit logs for a user
  Stream<List<AuditLogModel>> streamLogsByUser(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AuditLogModel.fromJson(doc.data()))
              .toList(),
        );
  }

  /// Get audit logs for a resource
  Future<List<AuditLogModel>> getLogsByResource(
    String resourceType,
    String resourceId, {
    int limit = 50,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('resourceType', isEqualTo: resourceType)
          .where('resourceId', isEqualTo: resourceId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => AuditLogModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting resource logs: $e');
      return [];
    }
  }

  /// Stream audit logs for a resource
  Stream<List<AuditLogModel>> streamLogsByResource(
    String resourceType,
    String resourceId,
  ) {
    return _firestore
        .collection(_collection)
        .where('resourceType', isEqualTo: resourceType)
        .where('resourceId', isEqualTo: resourceId)
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AuditLogModel.fromJson(doc.data()))
              .toList(),
        );
  }

  /// Get audit logs by action
  Future<List<AuditLogModel>> getLogsByAction(
    String action, {
    int limit = 50,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('action', isEqualTo: action)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => AuditLogModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting action logs: $e');
      return [];
    }
  }

  /// Get audit logs in date range
  Future<List<AuditLogModel>> getLogsByDateRange(
    DateTime startDate,
    DateTime endDate, {
    int limit = 100,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where(
            'timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
          )
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => AuditLogModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting logs by date range: $e');
      return [];
    }
  }

  /// Get failed actions (errors)
  Future<List<AuditLogModel>> getFailedActions({int limit = 50}) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('status', isEqualTo: 'failure')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => AuditLogModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting failed actions: $e');
      return [];
    }
  }

  /// Stream failed actions
  Stream<List<AuditLogModel>> streamFailedActions() {
    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: 'failure')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AuditLogModel.fromJson(doc.data()))
              .toList(),
        );
  }

  /// Get logs by user role
  Future<List<AuditLogModel>> getLogsByRole(
    String role, {
    int limit = 50,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('userRole', isEqualTo: role)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => AuditLogModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting logs by role: $e');
      return [];
    }
  }

  /// Get suspicious activities (multiple failed actions in short time)
  Future<List<String>> getSuspiciousUsers({int failureThreshold = 5}) async {
    try {
      final recentLogs = await getFailedActions(limit: 1000);

      final userFailures = <String, int>{};
      for (final log in recentLogs) {
        userFailures[log.userId] = (userFailures[log.userId] ?? 0) + 1;
      }

      return userFailures.entries
          .where((entry) => entry.value >= failureThreshold)
          .map((entry) => entry.key)
          .toList();
    } catch (e) {
      print('Error getting suspicious users: $e');
      return [];
    }
  }

  /// Generate audit report
  Future<AuditReport> generateReport(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final logs = await getLogsByDateRange(startDate, endDate, limit: 1000);

      int totalActions = logs.length;
      int successCount = logs.where((log) => log.isSuccess).length;
      int failureCount = logs.where((log) => log.isFailure).length;

      final actionCounts = <String, int>{};
      final userCounts = <String, int>{};

      for (final log in logs) {
        actionCounts[log.action] = (actionCounts[log.action] ?? 0) + 1;
        userCounts[log.userId] = (userCounts[log.userId] ?? 0) + 1;
      }

      return AuditReport(
        startDate: startDate,
        endDate: endDate,
        totalActions: totalActions,
        successCount: successCount,
        failureCount: failureCount,
        actionBreakdown: actionCounts,
        userBreakdown: userCounts,
        generatedAt: DateTime.now(),
      );
    } catch (e) {
      print('Error generating report: $e');
      rethrow;
    }
  }

  /// Delete old logs (older than specified days)
  Future<void> deleteOldLogs(int daysOld) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));

      final snapshot = await _firestore
          .collection(_collection)
          .where('timestamp', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();

      for (final doc in snapshot.docs) {
        await _firestore.collection(_collection).doc(doc.id).delete();
      }

      print('Deleted ${snapshot.docs.length} old audit logs');
    } catch (e) {
      print('Error deleting old logs: $e');
      rethrow;
    }
  }
}

/// Helper class for audit report
class AuditReport {
  final DateTime startDate;
  final DateTime endDate;
  final int totalActions;
  final int successCount;
  final int failureCount;
  final Map<String, int> actionBreakdown;
  final Map<String, int> userBreakdown;
  final DateTime generatedAt;

  AuditReport({
    required this.startDate,
    required this.endDate,
    required this.totalActions,
    required this.successCount,
    required this.failureCount,
    required this.actionBreakdown,
    required this.userBreakdown,
    required this.generatedAt,
  });

  double get successRate =>
      totalActions == 0 ? 0 : (successCount / totalActions) * 100;

  int get mostActiveUser {
    if (userBreakdown.isEmpty) return 0;
    return userBreakdown.values.reduce((a, b) => a > b ? a : b);
  }

  String get topAction {
    if (actionBreakdown.isEmpty) return 'N/A';
    return actionBreakdown.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }
}
