import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legal_sync/model/appoinment_model.dart';
import 'package:legal_sync/model/client_Model.dart';
import 'package:legal_sync/services/appoinment_services.dart';
import 'package:legal_sync/services/client_services.dart';

final appointmentServiceProvider = Provider((ref) => AppointmentService());
final clientServiceProvider = Provider((ref) => ClientService());

final streamAppointmentsByLawyerProvider =
    StreamProvider.family<List<AppointmentModel>, String>((ref, lawyerId) {
      final service = ref.watch(appointmentServiceProvider);
      return service.streamAppointmentsByLawyer(lawyerId);
    });

final streamUpcomingAppointmentsForLawyerProvider =
    StreamProvider.family<List<AppointmentModel>, String>((ref, lawyerId) {
      final service = ref.watch(appointmentServiceProvider);
      return service.streamUpcomingAppointmentsForLawyer(lawyerId);
    });

final streamPendingAppointmentsForLawyerProvider =
    StreamProvider.family<List<AppointmentModel>, String>((ref, lawyerId) {
      final service = ref.watch(appointmentServiceProvider);
      return service.streamPendingAppointmentsForLawyer(lawyerId);
    });

/// ✅ NEW: Stream approved/accepted consultations for lawyer
final streamApprovedConsultationsProvider =
    StreamProvider.family<List<AppointmentModel>, String>((ref, lawyerId) {
      final service = ref.watch(appointmentServiceProvider);
      return service
          .streamAppointmentsByLawyer(lawyerId)
          .map(
            (appointments) =>
                appointments.where((apt) => apt.status == 'approved').toList(),
          );
    });

/// ✅ NEW: Get clients with consultations for lawyer (Reactive Stream)
final clientsWithConsultationsProvider =
    StreamProvider.family<List<ClientModel>, String>((ref, lawyerId) {
      final clientService = ref.watch(clientServiceProvider);
      final appointmentService = ref.watch(appointmentServiceProvider);

      return appointmentService.streamAppointmentsByLawyer(lawyerId).asyncMap((
        consultations,
      ) async {
        if (consultations.isEmpty) return [];

        // Include pending, approved, and completed consultations
        final relevantConsultations =
            consultations.where((apt) {
              return ['pending', 'approved', 'completed'].contains(apt.status);
            }).toList();

        if (relevantConsultations.isEmpty) return [];

        // Get unique client IDs
        final uniqueClientIds =
            relevantConsultations.map((apt) => apt.clientId).toSet().toList();

        final clients = <ClientModel>[];
        for (final clientId in uniqueClientIds) {
          final client = await clientService.getClientById(clientId);
          if (client != null) {
            clients.add(client);
          }
        }
        return clients;
      });
    });

// Keep the old name as an alias if needed, or update consumers.
// Let's update consumers for clarity.


final appointmentStateProvider =
    StateNotifierProvider<AppointmentNotifier, AsyncValue<void>>((ref) {
      final service = ref.watch(appointmentServiceProvider);
      return AppointmentNotifier(service);
    });

class AppointmentNotifier extends StateNotifier<AsyncValue<void>> {
  final AppointmentService _service;

  AppointmentNotifier(this._service) : super(const AsyncValue.data(null));

  Future<void> approveAppointment(String appointmentId) async {
    state = const AsyncValue.loading();
    try {
      await _service.approveAppointment(appointmentId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> rejectAppointment(String appointmentId, {String? reason}) async {
    state = const AsyncValue.loading();
    try {
      await _service.rejectAppointment(appointmentId, adminNote: reason);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> completeAppointment(String appointmentId) async {
    state = const AsyncValue.loading();
    try {
      await _service.completeAppointment(appointmentId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
