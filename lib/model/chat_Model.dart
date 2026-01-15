import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String messageId;
  final String senderId;
  final String receiverId;
  final String message;
  final String messageType; // text, image, file, audio, video
  final String? fileUrl;
  final String? replyTo;
  final DateTime sentAt;
  final bool isRead;
  final bool isEdited;
  final bool isDeleted;

  final double? aiConfidence;
  final String? aiCategory;
  final bool? aiReviewedByAdmin;
  final String? aiSuggestedReply;
  final String? aiSummary;
  final String? aiLanguage;

  const ChatMessage({
    required this.messageId,
    required this.senderId,
    required this.receiverId,
    required this.message,
    this.messageType = "text",
    this.fileUrl,
    this.replyTo,
    required this.sentAt,
    this.isRead = false,
    this.isEdited = false,
    this.isDeleted = false,
    this.aiConfidence,
    this.aiCategory,
    this.aiReviewedByAdmin,
    this.aiSuggestedReply,
    this.aiSummary,
    this.aiLanguage,
  });

  /// Safe date parsing
  static DateTime _safeDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }

  /// Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      "messageId": messageId,
      "senderId": senderId,
      "receiverId": receiverId,
      "message": message,
      "messageType": messageType,
      "fileUrl": fileUrl,
      "replyTo": replyTo,
      "sentAt": Timestamp.fromDate(sentAt),
      "isRead": isRead,
      "isEdited": isEdited,
      "isDeleted": isDeleted,
      "aiConfidence": aiConfidence,
      "aiCategory": aiCategory,
      "aiReviewedByAdmin": aiReviewedByAdmin,
      "aiSuggestedReply": aiSuggestedReply,
      "aiSummary": aiSummary,
      "aiLanguage": aiLanguage,
    };
  }

  /// Create object from Firestore map
  factory ChatMessage.fromMap(Map<String, dynamic> map, String id) {
    return ChatMessage(
      messageId: id,
      senderId: map["senderId"] ?? '',
      receiverId: map["receiverId"] ?? '',
      message: map["message"] ?? '',
      messageType: map["messageType"] ?? 'text',
      fileUrl: map["fileUrl"],
      replyTo: map["replyTo"],
      sentAt: _safeDate(map["sentAt"]),
      isRead: map["isRead"] ?? false,
      isEdited: map["isEdited"] ?? false,
      isDeleted: map["isDeleted"] ?? false,
      aiConfidence: (map["aiConfidence"] is num)
          ? (map["aiConfidence"] as num).toDouble()
          : null,
      aiCategory: map["aiCategory"],
      aiReviewedByAdmin: map["aiReviewedByAdmin"],
      aiSuggestedReply: map["aiSuggestedReply"],
      aiSummary: map["aiSummary"],
      aiLanguage: map["aiLanguage"],
    );
  }

  /// 🔹 Convert to JSON (alias for toMap)
  Map<String, dynamic> toJson() => toMap();

  /// Copy with optional updates
  ChatMessage copyWith({
    String? message,
    bool? isRead,
    bool? isEdited,
    bool? isDeleted,
    String? fileUrl,
    double? aiConfidence,
    String? aiCategory,
    bool? aiReviewedByAdmin,
    String? aiSuggestedReply,
    String? aiSummary,
    String? aiLanguage,
  }) {
    return ChatMessage(
      messageId: messageId,
      senderId: senderId,
      receiverId: receiverId,
      message: message ?? this.message,
      messageType: messageType,
      fileUrl: fileUrl ?? this.fileUrl,
      replyTo: replyTo,
      sentAt: sentAt,
      isRead: isRead ?? this.isRead,
      isEdited: isEdited ?? this.isEdited,
      isDeleted: isDeleted ?? this.isDeleted,
      aiConfidence: aiConfidence ?? this.aiConfidence,
      aiCategory: aiCategory ?? this.aiCategory,
      aiReviewedByAdmin: aiReviewedByAdmin ?? this.aiReviewedByAdmin,
      aiSuggestedReply: aiSuggestedReply ?? this.aiSuggestedReply,
      aiSummary: aiSummary ?? this.aiSummary,
      aiLanguage: aiLanguage ?? this.aiLanguage,
    );
  }
}
