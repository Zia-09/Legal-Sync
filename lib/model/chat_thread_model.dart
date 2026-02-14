import 'package:cloud_firestore/cloud_firestore.dart';

class ChatThread {
  final String threadId;
  final String lawyerId;
  final String clientId;
  final String? caseId;

  final DateTime createdAt;
  final DateTime updatedAt;

  final String? lastMessage;
  final String? lastMessageSenderId;
  final DateTime? lastMessageAt;

  final int unreadByLawyer;
  final int unreadByClient;

  final bool isArchived;
  final bool isBlocked;

  final bool aiModerationEnabled;
  final bool flaggedByAI;
  final bool reviewedByAdmin;

  const ChatThread({
    required this.threadId,
    required this.lawyerId,
    required this.clientId,
    this.caseId,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessage,
    this.lastMessageSenderId,
    this.lastMessageAt,
    this.unreadByLawyer = 0,
    this.unreadByClient = 0,
    this.isArchived = false,
    this.isBlocked = false,
    this.aiModerationEnabled = true,
    this.flaggedByAI = false,
    this.reviewedByAdmin = false,
  });

  /// ===============================
  /// Firestore → Model
  /// ===============================
  factory ChatThread.fromMap(Map<String, dynamic> map, String docId) {
    return ChatThread(
      threadId: docId,
      lawyerId: map['lawyerId'] ?? '',
      clientId: map['clientId'] ?? '',
      caseId: map['caseId'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      lastMessage: map['lastMessage'],
      lastMessageSenderId: map['lastMessageSenderId'],
      lastMessageAt: map['lastMessageAt'] != null
          ? (map['lastMessageAt'] as Timestamp).toDate()
          : null,
      unreadByLawyer: map['unreadByLawyer'] ?? 0,
      unreadByClient: map['unreadByClient'] ?? 0,
      isArchived: map['isArchived'] ?? false,
      isBlocked: map['isBlocked'] ?? false,
      aiModerationEnabled: map['aiModerationEnabled'] ?? true,
      flaggedByAI: map['flaggedByAI'] ?? false,
      reviewedByAdmin: map['reviewedByAdmin'] ?? false,
    );
  }

  /// ===============================
  /// Model → Firestore
  /// ===============================
  Map<String, dynamic> toMap() {
    return {
      'lawyerId': lawyerId,
      'clientId': clientId,
      'caseId': caseId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'lastMessage': lastMessage,
      'lastMessageSenderId': lastMessageSenderId,
      'lastMessageAt': lastMessageAt != null
          ? Timestamp.fromDate(lastMessageAt!)
          : null,
      'unreadByLawyer': unreadByLawyer,
      'unreadByClient': unreadByClient,
      'isArchived': isArchived,
      'isBlocked': isBlocked,
      'aiModerationEnabled': aiModerationEnabled,
      'flaggedByAI': flaggedByAI,
      'reviewedByAdmin': reviewedByAdmin,
    };
  }

  /// 🔹 Convert to JSON (alias for toMap)
  Map<String, dynamic> toJson() => toMap();

  /// 🔹 Create from JSON (alias for fromMap)
  factory ChatThread.fromJson(Map<String, dynamic> json) {
    return ChatThread.fromMap(json, json['threadId'] ?? '');
  }

  ChatThread copyWith({
    String? lastMessage,
    String? lastMessageSenderId,
    DateTime? lastMessageAt,
    int? unreadByLawyer,
    int? unreadByClient,
    bool? isArchived,
    bool? isBlocked,
    bool? flaggedByAI,
    bool? reviewedByAdmin,
    DateTime? updatedAt,
  }) {
    return ChatThread(
      threadId: threadId,
      lawyerId: lawyerId,
      clientId: clientId,
      caseId: caseId,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadByLawyer: unreadByLawyer ?? this.unreadByLawyer,
      unreadByClient: unreadByClient ?? this.unreadByClient,
      isArchived: isArchived ?? this.isArchived,
      isBlocked: isBlocked ?? this.isBlocked,
      aiModerationEnabled: aiModerationEnabled,
      flaggedByAI: flaggedByAI ?? this.flaggedByAI,
      reviewedByAdmin: reviewedByAdmin ?? this.reviewedByAdmin,
    );
  }
}

typedef ChatThreadModel = ChatThread;
