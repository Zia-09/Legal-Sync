import 'package:cloud_firestore/cloud_firestore.dart';

class HearingModel {
  final String hearingId;
  final String caseId;
  final String? courtName;
  final DateTime hearingDate;
  final String? notes;
  final bool reminderSent;
  final String? reminderTime; // "24h_before", "1h_before", "custom"
  final String
  status; // "scheduled", "ongoing", "completed", "postponed", "cancelled"
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? createdBy; // lawyerId or clientId
  final String? outcome; // "win", "lose", "postponed", etc.
  final String? judgeNotes;

  const HearingModel({
    required this.hearingId,
    required this.caseId,
    this.courtName,
    required this.hearingDate,
    this.notes,
    this.reminderSent = false,
    this.reminderTime,
    this.status = "scheduled",
    required this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.outcome,
    this.judgeNotes,
  });

  factory HearingModel.fromJson(Map<String, dynamic> json) {
    return HearingModel(
      hearingId: json['hearingId']?.toString() ?? '',
      caseId: json['caseId']?.toString() ?? '',
      courtName: json['courtName']?.toString(),
      hearingDate: json['hearingDate'] is Timestamp
          ? (json['hearingDate'] as Timestamp).toDate()
          : DateTime.tryParse(json['hearingDate']?.toString() ?? '') ??
                DateTime.now(),
      notes: json['notes']?.toString(),
      reminderSent: json['reminderSent'] ?? false,
      reminderTime: json['reminderTime']?.toString(),
      status: json['status']?.toString() ?? 'scheduled',
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
                DateTime.now(),
      updatedAt: json['updatedAt'] is Timestamp
          ? (json['updatedAt'] as Timestamp).toDate()
          : (json['updatedAt'] != null
                ? DateTime.tryParse(json['updatedAt']?.toString() ?? '')
                : null),
      createdBy: json['createdBy']?.toString(),
      outcome: json['outcome']?.toString(),
      judgeNotes: json['judgeNotes']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hearingId': hearingId,
      'caseId': caseId,
      'courtName': courtName,
      'hearingDate': Timestamp.fromDate(hearingDate),
      'notes': notes,
      'reminderSent': reminderSent,
      'reminderTime': reminderTime,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'createdBy': createdBy,
      'outcome': outcome,
      'judgeNotes': judgeNotes,
    };
  }

  HearingModel copyWith({
    String? courtName,
    DateTime? hearingDate,
    String? notes,
    bool? reminderSent,
    String? reminderTime,
    String? status,
    DateTime? updatedAt,
    String? outcome,
    String? judgeNotes,
  }) {
    return HearingModel(
      hearingId: hearingId,
      caseId: caseId,
      courtName: courtName ?? this.courtName,
      hearingDate: hearingDate ?? this.hearingDate,
      notes: notes ?? this.notes,
      reminderSent: reminderSent ?? this.reminderSent,
      reminderTime: reminderTime ?? this.reminderTime,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy,
      outcome: outcome ?? this.outcome,
      judgeNotes: judgeNotes ?? this.judgeNotes,
    );
  }

  bool get isUpcoming => hearingDate.isAfter(DateTime.now());
  bool get isCompleted => status == 'completed';
}
