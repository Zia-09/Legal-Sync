import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:legal_sync/model/chat_Model.dart';
import 'package:legal_sync/model/chat_thread_model.dart';
import 'package:legal_sync/model/lawyer_Model.dart';
import 'package:legal_sync/provider/chat_provider.dart';
import 'package:legal_sync/provider/chat_thread_provider.dart';
import 'package:legal_sync/provider/lawyer_provider.dart';
import 'package:legal_sync/provider/case_provider.dart';
import 'package:legal_sync/screens/client panel/chat_detail_screen.dart';

// ─── Chat List Widget ─────────────────────────────────────────────────────────

class ChatList extends ConsumerWidget {
  final List<ChatThreadModel> threads;
  final String currentUserId;
  final bool isGroup;

  const ChatList({
    super.key,
    required this.threads,
    required this.currentUserId,
    this.isGroup = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (threads.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, color: Color(0xFF2A2A2A), size: 52),
            SizedBox(height: 12),
            Text(
              'No conversations here',
              style: TextStyle(color: Color(0xFF6B6B6B), fontSize: 14),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: threads.length,
      itemBuilder: (_, i) {
        final thread = threads[i];

        return ref
            .watch(getLawyerByIdProvider(thread.lawyerId))
            .when(
              data: (lawyer) {
                if (lawyer == null) return const SizedBox.shrink();
                return ChatTile(
                  lawyer: lawyer,
                  thread: thread,
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
  final ChatThreadModel thread;
  final String currentUserId;
  final bool isGroup;

  const ChatTile({
    super.key,
    required this.lawyer,
    required this.thread,
    required this.currentUserId,
    this.isGroup = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typingAsync = ref.watch(
      typingStatusProvider((
        senderId: lawyer.lawyerId, // Check if lawyer is typing
        receiverId: currentUserId,
      )),
    );
    final isTyping = typingAsync.value ?? false;

    final lastMsgDate = thread.lastMessageAt ?? thread.updatedAt;
    final timeStr = DateFormat('hh:mm a').format(lastMsgDate);

    final unreadCount = currentUserId == thread.clientId
        ? thread.unreadByClient
        : thread.unreadByLawyer;
    final isUnread = unreadCount > 0;

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
                    isTyping
                        ? 'Typing...'
                        : (thread.lastMessage ?? 'No messages yet'),
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
                    child: Center(
                      child: Text(
                        '$unreadCount',
                        style: const TextStyle(
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
      child: isGroup && thread.caseId != null
          ? ref
                .watch(getCaseByIdProvider(thread.caseId!))
                .when(
                  data: (caseModel) =>
                      buildTileContent(caseModel?.caseType ?? 'Case Chat'),
                  loading: () => buildTileContent('Loading Group...'),
                  error: (_, __) => buildTileContent('Case Chat'),
                )
          : buildTileContent(lawyer.name),
    );
  }
}
