import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

/// ✅ NEW: Get clients with accepted consultations for lawyer (Future-based for efficiency)
final clientsWithAcceptedConsultationsProvider =
    FutureProvider.family<List<ClientModel>, String>((ref, lawyerId) async {
      final clientService = ref.read(clientServiceProvider);

      // Get all approved consultations for this lawyer from Firestore
      final appointmentQuery = FirebaseFirestore.instance
          .collection('appointments')
          .where('lawyerId', isEqualTo: lawyerId)
          .where('status', isEqualTo: 'approved')
          .get();

      final snapshot = await appointmentQuery;
      final consultations = snapshot.docs
          .map((doc) => AppointmentModel.fromJson(doc.data()))
          .toList();

      if (consultations.isEmpty) {
        return [];
      }

      // Get unique client IDs
      final uniqueClientIds = consultations
          .map((apt) => apt.clientId)
          .toSet()
          .toList();

      final clients = <ClientModel>[];

      for (final clientId in uniqueClientIds) {
        final client = await clientService.getClientById(clientId);
        if (client != null) {
          clients.add(client);
        }
      }

      return clients;
    });

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
