import 'package:cloud_firestore/cloud_firestore.dart';

/// 🔹 Billing Model - Track client-specific payment and billing info
class BillingModel {
  final String billingId;
  final String clientId;
  final double totalBilled;
  final double totalPaid;
  final double balance;
  final List<String> invoiceIds; // References to invoices
  final String billingFrequency; // monthly, quarterly, yearly
  final DateTime? nextBillingDate;
  final String paymentMethod; // credit_card, bank_transfer, check
  final bool autoReminder;
  final int reminderDaysBefore; // Send reminder N days before due
  final DateTime createdAt;
  final DateTime? lastBilledAt;
  final String status; // active, paused, stopped

  BillingModel({
    required this.billingId,
    required this.clientId,
    required this.totalBilled,
    required this.totalPaid,
    required this.balance,
    required this.invoiceIds,
    required this.billingFrequency,
    this.nextBillingDate,
    required this.paymentMethod,
    this.autoReminder = true,
    this.reminderDaysBefore = 7,
    required this.createdAt,
    this.lastBilledAt,
    required this.status,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'billingId': billingId,
      'clientId': clientId,
      'totalBilled': totalBilled,
      'totalPaid': totalPaid,
      'balance': balance,
      'invoiceIds': invoiceIds,
      'billingFrequency': billingFrequency,
      'nextBillingDate': nextBillingDate != null
          ? Timestamp.fromDate(nextBillingDate!)
          : null,
      'paymentMethod': paymentMethod,
      'autoReminder': autoReminder,
      'reminderDaysBefore': reminderDaysBefore,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastBilledAt': lastBilledAt != null
          ? Timestamp.fromDate(lastBilledAt!)
          : null,
      'status': status,
    };
  }

  /// Create from JSON
  factory BillingModel.fromJson(Map<String, dynamic> json) {
    return BillingModel(
      billingId: json['billingId'] ?? '',
      clientId: json['clientId'] ?? '',
      totalBilled: (json['totalBilled'] ?? 0.0).toDouble(),
      totalPaid: (json['totalPaid'] ?? 0.0).toDouble(),
      balance: (json['balance'] ?? 0.0).toDouble(),
      invoiceIds: List<String>.from(json['invoiceIds'] ?? []),
      billingFrequency: json['billingFrequency'] ?? 'monthly',
      nextBillingDate: json['nextBillingDate'] is Timestamp
          ? (json['nextBillingDate'] as Timestamp).toDate()
          : null,
      paymentMethod: json['paymentMethod'] ?? 'credit_card',
      autoReminder: json['autoReminder'] ?? true,
      reminderDaysBefore: json['reminderDaysBefore'] ?? 7,
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.parse(json['createdAt'] ?? DateTime.now().toString()),
      lastBilledAt: json['lastBilledAt'] is Timestamp
          ? (json['lastBilledAt'] as Timestamp).toDate()
          : null,
      status: json['status'] ?? 'active',
    );
  }

  /// Copy with method
  BillingModel copyWith({
    String? billingId,
    String? clientId,
    double? totalBilled,
    double? totalPaid,
    double? balance,
    List<String>? invoiceIds,
    String? billingFrequency,
    DateTime? nextBillingDate,
    String? paymentMethod,
    bool? autoReminder,
    int? reminderDaysBefore,
    DateTime? createdAt,
    DateTime? lastBilledAt,
    String? status,
  }) {
    return BillingModel(
      billingId: billingId ?? this.billingId,
      clientId: clientId ?? this.clientId,
      totalBilled: totalBilled ?? this.totalBilled,
      totalPaid: totalPaid ?? this.totalPaid,
      balance: balance ?? this.balance,
      invoiceIds: invoiceIds ?? this.invoiceIds,
      billingFrequency: billingFrequency ?? this.billingFrequency,
      nextBillingDate: nextBillingDate ?? this.nextBillingDate,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      autoReminder: autoReminder ?? this.autoReminder,
      reminderDaysBefore: reminderDaysBefore ?? this.reminderDaysBefore,
      createdAt: createdAt ?? this.createdAt,
      lastBilledAt: lastBilledAt ?? this.lastBilledAt,
      status: status ?? this.status,
    );
  }

  /// Check if balance is due
  bool get hasBalance {
    return balance > 0;
  }

  /// Check if overdue
  bool get isOverdue {
    if (nextBillingDate == null) return false;
    return nextBillingDate!.isBefore(DateTime.now());
  }

  /// Calculate days until next billing
  int? get daysUntilNextBilling {
    if (nextBillingDate == null) return null;
    return nextBillingDate!.difference(DateTime.now()).inDays;
  }

  /// Get billing frequency display name
  String get frequencyDisplay {
    return switch (billingFrequency) {
      'monthly' => 'Monthly',
      'quarterly' => 'Quarterly',
      'yearly' => 'Yearly',
      _ => 'Unknown',
    };
  }

  /// Check if billing is active
  bool get isActive {
    return status.toLowerCase() == 'active';
  }

  /// Calculate paid percentage
  double get paidPercentage {
    if (totalBilled == 0) return 0;
    return (totalPaid / totalBilled) * 100;
  }

  @override
  String toString() {
    return 'BillingModel(billingId: $billingId, clientId: $clientId, totalBilled: $totalBilled, balance: $balance)';
  }
}
