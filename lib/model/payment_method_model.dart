import 'package:cloud_firestore/cloud_firestore.dart';

/// 🔹 Payment / Transaction Model
class TransactionModel {
  final String transactionId;
  final String userId; // Client who made the payment
  final String? lawyerId; // Optional, if payment is for a lawyer
  final String appointmentId; // Associated appointment
  final double amount;
  final String currency; // e.g., "PKR"
  final String
  paymentMethod; // e.g., "JazzCash", "Easypaisa", "Bank Transfer", "Card"
  final String status; // "pending", "completed", "failed", "refunded"
  final String? paymentReference; // From payment gateway
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? adminNote; // Optional admin remarks
  final Map<String, dynamic>? metadata; // Extra info if needed

  const TransactionModel({
    required this.transactionId,
    required this.userId,
    this.lawyerId,
    required this.appointmentId,
    required this.amount,
    this.currency = "PKR",
    this.paymentMethod = "unknown",
    this.status = "pending",
    this.paymentReference,
    required this.createdAt,
    this.updatedAt,
    this.adminNote,
    this.metadata,
  });

  /// 🔹 Convert Firestore / JSON to TransactionModel
  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      transactionId: json['transactionId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      lawyerId: json['lawyerId']?.toString(),
      appointmentId: json['appointmentId']?.toString() ?? '',
      amount: (json['amount'] is num)
          ? (json['amount'] as num).toDouble()
          : 0.0,
      currency: json['currency']?.toString() ?? "PKR",
      paymentMethod: json['paymentMethod']?.toString() ?? "unknown",
      status: json['status']?.toString() ?? "pending",
      paymentReference: json['paymentReference']?.toString(),
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
                DateTime.now(),
      updatedAt: json['updatedAt'] is Timestamp
          ? (json['updatedAt'] as Timestamp).toDate()
          : (json['updatedAt'] != null
                ? DateTime.tryParse(json['updatedAt']?.toString() ?? '')
                : null),
      adminNote: json['adminNote']?.toString(),
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
    );
  }

  /// 🔹 Convert TransactionModel to Firestore / JSON
  Map<String, dynamic> toJson() {
    return {
      'transactionId': transactionId,
      'userId': userId,
      'lawyerId': lawyerId,
      'appointmentId': appointmentId,
      'amount': amount,
      'currency': currency,
      'paymentMethod': paymentMethod,
      'status': status,
      'paymentReference': paymentReference,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'adminNote': adminNote,
      'metadata': metadata,
    };
  }

  /// 🔹 CopyWith for updates
  TransactionModel copyWith({
    String? status,
    String? paymentReference,
    DateTime? updatedAt,
    String? adminNote,
    Map<String, dynamic>? metadata,
  }) {
    return TransactionModel(
      transactionId: transactionId,
      userId: userId,
      lawyerId: lawyerId,
      appointmentId: appointmentId,
      amount: amount,
      currency: currency,
      paymentMethod: paymentMethod,
      status: status ?? this.status,
      paymentReference: paymentReference ?? this.paymentReference,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      adminNote: adminNote ?? this.adminNote,
      metadata: metadata ?? this.metadata,
    );
  }

  /// 🔹 Helper: Check if payment is completed
  bool get isCompleted => status.toLowerCase() == 'completed';
}
