import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:legal_sync/model/appoinment_model.dart';

class AppointmentService {
  final CollectionReference _appointments = FirebaseFirestore.instance
      .collection('appointments');

  /// 🔹 Add or create new appointment
  Future<void> addAppointment(AppointmentModel appointment) async {
    await _appointments
        .doc(appointment.appointmentId)
        .set(appointment.toJson());
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
}
