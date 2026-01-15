import 'package:cloud_firestore/cloud_firestore.dart';

class AICasePredictionModel {
  final String caseId; // REAL case ID (used as document ID)
  final String lawyerId;
  final String clientId;
  final String caseType;
  final String description;

  final double confidence; // 0.0 → 1.0
  final String predictedOutcome; // win | lose | settle
  final String predictionExplanation;

  final DateTime predictedAt;

  // Optional review fields
  final bool? predictionConfirmed;
  final String? adminNotes;
  final double? updatedConfidence;
  final DateTime? updatedAt;

  const AICasePredictionModel({
    required this.caseId,
    required this.lawyerId,
    required this.clientId,
    required this.caseType,
    required this.description,
    required this.confidence,
    required this.predictedOutcome,
    required this.predictionExplanation,
    required this.predictedAt,
    this.predictionConfirmed,
    this.adminNotes,
    this.updatedConfidence,
    this.updatedAt,
  });

  /// 🔹 Firestore serialization
  Map<String, dynamic> toJson() {
    return {
      'caseId': caseId,
      'lawyerId': lawyerId,
      'clientId': clientId,
      'caseType': caseType,
      'description': description,
      'confidence': confidence,
      'predictedOutcome': predictedOutcome,
      'predictionExplanation': predictionExplanation,
      'predictedAt': Timestamp.fromDate(predictedAt),
      'predictionConfirmed': predictionConfirmed,
      'adminNotes': adminNotes,
      'updatedConfidence': updatedConfidence,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  /// 🔹 Firestore deserialization
  factory AICasePredictionModel.fromJson(Map<String, dynamic> json) {
    return AICasePredictionModel(
      caseId: json['caseId'] ?? '',
      lawyerId: json['lawyerId'] ?? '',
      clientId: json['clientId'] ?? '',
      caseType: json['caseType'] ?? '',
      description: json['description'] ?? '',
      confidence: (json['confidence'] ?? 0).toDouble(),
      predictedOutcome: json['predictedOutcome'] ?? 'unknown',
      predictionExplanation: json['predictionExplanation'] ?? '',
      predictedAt: (json['predictedAt'] as Timestamp).toDate(),
      predictionConfirmed: json['predictionConfirmed'],
      adminNotes: json['adminNotes'],
      updatedConfidence: json['updatedConfidence'] != null
          ? (json['updatedConfidence'] as num).toDouble()
          : null,
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// 🔹 Safe update helper
  AICasePredictionModel copyWith({
    double? confidence,
    String? predictedOutcome,
    String? predictionExplanation,
    bool? predictionConfirmed,
    String? adminNotes,
    double? updatedConfidence,
    DateTime? updatedAt,
  }) {
    return AICasePredictionModel(
      caseId: caseId,
      lawyerId: lawyerId,
      clientId: clientId,
      caseType: caseType,
      description: description,
      confidence: confidence ?? this.confidence,
      predictedOutcome: predictedOutcome ?? this.predictedOutcome,
      predictionExplanation:
          predictionExplanation ?? this.predictionExplanation,
      predictedAt: predictedAt,
      predictionConfirmed: predictionConfirmed ?? this.predictionConfirmed,
      adminNotes: adminNotes ?? this.adminNotes,
      updatedConfidence: updatedConfidence ?? this.updatedConfidence,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
