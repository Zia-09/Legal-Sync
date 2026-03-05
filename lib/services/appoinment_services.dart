import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:legal_sync/model/appoinment_model.dart';

class AppointmentService {
  final CollectionReference _appointments = FirebaseFirestore.instance
      .collection('appointments');

  String _generateAppointmentId() => _appointments.doc().id;

  /// 🔹 Add or create new appointment
  Future<void> addAppointment(AppointmentModel appointment) async {
    await _appointments
        .doc(appointment.appointmentId)
        .set(appointment.toJson());
  }

  Future<String> requestAppointment({
    required String clientId,
    required String lawyerId,
    required DateTime scheduledAt,
    required double fee,
    int durationMinutes = 30,
    String? adminNote,
  }) async {
    final appointmentId = _generateAppointmentId();
    final appointment = AppointmentModel(
      appointmentId: appointmentId,
      clientId: clientId,
      lawyerId: lawyerId,
      scheduledAt: scheduledAt,
      durationMinutes: durationMinutes,
      fee: fee,
      status: 'pending',
      adminNote: adminNote,
    );
    await addAppointment(appointment);
    return appointmentId;
  }

  /// 🔹 Update appointment
  Future<void> updateAppointment(AppointmentModel appointment) async {
    await _appointments
        .doc(appointment.appointmentId)
        .update(appointment.toJson());
  }

  /// 🔹 Delete appointment
  Future<void> deleteAppointment(String appointmentId) async {
    await _appointments.doc(appointmentId).delete();
  }

  Future<void> approveAppointment(String appointmentId, {String? adminNote}) {
    return _appointments.doc(appointmentId).update({
      'status': 'approved',
      'adminNote': adminNote,
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> rejectAppointment(String appointmentId, {String? adminNote}) {
    return _appointments.doc(appointmentId).update({
      'status': 'cancelled',
      'adminNote': adminNote ?? 'Rejected by admin/lawyer',
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> rescheduleAppointment(
    String appointmentId,
    DateTime newDateTime, {
    String? adminNote,
  }) {
    return _appointments.doc(appointmentId).update({
      'scheduledAt': Timestamp.fromDate(newDateTime),
      'status': 'approved',
      'adminNote': adminNote,
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> completeAppointment(String appointmentId) {
    return _appointments.doc(appointmentId).update({
      'status': 'completed',
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> cancelAppointment(String appointmentId, {String? reason}) {
    return _appointments.doc(appointmentId).update({
      'status': 'cancelled',
      'adminNote': reason,
      'updatedAt': Timestamp.now(),
    });
  }

  /// 🔹 Get single appointment by ID
  Future<AppointmentModel?> getAppointment(String appointmentId) async {
    final doc = await _appointments.doc(appointmentId).get();
    if (doc.exists) {
      return AppointmentModel.fromJson(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  /// 🔹 Stream all appointments
  Stream<List<AppointmentModel>> streamAppointments() {
    return _appointments.snapshots().map(
      (snapshot) => snapshot.docs
          .map(
            (doc) =>
                AppointmentModel.fromJson(doc.data() as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  /// 🔹 Stream appointments for a specific client
  Stream<List<AppointmentModel>> streamAppointmentsByClient(String clientId) {
    return _appointments
        .where('clientId', isEqualTo: clientId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => AppointmentModel.fromJson(
                  doc.data() as Map<String, dynamic>,
                ),
              )
              .toList(),
        );
  }

  /// 🔹 Stream appointments for a specific lawyer
  Stream<List<AppointmentModel>> streamAppointmentsByLawyer(String lawyerId) {
    return _appointments
        .where('lawyerId', isEqualTo: lawyerId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => AppointmentModel.fromJson(
                  doc.data() as Map<String, dynamic>,
                ),
              )
              .toList(),
        );
  }

  Stream<List<AppointmentModel>> streamUpcomingAppointmentsForLawyer(
    String lawyerId,
  ) {
    return streamAppointmentsByLawyer(lawyerId).map((appointments) {
      final now = DateTime.now();
      final filtered = appointments.where((a) {
        return a.status == 'approved' && a.scheduledAt.isAfter(now);
      }).toList();
      filtered.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
      return filtered;
    });
  }

  Stream<List<AppointmentModel>> streamPendingAppointmentsForLawyer(
    String lawyerId,
  ) {
    return _appointments
        .where('lawyerId', isEqualTo: lawyerId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => AppointmentModel.fromJson(
                  doc.data() as Map<String, dynamic>,
                ),
              )
              .toList(),
        );
  }

  Stream<List<AppointmentModel>> streamUpcomingAppointmentsForClient(
    String clientId,
  ) {
    return streamAppointmentsByClient(clientId).map((appointments) {
      final now = DateTime.now();
      final targetStatuses = ['pending', 'approved'];
      final filtered = appointments.where((a) {
        return targetStatuses.contains(a.status) && a.scheduledAt.isAfter(now);
      }).toList();
      filtered.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
      return filtered;
    });
  }
}
