import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:legal_sync/model/lawyer_Model.dart';
import 'package:legal_sync/provider/client_provider.dart';
import 'package:legal_sync/provider/chat_provider.dart';
import 'package:legal_sync/services/chat_service.dart';
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
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (image == null) return;

      // Upload to Supabase
      final imageUrl = await supabaseService.uploadFile(
        file: File(image.path),
        path: 'chat_attachments/${widget.receiverId}',
      );

      // Send message
      await ChatService().sendMessage(
        senderId: clientId,
        receiverId: widget.receiverId,
        message: 'Image',
        messageType: 'image',
        fileUrl: imageUrl,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send attachment: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
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
                  backgroundColor: const Color(0xFF0F0F0F),
                  appBar: AppBar(
                    backgroundColor: const Color(0xFF141414),
                    leadingWidth: 40,
                    leading: IconButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    title: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E),
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
                                      style: const TextStyle(
                                        color: Colors.white,
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
                                style: const TextStyle(
                                  color: Colors.white,
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
                                                  : const Color(0xFF6B6B6B),
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
                                            : const Color(0xFF6B6B6B),
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
                                            : const Color(0xFF6B6B6B),
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
                        icon: const Icon(
                          Icons.call_outlined,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.more_vert, color: Colors.white),
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
                                  color: isMine
                                      ? const Color(0xFFFF6B00)
                                      : const Color(0xFF1E1E1E),
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
                                    if (msg.message.isNotEmpty &&
                                        msg.messageType == 'text')
                                      Text(
                                        msg.message,
                                        style: TextStyle(
                                          color: isMine
                                              ? Colors.white
                                              : const Color(0xFFDDDDDD),
                                          fontSize: 13,
                                          height: 1.4,
                                        ),
                                      ),
                                    const SizedBox(height: 4),
                                    Text(
                                      DateFormat('hh:mm a').format(msg.sentAt),
                                      style: TextStyle(
                                        color: isMine
                                            ? Colors.white.withValues(
                                                alpha: 0.6,
                                              )
                                            : const Color(0xFF5A5A5A),
                                        fontSize: 10,
                                      ),
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
                        decoration: const BoxDecoration(
                          color: Color(0xFF141414),
                          border: Border(
                            top: BorderSide(color: Color(0xFF1E1E1E)),
                          ),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () =>
                                  _pickAndSendFile(client.clientId),
                              icon: const Icon(
                                Icons.attach_file,
                                color: Color(0xFF6B6B6B),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E1E1E),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: const Color(0xFF2A2A2A),
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
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                  decoration: const InputDecoration(
                                    hintText: 'Type a message...',
                                    hintStyle: TextStyle(
                                      color: Color(0xFF5A5A5A),
                                    ),
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
                                  await ChatService().sendMessage(
                                    senderId: client.clientId,
                                    receiverId: widget.receiverId,
                                    message: text,
                                  );
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
              loading: () => const Scaffold(
                backgroundColor: Color(0xFF0F0F0F),
                body: Center(
                  child: CircularProgressIndicator(color: Color(0xFFFF6B00)),
                ),
              ),
              error: (e, st) => Scaffold(
                backgroundColor: const Color(0xFF0F0F0F),
                body: Center(
                  child: Text(
                    'Error: $e',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            );
      },
      loading: () => const Scaffold(
        backgroundColor: Color(0xFF0F0F0F),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFFF6B00)),
        ),
      ),
      error: (e, st) => Scaffold(
        backgroundColor: const Color(0xFF0F0F0F),
        body: Center(
          child: Text(
            'Auth Error: $e',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}
