import 'package:cloud_firestore/cloud_firestore.dart';

/// 🔹 Case Deadline / Task Model
/// Tracks important deadlines, follow-ups, and tasks for a case
class DeadlineModel {
  final String deadlineId;
  final String caseId;
  final String lawyerId;
  final String title;
  final String description;
  final DateTime dueDate;
  final DateTime? remindAt; // When to send reminder
  final String priority; // "low", "medium", "high", "urgent"
  final String status; // "pending", "in-progress", "completed", "overdue"
  final String? assignedTo; // Could be team member
  final List<String> tags; // For categorization
  final bool notificationSent;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? completedAt;
  final String? notes;

  const DeadlineModel({
    required this.deadlineId,
    required this.caseId,
    required this.lawyerId,
    required this.title,
    required this.description,
    required this.dueDate,
    this.remindAt,
    this.priority = "medium",
    this.status = "pending",
    this.assignedTo,
    this.tags = const [],
    this.notificationSent = false,
    required this.createdAt,
    this.updatedAt,
    this.completedAt,
    this.notes,
  });

  /// ===============================
  /// Firestore → Model
  /// ===============================
  factory DeadlineModel.fromJson(Map<String, dynamic> json) {
    return DeadlineModel(
      deadlineId: json['deadlineId'] ?? '',
      caseId: json['caseId'] ?? '',
      lawyerId: json['lawyerId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      dueDate: json['dueDate'] is Timestamp
          ? (json['dueDate'] as Timestamp).toDate()
          : DateTime.parse(json['dueDate']?.toString() ?? ''),
      remindAt: json['remindAt'] is Timestamp
          ? (json['remindAt'] as Timestamp).toDate()
          : null,
      priority: json['priority'] ?? 'medium',
      status: json['status'] ?? 'pending',
      assignedTo: json['assignedTo'],
      tags: List<String>.from(json['tags'] ?? []),
      notificationSent: json['notificationSent'] ?? false,
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: json['updatedAt'] is Timestamp
          ? (json['updatedAt'] as Timestamp).toDate()
          : null,
      completedAt: json['completedAt'] is Timestamp
          ? (json['completedAt'] as Timestamp).toDate()
          : null,
      notes: json['notes'],
    );
  }

  /// ===============================
  /// Model → Firestore
  /// ===============================
  Map<String, dynamic> toJson() {
    return {
      'deadlineId': deadlineId,
      'caseId': caseId,
      'lawyerId': lawyerId,
      'title': title,
      'description': description,
      'dueDate': Timestamp.fromDate(dueDate),
      'remindAt': remindAt != null ? Timestamp.fromDate(remindAt!) : null,
      'priority': priority,
      'status': status,
      'assignedTo': assignedTo,
      'tags': tags,
      'notificationSent': notificationSent,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'completedAt': completedAt != null
          ? Timestamp.fromDate(completedAt!)
          : null,
      'notes': notes,
    };
  }

  /// ===============================
  /// CopyWith
  /// ===============================
  DeadlineModel copyWith({
    String? title,
    String? description,
    DateTime? dueDate,
    DateTime? remindAt,
    String? priority,
    String? status,
    String? assignedTo,
    List<String>? tags,
    bool? notificationSent,
    DateTime? updatedAt,
    DateTime? completedAt,
    String? notes,
  }) {
    return DeadlineModel(
      deadlineId: deadlineId,
      caseId: caseId,
      lawyerId: lawyerId,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      remindAt: remindAt ?? this.remindAt,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      assignedTo: assignedTo ?? this.assignedTo,
      tags: tags ?? this.tags,
      notificationSent: notificationSent ?? this.notificationSent,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
      notes: notes ?? this.notes,
    );
  }

  /// ===============================
  /// Helpers
  /// ===============================
  bool get isOverdue =>
      status != 'completed' && DateTime.now().isAfter(dueDate);
  bool get isUpcoming => !isOverdue && dueDate.isAfter(DateTime.now());
  Duration? get timeRemaining =>
      isOverdue ? null : dueDate.difference(DateTime.now());
}
