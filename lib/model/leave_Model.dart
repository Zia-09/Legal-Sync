import 'package:cloud_firestore/cloud_firestore.dart';

/// 🔹 Leave Model - Track lawyer time off/availability
class LeaveModel {
  final String leaveId;
  final String lawyerId;
  final DateTime startDate;
  final DateTime endDate;
  final String reason; // vacation, sick, personal, training
  final String status; // approved, pending, rejected
  final String? approvedBy; // admin user ID
  final DateTime? approvedDate;
  final String? notes;
  final DateTime createdAt;
  final bool notifyClients;

  LeaveModel({
    required this.leaveId,
    required this.lawyerId,
    required this.startDate,
    required this.endDate,
    required this.reason,
    required this.status,
    this.approvedBy,
    this.approvedDate,
    this.notes,
    required this.createdAt,
    this.notifyClients = true,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'leaveId': leaveId,
      'lawyerId': lawyerId,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'reason': reason,
      'status': status,
      'approvedBy': approvedBy,
      'approvedDate': approvedDate != null
          ? Timestamp.fromDate(approvedDate!)
          : null,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'notifyClients': notifyClients,
    };
  }

  /// Create from JSON
  factory LeaveModel.fromJson(Map<String, dynamic> json) {
    return LeaveModel(
      leaveId: json['leaveId'] ?? '',
      lawyerId: json['lawyerId'] ?? '',
      startDate: json['startDate'] is Timestamp
          ? (json['startDate'] as Timestamp).toDate()
          : DateTime.parse(json['startDate'] ?? DateTime.now().toString()),
      endDate: json['endDate'] is Timestamp
          ? (json['endDate'] as Timestamp).toDate()
          : DateTime.parse(json['endDate'] ?? DateTime.now().toString()),
      reason: json['reason'] ?? '',
      status: json['status'] ?? 'pending',
      approvedBy: json['approvedBy'],
      approvedDate: json['approvedDate'] is Timestamp
          ? (json['approvedDate'] as Timestamp).toDate()
          : null,
      notes: json['notes'],
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.parse(json['createdAt'] ?? DateTime.now().toString()),
      notifyClients: json['notifyClients'] ?? true,
    );
  }

  /// Copy with method
  LeaveModel copyWith({
    String? leaveId,
    String? lawyerId,
    DateTime? startDate,
    DateTime? endDate,
    String? reason,
    String? status,
    String? approvedBy,
    DateTime? approvedDate,
    String? notes,
    DateTime? createdAt,
    bool? notifyClients,
  }) {
    return LeaveModel(
      leaveId: leaveId ?? this.leaveId,
      lawyerId: lawyerId ?? this.lawyerId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedDate: approvedDate ?? this.approvedDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      notifyClients: notifyClients ?? this.notifyClients,
    );
  }

  /// Get number of leave days
  int get leaveDays {
    return endDate.difference(startDate).inDays + 1;
  }

  /// Check if leave is in future
  bool get isFuture {
    return startDate.isAfter(DateTime.now());
  }

  /// Check if leave is currently active
  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }

  /// Check if leave is approved
  bool get isApproved {
    return status.toLowerCase() == 'approved';
  }

  /// Check if leave is pending
  bool get isPending {
    return status.toLowerCase() == 'pending';
  }

  /// Check if leave is rejected
  bool get isRejected {
    return status.toLowerCase() == 'rejected';
  }

  @override
  String toString() {
    return 'LeaveModel(leaveId: $leaveId, lawyerId: $lawyerId, reason: $reason, status: $status)';
  }
}
