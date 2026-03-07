import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:legal_sync/model/chat_Model.dart';
import 'package:legal_sync/provider/auth_provider.dart';
import 'package:legal_sync/provider/chat_provider.dart';
import 'package:legal_sync/provider/chat_thread_provider.dart';
import 'package:legal_sync/provider/client_provider.dart';
import 'package:legal_sync/services/supabase_service.dart';
import 'package:intl/intl.dart';

class LawyerChatScreen extends ConsumerStatefulWidget {
  final String receiverId;
  // Keep these as fallback or initial values
  final String clientName;
  final String avatarUrl;

  const LawyerChatScreen({
    super.key,
    required this.clientName,
    required this.avatarUrl,
    required this.receiverId,
  });

  @override
  ConsumerState<LawyerChatScreen> createState() => _LawyerChatScreenState();
}

class _LawyerChatScreenState extends ConsumerState<LawyerChatScreen> {
  final TextEditingController _ctrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureThreadExists();
      _markAsRead();
    });
  }

  Future<void> _markAsRead() async {
    final user = ref.read(authStateProvider).value;
    if (user != null) {
      await ref
          .read(chatStateNotifierProvider.notifier)
          .markConversationAsRead(
            userId: user.uid,
            partnerId: widget.receiverId,
          );
    }
  }

  @override
  void dispose() {
    final user = ref.read(authStateProvider).value;
    if (user != null) {
      ref
          .read(chatStateNotifierProvider.notifier)
          .setTypingStatus(
            senderId: user.uid,
            receiverId: widget.receiverId,
            isTyping: false,
          );
    }
    _ctrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _ensureThreadExists() async {
    final user = ref.read(authStateProvider).value;
    if (user != null) {
      await ref
          .read(chatThreadServiceProvider)
          .createThread(lawyerId: user.uid, clientId: widget.receiverId);
    }
  }

  void _sendMessage() async {
    final user = ref.read(authStateProvider).value;
    if (user == null || _ctrl.text.trim().isEmpty) return;

    final text = _ctrl.text.trim();
    _ctrl.clear();

    // Ensure thread exists before sending (for lawyer-initiated chats)
    await _ensureThreadExists();

    final message = ChatModel(
      messageId: '', // Service will generate
      senderId: user.uid,
      receiverId: widget.receiverId,
      message: text,
      sentAt: DateTime.now(),
      isRead: false,
    );

    try {
      await ref.read(chatStateNotifierProvider.notifier).sendMessage(message);
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to send message: $e')));
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _pickAndSendFile(String lawyerId) async {
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
        senderId: lawyerId,
        receiverId: widget.receiverId,
        message: isImage ? 'Shared an image' : 'Shared a file: $fileName',
        messageType: isImage ? 'image' : 'file',
        fileUrl: fileUrl,
        sentAt: DateTime.now(),
      );

      await ref
          .read(chatStateNotifierProvider.notifier)
          .sendMessage(newMessage);
      _scrollToBottom();
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
        title: const Text('Delete Conversation'),
        content: const Text(
          'Are you sure you want to delete this conversation? This action cannot be undone.',
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
      final user = ref.read(authStateProvider).value;
      if (user != null) {
        final chatId = [user.uid, widget.receiverId]..sort();
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
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    if (user == null)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final messagesAsync = ref.watch(
      messagesBetweenUsersProvider((
        userId1: user.uid,
        userId2: widget.receiverId,
      )),
    );

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark
        ? const Color(0xFF121212)
        : const Color(0xFFF7F9FC);
    final cardColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 1,
        shadowColor: isDark ? Colors.black54 : Colors.black12,
        iconTheme: IconThemeData(color: textColor),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: ref
            .watch(getClientByIdProvider(widget.receiverId))
            .when(
              data: (client) {
                final name = client?.name ?? widget.clientName;
                final img = (client?.profileImage ?? widget.avatarUrl)
                    .toString();
                return Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundImage: img.isNotEmpty
                          ? NetworkImage(img)
                          : null,
                      child: img.isEmpty ? Text(name[0]) : null,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: client?.isOnline == true
                                    ? Colors.green
                                    : Colors.grey,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              client?.isOnline == true ? 'Online' : 'Offline',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                );
              },
              loading: () => Text(widget.clientName),
              error: (_, __) => Text(widget.clientName),
            ),

        actions: [
          IconButton(
            icon: Icon(Icons.phone_outlined, color: textColor),
            onPressed: () {},
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
                    Icon(Icons.delete_outline, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Text('Delete Chat', style: TextStyle(color: Colors.red)),
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
            child: messagesAsync.when(
              data: (messages) {
                WidgetsBinding.instance.addPostFrameCallback(
                  (_) => _scrollToBottom(),
                );
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(20),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == user.uid;

                    // 🔹 Mark message as read if it's new and for me
                    if (!isMe && !message.isRead) {
                      _markAsRead();
                    }

                    return _buildMessageBubble(
                      message,
                      isMe,
                      isDark,
                      textColor,
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
          _buildMessageInput(user, isDark, cardColor, textColor),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
    ChatMessage msg,
    bool isMe,
    bool isDark,
    Color textColor,
  ) {
    final time = DateFormat('h:mm a').format(msg.sentAt);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 14,
              backgroundImage: NetworkImage(widget.avatarUrl),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isMe
                        ? const Color(0xFFFF6B00)
                        : (isDark
                              ? const Color(0xFF2A2A2A)
                              : Colors.grey.shade100),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: isMe
                          ? const Radius.circular(16)
                          : const Radius.circular(0),
                      bottomRight: isMe
                          ? const Radius.circular(0)
                          : const Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: isMe
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      if (msg.messageType == 'image' && msg.fileUrl != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              msg.fileUrl!,
                              fit: BoxFit.cover,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      width: 200,
                                      height: 200,
                                      color: Colors.grey.shade200,
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          value:
                                              loadingProgress
                                                      .expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                        .cumulativeBytesLoaded /
                                                    loadingProgress
                                                        .expectedTotalBytes!
                                              : null,
                                          color: const Color(0xFFFF6B00),
                                        ),
                                      ),
                                    );
                                  },
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    width: 200,
                                    height: 200,
                                    color: Colors.grey.shade200,
                                    child: const Icon(
                                      Icons.broken_image,
                                      color: Colors.grey,
                                    ),
                                  ),
                            ),
                          ),
                        ),
                      if (msg.messageType == 'file' && msg.fileUrl != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isMe
                                ? Colors.white.withOpacity(0.1)
                                : (isDark
                                      ? const Color(0xFF333333)
                                      : Colors.white),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.insert_drive_file,
                                color: isMe
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
                                    color: isMe ? Colors.white : textColor,
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
                      Text(
                        msg.message,
                        style: TextStyle(
                          color: isMe ? Colors.white : textColor,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      time,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 11,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      Icon(
                        msg.isRead ? Icons.done_all : Icons.done,
                        size: 14,
                        color: msg.isRead ? Colors.blue : Colors.grey.shade400,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput(
    dynamic user,
    bool isDark,
    Color cardColor,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(
                  Icons.attach_file,
                  color: isDark ? Colors.white : Colors.black54,
                ),
                onPressed: () => _pickAndSendFile(user.uid),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2A2A2A)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  style: TextStyle(color: textColor),
                  controller: _ctrl,
                  onChanged: (val) {
                    final user = ref.read(authStateProvider).value;
                    if (user != null) {
                      ref
                          .read(chatStateNotifierProvider.notifier)
                          .setTypingStatus(
                            senderId: user.uid,
                            receiverId: widget.receiverId,
                            isTyping: val.isNotEmpty,
                          );
                    }
                  },

                  onSubmitted: (_) => _sendMessage(),
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    border: InputBorder.none,
                    hintStyle: TextStyle(
                      color: isDark ? Colors.white54 : Colors.black38,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFFFF6B00), // Orange
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white, size: 20),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
