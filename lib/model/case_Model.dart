import 'package:cloud_firestore/cloud_firestore.dart';

class CaseModel {
  final String caseId;
  final String clientId;
  final String lawyerId;
  final String title;
  final String description;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final double? caseFee;
  final String? caseType;
  final List<String> documentUrls;
  final String? courtName;
  final DateTime? hearingDate;
  final String? remarks;
  final List<String> messageIds;
  final bool isApproved;
  final String? adminNote;
  final String priority;
  final bool isArchived;

  final double? aiConfidence;
  final String? predictedOutcome;
  final bool? aiReviewedByAdmin;
  final String? aiModelVersion;
  final DateTime? aiPredictedAt;

  const CaseModel({
    required this.caseId,
    required this.clientId,
    required this.lawyerId,
    required this.title,
    required this.description,
    this.status = 'pending',
    required this.createdAt,
    this.updatedAt,
    this.caseFee,
    this.caseType,
    this.documentUrls = const [],
    this.courtName,
    this.hearingDate,
    this.remarks,
    this.messageIds = const [],
    this.isApproved = false,
    this.adminNote,
    this.priority = 'normal',
    this.isArchived = false,
    this.aiConfidence,
    this.predictedOutcome,
    this.aiReviewedByAdmin,
    this.aiModelVersion,
    this.aiPredictedAt,
  });

  // AI Prediction Fields comment (for clarity)

