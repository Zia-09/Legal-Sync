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
  final String? modeOfConduct; // "Online", "Offline"
  final String? hearingType;
  final String? clientId;

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // HEARING PARTICIPATION & FEEDBACK FIELDS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  final Map<String, dynamic>
  participationStatus; // {clientId: 'accepted'|'declined'|'pending'|'busy', lawyerId: status}
  final bool? clientAttended; // Did client actually attend the hearing
  final bool? lawyerAttended; // Did lawyer attend the hearing
  final String?
  hearingFeedback; // Post-hearing notes - description of how hearing went
  final DateTime? feedbackProvidedAt; // When feedback was submitted
  final String?
  feedbackProvidedBy; // Who provided feedback (clientId or lawyerId)
  final int?
  hearingQualityRating; // 1-5 rating of hearing quality (optional client/lawyer rating)

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
    this.modeOfConduct,
    this.hearingType,
    this.clientId,
    this.participationStatus = const {},
    this.clientAttended,
    this.lawyerAttended,
    this.hearingFeedback,
    this.feedbackProvidedAt,
    this.feedbackProvidedBy,
    this.hearingQualityRating,
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
      modeOfConduct: json['modeOfConduct']?.toString(),
      hearingType: json['hearingType']?.toString(),
      clientId: json['clientId']?.toString(),
      participationStatus:
          (json['participationStatus'] as Map<String, dynamic>?) ?? {},
      clientAttended: json['clientAttended'] as bool?,
      lawyerAttended: json['lawyerAttended'] as bool?,
      hearingFeedback: json['hearingFeedback']?.toString(),
      feedbackProvidedAt: json['feedbackProvidedAt'] is Timestamp
          ? (json['feedbackProvidedAt'] as Timestamp).toDate()
          : (json['feedbackProvidedAt'] != null
                ? DateTime.tryParse(
                    json['feedbackProvidedAt']?.toString() ?? '',
                  )
                : null),
      feedbackProvidedBy: json['feedbackProvidedBy']?.toString(),
      hearingQualityRating: json['hearingQualityRating'] as int?,
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
      'modeOfConduct': modeOfConduct,
      'hearingType': hearingType,
      'clientId': clientId,
      'participationStatus': participationStatus,
      'clientAttended': clientAttended,
      'lawyerAttended': lawyerAttended,
      'hearingFeedback': hearingFeedback,
      'feedbackProvidedAt': feedbackProvidedAt != null
          ? Timestamp.fromDate(feedbackProvidedAt!)
          : null,
      'feedbackProvidedBy': feedbackProvidedBy,
      'hearingQualityRating': hearingQualityRating,
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
    String? modeOfConduct,
    String? hearingType,
    String? clientId,
    Map<String, dynamic>? participationStatus,
    bool? clientAttended,
    bool? lawyerAttended,
    String? hearingFeedback,
    DateTime? feedbackProvidedAt,
    String? feedbackProvidedBy,
    int? hearingQualityRating,
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
      modeOfConduct: modeOfConduct ?? this.modeOfConduct,
      hearingType: hearingType ?? this.hearingType,
      clientId: clientId ?? this.clientId,
      participationStatus: participationStatus ?? this.participationStatus,
      clientAttended: clientAttended ?? this.clientAttended,
      lawyerAttended: lawyerAttended ?? this.lawyerAttended,
      hearingFeedback: hearingFeedback ?? this.hearingFeedback,
      feedbackProvidedAt: feedbackProvidedAt ?? this.feedbackProvidedAt,
      feedbackProvidedBy: feedbackProvidedBy ?? this.feedbackProvidedBy,
      hearingQualityRating: hearingQualityRating ?? this.hearingQualityRating,
    );
  }

  bool get isUpcoming => hearingDate.isAfter(DateTime.now());
  bool get isCompleted => status == 'completed';
}
