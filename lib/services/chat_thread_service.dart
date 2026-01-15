import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/chat_thread_model.dart';
import '../model/chat_Model.dart';

class ChatThreadService {
  final FirebaseFirestore _db;

  ChatThreadService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  static const String _collection = 'chats';

  // ===============================
  // CREATE NEW CHAT THREAD
  // ===============================
  Future<String> createThread({
    required String lawyerId,
    required String clientId,
    String? caseId,
  }) async {
    final docRef = _db.collection(_collection).doc();
    final now = DateTime.now();

    final thread = ChatThread(
      threadId: docRef.id,
      lawyerId: lawyerId,
      clientId: clientId,
      caseId: caseId,
      createdAt: now,
      updatedAt: now,
    );

    await docRef.set(thread.toJson());
    return docRef.id;
  }

  // ===============================
  // STREAM THREADS FOR LAWYER
  // ===============================
  Stream<List<ChatThread>> streamThreadsForLawyer(String lawyerId) {
    return _db
        .collection(_collection)
        .where('lawyerId', isEqualTo: lawyerId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ChatThread.fromJson(doc.data()))
              .toList(),
        );
  }

  // ===============================
  // STREAM THREADS FOR CLIENT
  // ===============================
  Stream<List<ChatThread>> streamThreadsForClient(String clientId) {
    return _db
        .collection(_collection)
        .where('clientId', isEqualTo: clientId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ChatThread.fromJson(doc.data()))
              .toList(),
        );
  }

  // ===============================
  // WATCH SINGLE THREAD
  // ===============================
  Stream<ChatThread> watchThread(String threadId) {
    return _db.collection(_collection).doc(threadId).snapshots().map((doc) {
      final data = doc.data();
      if (data == null) throw Exception('ChatThread not found');
      return ChatThread.fromJson(data);
    });
  }

  // ===============================
  // SEND MESSAGE INSIDE THREAD
  // ===============================
  Future<void> sendMessage({
    required String threadId,
    required ChatMessage message,
  }) async {
    final threadRef = _db.collection(_collection).doc(threadId);
    final messagesRef = threadRef.collection('messages');

    // Save message
    await messagesRef.doc(message.messageId).set(message.toMap());

    // Increment unread counters properly
    final threadDoc = await threadRef.get();
    final threadData = threadDoc.data();

    if (threadData != null) {
      int unreadByLawyer = threadData['unreadByLawyer'] ?? 0;
      int unreadByClient = threadData['unreadByClient'] ?? 0;

      if (message.senderId != threadData['lawyerId']) {
        unreadByLawyer++;
      }
      if (message.senderId != threadData['clientId']) {
        unreadByClient++;
      }

      // Update thread metadata
      await threadRef.update({
        'lastMessage': message.message,
        'lastMessageSenderId': message.senderId,
        'lastMessageAt': Timestamp.fromDate(message.sentAt),
        'updatedAt': Timestamp.now(),
        'unreadByLawyer': unreadByLawyer,
        'unreadByClient': unreadByClient,
      });
    }
  }

  // ===============================
  // STREAM MESSAGES OF THREAD
  // ===============================
  Stream<List<ChatMessage>> streamMessages(String threadId) {
    return _db
        .collection(_collection)
        .doc(threadId)
        .collection('messages')
        .orderBy('sentAt', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ChatMessage.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // ===============================
  // MARK THREAD AS READ
  // ===============================
  Future<void> markThreadAsRead({
    required String threadId,
    required bool isLawyer,
  }) async {
    final threadRef = _db.collection(_collection).doc(threadId);
    if (isLawyer) {
      await threadRef.update({'unreadByLawyer': 0});
    } else {
      await threadRef.update({'unreadByClient': 0});
    }
  }

  // ===============================
  // DELETE THREAD (AND MESSAGES)
  // ===============================
  Future<void> deleteThread(String threadId) async {
    final threadRef = _db.collection(_collection).doc(threadId);
    final messagesSnap = await threadRef.collection('messages').get();

    for (final doc in messagesSnap.docs) {
      await doc.reference.delete();
    }

    await threadRef.delete();
  }
}
