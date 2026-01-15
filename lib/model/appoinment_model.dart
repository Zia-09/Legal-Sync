import 'package:cloud_firestore/cloud_firestore.dart';

class AppointmentModel {
  final String appointmentId;
  final String clientId;
  final String lawyerId;
  final DateTime scheduledAt;
  final int durationMinutes;
  final double fee;
  final String status; // pending, approved, completed, cancelled
  final String? paymentId;
  final String? adminNote;
  final bool isPaid;

  const AppointmentModel({
    required this.appointmentId,
    required this.clientId,
    required this.lawyerId,
    required this.scheduledAt,
    this.durationMinutes = 30,
    required this.fee,
    this.status = "pending",
    this.paymentId,
    this.adminNote,
    this.isPaid = false,
  });

  /// 🔹 Convert Firestore/JSON to AppointmentModel
  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      appointmentId: json['appointmentId']?.toString() ?? '',
      clientId: json['clientId']?.toString() ?? '',
      lawyerId: json['lawyerId']?.toString() ?? '',
      scheduledAt: json['scheduledAt'] is Timestamp
          ? (json['scheduledAt'] as Timestamp).toDate()
          : DateTime.tryParse(json['scheduledAt']?.toString() ?? '') ??
                DateTime.now(),
      durationMinutes: json['durationMinutes'] ?? 30,
      fee: (json['fee'] is num) ? (json['fee'] as num).toDouble() : 0.0,
      status: json['status']?.toString() ?? 'pending',
      paymentId: json['paymentId']?.toString(),
      adminNote: json['adminNote']?.toString(),
      isPaid: json['isPaid'] ?? false,
    );
  }

  /// 🔹 Convert AppointmentModel to Firestore/JSON
  Map<String, dynamic> toJson() {
    return {
      'appointmentId': appointmentId,
      'clientId': clientId,
      'lawyerId': lawyerId,
      'scheduledAt': Timestamp.fromDate(scheduledAt),
      'durationMinutes': durationMinutes,
      'fee': fee,
      'status': status,
      'paymentId': paymentId,
      'adminNote': adminNote,
      'isPaid': isPaid,
    };
  }

  /// 🔹 CopyWith for immutability and updates
  AppointmentModel copyWith({
    String? status,
    bool? isPaid,
    DateTime? scheduledAt,
    int? durationMinutes,
    double? fee,
    String? adminNote,
    String? paymentId,
  }) {
    return AppointmentModel(
      appointmentId: appointmentId,
      clientId: clientId,
      lawyerId: lawyerId,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      fee: fee ?? this.fee,
      status: status ?? this.status,
      paymentId: paymentId ?? this.paymentId,
      adminNote: adminNote ?? this.adminNote,
      isPaid: isPaid ?? this.isPaid,
    );
  }

  /// 🔹 Helper: Check if appointment is in the future
  bool get isUpcoming => scheduledAt.isAfter(DateTime.now());

  /// 🔹 Helper: Get appointment end time
  DateTime get endTime => scheduledAt.add(Duration(minutes: durationMinutes));
}
