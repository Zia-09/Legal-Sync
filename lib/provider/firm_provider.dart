import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../model/firm_Model.dart';
import '../services/firm_service.dart';

// ===============================
// Firm Service Provider
// ===============================
final firmServiceProvider = Provider((ref) => FirmService());

// ===============================
// Firm by Owner Provider
// ===============================
final firmByOwnerProvider = StreamProvider.family<FirmModel?, String>((
  ref,
  ownerLawyerId,
) {
  final service = ref.watch(firmServiceProvider);
  return service.streamFirmByOwner(ownerLawyerId);
});

// ===============================
// Firm Stats Provider
// ===============================
final firmStatsProvider = FutureProvider.family<Map<String, dynamic>, String>((
  ref,
  firmId,
) {
  final service = ref.watch(firmServiceProvider);
  return service.getFirmStats(firmId);
});

// ===============================
// Firm Notifier
// ===============================
class FirmNotifier extends StateNotifier<FirmModel?> {
  final FirmService _service;

  FirmNotifier(this._service) : super(null);

  Future<void> createFirm(FirmModel firm) async {
    await _service.createFirm(firm);
    state = firm;
  }

  Future<void> updateFirm(FirmModel firm) async {
    await _service.updateFirm(firm);
    state = firm;
  }

  Future<void> addLawyer(String lawyerId) async {
    if (state != null) {
      await _service.addLawyerToFirm(state!.firmId, lawyerId);
    }
  }

  Future<void> removeLawyer(String lawyerId) async {
    if (state != null) {
      await _service.removeLawyerFromFirm(state!.firmId, lawyerId);
    }
  }

  Future<void> addStaff(String staffId) async {
    if (state != null) {
      await _service.addStaffToFirm(state!.firmId, staffId);
    }
  }

  Future<void> removeStaff(String staffId) async {
    if (state != null) {
      await _service.removeStaffFromFirm(state!.firmId, staffId);
    }
  }

  Future<void> deactivate() async {
    if (state != null) {
      await _service.deactivateFirm(state!.firmId);
    }
  }

  Future<void> activate() async {
    if (state != null) {
      await _service.activateFirm(state!.firmId);
    }
  }

  Future<void> loadFirm(String firmId) async {
    final firm = await _service.getFirm(firmId);
    state = firm;
  }
}

// ===============================
// Selected Firm Provider
// ===============================
final selectedFirmProvider = StateNotifierProvider<FirmNotifier, FirmModel?>(
  (ref) => FirmNotifier(ref.watch(firmServiceProvider)),
);
