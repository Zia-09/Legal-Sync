import 'package:cloud_firestore/cloud_firestore.dart';

/// 🔹 Notification / Push Notification Model
class NotificationModel {
  final String notificationId;
  final String userId; // Could be clientId or lawyerId
  final String title;
  final String message;
  final String type; // e.g., "appointment", "review", "system", "payment"
  final bool isRead;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>?
  metadata; // Optional extra info like appointmentId, reviewId

  const NotificationModel({
    required this.notificationId,
    required this.userId,
    required this.title,
    required this.message,
    this.type = "system",
    this.isRead = false,
    required this.createdAt,
    this.updatedAt,
    this.metadata,
  });

  /// 🔹 Convert Firestore / JSON to NotificationModel
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      notificationId: json['notificationId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      type: json['type']?.toString() ?? 'system',
      isRead: json['isRead'] ?? false,
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
                DateTime.now(),
      updatedAt: json['updatedAt'] is Timestamp
          ? (json['updatedAt'] as Timestamp).toDate()
          : (json['updatedAt'] != null
                ? DateTime.tryParse(json['updatedAt']?.toString() ?? '')
                : null),
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
    );
  }

  /// 🔹 Convert NotificationModel to Firestore / JSON
  Map<String, dynamic> toJson() {
    return {
      'notificationId': notificationId,
      'userId': userId,
      'title': title,
      'message': message,
      'type': type,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'metadata': metadata,
    };
  }

  /// 🔹 CopyWith for updates
  NotificationModel copyWith({
    String? title,
    String? message,
    String? type,
    bool? isRead,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return NotificationModel(
      notificationId: notificationId,
      userId: userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }
}
