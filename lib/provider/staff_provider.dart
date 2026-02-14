import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../model/staff_Model.dart';
import '../services/staff_service.dart';

// ===============================
// Staff Service Provider
// ===============================
final staffServiceProvider = Provider((ref) => StaffService());

// ===============================
// Staff for Firm Provider
// ===============================
final staffForFirmProvider = StreamProvider.family<List<StaffModel>, String>((
  ref,
  firmId,
) {
  final service = ref.watch(staffServiceProvider);
  return service.streamStaffForFirm(firmId);
});

// ===============================
// Staff by Role Provider
// ===============================
final staffByRoleProvider =
    StreamProvider.family<List<StaffModel>, ({String firmId, String role})>((
      ref,
      params,
    ) {
      final service = ref.watch(staffServiceProvider);
      return service.streamStaffByRole(params.firmId, params.role);
    });

// ===============================
// Staff Workload Provider
// ===============================
final staffWorkloadProvider = FutureProvider.family<int, String>((
  ref,
  staffId,
) {
  final service = ref.watch(staffServiceProvider);
  return service.getStaffWorkload(staffId);
});

// ===============================
// Staff Notifier
// ===============================
class StaffNotifier extends StateNotifier<StaffModel?> {
  final StaffService _service;

  StaffNotifier(this._service) : super(null);

  Future<void> createStaff(StaffModel staff) async {
    await _service.createStaff(staff);
    state = staff;
  }

  Future<void> updateStaff(StaffModel staff) async {
    await _service.updateStaff(staff);
    state = staff;
  }

  Future<void> deleteStaff(String staffId) async {
    await _service.deleteStaff(staffId);
  }

  Future<void> assignCase(String caseId) async {
    if (state != null) {
      await _service.assignCase(state!.staffId, caseId);
    }
  }

  Future<void> unassignCase(String caseId) async {
    if (state != null) {
      await _service.unassignCase(state!.staffId, caseId);
    }
  }

  Future<void> loadStaff(String staffId) async {
    final staff = await _service.getStaff(staffId);
    state = staff;
  }
}

// ===============================
// Selected Staff Provider
// ===============================
final selectedStaffProvider = StateNotifierProvider<StaffNotifier, StaffModel?>(
  (ref) => StaffNotifier(ref.watch(staffServiceProvider)),
);
