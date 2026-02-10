import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../model/lawyer_availability_Model.dart';
import '../services/lawyer_availability_service.dart';

// ===============================
// Availability Service Provider
// ===============================
final availabilityServiceProvider = Provider(
  (ref) => LawyerAvailabilityService(),
);

// ===============================
// Lawyer Availability Provider
// ===============================
final lawyerAvailabilityProvider =
    StreamProvider.family<List<LawyerAvailabilityModel>, String>((
      ref,
      lawyerId,
    ) {
      final service = ref.watch(availabilityServiceProvider);
      return service.streamAvailabilityForLawyer(lawyerId);
    });

// ===============================
// Available Slots Provider
// ===============================
final availableSlotsProvider = FutureProvider.family<int, String>((
  ref,
  lawyerId,
) {
  final service = ref.watch(availabilityServiceProvider);
  return service.getAvailableSlots(lawyerId);
});

// ===============================
// Availability Notifier
// ===============================
class AvailabilityNotifier extends StateNotifier<LawyerAvailabilityModel?> {
  final LawyerAvailabilityService _service;

  AvailabilityNotifier(this._service) : super(null);

  Future<void> createAvailability(LawyerAvailabilityModel availability) async {
    await _service.createAvailability(availability);
    state = availability;
  }

  Future<void> updateAvailability(LawyerAvailabilityModel availability) async {
    await _service.updateAvailability(availability);
    state = availability;
  }

  Future<void> bookSlot(String availabilityId, String appointmentId) async {
    await _service.bookSlot(availabilityId, appointmentId);
  }

  Future<void> cancelSlot(String availabilityId, String appointmentId) async {
    await _service.cancelSlot(availabilityId, appointmentId);
  }

  Future<void> toggleStatus(String availabilityId, bool isActive) async {
    await _service.toggleAvailabilityStatus(availabilityId, isActive);
  }

  Future<void> loadAvailability(String availabilityId) async {
    final availability = await _service.getAvailability(availabilityId);
    state = availability;
  }
}

// ===============================
// Selected Availability Provider
// ===============================
final selectedAvailabilityProvider =
    StateNotifierProvider<AvailabilityNotifier, LawyerAvailabilityModel?>(
      (ref) => AvailabilityNotifier(ref.watch(availabilityServiceProvider)),
    );
