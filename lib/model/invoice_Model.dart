import 'package:cloud_firestore/cloud_firestore.dart';

class InvoiceModel {
  final String invoiceId;
  final String caseId;
  final String lawyerId;
  final String clientId;
  final double totalHours;
  final double ratePerHour;
  final double totalAmount;
  final String? pdfUrl;
  final DateTime createdAt;
  final DateTime? dueDate;
  final String
  status; // "draft", "sent", "viewed", "paid", "overdue", "cancelled"
  final DateTime? paidAt;
  final String? paymentMethod;
  final List<Map<String, dynamic>>
  lineItems; // {description, hours, rate, amount}
  final double? discountPercent;
  final double? taxPercent;
  final String? notes;
  final String? invoiceNumber; // Custom invoice number

  const InvoiceModel({
    required this.invoiceId,
    required this.caseId,
    required this.lawyerId,
    required this.clientId,
    required this.totalHours,
    required this.ratePerHour,
    required this.totalAmount,
    this.pdfUrl,
    required this.createdAt,
    this.dueDate,
    this.status = "draft",
    this.paidAt,
    this.paymentMethod,
    this.lineItems = const [],
    this.discountPercent,
    this.taxPercent,
    this.notes,
    this.invoiceNumber,
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    return InvoiceModel(
      invoiceId: json['invoiceId']?.toString() ?? '',
      caseId: json['caseId']?.toString() ?? '',
      lawyerId: json['lawyerId']?.toString() ?? '',
      clientId: json['clientId']?.toString() ?? '',
      totalHours: (json['totalHours'] is num)
          ? (json['totalHours'] as num).toDouble()
          : 0.0,
      ratePerHour: (json['ratePerHour'] is num)
          ? (json['ratePerHour'] as num).toDouble()
          : 0.0,
      totalAmount: (json['totalAmount'] is num)
          ? (json['totalAmount'] as num).toDouble()
          : 0.0,
      pdfUrl: json['pdfUrl']?.toString(),
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
                DateTime.now(),
      dueDate: json['dueDate'] is Timestamp
          ? (json['dueDate'] as Timestamp).toDate()
          : (json['dueDate'] != null
                ? DateTime.tryParse(json['dueDate']?.toString() ?? '')
                : null),
      status: json['status']?.toString() ?? 'draft',
      paidAt: json['paidAt'] is Timestamp
          ? (json['paidAt'] as Timestamp).toDate()
          : (json['paidAt'] != null
                ? DateTime.tryParse(json['paidAt']?.toString() ?? '')
                : null),
      paymentMethod: json['paymentMethod']?.toString(),
      lineItems:
          (json['lineItems'] as List?)?.cast<Map<String, dynamic>>() ?? [],
      discountPercent: (json['discountPercent'] is num)
          ? (json['discountPercent'] as num).toDouble()
          : null,
      taxPercent: (json['taxPercent'] is num)
          ? (json['taxPercent'] as num).toDouble()
          : null,
      notes: json['notes']?.toString(),
      invoiceNumber: json['invoiceNumber']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'invoiceId': invoiceId,
      'caseId': caseId,
      'lawyerId': lawyerId,
      'clientId': clientId,
      'totalHours': totalHours,
      'ratePerHour': ratePerHour,
      'totalAmount': totalAmount,
      'pdfUrl': pdfUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'status': status,
      'paidAt': paidAt != null ? Timestamp.fromDate(paidAt!) : null,
      'paymentMethod': paymentMethod,
      'lineItems': lineItems,
      'discountPercent': discountPercent,
      'taxPercent': taxPercent,
      'notes': notes,
      'invoiceNumber': invoiceNumber,
    };
  }

  InvoiceModel copyWith({
    double? totalHours,
    double? ratePerHour,
    double? totalAmount,
    String? pdfUrl,
    DateTime? dueDate,
    String? status,
    DateTime? paidAt,
    String? paymentMethod,
    List<Map<String, dynamic>>? lineItems,
    double? discountPercent,
    double? taxPercent,
    String? notes,
  }) {
    return InvoiceModel(
      invoiceId: invoiceId,
      caseId: caseId,
      lawyerId: lawyerId,
      clientId: clientId,
      totalHours: totalHours ?? this.totalHours,
      ratePerHour: ratePerHour ?? this.ratePerHour,
      totalAmount: totalAmount ?? this.totalAmount,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      createdAt: createdAt,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      paidAt: paidAt ?? this.paidAt,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      lineItems: lineItems ?? this.lineItems,
      discountPercent: discountPercent ?? this.discountPercent,
      taxPercent: taxPercent ?? this.taxPercent,
      notes: notes ?? this.notes,
      invoiceNumber: invoiceNumber,
    );
  }

  bool get isPaid => status == 'paid';
  bool get isOverdue =>
      dueDate != null && dueDate!.isBefore(DateTime.now()) && !isPaid;
  double get netAmount {
    double amount = totalAmount;
    if (discountPercent != null) {
      amount -= (amount * (discountPercent! / 100));
    }
    if (taxPercent != null) {
      amount += (amount * (taxPercent! / 100));
    }
    return amount;
  }
}
