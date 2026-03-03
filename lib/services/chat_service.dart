import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/chat_Model.dart';

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
  Future<String> sendMessage({
    required String senderId,
    required String receiverId,
    required String message,
    String messageType = 'text',
    String? fileUrl,
    String? replyTo,
    String? caseId,
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
      caseId: caseId,
      sentAt: DateTime.now(),
    );

    await docRef.set(newMessage.toMap());
    return docRef.id;
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

  /// =========================
  /// TYPING STATUS
  /// =========================
  Future<void> setTypingStatus({
    required String senderId,
    required String receiverId,
    required bool isTyping,
  }) async {
    final chatId = _getChatId(senderId, receiverId);
    await _db
        .collection(_collection)
        .doc(chatId)
        .collection('typing')
        .doc(senderId)
        .set({'isTyping': isTyping, 'updatedAt': FieldValue.serverTimestamp()});
  }

  Stream<bool> streamTypingStatus(String senderId, String receiverId) {
    final chatId = _getChatId(senderId, receiverId);
    return _db
        .collection(_collection)
        .doc(chatId)
        .collection('typing')
        .doc(receiverId)
        .snapshots()
        .map((doc) => doc.data()?['isTyping'] ?? false);
  }

  // =========================
  // LEGACY/PROVIDER COMPAT HELPERS
  // =========================

  Stream<List<ChatMessage>> streamAllMessages() {
    return _db
        .collectionGroup('messages')
        .orderBy('sentAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ChatMessage.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Stream<List<ChatMessage>> streamMessagesBetween(
    String userId1,
    String userId2,
  ) {
    return getMessages(userId1, userId2);
  }

  // Case-based chat is handled by chat threads; keep this safe fallback.
  Stream<List<ChatMessage>> streamMessagesByCase(String caseId) {
    return Stream<List<ChatMessage>>.value(const <ChatMessage>[]);
  }

  Stream<List<ChatMessage>> streamUserMessages(String userId) {
    return streamAllMessages().map(
      (messages) => messages
          .where(
            (message) =>
                message.senderId == userId || message.receiverId == userId,
          )
          .toList(),
    );
  }

  Stream<int> streamUnreadCount(String userId) {
    return streamUserMessages(userId).map(
      (messages) => messages
          .where((message) => message.receiverId == userId && !message.isRead)
          .length,
    );
  }

  Future<ChatMessage?> getMessage(String messageId) async {
    final doc = await _findMessageDoc(messageId);
    if (doc == null) {
      return null;
    }
    return ChatMessage.fromMap(doc.data(), doc.id);
  }

  Future<String> sendMessageModel(ChatMessage message) {
    return sendMessage(
      senderId: message.senderId,
      receiverId: message.receiverId,
      message: message.message,
      messageType: message.messageType,
      fileUrl: message.fileUrl,
      replyTo: message.replyTo,
      caseId: message.caseId,
    );
  }

  Future<void> updateMessage(ChatMessage message) {
    return editMessage(
      message.senderId,
      message.receiverId,
      message.messageId,
      message.message,
    );
  }

  Future<void> deleteMessageById(String messageId) async {
    final doc = await _findMessageDoc(messageId);
    if (doc == null) {
      return;
    }

    await doc.reference.update({
      'isDeleted': true,
      'message': 'Message deleted',
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> markAsReadById(String messageId) async {
    final doc = await _findMessageDoc(messageId);
    if (doc == null) {
      return;
    }

    await doc.reference.update({'isRead': true, 'updatedAt': Timestamp.now()});
  }

  Future<void> markAsReadBatch(List<String> messageIds) async {
    for (final messageId in messageIds) {
      await markAsReadById(messageId);
    }
  }

  Future<QueryDocumentSnapshot<Map<String, dynamic>>?> _findMessageDoc(
    String messageId,
  ) async {
    final snapshot = await _db
        .collectionGroup('messages')
        .where('messageId', isEqualTo: messageId)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    return snapshot.docs.first;
  }
}
