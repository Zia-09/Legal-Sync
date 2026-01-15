import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/chat_Model.dart';
import '../services/chat_service.dart';

// ===============================
// Chat Service Provider
// ===============================
final chatServiceProvider = Provider((ref) => ChatService());

// ===============================
// All Messages Provider
// ===============================
final allMessagesProvider = StreamProvider<List<ChatModel>>((ref) {
  final service = ref.watch(chatServiceProvider);
  return service.streamAllMessages();
});

// ===============================
// Messages between Users Provider
// ===============================
final messagesBetweenUsersProvider =
    StreamProvider.family<List<ChatModel>, ({String userId1, String userId2})>((
      ref,
      params,
    ) {
      final service = ref.watch(chatServiceProvider);
      return service.streamMessagesBetween(params.userId1, params.userId2);
    });

// ===============================
// Case Messages Provider
// ===============================
final caseMessagesProvider = StreamProvider.family<List<ChatModel>, String>((
  ref,
  caseId,
) {
  final service = ref.watch(chatServiceProvider);
  return service.streamMessagesByCase(caseId);
});

// ===============================
// User Messages Provider
// ===============================
final userMessagesProvider = StreamProvider.family<List<ChatModel>, String>((
  ref,
  userId,
) {
  final service = ref.watch(chatServiceProvider);
  return service.streamUserMessages(userId);
});

// ===============================
// Unread Messages Count Provider
// ===============================
final unreadMessagesCountProvider = StreamProvider.family<int, String>((
  ref,
  userId,
) {
  final service = ref.watch(chatServiceProvider);
  return service.streamUnreadCount(userId);
});

// ===============================
// Get Message by ID Provider
// ===============================
final getMessageByIdProvider = FutureProvider.family<ChatModel?, String>((
  ref,
  messageId,
) async {
  final service = ref.watch(chatServiceProvider);
  return service.getMessage(messageId);
});

// ===============================
// Chat Notifier
// ===============================
class ChatNotifier extends StateNotifier<ChatModel?> {
  final ChatService _service;

  ChatNotifier(this._service) : super(null);

  Future<String> sendMessage(ChatModel message) async {
    final id = await _service.sendMessage(message);
    state = message;
    return id;
  }

  Future<void> updateMessage(ChatModel message) async {
    await _service.updateMessage(message);
    state = message;
  }

  Future<void> deleteMessage(String messageId) async {
    await _service.deleteMessage(messageId);
    state = null;
  }

  Future<void> markAsRead(String messageId) async {
    await _service.markAsRead(messageId);
  }

  Future<void> markAsReadBatch(List<String> messageIds) async {
    await _service.markAsReadBatch(messageIds);
  }

  Future<void> loadMessage(String messageId) async {
    final message = await _service.getMessage(messageId);
    state = message;
  }
}

// ===============================
// Chat State Notifier Provider
// ===============================
final chatStateNotifierProvider =
    StateNotifierProvider<ChatNotifier, ChatModel?>((ref) {
      final service = ref.watch(chatServiceProvider);
      return ChatNotifier(service);
    });

// ===============================
// Selected Message Provider
// ===============================
final selectedMessageProvider = StateProvider<ChatModel?>((ref) => null);
