import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../model/leave_Model.dart';
import '../services/leave_service.dart';

// ===============================
// Leave Service Provider
// ===============================
final leaveServiceProvider = Provider((ref) => LeaveService());

// ===============================
// Pending Leaves Provider
// ===============================
final pendingLeavesProvider = FutureProvider<List<LeaveModel>>((ref) async {
  final service = ref.watch(leaveServiceProvider);
  return service.getPendingLeaves();
});

// ===============================
// Pending Leaves Stream Provider
// ===============================
final streamPendingLeavesProvider = StreamProvider<List<LeaveModel>>((ref) {
  final service = ref.watch(leaveServiceProvider);
  return service.streamPendingLeaves();
});

// ===============================
// Leaves for Lawyer Provider
// ===============================
final leavesByLawyerProvider = StreamProvider.family<List<LeaveModel>, String>((
  ref,
  lawyerId,
) {
  final service = ref.watch(leaveServiceProvider);
  return service.streamLeavesByLawyer(lawyerId);
});

// ===============================
// Get Leave by ID Provider
// ===============================
final getLeaveByIdProvider = FutureProvider.family<LeaveModel?, String>((
  ref,
  leaveId,
) async {
  final service = ref.watch(leaveServiceProvider);
  return service.getLeaveById(leaveId);
});

// ===============================
// Leave Notifier
// ===============================
class LeaveNotifier extends StateNotifier<LeaveModel?> {
  final LeaveService _service;

  LeaveNotifier(this._service) : super(null);

  Future<void> addLeave(LeaveModel leave) async {
    await _service.addLeave(leave);
    state = leave;
  }

  Future<void> updateLeave(String leaveId, Map<String, dynamic> data) async {
    await _service.updateLeave(leaveId, data);
  }

  Future<void> deleteLeave(String leaveId) async {
    await _service.deleteLeave(leaveId);
    state = null;
  }

  Future<void> loadLeave(String leaveId) async {
    final leave = await _service.getLeaveById(leaveId);
    state = leave;
  }
}

// ===============================
// Leave State Notifier Provider
// ===============================
final leaveStateNotifierProvider =
    StateNotifierProvider<LeaveNotifier, LeaveModel?>((ref) {
      final service = ref.watch(leaveServiceProvider);
      return LeaveNotifier(service);
    });

// ===============================
// Selected Leave Provider
// ===============================
final selectedLeaveProvider = StateProvider<LeaveModel?>((ref) => null);