  static DateTime? _safeDate(dynamic value) {
    try {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is String && value.isNotEmpty) return DateTime.parse(value);
    } catch (_) {}
    return null;
  }

  Map<String, dynamic> toMap() {
    return {
      'caseId': caseId,
      'clientId': clientId,
      'lawyerId': lawyerId,
      'title': title,
      'description': description,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'caseFee': caseFee,
      'caseType': caseType,
      'documentUrls': documentUrls,
      'courtName': courtName,
      'hearingDate': hearingDate != null
          ? Timestamp.fromDate(hearingDate!)
          : null,
      'remarks': remarks,
      'messageIds': messageIds,
      'isApproved': isApproved,
      'adminNote': adminNote,
      'priority': priority,
      'isArchived': isArchived,
      'aiConfidence': aiConfidence,
      'predictedOutcome': predictedOutcome,
      'aiReviewedByAdmin': aiReviewedByAdmin,
      'aiModelVersion': aiModelVersion,
      'aiPredictedAt': aiPredictedAt != null
          ? Timestamp.fromDate(aiPredictedAt!)
          : null,
    };
  }

  /// 🔹 Convert CaseModel to Firestore map
  Map<String, dynamic> toJson() {
    return {
      'caseId': caseId,
      'clientId': clientId,
      'lawyerId': lawyerId,
      'title': title,
      'description': description,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'caseFee': caseFee,
      'caseType': caseType,
      'documentUrls': documentUrls,
      'courtName': courtName,
      'hearingDate': hearingDate != null
          ? Timestamp.fromDate(hearingDate!)
          : null,
      'remarks': remarks,
      'messageIds': messageIds,
      'isApproved': isApproved,
      'adminNote': adminNote,
      'priority': priority,
      'isArchived': isArchived,
      'aiConfidence': aiConfidence,
      'predictedOutcome': predictedOutcome,
      'aiReviewedByAdmin': aiReviewedByAdmin,
      'aiModelVersion': aiModelVersion,
      'aiPredictedAt': aiPredictedAt != null
          ? Timestamp.fromDate(aiPredictedAt!)
          : null,
    };
  }

  /// 🔹 Convert Firestore map to CaseModel
  factory CaseModel.fromJson(Map<String, dynamic> json, {String? id}) {
    return CaseModel(
      caseId: id ?? json['caseId']?.toString() ?? '',
      clientId: json['clientId']?.toString() ?? '',
      lawyerId: json['lawyerId']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      createdAt: _safeDate(json['createdAt']) ?? DateTime.now(),
      updatedAt: _safeDate(json['updatedAt']),
      caseFee: (json['caseFee'] is num)
          ? (json['caseFee'] as num).toDouble()
          : null,
      caseType: json['caseType']?.toString(),
      documentUrls: (json['documentUrls'] as List?)?.cast<String>() ?? const [],
      courtName: json['courtName']?.toString(),
      hearingDate: _safeDate(json['hearingDate']),
      remarks: json['remarks']?.toString(),
      messageIds: (json['messageIds'] as List?)?.cast<String>() ?? const [],
      isApproved: json['isApproved'] ?? false,
      adminNote: json['adminNote']?.toString(),
      priority: json['priority']?.toString() ?? 'normal',
      isArchived: json['isArchived'] ?? false,
      aiConfidence: (json['aiConfidence'] is num)
          ? (json['aiConfidence'] as num).toDouble()
          : null,
      predictedOutcome: json['predictedOutcome']?.toString(),
      aiReviewedByAdmin: json['aiReviewedByAdmin'],
      aiModelVersion: json['aiModelVersion']?.toString(),
      aiPredictedAt: _safeDate(json['aiPredictedAt']),
    );
  }

  factory CaseModel.fromMap(Map<String, dynamic> map, String id) {
    return CaseModel(
      caseId: id,
      clientId: map['clientId']?.toString() ?? '',
      lawyerId: map['lawyerId']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      status: map['status']?.toString() ?? 'pending',
      createdAt: _safeDate(map['createdAt']) ?? DateTime.now(),
      updatedAt: _safeDate(map['updatedAt']),
      caseFee: (map['caseFee'] is num)
          ? (map['caseFee'] as num).toDouble()
          : null,
      caseType: map['caseType']?.toString(),
      documentUrls: (map['documentUrls'] as List?)?.cast<String>() ?? const [],
      courtName: map['courtName']?.toString(),
      hearingDate: _safeDate(map['hearingDate']),
      remarks: map['remarks']?.toString(),
      messageIds: (map['messageIds'] as List?)?.cast<String>() ?? const [],
      isApproved: map['isApproved'] ?? false,
      adminNote: map['adminNote']?.toString(),
      priority: map['priority']?.toString() ?? 'normal',
      isArchived: map['isArchived'] ?? false,
      aiConfidence: (map['aiConfidence'] is num)
          ? (map['aiConfidence'] as num).toDouble()
          : null,
      predictedOutcome: map['predictedOutcome']?.toString(),
      aiReviewedByAdmin: map['aiReviewedByAdmin'],
      aiModelVersion: map['aiModelVersion']?.toString(),
      aiPredictedAt: _safeDate(map['aiPredictedAt']),
    );
  }

  CaseModel copyWith({
    String? title,
    String? description,
    String? status,
    DateTime? updatedAt,
    double? caseFee,
    String? caseType,
    List<String>? documentUrls,
    String? courtName,
    DateTime? hearingDate,
    String? remarks,
    List<String>? messageIds,
    bool? isApproved,
    String? adminNote,
    String? priority,
    bool? isArchived,
    double? aiConfidence,
    String? predictedOutcome,
    bool? aiReviewedByAdmin,
    String? aiModelVersion,
    DateTime? aiPredictedAt,
  }) {
    return CaseModel(
      caseId: caseId,
      clientId: clientId,
      lawyerId: lawyerId,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      caseFee: caseFee ?? this.caseFee,
      caseType: caseType ?? this.caseType,
      documentUrls: documentUrls ?? this.documentUrls,
      courtName: courtName ?? this.courtName,
      hearingDate: hearingDate ?? this.hearingDate,
      remarks: remarks ?? this.remarks,
      messageIds: messageIds ?? this.messageIds,
      isApproved: isApproved ?? this.isApproved,
      adminNote: adminNote ?? this.adminNote,
      priority: priority ?? this.priority,
      isArchived: isArchived ?? this.isArchived,
      aiConfidence: aiConfidence ?? this.aiConfidence,
      predictedOutcome: predictedOutcome ?? this.predictedOutcome,
      aiReviewedByAdmin: aiReviewedByAdmin ?? this.aiReviewedByAdmin,
      aiModelVersion: aiModelVersion ?? this.aiModelVersion,
      aiPredictedAt: aiPredictedAt ?? this.aiPredictedAt,
    );
  }
}
