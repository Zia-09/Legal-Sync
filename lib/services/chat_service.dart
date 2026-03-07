import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/chat_Model.dart';
import '../services/notification_services.dart';

class ChatService {
  ChatService({
    FirebaseFirestore? firestore,
    NotificationService? notificationService,
  }) : _db = firestore ?? FirebaseFirestore.instance,
       _notificationService = notificationService ?? NotificationService();

  final FirebaseFirestore _db;
  final NotificationService _notificationService;

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
    final threadRef = _db.collection(_collection).doc(chatId);
    final msgDocRef = _messagesRef(chatId).doc();

    final newMessage = ChatMessage(
      messageId: msgDocRef.id,
      senderId: senderId,
      receiverId: receiverId,
      message: message,
      messageType: messageType,
      fileUrl: fileUrl,
      replyTo: replyTo,
      caseId: caseId,
      sentAt: DateTime.now(),
    );

    // Run as a batch or transaction to ensure consistency
    final batch = _db.batch();

    // 1. Save the message
    batch.set(msgDocRef, newMessage.toMap());

    // 2. Update/Create the thread metadata
    final threadDoc = await threadRef.get();
    if (!threadDoc.exists) {
      // Create new thread doc
      batch.set(threadRef, {
        'threadId': chatId,
        'lawyerId': senderId.contains('lawyer') ? senderId : receiverId,
        'clientId': senderId.contains('lawyer') ? receiverId : senderId,
        'caseId': caseId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastMessage': message,
        'lastMessageSenderId': senderId,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'unreadByLawyer': senderId.contains('lawyer') ? 0 : 1,
        'unreadByClient': senderId.contains('lawyer') ? 1 : 0,
        'isArchived': false,
        'isBlocked': false,
      });
    } else {
      // Update existing thread doc
      final data = threadDoc.data()!;
      int unreadByLawyer = data['unreadByLawyer'] ?? 0;
      int unreadByClient = data['unreadByClient'] ?? 0;

      // Increment unread count for the receiver
      if (senderId == (data['clientId'] ?? '') ||
          (data['clientId'] == null && !senderId.contains('lawyer'))) {
        unreadByLawyer++;
      } else {
        unreadByClient++;
      }

      batch.update(threadRef, {
        'lastMessage': message,
        'lastMessageSenderId': senderId,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'unreadByLawyer': unreadByLawyer,
        'unreadByClient': unreadByClient,
      });
    }

    await batch.commit();

    // 3. Send a notification to the receiver
    await _notificationService.createNotification(
      userId: receiverId,
      title: 'New Message',
      message: messageType == 'text' ? message : 'Sent you a $messageType',
      type: 'chat',
      metadata: {'senderId': senderId, 'chatId': chatId},
    );

    return msgDocRef.id;
  }

  /// =========================
  /// REAL-TIME MESSAGE STREAM
  /// =========================
  Stream<List<ChatMessage>> getMessages(String userId1, String userId2) {
    final chatId = _getChatId(userId1, userId2);

    return _messagesRef(chatId).snapshots().map((snapshot) {
      final msgs = snapshot.docs
          .map((doc) => ChatMessage.fromMap(doc.data(), doc.id))
          .toList();
      msgs.sort((a, b) => a.sentAt.compareTo(b.sentAt)); // Oldest first
      return msgs;
    });
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
  /// MARK CONVERSATION AS READ
  /// =========================
  Future<void> markConversationAsRead({
    required String userId,
    required String partnerId,
  }) async {
    final chatId = _getChatId(userId, partnerId);
    final threadRef = _db.collection(_collection).doc(chatId);

    // 1. Get all unread messages for this user
    final unreadMsgs = await _messagesRef(chatId)
        .where('receiverId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    if (unreadMsgs.docs.isEmpty) {
      // Still reset thread count just in case of desync
      await threadRef.update({
        userId.contains('lawyer') ? 'unreadByLawyer' : 'unreadByClient': 0,
      });
      return;
    }

    // 2. Mark them as read in a batch
    final batch = _db.batch();
    for (final doc in unreadMsgs.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    // 3. Reset thread unread count
    batch.update(threadRef, {
      userId.contains('lawyer') ? 'unreadByLawyer' : 'unreadByClient': 0,
    });

    await batch.commit();

    // 4. Clear related notifications
    await _notificationService.clearChatNotifications(
      userId: userId,
      partnerId: partnerId,
    );
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
    return _db.collectionGroup('messages').snapshots().map((snapshot) {
      final docs = snapshot.docs
          .map((doc) => ChatMessage.fromMap(doc.data(), doc.id))
          .toList();
      docs.sort((a, b) => b.sentAt.compareTo(a.sentAt)); // Newest first
      return docs;
    });
  }

  Stream<List<ChatMessage>> streamMessagesBetween(
    String userId1,
    String userId2,
  ) {
    return getMessages(userId1, userId2);
  }

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

  /// =========================
  /// DELETE CONVERSATION
  /// =========================
  Future<void> deleteConversation(String chatId) async {
    try {
      // 1. Get all messages in the thread
      final messagesSnapshot = await _messagesRef(chatId).get();

      // 2. Delete all messages and the thread doc in a batch
      final batch = _db.batch();

      for (var doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Delete thread metadata
      batch.delete(_db.collection(_collection).doc(chatId));

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete conversation: $e');
    }
  }
}
