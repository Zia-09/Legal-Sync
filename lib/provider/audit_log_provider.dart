import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../model/audit_log_Model.dart';
import '../services/audit_log_service.dart';

// ===============================
// Audit Log Service Provider
// ===============================
final auditLogServiceProvider = Provider((ref) => AuditLogService());

// ===============================
// All Audit Logs Provider
// ===============================
final allAuditLogsProvider = StreamProvider<List<AuditLogModel>>((ref) {
  final service = ref.watch(auditLogServiceProvider);
  return service.streamLogsByUser(''); // Returns all logs
});

// ===============================
// Audit Logs for User Provider
// ===============================
final auditLogsForUserProvider =
    StreamProvider.family<List<AuditLogModel>, String>((ref, userId) {
      final service = ref.watch(auditLogServiceProvider);
      return service.streamLogsByUser(userId);
    });

// ===============================
// Audit Logs for Resource Provider
// ===============================
final auditLogsForResourceProvider =
    StreamProvider.family<
      List<AuditLogModel>,
      ({String resourceType, String resourceId})
    >((ref, params) {
      final service = ref.watch(auditLogServiceProvider);
      return service.streamLogsByResource(
        params.resourceType,
        params.resourceId,
      );
    });

// ===============================
// Get Audit Logs by Action Provider
// ===============================
final getAuditLogsByActionProvider =
    FutureProvider.family<List<AuditLogModel>, String>((ref, action) async {
      final service = ref.watch(auditLogServiceProvider);
      return service.getLogsByAction(action);
    });

// ===============================
// Audit Logs in Date Range Provider
// ===============================
final auditLogsInDateRangeProvider =
    StreamProvider.family<
      List<AuditLogModel>,
      ({DateTime startDate, DateTime endDate})
    >((ref, params) {
      final service = ref.watch(auditLogServiceProvider);
      return service.streamLogsByResource('', ''); // Limited by Firestore
    });

// ===============================
// Audit Log Notifier
// ===============================
class AuditLogNotifier extends StateNotifier<AuditLogModel?> {
  final AuditLogService _service;

  AuditLogNotifier(this._service) : super(null);

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
    await _service.logAction(
      userId: userId,
      userRole: userRole,
      action: action,
      resourceType: resourceType,
      resourceId: resourceId,
      description: description,
      ipAddress: ipAddress,
      userAgent: userAgent,
      changeDetails: changeDetails,
    );
  }

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
    await _service.logFailedAction(
      userId: userId,
      userRole: userRole,
      action: action,
      resourceType: resourceType,
      resourceId: resourceId,
      errorMessage: errorMessage,
      ipAddress: ipAddress,
      userAgent: userAgent,
    );
  }
}

// ===============================
// Audit Log State Notifier Provider
// ===============================
final auditLogStateNotifierProvider =
    StateNotifierProvider<AuditLogNotifier, AuditLogModel?>((ref) {
      final service = ref.watch(auditLogServiceProvider);
      return AuditLogNotifier(service);
    });

// ===============================
// Selected Audit Log Provider
// ===============================
final selectedAuditLogProvider = StateProvider<AuditLogModel?>((ref) => null);
