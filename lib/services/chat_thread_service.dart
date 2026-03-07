import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/chat_thread_model.dart';
import '../model/chat_Model.dart';

class ChatThreadService {
  final FirebaseFirestore _db;

  ChatThreadService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  static const String _collection = 'chats';

  String getThreadId(String userId1, String userId2) {
    return (userId1.hashCode <= userId2.hashCode)
        ? '${userId1}_$userId2'
        : '${userId2}_$userId1';
  }

  // ===============================
  // CREATE NEW CHAT THREAD
  // ===============================
  Future<String> createThread({
    required String lawyerId,
    required String clientId,
    String? caseId,
  }) async {
    final threadId = getThreadId(lawyerId, clientId);
    final docRef = _db.collection(_collection).doc(threadId);
    final now = DateTime.now();

    final threadDoc = await docRef.get();
    if (!threadDoc.exists) {
      final thread = ChatThread(
        threadId: threadId,
        lawyerId: lawyerId,
        clientId: clientId,
        caseId: caseId,
        createdAt: now,
        updatedAt: now,
      );
      await docRef.set({...thread.toJson(), 'threadId': threadId});
    }
    return threadId;
  }

  // ===============================
  // STREAM THREADS FOR LAWYER
  // ===============================
  Stream<List<ChatThread>> streamThreadsForLawyer(String lawyerId) {
    return _db
        .collection(_collection)
        .where('lawyerId', isEqualTo: lawyerId)
        .snapshots()
        .map((snapshot) {
          final docs = snapshot.docs
              .map((doc) => ChatThread.fromMap(doc.data(), doc.id))
              .toList();
          docs.sort(
            (a, b) => b.updatedAt.compareTo(a.updatedAt),
          ); // Newest first
          return docs;
        });
  }

  // ===============================
  // STREAM THREADS FOR CLIENT
  // ===============================
  Stream<List<ChatThread>> streamThreadsForClient(String clientId) {
    return _db
        .collection(_collection)
        .where('clientId', isEqualTo: clientId)
        .snapshots()
        .map((snapshot) {
          final docs = snapshot.docs
              .map((doc) => ChatThread.fromMap(doc.data(), doc.id))
              .toList();
          docs.sort(
            (a, b) => b.updatedAt.compareTo(a.updatedAt),
          ); // Newest first
          return docs;
        });
  }

  // ===============================
  // WATCH SINGLE THREAD
  // ===============================
  Stream<ChatThread> watchThread(String threadId) {
    return _db.collection(_collection).doc(threadId).snapshots().map((doc) {
      final data = doc.data();
      if (data == null) throw Exception('ChatThread not found');
      return ChatThread.fromMap(data, doc.id);
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
        .snapshots()
        .map((snapshot) {
          final msgs = snapshot.docs
              .map((doc) => ChatMessage.fromMap(doc.data(), doc.id))
              .toList();
          msgs.sort((a, b) => a.sentAt.compareTo(b.sentAt)); // Oldest first
          return msgs;
        });
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

  // ===============================
  // LEGACY/PROVIDER COMPAT HELPERS
  // ===============================

  Stream<List<ChatThread>> streamAllThreads() {
    return _db.collection(_collection).snapshots().map((snapshot) {
      final docs = snapshot.docs
          .map((doc) => ChatThread.fromMap(doc.data(), doc.id))
          .toList();
      docs.sort((a, b) => b.updatedAt.compareTo(a.updatedAt)); // Newest first
      return docs;
    });
  }

  Stream<List<ChatThread>> streamThreadsForCase(String caseId) {
    return _db
        .collection(_collection)
        .where('caseId', isEqualTo: caseId)
        .snapshots()
        .map((snapshot) {
          final docs = snapshot.docs
              .map((doc) => ChatThread.fromMap(doc.data(), doc.id))
              .toList();
          docs.sort(
            (a, b) => b.updatedAt.compareTo(a.updatedAt),
          ); // Newest first
          return docs;
        });
  }

  Stream<List<ChatThread>> streamThreadsForUser(String userId) {
    return streamAllThreads().map(
      (threads) => threads
          .where(
            (thread) => thread.lawyerId == userId || thread.clientId == userId,
          )
          .toList(),
    );
  }

  Stream<List<ChatThread>> streamThreadsBetween(
    String userId1,
    String userId2,
  ) {
    return streamAllThreads().map(
      (threads) => threads
          .where(
            (thread) =>
                (thread.lawyerId == userId1 && thread.clientId == userId2) ||
                (thread.lawyerId == userId2 && thread.clientId == userId1),
          )
          .toList(),
    );
  }

  Future<ChatThread?> getThread(String threadId) async {
    final doc = await _db.collection(_collection).doc(threadId).get();
    final data = doc.data();
    if (!doc.exists || data == null) {
      return null;
    }
    return ChatThread.fromMap(data, doc.id);
  }

  Stream<int> streamUnreadThreadsCount(String userId) {
    return streamThreadsForUser(userId).map((threads) {
      return threads.fold<int>(0, (totalUnread, thread) {
        if (thread.lawyerId == userId) {
          return totalUnread + thread.unreadByLawyer;
        }
        return totalUnread + thread.unreadByClient;
      });
    });
  }

  Future<void> updateThread(ChatThread thread) async {
    await _db.collection(_collection).doc(thread.threadId).update({
      ...thread.toJson(),
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> addMessageToThread(String threadId, String messageId) async {
    await _db.collection(_collection).doc(threadId).update({
      'lastMessageId': messageId,
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> markThreadAsReadForUser({
    required String threadId,
    required String userId,
  }) async {
    final thread = await getThread(threadId);
    if (thread == null) {
      return;
    }

    await markThreadAsRead(
      threadId: threadId,
      isLawyer: thread.lawyerId == userId,
    );
  }

  Future<void> archiveThread(String threadId) async {
    await _db.collection(_collection).doc(threadId).update({
      'isArchived': true,
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> unarchiveThread(String threadId) async {
    await _db.collection(_collection).doc(threadId).update({
      'isArchived': false,
      'updatedAt': Timestamp.now(),
    });
  }
}
