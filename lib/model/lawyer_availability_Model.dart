import 'package:cloud_firestore/cloud_firestore.dart';

/// 🔹 Lawyer Availability / Appointment Slot Model
/// Manages lawyer's available time slots for appointments
class LawyerAvailabilityModel {
  final String availabilityId;
  final String lawyerId;
  final String dayOfWeek; // "monday", "tuesday", etc.
  final String startTime; // e.g., "09:00"
  final String endTime; // e.g., "17:00"
  final int slotDurationMinutes; // e.g., 30, 60
  final bool isActive;
  final List<String> bookedSlots; // Appointment IDs
  final String? breakStartTime; // e.g., "13:00"
  final String? breakEndTime; // e.g., "14:00"
  final DateTime createdAt;
  final DateTime? updatedAt;

  const LawyerAvailabilityModel({
    required this.availabilityId,
    required this.lawyerId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.slotDurationMinutes = 30,
    this.isActive = true,
    this.bookedSlots = const [],
    this.breakStartTime,
    this.breakEndTime,
    required this.createdAt,
    this.updatedAt,
  });

  /// ===============================
  /// Firestore → Model
  /// ===============================
  factory LawyerAvailabilityModel.fromJson(Map<String, dynamic> json) {
    return LawyerAvailabilityModel(
      availabilityId: json['availabilityId'] ?? '',
      lawyerId: json['lawyerId'] ?? '',
      dayOfWeek: json['dayOfWeek'] ?? '',
      startTime: json['startTime'] ?? '09:00',
      endTime: json['endTime'] ?? '17:00',
      slotDurationMinutes: json['slotDurationMinutes'] ?? 30,
      isActive: json['isActive'] ?? true,
      bookedSlots: List<String>.from(json['bookedSlots'] ?? []),
      breakStartTime: json['breakStartTime'],
      breakEndTime: json['breakEndTime'],
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: json['updatedAt'] is Timestamp
          ? (json['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// ===============================
  /// Model → Firestore
  /// ===============================
  Map<String, dynamic> toJson() {
    return {
      'availabilityId': availabilityId,
      'lawyerId': lawyerId,
      'dayOfWeek': dayOfWeek,
      'startTime': startTime,
      'endTime': endTime,
      'slotDurationMinutes': slotDurationMinutes,
      'isActive': isActive,
      'bookedSlots': bookedSlots,
      'breakStartTime': breakStartTime,
      'breakEndTime': breakEndTime,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  /// ===============================
  /// CopyWith
  /// ===============================
  LawyerAvailabilityModel copyWith({
    String? startTime,
    String? endTime,
    int? slotDurationMinutes,
    bool? isActive,
    List<String>? bookedSlots,
    String? breakStartTime,
    String? breakEndTime,
    DateTime? updatedAt,
  }) {
    return LawyerAvailabilityModel(
      availabilityId: availabilityId,
      lawyerId: lawyerId,
      dayOfWeek: dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      slotDurationMinutes: slotDurationMinutes ?? this.slotDurationMinutes,
      isActive: isActive ?? this.isActive,
      bookedSlots: bookedSlots ?? this.bookedSlots,
      breakStartTime: breakStartTime ?? this.breakStartTime,
      breakEndTime: breakEndTime ?? this.breakEndTime,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// ===============================
  /// Helpers
  /// ===============================
  int get availableSlots {
    // Calculate total available slots minus booked ones
    return bookedSlots.isEmpty ? 100 : 100 - bookedSlots.length;
  }

  bool get isFull => availableSlots <= 0;
}
