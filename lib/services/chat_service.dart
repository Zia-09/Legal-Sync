import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/chat_model.dart';

class ChatService {
  final FirebaseFirestore _db;

  ChatService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  static const String _collection = 'chats';

  /// =========================
  /// PRIVATE HELPERS
  /// =========================

  String _getChatId(String userId1, String userId2) {
    return (userId1.hashCode <= userId2.hashCode)
        ? '${userId1}_$userId2'
        : '${userId2}_$userId1';
  }

  CollectionReference<Map<String, dynamic>> _messagesRef(String chatId) {
    return _db.collection(_collection).doc(chatId).collection('messages');
  }

  /// =========================
  /// SEND MESSAGE
  /// =========================
  Future<void> sendMessage({
    required String senderId,
    required String receiverId,
    required String message,
    String messageType = 'text',
    String? fileUrl,
    String? replyTo,
  }) async {
    final chatId = _getChatId(senderId, receiverId);
    final docRef = _messagesRef(chatId).doc();

    final newMessage = ChatMessage(
      messageId: docRef.id,
      senderId: senderId,
      receiverId: receiverId,
      message: message,
      messageType: messageType,
      fileUrl: fileUrl,
      replyTo: replyTo,
      sentAt: DateTime.now(),
    );

    await docRef.set(newMessage.toMap());
  }

  /// =========================
  /// REAL-TIME MESSAGE STREAM
  /// =========================
  Stream<List<ChatMessage>> getMessages(String userId1, String userId2) {
    final chatId = _getChatId(userId1, userId2);

    return _messagesRef(chatId)
        .orderBy('sentAt', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ChatMessage.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  /// =========================
  /// MARK MESSAGE AS READ
  /// =========================
  Future<void> markAsRead(
    String userId1,
    String userId2,
    String messageId,
  ) async {
    final chatId = _getChatId(userId1, userId2);

    await _messagesRef(chatId).doc(messageId).update({'isRead': true});
  }

  /// =========================
  /// EDIT MESSAGE
  /// =========================
  Future<void> editMessage(
    String userId1,
    String userId2,
    String messageId,
    String newMessage,
  ) async {
    final chatId = _getChatId(userId1, userId2);

    await _messagesRef(
      chatId,
    ).doc(messageId).update({'message': newMessage, 'isEdited': true});
  }

  /// =========================
  /// SOFT DELETE MESSAGE
  /// =========================
  Future<void> deleteMessage(
    String userId1,
    String userId2,
    String messageId,
  ) async {
    final chatId = _getChatId(userId1, userId2);

    await _messagesRef(
      chatId,
    ).doc(messageId).update({'isDeleted': true, 'message': 'Message deleted'});
  }
}
