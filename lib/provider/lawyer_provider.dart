import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/lawyer_Model.dart';
import '../services/lawyer_services.dart';

// ===============================
// Lawyer Service Provider
// ===============================
final lawyerServiceProvider = Provider((ref) => LawyerService());

// ===============================
// All Lawyers Provider
// ===============================
final allLawyersProvider = StreamProvider<List<LawyerModel>>((ref) {
  final service = ref.watch(lawyerServiceProvider);
  return service.streamAllLawyers();
});

// ===============================
// Get Lawyer by ID Provider
// ===============================
final getLawyerByIdProvider = FutureProvider.family<LawyerModel?, String>((
  ref,
  lawyerId,
) async {
  final service = ref.watch(lawyerServiceProvider);
  return service.getLawyer(lawyerId);
});

// ===============================
// Verified Lawyers Provider
// ===============================
final verifiedLawyersProvider = StreamProvider<List<LawyerModel>>((ref) {
  final service = ref.watch(lawyerServiceProvider);
  return service.streamVerifiedLawyers();
});

// ===============================
// Lawyers by Specialization Provider
// ===============================
final lawyersBySpecializationProvider =
    StreamProvider.family<List<LawyerModel>, String>((ref, specialization) {
      final service = ref.watch(lawyerServiceProvider);
      return service.streamLawyersBySpecialization(specialization);
    });

// ===============================
// Top Rated Lawyers Provider
// ===============================
final topRatedLawyersProvider = StreamProvider<List<LawyerModel>>((ref) {
  final service = ref.watch(lawyerServiceProvider);
  return service.streamTopRatedLawyers();
});

// ===============================
// Pending Lawyer Approvals Provider
// ===============================
final pendingLawyerApprovalsProvider = StreamProvider<List<LawyerModel>>((ref) {
  final service = ref.watch(lawyerServiceProvider);
  return service.streamPendingApprovals();
});

// ===============================
// Lawyer Cases Provider
// ===============================
final lawyerCasesCountProvider = FutureProvider.family<int, String>((
  ref,
  lawyerId,
) async {
  final service = ref.watch(lawyerServiceProvider);
  return service.getLawyerCasesCount(lawyerId);
});

// ===============================
// Lawyer Availability Status Provider
// ===============================
final lawyerAvailabilityStatusProvider = FutureProvider.family<bool, String>((
  ref,
  lawyerId,
) async {
  final service = ref.watch(lawyerServiceProvider);
  return service.isLawyerAvailable(lawyerId);
});

// ===============================
// Lawyer Notifier
// ===============================
class LawyerNotifier extends StateNotifier<LawyerModel?> {
  final LawyerService _service;

  LawyerNotifier(this._service) : super(null);

  Future<String> createLawyer(LawyerModel lawyer) async {
    final id = await _service.createLawyer(lawyer);
    state = lawyer;
    return id;
  }

  Future<void> updateLawyer(LawyerModel lawyer) async {
    await _service.updateLawyer(lawyer);
    state = lawyer;
  }

  Future<void> deleteLawyer(String lawyerId) async {
    await _service.deleteLawyer(lawyerId);
    state = null;
  }

  Future<void> loadLawyer(String lawyerId) async {
    final lawyer = await _service.getLawyer(lawyerId);
    state = lawyer;
  }

  Future<void> approveLawyer(String lawyerId) async {
    await _service.approveLawyer(lawyerId);
  }

  Future<void> rejectLawyer(String lawyerId, String reason) async {
    await _service.rejectLawyer(lawyerId, reason);
  }

  Future<void> updateRating(String lawyerId, double newRating) async {
    await _service.updateRating(lawyerId, newRating);
  }
}

// ===============================
// Lawyer State Notifier Provider
// ===============================
final lawyerStateNotifierProvider =
    StateNotifierProvider<LawyerNotifier, LawyerModel?>((ref) {
      final service = ref.watch(lawyerServiceProvider);
      return LawyerNotifier(service);
    });

// ===============================
// Selected Lawyer Provider
// ===============================
final selectedLawyerProvider = StateProvider<LawyerModel?>((ref) => null);
