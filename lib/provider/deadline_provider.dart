import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/deadline_Model.dart';
import '../services/deadline_service.dart';

// ===============================
// Deadline Service Provider
// ===============================
final deadlineServiceProvider = Provider((ref) => DeadlineService());

// ===============================
// Deadlines for Case Provider
// ===============================
final deadlinesForCaseProvider =
    StreamProvider.family<List<DeadlineModel>, String>((ref, caseId) {
      final service = ref.watch(deadlineServiceProvider);
      return service.streamDeadlinesForCase(caseId);
    });

// ===============================
// Deadlines for Lawyer Provider
// ===============================
final deadlinesForLawyerProvider =
    StreamProvider.family<List<DeadlineModel>, String>((ref, lawyerId) {
      final service = ref.watch(deadlineServiceProvider);
      return service.streamDeadlinesForLawyer(lawyerId);
    });

// ===============================
// Overdue Deadlines Provider
// ===============================
final overdueDeadlinesProvider =
    StreamProvider.family<List<DeadlineModel>, String>((ref, lawyerId) {
      final service = ref.watch(deadlineServiceProvider);
      return service.streamOverdueDeadlines(lawyerId);
    });

// ===============================
// Deadlines by Priority Provider
// ===============================
final deadlinesByPriorityProvider =
    StreamProvider.family<
      List<DeadlineModel>,
      ({String lawyerId, String priority})
    >((ref, params) {
      final service = ref.watch(deadlineServiceProvider);
      return service.streamDeadlinesByPriority(
        params.lawyerId,
        params.priority,
      );
    });

// ===============================
// Deadline Notifier
// ===============================
class DeadlineNotifier extends StateNotifier<DeadlineModel?> {
  final DeadlineService _service;

  DeadlineNotifier(this._service) : super(null);

  Future<void> createDeadline(DeadlineModel deadline) async {
    final id = await _service.createDeadline(deadline);
    state = deadline.copyWith();
  }

  Future<void> updateDeadline(DeadlineModel deadline) async {
    await _service.updateDeadline(deadline);
    state = deadline;
  }

  Future<void> completeDeadline(String deadlineId) async {
    await _service.completeDeadline(deadlineId);
  }

  Future<void> loadDeadline(String deadlineId) async {
    final deadline = await _service.getDeadline(deadlineId);
    state = deadline;
  }
}

// ===============================
// Selected Deadline Provider
// ===============================
final selectedDeadlineProvider =
    StateNotifierProvider<DeadlineNotifier, DeadlineModel?>(
      (ref) => DeadlineNotifier(ref.watch(deadlineServiceProvider)),
    );
