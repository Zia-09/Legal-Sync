import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentTransactionModel {
  final String transactionId;
  final String clientId;
  final String lawyerId;
  final String caseId;
  final double amount;
  final String paymentMethod; // 'card', 'wallet', 'bank_transfer', etc.
  final String status; // 'pending', 'completed', 'failed', 'refunded'
  final String transactionType; // 'payment', 'refund', 'adjustment'
  final DateTime transactionDate;
  final DateTime? completedDate;
  final String? description;
  final String? transactionRef; // Reference from payment gateway (Stripe, PayPal)
  final String? failureReason;
  final Map<String, dynamic>? metadata;

  PaymentTransactionModel({
    required this.transactionId,
    required this.clientId,
    required this.lawyerId,
    required this.caseId,
    required this.amount,
    required this.paymentMethod,
    required this.status,
    required this.transactionType,
    required this.transactionDate,
    this.completedDate,
    this.description,
    this.transactionRef,
    this.failureReason,
    this.metadata,
  });

  factory PaymentTransactionModel.fromJson(Map<String, dynamic> json) {
    return PaymentTransactionModel(
      transactionId: json['transactionId'] as String? ?? '',
      clientId: json['clientId'] as String? ?? '',
      lawyerId: json['lawyerId'] as String? ?? '',
      caseId: json['caseId'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: json['paymentMethod'] as String? ?? 'card',
      status: json['status'] as String? ?? 'pending',
      transactionType: json['transactionType'] as String? ?? 'payment',
      transactionDate: (json['transactionDate'] is Timestamp)
          ? (json['transactionDate'] as Timestamp).toDate()
          : DateTime.parse(json['transactionDate'] as String? ?? DateTime.now().toIso8601String()),
      completedDate: json['completedDate'] != null
          ? (json['completedDate'] is Timestamp)
              ? (json['completedDate'] as Timestamp).toDate()
              : DateTime.parse(json['completedDate'] as String)
          : null,
      description: json['description'] as String?,
      transactionRef: json['transactionRef'] as String?,
      failureReason: json['failureReason'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'transactionId': transactionId,
      'clientId': clientId,
      'lawyerId': lawyerId,
      'caseId': caseId,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'status': status,
      'transactionType': transactionType,
      'transactionDate': Timestamp.fromDate(transactionDate),
      'completedDate': completedDate != null ? Timestamp.fromDate(completedDate!) : null,
      'description': description,
      'transactionRef': transactionRef,
      'failureReason': failureReason,
      'metadata': metadata,
    };
  }

  PaymentTransactionModel copyWith({
    String? transactionId,
    String? clientId,
    String? lawyerId,
    String? caseId,
    double? amount,
    String? paymentMethod,
    String? status,
    String? transactionType,
    DateTime? transactionDate,
    DateTime? completedDate,
    String? description,
    String? transactionRef,
    String? failureReason,
    Map<String, dynamic>? metadata,
  }) {
    return PaymentTransactionModel(
      transactionId: transactionId ?? this.transactionId,
      clientId: clientId ?? this.clientId,
      lawyerId: lawyerId ?? this.lawyerId,
      caseId: caseId ?? this.caseId,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      transactionType: transactionType ?? this.transactionType,
      transactionDate: transactionDate ?? this.transactionDate,
      completedDate: completedDate ?? this.completedDate,
      description: description ?? this.description,
      transactionRef: transactionRef ?? this.transactionRef,
      failureReason: failureReason ?? this.failureReason,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'PaymentTransactionModel(id: $transactionId, status: $status, amount: $amount)';
  }
}
