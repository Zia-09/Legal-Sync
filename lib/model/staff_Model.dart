import 'package:cloud_firestore/cloud_firestore.dart';

/// 🔹 Staff / Team Member Model
/// For managing firm staff and team members
class StaffModel {
  final String staffId;
  final String firmId;
  final String name;
  final String email;
  final String phone;
  final String role; // "paralegal", "associate", "secretary", "intern"
  final String specialization; // e.g., "corporate", "criminal", "family"
  final bool isActive;
  final DateTime joinedAt;
  final DateTime? terminatedAt;
  final double? salary; // Optional, firm management
  final String? workSchedule; // e.g., "9-5", "flexible"
  final List<String> assignedCases; // Case IDs they work on
  final String? supervisorId; // ID of supervising lawyer
  final DateTime createdAt;
  final DateTime? updatedAt;

  const StaffModel({
    required this.staffId,
    required this.firmId,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.specialization,
    this.isActive = true,
    required this.joinedAt,
    this.terminatedAt,
    this.salary,
    this.workSchedule,
    this.assignedCases = const [],
    this.supervisorId,
    required this.createdAt,
    this.updatedAt,
  });

  /// ===============================
  /// Firestore → Model
  /// ===============================
  factory StaffModel.fromJson(Map<String, dynamic> json) {
    return StaffModel(
      staffId: json['staffId'] ?? '',
      firmId: json['firmId'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? 'intern',
      specialization: json['specialization'] ?? '',
      isActive: json['isActive'] ?? true,
      joinedAt: json['joinedAt'] is Timestamp
          ? (json['joinedAt'] as Timestamp).toDate()
          : DateTime.now(),
      terminatedAt: json['terminatedAt'] is Timestamp
          ? (json['terminatedAt'] as Timestamp).toDate()
          : null,
      salary: (json['salary'] is num)
          ? (json['salary'] as num).toDouble()
          : null,
      workSchedule: json['workSchedule'],
      assignedCases: List<String>.from(json['assignedCases'] ?? []),
      supervisorId: json['supervisorId'],
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
      'staffId': staffId,
      'firmId': firmId,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'specialization': specialization,
      'isActive': isActive,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'terminatedAt': terminatedAt != null
          ? Timestamp.fromDate(terminatedAt!)
          : null,
      'salary': salary,
      'workSchedule': workSchedule,
      'assignedCases': assignedCases,
      'supervisorId': supervisorId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  /// ===============================
  /// CopyWith
  /// ===============================
  StaffModel copyWith({
    String? name,
    String? role,
    String? specialization,
    bool? isActive,
    double? salary,
    List<String>? assignedCases,
    DateTime? updatedAt,
    DateTime? terminatedAt,
  }) {
    return StaffModel(
      staffId: staffId,
      firmId: firmId,
      name: name ?? this.name,
      email: email,
      phone: phone,
      role: role ?? this.role,
      specialization: specialization ?? this.specialization,
      isActive: isActive ?? this.isActive,
      joinedAt: joinedAt,
      terminatedAt: terminatedAt ?? this.terminatedAt,
      salary: salary ?? this.salary,
      workSchedule: workSchedule,
      assignedCases: assignedCases ?? this.assignedCases,
      supervisorId: supervisorId,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
