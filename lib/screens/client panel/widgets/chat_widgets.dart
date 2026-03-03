import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:legal_sync/model/chat_Model.dart';
import 'package:legal_sync/model/lawyer_Model.dart';
import 'package:legal_sync/provider/chat_provider.dart';
import 'package:legal_sync/provider/lawyer_provider.dart';
import 'package:legal_sync/provider/case_provider.dart';
import 'package:legal_sync/screens/client panel/chat_detail_screen.dart';

// ─── Chat List Widget ─────────────────────────────────────────────────────────

class ChatList extends ConsumerWidget {
  final List<ChatMessage> chatMessages;
  final String currentUserId;
  final String searchQuery;
  final bool isGroup;

  const ChatList({
    super.key,
    required this.chatMessages,
    required this.currentUserId,
    this.searchQuery = '',
    this.isGroup = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (chatMessages.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, color: Color(0xFF2A2A2A), size: 52),
            SizedBox(height: 12),
            Text(
              'No messages here',
              style: TextStyle(color: Color(0xFF6B6B6B), fontSize: 14),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: chatMessages.length,
      itemBuilder: (_, i) {
        final msg = chatMessages[i];
        final otherId = msg.senderId == currentUserId
            ? msg.receiverId
            : msg.senderId;

        return ref
            .watch(getLawyerByIdProvider(otherId))
            .when(
              data: (lawyer) {
                if (lawyer == null) return const SizedBox.shrink();
                return ChatTile(
                  lawyer: lawyer,
                  lastMessage: msg,
                  currentUserId: currentUserId,
                  isGroup: isGroup,
                );
              },
              loading: () => const SizedBox(height: 80),
              error: (e, st) => const SizedBox.shrink(),
            );
      },
    );
  }
}

// ─── Chat Tile Widget ─────────────────────────────────────────────────────────

class ChatTile extends ConsumerWidget {
  final LawyerModel lawyer;
  final ChatMessage lastMessage;
  final String currentUserId;
  final bool isGroup;

  const ChatTile({
    super.key,
    required this.lawyer,
    required this.lastMessage,
    required this.currentUserId,
    this.isGroup = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typingAsync = ref.watch(
      typingStatusProvider((
        senderId: currentUserId,
        receiverId: lawyer.lawyerId,
      )),
    );
    final isTyping = typingAsync.value ?? false;

    final timeStr = DateFormat('hh:mm a').format(lastMessage.sentAt);
    final isUnread =
        !lastMessage.isRead && lastMessage.receiverId == currentUserId;

    Widget buildTileContent(String name) {
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF252525)),
        ),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: lawyer.profileImageUrl.isNotEmpty
                        ? Image.network(
                            lawyer.profileImageUrl,
                            fit: BoxFit.cover,
                          )
                        : Center(
                            child: Text(
                              lawyer.name[0],
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                  ),
                ),
                if (lawyer.isOnline)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 13,
                      height: 13,
                      decoration: BoxDecoration(
                        color: const Color(0xFF059669),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF1A1A1A),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    isTyping ? 'Typing...' : lastMessage.message,
                    style: TextStyle(
                      color: isTyping
                          ? const Color(0xFFFF6B00)
                          : (isUnread ? Colors.white : const Color(0xFF6B6B6B)),
                      fontSize: 12,
                      fontWeight: isUnread || isTyping
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Time
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  timeStr,
                  style: TextStyle(
                    color: isUnread
                        ? const Color(0xFFFF6B00)
                        : const Color(0xFF5A5A5A),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 5),
                if (isUnread)
                  Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF6B00),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text(
                        '!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              ChatDetailScreen(receiverId: lawyer.lawyerId, lawyer: lawyer),
        ),
      ),
      child: isGroup && lastMessage.caseId != null
          ? ref
                .watch(getCaseByIdProvider(lastMessage.caseId!))
                .when(
                  data: (caseModel) =>
                      buildTileContent(caseModel?.title ?? 'Case Chat'),
                  loading: () => buildTileContent('Loading Group...'),
                  error: (_, __) => buildTileContent('Case Chat'),
                )
          : buildTileContent(lawyer.name),
    );
  }
}
