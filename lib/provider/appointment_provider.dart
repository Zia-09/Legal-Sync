import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legal_sync/model/appoinment_model.dart';
import 'package:legal_sync/services/appoinment_services.dart';

final appointmentServiceProvider = Provider((ref) => AppointmentService());

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
