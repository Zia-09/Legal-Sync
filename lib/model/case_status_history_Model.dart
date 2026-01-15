import 'package:cloud_firestore/cloud_firestore.dart';

/// 🔹 Case Status History Model
/// Tracks all status changes for a case for audit trail and history
class CaseStatusHistoryModel {
  final String historyId;
  final String caseId;
  final String lawyerId;
  final String previousStatus;
  final String newStatus;
  final String? reason; // Why status changed
  final String changedBy; // User ID who made the change
  final DateTime changedAt;
  final String? notes; // Additional notes
  final Map<String, dynamic>? metadata; // Extra context

  const CaseStatusHistoryModel({
    required this.historyId,
    required this.caseId,
    required this.lawyerId,
    required this.previousStatus,
    required this.newStatus,
    this.reason,
    required this.changedBy,
    required this.changedAt,
    this.notes,
    this.metadata,
  });

  /// ===============================
  /// Firestore → Model
  /// ===============================
  factory CaseStatusHistoryModel.fromJson(Map<String, dynamic> json) {
    return CaseStatusHistoryModel(
      historyId: json['historyId'] ?? '',
      caseId: json['caseId'] ?? '',
      lawyerId: json['lawyerId'] ?? '',
      previousStatus: json['previousStatus'] ?? '',
      newStatus: json['newStatus'] ?? '',
      reason: json['reason'],
      changedBy: json['changedBy'] ?? '',
      changedAt: json['changedAt'] is Timestamp
          ? (json['changedAt'] as Timestamp).toDate()
          : DateTime.now(),
      notes: json['notes'],
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
    );
  }

  /// ===============================
  /// Model → Firestore
  /// ===============================
  Map<String, dynamic> toJson() {
    return {
      'historyId': historyId,
      'caseId': caseId,
      'lawyerId': lawyerId,
      'previousStatus': previousStatus,
      'newStatus': newStatus,
      'reason': reason,
      'changedBy': changedBy,
      'changedAt': Timestamp.fromDate(changedAt),
      'notes': notes,
      'metadata': metadata,
    };
  }

  /// ===============================
  /// CopyWith
  /// ===============================
  CaseStatusHistoryModel copyWith({
    String? reason,
    String? notes,
    Map<String, dynamic>? metadata,
  }) {
    return CaseStatusHistoryModel(
      historyId: historyId,
      caseId: caseId,
      lawyerId: lawyerId,
      previousStatus: previousStatus,
      newStatus: newStatus,
      reason: reason ?? this.reason,
      changedBy: changedBy,
      changedAt: changedAt,
      notes: notes ?? this.notes,
      metadata: metadata ?? this.metadata,
    );
  }
}
