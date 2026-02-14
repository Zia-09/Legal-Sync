import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../model/chat_thread_model.dart';
import '../services/chat_thread_service.dart';

// ===============================
// Chat Thread Service Provider
// ===============================
final chatThreadServiceProvider = Provider((ref) => ChatThreadService());

// ===============================
// All Chat Threads Provider
// ===============================
final allChatThreadsProvider = StreamProvider<List<ChatThreadModel>>((ref) {
  final service = ref.watch(chatThreadServiceProvider);
  return service.streamAllThreads();
});

// ===============================
// Chat Threads for Case Provider
// ===============================
final chatThreadsForCaseProvider =
    StreamProvider.family<List<ChatThreadModel>, String>((ref, caseId) {
      final service = ref.watch(chatThreadServiceProvider);
      return service.streamThreadsForCase(caseId);
    });

// ===============================
// Chat Threads for User Provider
// ===============================
final chatThreadsForUserProvider =
    StreamProvider.family<List<ChatThreadModel>, String>((ref, userId) {
      final service = ref.watch(chatThreadServiceProvider);
      return service.streamThreadsForUser(userId);
    });

// ===============================
// Chat Threads between Users Provider
// ===============================
final chatThreadsBetweenUsersProvider =
    StreamProvider.family<
      List<ChatThreadModel>,
      ({String userId1, String userId2})
    >((ref, params) {
      final service = ref.watch(chatThreadServiceProvider);
      return service.streamThreadsBetween(params.userId1, params.userId2);
    });

// ===============================
// Get Chat Thread by ID Provider
// ===============================
final getChatThreadByIdProvider =
    FutureProvider.family<ChatThreadModel?, String>((ref, threadId) async {
      final service = ref.watch(chatThreadServiceProvider);
      return service.getThread(threadId);
    });

// ===============================
// Unread Threads Count Provider
// ===============================
final unreadThreadsCountProvider = StreamProvider.family<int, String>((
  ref,
  userId,
) {
  final service = ref.watch(chatThreadServiceProvider);
  return service.streamUnreadThreadsCount(userId);
});

// ===============================
// Chat Thread Notifier
// ===============================
class ChatThreadNotifier extends StateNotifier<ChatThreadModel?> {
  final ChatThreadService _service;

  ChatThreadNotifier(this._service) : super(null);

  Future<String> createThread(ChatThreadModel thread) async {
    final id = await _service.createThread(thread);
    state = thread;
    return id;
  }

  Future<void> updateThread(ChatThreadModel thread) async {
    await _service.updateThread(thread);
    state = thread;
  }

  Future<void> deleteThread(String threadId) async {
    await _service.deleteThread(threadId);
    state = null;
  }

  Future<void> loadThread(String threadId) async {
    final thread = await _service.getThread(threadId);
    state = thread;
  }

  Future<void> addMessageToThread(String threadId, String messageId) async {
    await _service.addMessageToThread(threadId, messageId);
  }

  Future<void> markThreadAsRead(String threadId, String userId) async {
    await _service.markThreadAsRead(threadId, userId);
  }

  Future<void> archiveThread(String threadId) async {
    await _service.archiveThread(threadId);
  }

  Future<void> unarchiveThread(String threadId) async {
    await _service.unarchiveThread(threadId);
  }
}

// ===============================
// Chat Thread State Notifier Provider
// ===============================
final chatThreadStateNotifierProvider =
    StateNotifierProvider<ChatThreadNotifier, ChatThreadModel?>((ref) {
      final service = ref.watch(chatThreadServiceProvider);
      return ChatThreadNotifier(service);
    });

// ===============================
// Selected Chat Thread Provider
// ===============================
final selectedChatThreadProvider = StateProvider<ChatThreadModel?>(
  (ref) => null,
);
