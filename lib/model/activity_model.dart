import 'package:cloud_firestore/cloud_firestore.dart';

/// 🔹 Activity Model - Track all user activities within a specific case for Case Activity Log
class ActivityModel {
  final String id;
  final String caseId;
  final String userId;
  final String userName;
  final String userRole; // lawyer, client, admin
  final String
  actionType; // case_created, document_uploaded, hearing_added, message_sent
  final String
  actionDescription; // "Lawyer created case", "Client uploaded document"
  final DateTime createdAt;

  ActivityModel({
    required this.id,
    required this.caseId,
    required this.userId,
    required this.userName,
    required this.userRole,
    required this.actionType,
    required this.actionDescription,
    required this.createdAt,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'caseId': caseId,
      'userId': userId,
      'userName': userName,
      'userRole': userRole,
      'actionType': actionType,
      'actionDescription': actionDescription,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Create from JSON
  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    return ActivityModel(
      id: json['id'] ?? '',
      caseId: json['caseId'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      userRole: json['userRole'] ?? '',
      actionType: json['actionType'] ?? '',
      actionDescription: json['actionDescription'] ?? '',
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.parse(json['createdAt'] ?? DateTime.now().toString()),
    );
  }

  /// Copy with method
  ActivityModel copyWith({
    String? id,
    String? caseId,
    String? userId,
    String? userName,
    String? userRole,
    String? actionType,
    String? actionDescription,
    DateTime? createdAt,
  }) {
    return ActivityModel(
      id: id ?? this.id,
      caseId: caseId ?? this.caseId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userRole: userRole ?? this.userRole,
      actionType: actionType ?? this.actionType,
      actionDescription: actionDescription ?? this.actionDescription,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
