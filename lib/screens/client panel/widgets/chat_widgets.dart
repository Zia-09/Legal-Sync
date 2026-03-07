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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtitleColor = isDark
        ? const Color(0xFF9E9E9E)
        : Colors.grey.shade600;

    if (threads.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade300,
              size: 52,
            ),
            const SizedBox(height: 12),
            Text(
              'No conversations here',
              style: TextStyle(color: subtitleColor, fontSize: 14),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark
        ? const Color(0xFF9E9E9E)
        : Colors.grey.shade600;

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
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? const Color(0xFF252525) : Colors.grey.shade200,
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
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
                    color: isDark
                        ? const Color(0xFF1E1E1E)
                        : Colors.grey.shade100,
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
                              style: TextStyle(
                                color: textColor,
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
                        border: Border.all(color: cardColor, width: 2),
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
                    style: TextStyle(
                      color: textColor,
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
                          : (isUnread ? textColor : subtitleColor),
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
                    color: isUnread ? const Color(0xFFFF6B00) : subtitleColor,
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

    return Dismissible(
      key: Key(thread.threadId),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
            title: Text(
              'Delete Conversation',
              style: TextStyle(color: textColor),
            ),
            content: Text(
              'Are you sure you want to delete this conversation? This action cannot be undone.',
              style: TextStyle(color: subtitleColor),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        ref
            .read(chatStateNotifierProvider.notifier)
            .deleteConversation(thread.threadId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Conversation deleted'),
            backgroundColor: Colors.redAccent,
          ),
        );
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.redAccent.withOpacity(0.8),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: GestureDetector(
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
                    error: (_, _) => buildTileContent('Case Chat'),
                  )
            : buildTileContent(lawyer.name),
      ),
    );
  }
}
