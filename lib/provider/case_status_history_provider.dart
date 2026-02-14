import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../model/case_status_history_Model.dart';
import '../services/case_status_history_service.dart';

// ===============================
// Case Status History Service Provider
// ===============================
final caseStatusHistoryServiceProvider = Provider(
  (ref) => CaseStatusHistoryService(),
);

// ===============================
// All Status History Provider
// ===============================
final allStatusHistoryProvider = StreamProvider<List<CaseStatusHistoryModel>>((
  ref,
) {
  final service = ref.watch(caseStatusHistoryServiceProvider);
  return service.streamCaseStatusHistory(''); // Returns all or use empty
});

// ===============================
// Status History for Case Provider
// ===============================
final statusHistoryForCaseProvider =
    StreamProvider.family<List<CaseStatusHistoryModel>, String>((ref, caseId) {
      final service = ref.watch(caseStatusHistoryServiceProvider);
      return service.streamStatusChangesForCase(caseId);
    });

// ===============================
// Status History for Lawyer Provider
// ===============================
final statusHistoryForLawyerProvider =
    StreamProvider.family<List<CaseStatusHistoryModel>, String>((
      ref,
      lawyerId,
    ) {
      final service = ref.watch(caseStatusHistoryServiceProvider);
      return service.streamStatusChangesForLawyer(lawyerId);
    });

// ===============================
// Get Status History by ID Provider
// ===============================
final getStatusHistoryByIdProvider =
    FutureProvider.family<CaseStatusHistoryModel?, String>((
      ref,
      historyId,
    ) async {
      // Note: Service doesn't have getStatusHistory method
      // Use streamCaseStatusHistory instead for real-time updates
      return null;
    });

// ===============================
// Status History in Date Range Provider
// ===============================
final statusHistoryInDateRangeProvider =
    StreamProvider.family<
      List<CaseStatusHistoryModel>,
      ({String caseId, DateTime startDate, DateTime endDate})
    >((ref, params) {
      final service = ref.watch(caseStatusHistoryServiceProvider);
      return service.streamStatusChangesInRange(
        caseId: params.caseId,
        startDate: params.startDate,
        endDate: params.endDate,
      );
    });

// ===============================
// Case Status History Notifier
// ===============================
class CaseStatusHistoryNotifier extends StateNotifier<CaseStatusHistoryModel?> {
  final CaseStatusHistoryService _service;

  CaseStatusHistoryNotifier(this._service) : super(null);

  Future<String> logStatusChange({
    required String caseId,
    required String lawyerId,
    required String previousStatus,
    required String newStatus,
    required String changedBy,
    String? reason,
    String? notes,
  }) async {
    await _service.logStatusChange(
      caseId: caseId,
      lawyerId: lawyerId,
      previousStatus: previousStatus,
      newStatus: newStatus,
      changedBy: changedBy,
      reason: reason,
      notes: notes,
    );
    return 'logged';
  }

  Future<void> createHistory(CaseStatusHistoryModel history) async {
    final id = await _service.createStatusHistory(history);
    state = history;
  }

  Future<void> deleteHistory(String historyId) async {
    await _service.deleteStatusHistory(historyId);
    state = null;
  }
}

// ===============================
// Case Status History State Notifier Provider
// ===============================
final caseStatusHistoryStateNotifierProvider =
    StateNotifierProvider<CaseStatusHistoryNotifier, CaseStatusHistoryModel?>((
      ref,
    ) {
      final service = ref.watch(caseStatusHistoryServiceProvider);
      return CaseStatusHistoryNotifier(service);
    });

// ===============================
// Selected Status History Provider
// ===============================
final selectedStatusHistoryProvider = StateProvider<CaseStatusHistoryModel?>(
  (ref) => null,
);
