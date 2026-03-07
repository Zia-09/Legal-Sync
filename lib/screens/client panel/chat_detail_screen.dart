import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:legal_sync/model/chat_Model.dart';
import 'package:legal_sync/model/lawyer_Model.dart';
import 'package:legal_sync/provider/client_provider.dart';
import 'package:legal_sync/provider/chat_provider.dart';
import 'package:legal_sync/provider/chat_thread_provider.dart';
import 'package:legal_sync/services/supabase_service.dart';

class ChatDetailScreen extends ConsumerStatefulWidget {
  final String receiverId;
  final LawyerModel lawyer;
  const ChatDetailScreen({
    super.key,
    required this.receiverId,
    required this.lawyer,
  });

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final TextEditingController _ctrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _pickAndSendFile(String clientId) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx'],
      );

      if (result == null || result.files.isEmpty) return;

      final file = File(result.files.first.path!);
      final fileName = result.files.first.name;
      final isImage = [
        'jpg',
        'jpeg',
        'png',
      ].contains(result.files.first.extension?.toLowerCase());

      // Upload to Supabase
      final fileUrl = await supabaseService.uploadFile(
        file: file,
        path: 'chat_attachments/${widget.receiverId}',
      );

      final newMessage = ChatMessage(
        messageId: '', // Service will generate
        senderId: clientId,
        receiverId: widget.receiverId,
        message: isImage ? 'Shared an image' : 'Shared a file: $fileName',
        messageType: isImage ? 'image' : 'file',
        fileUrl: fileUrl,
        sentAt: DateTime.now(),
      );

      await ref
          .read(chatStateNotifierProvider.notifier)
          .sendMessage(newMessage);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send attachment: $e')),
        );
      }
    }
  }

  Future<void> _deleteConversation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Delete Conversation',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to delete this conversation? This action cannot be undone.',
          style: TextStyle(color: Color(0xFFCCCCCC)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final client = ref.read(currentClientProvider).value;
      if (client != null) {
        final chatId = [client.clientId, widget.receiverId]..sort();
        final threadId = chatId.join('_');
        await ref
            .read(chatStateNotifierProvider.notifier)
            .deleteConversation(threadId);
        if (mounted) {
          Navigator.pop(context);
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureThreadExists();
      _markAsRead();
    });
  }

  Future<void> _markAsRead() async {
    final client = ref.read(currentClientProvider).value;
    if (client != null) {
      await ref
          .read(chatStateNotifierProvider.notifier)
          .markConversationAsRead(
            userId: client.clientId,
            partnerId: widget.receiverId,
          );
    }
  }

  Future<void> _ensureThreadExists() async {
    final client = ref.read(currentClientProvider).value;
    if (client != null) {
      await ref
          .read(chatThreadServiceProvider)
          .createThread(lawyerId: widget.receiverId, clientId: client.clientId);
    }
  }

  @override
  void dispose() {
    final clientAsync = ref.read(currentClientProvider);
    clientAsync.whenData((client) {
      if (client != null) {
        ref
            .read(chatStateNotifierProvider.notifier)
            .setTypingStatus(
              senderId: client.clientId,
              receiverId: widget.receiverId,
              isTyping: false,
            );
      }
    });
    _ctrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clientAsync = ref.watch(currentClientProvider);

    return clientAsync.when(
      data: (client) {
        if (client == null) return const Scaffold();

        final isDark = Theme.of(context).brightness == Brightness.dark;
        final scaffoldBg = isDark
            ? const Color(0xFF121212)
            : const Color(0xFFF7F9FC);
        final cardColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
        final appBarColor = isDark ? const Color(0xFF141414) : Colors.white;
        final textColor = isDark ? Colors.white : Colors.black87;
        final subtitleColor = isDark
            ? const Color(0xFF6B6B6B)
            : Colors.grey.shade600;
        final inputBg = isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade100;
        final msgMineColor = const Color(0xFFFF6B00);
        final msgTheirsColor = isDark
            ? const Color(0xFF1E1E1E)
            : Colors.grey.shade200;
        final msgTextColorMine = Colors.white;
        final msgTextColorTheirs = isDark
            ? const Color(0xFFDDDDDD)
            : Colors.black87;

        return ref
            .watch(
              messagesBetweenUsersProvider((
                userId1: client.clientId,
                userId2: widget.receiverId,
              )),
            )
            .when(
              data: (messages) {
                WidgetsBinding.instance.addPostFrameCallback(
                  (_) => _scrollToBottom(),
                );
                return Scaffold(
                  backgroundColor: scaffoldBg,
                  appBar: AppBar(
                    backgroundColor: appBarColor,
                    elevation: 1,
                    shadowColor: isDark ? Colors.black54 : Colors.black12,
                    leadingWidth: 40,
                    leading: IconButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.arrow_back_ios_new,
                        color: textColor,
                        size: 18,
                      ),
                    ),
                    title: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: inputBg,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: widget.lawyer.profileImageUrl.isNotEmpty
                                ? Image.network(
                                    widget.lawyer.profileImageUrl,
                                    fit: BoxFit.cover,
                                  )
                                : Center(
                                    child: Text(
                                      widget.lawyer.name[0],
                                      style: TextStyle(
                                        color: textColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.lawyer.name,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              ref
                                  .watch(
                                    typingStatusProvider((
                                      senderId: widget
                                          .receiverId, // Watch the other user's typing status
                                      receiverId: client.clientId,
                                    )),
                                  )
                                  .when(
                                    data: (isTyping) => isTyping
                                        ? const Text(
                                            'typing...',
                                            style: TextStyle(
                                              color: Color(0xFFFF6B00),
                                              fontSize: 10,
                                            ),
                                          )
                                        : Text(
                                            widget.lawyer.isOnline
                                                ? 'Online'
                                                : 'Offline',
                                            style: TextStyle(
                                              color: widget.lawyer.isOnline
                                                  ? const Color(0xFF059669)
                                                  : subtitleColor,
                                              fontSize: 11,
                                            ),
                                          ),
                                    loading: () => Text(
                                      widget.lawyer.isOnline
                                          ? 'Online'
                                          : 'Offline',
                                      style: TextStyle(
                                        color: widget.lawyer.isOnline
                                            ? const Color(0xFF059669)
                                            : subtitleColor,
                                        fontSize: 11,
                                      ),
                                    ),
                                    error: (_, __) => Text(
                                      widget.lawyer.isOnline
                                          ? 'Online'
                                          : 'Offline',
                                      style: TextStyle(
                                        color: widget.lawyer.isOnline
                                            ? const Color(0xFF059669)
                                            : subtitleColor,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      IconButton(
                        onPressed: () {},
                        icon: Icon(Icons.call_outlined, color: textColor),
                      ),
                      PopupMenuButton<String>(
                        color: cardColor,
                        icon: Icon(Icons.more_vert, color: textColor),
                        onSelected: (value) {
                          if (value == 'delete') {
                            _deleteConversation();
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Delete Chat',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  body: Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          physics: const BouncingScrollPhysics(),
                          itemCount: messages.length,
                          itemBuilder: (_, i) {
                            final msg = messages[i];
                            final isMine = msg.senderId == client.clientId;

                            // 🔹 Mark message as read if it's new and for me
                            if (!isMine && !msg.isRead) {
                              _markAsRead();
                            }

                            return Align(
                              alignment: isMine
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.72,
                                ),
                                decoration: BoxDecoration(
                                  color: isMine ? msgMineColor : msgTheirsColor,
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(16),
                                    topRight: const Radius.circular(16),
                                    bottomLeft: Radius.circular(
                                      isMine ? 16 : 4,
                                    ),
                                    bottomRight: Radius.circular(
                                      isMine ? 4 : 16,
                                    ),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: isMine
                                      ? CrossAxisAlignment.end
                                      : CrossAxisAlignment.start,
                                  children: [
                                    if (msg.messageType == 'image' &&
                                        msg.fileUrl != null)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 8.0,
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: Image.network(
                                            msg.fileUrl!,
                                            fit: BoxFit.cover,
                                            loadingBuilder:
                                                (
                                                  context,
                                                  child,
                                                  loadingProgress,
                                                ) {
                                                  if (loadingProgress == null) {
                                                    return child;
                                                  }
                                                  return Container(
                                                    height: 150,
                                                    width: 200,
                                                    color: Colors.grey[800],
                                                    child: const Center(
                                                      child:
                                                          CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                            color: Color(
                                                              0xFFFF6B00,
                                                            ),
                                                          ),
                                                    ),
                                                  );
                                                },
                                          ),
                                        ),
                                      ),
                                    if (msg.messageType == 'file' &&
                                        msg.fileUrl != null)
                                      Container(
                                        margin: const EdgeInsets.only(
                                          bottom: 8,
                                        ),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: isMine
                                              ? Colors.white.withOpacity(0.1)
                                              : (isDark
                                                    ? Colors.grey[850]
                                                    : Colors.white),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.insert_drive_file,
                                              color: isMine
                                                  ? Colors.white
                                                  : const Color(0xFFFF6B00),
                                              size: 30,
                                            ),
                                            const SizedBox(width: 10),
                                            Flexible(
                                              child: Text(
                                                msg.message.replaceFirst(
                                                  'Shared a file: ',
                                                  '',
                                                ),
                                                style: TextStyle(
                                                  color: isMine
                                                      ? msgTextColorMine
                                                      : msgTextColorTheirs,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    if (msg.message.isNotEmpty &&
                                        msg.messageType == 'text')
                                      Text(
                                        msg.message,
                                        style: TextStyle(
                                          color: isMine
                                              ? msgTextColorMine
                                              : msgTextColorTheirs,
                                          fontSize: 13,
                                          height: 1.4,
                                        ),
                                      ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          DateFormat(
                                            'hh:mm a',
                                          ).format(msg.sentAt),
                                          style: TextStyle(
                                            color: isMine
                                                ? msgTextColorMine.withOpacity(
                                                    0.6,
                                                  )
                                                : subtitleColor,
                                            fontSize: 10,
                                          ),
                                        ),
                                        if (isMine) ...[
                                          const SizedBox(width: 4),
                                          Icon(
                                            msg.isRead
                                                ? Icons.done_all
                                                : Icons.done,
                                            size: 14,
                                            color: msg.isRead
                                                ? Colors.lightBlueAccent
                                                : Colors.white60,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      // Input bar
                      Container(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
                        decoration: BoxDecoration(
                          color: appBarColor,
                          border: Border(
                            top: BorderSide(
                              color: isDark
                                  ? const Color(0xFF1E1E1E)
                                  : Colors.grey.shade200,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () =>
                                  _pickAndSendFile(client.clientId),
                              icon: Icon(
                                Icons.attach_file,
                                color: subtitleColor,
                              ),
                            ),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: inputBg,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: isDark
                                        ? const Color(0xFF2A2A2A)
                                        : Colors.transparent,
                                  ),
                                ),
                                child: TextField(
                                  controller: _ctrl,
                                  onChanged: (val) {
                                    ref
                                        .read(
                                          chatStateNotifierProvider.notifier,
                                        )
                                        .setTypingStatus(
                                          senderId: client.clientId,
                                          receiverId: widget.receiverId,
                                          isTyping: val.isNotEmpty,
                                        );
                                  },
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 13,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Type a message...',
                                    hintStyle: TextStyle(color: subtitleColor),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () async {
                                if (_ctrl.text.trim().isNotEmpty) {
                                  final text = _ctrl.text.trim();
                                  _ctrl.clear();
                                  // 🔹 Clear typing status when message is sent
                                  ref
                                      .read(chatStateNotifierProvider.notifier)
                                      .setTypingStatus(
                                        senderId: client.clientId,
                                        receiverId: widget.receiverId,
                                        isTyping: false,
                                      );
                                  // Ensure thread exists before sending
                                  await _ensureThreadExists();

                                  final newMessage = ChatMessage(
                                    messageId: '',
                                    senderId: client.clientId,
                                    receiverId: widget.receiverId,
                                    message: text,
                                    sentAt: DateTime.now(),
                                  );

                                  await ref
                                      .read(chatStateNotifierProvider.notifier)
                                      .sendMessage(newMessage);
                                }
                              },
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFF6B00),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.send_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
              loading: () => Scaffold(
                backgroundColor: scaffoldBg,
                body: const Center(
                  child: CircularProgressIndicator(color: Color(0xFFFF6B00)),
                ),
              ),
              error: (e, st) => Scaffold(
                backgroundColor: scaffoldBg,
                body: Center(
                  child: Text('Error: $e', style: TextStyle(color: textColor)),
                ),
              ),
            );
      },
      loading: () => Scaffold(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF121212)
            : const Color(0xFFF7F9FC),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFFFF6B00)),
        ),
      ),
      error: (e, st) => Scaffold(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF121212)
            : const Color(0xFFF7F9FC),
        body: Center(
          child: Text(
            'Auth Error: $e',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}
