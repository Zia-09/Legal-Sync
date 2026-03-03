import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legal_sync/provider/auth_provider.dart';
import 'package:legal_sync/provider/chat_provider.dart';
import 'package:legal_sync/provider/lawyer_provider.dart';
import 'package:legal_sync/model/chat_Model.dart';
import 'package:legal_sync/screens/lawyer%20panel/lawyer_chat_screen.dart';
import 'package:intl/intl.dart';

class LawyerMessagesScreen extends ConsumerStatefulWidget {
  const LawyerMessagesScreen({super.key});

  @override
  ConsumerState<LawyerMessagesScreen> createState() =>
      _LawyerMessagesScreenState();
}

class _LawyerMessagesScreenState extends ConsumerState<LawyerMessagesScreen> {
  String _selectedFilter = 'All';
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Messages',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.black87),
            onSelected: (val) {
              if (val == 'mark_all_read') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All messages marked as read'),
                    backgroundColor: Color(0xFFFF6B00),
                  ),
                );
              } else if (val == 'archived') {
                setState(() => _selectedFilter = 'Archived');
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'mark_all_read',
                child: Text('Mark all as read'),
              ),
              const PopupMenuItem(
                value: 'archived',
                child: Text('View Archived'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilters(),
          Expanded(
            child: user == null
                ? const Center(child: CircularProgressIndicator())
                : _buildMessagesList(user.uid),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 6),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
        decoration: InputDecoration(
          icon: Icon(Icons.search, color: Colors.grey.shade400, size: 20),
          hintText: 'Search conversations...',
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          border: InputBorder.none,
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.close,
                    color: Colors.grey.shade400,
                    size: 18,
                  ),
                  onPressed: () => setState(() {
                    _searchQuery = '';
                    _searchCtrl.clear();
                  }),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
      child: Row(
        children: [
          _buildFilterChip('All'),
          const SizedBox(width: 8),
          _buildFilterChip('Unread'),
          const SizedBox(width: 8),
          _buildFilterChip('Archived'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF6B00) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFFF6B00) : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildMessagesList(String lawyerId) {
    final messagesAsync = ref.watch(userMessagesProvider(lawyerId));

    return messagesAsync.when(
      data: (messages) {
        // Get latest message per conversation partner
        final Map<String, ChatModel> conversations = {};
        for (final msg in messages) {
          final partnerId = msg.senderId == lawyerId
              ? msg.receiverId
              : msg.senderId;
          if (!conversations.containsKey(partnerId) ||
              msg.sentAt.isAfter(conversations[partnerId]!.sentAt)) {
            conversations[partnerId] = msg;
          }
        }

        var convList = conversations.values.toList()
          ..sort((a, b) => b.sentAt.compareTo(a.sentAt));

        // Apply filter
        if (_selectedFilter == 'Unread') {
          convList = convList
              .where((m) => !m.isRead && m.receiverId == lawyerId)
              .toList();
        } else if (_selectedFilter == 'Archived') {
          convList = [];
        }

        // Apply search
        if (_searchQuery.isNotEmpty) {
          convList = convList
              .where((m) => m.message.toLowerCase().contains(_searchQuery))
              .toList();
        }

        if (convList.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          itemCount: convList.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final msg = convList[index];
            final partnerId = msg.senderId == lawyerId
                ? msg.receiverId
                : msg.senderId;
            return _buildChatTile(msg, partnerId, lawyerId, ref);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading messages: $e')),
    );
  }

  Widget _buildChatTile(
    ChatModel msg,
    String partnerId,
    String lawyerId,
    WidgetRef ref,
  ) {
    final isUnread = !msg.isRead && msg.receiverId == lawyerId;
    final partnerAsync = ref.watch(getLawyerByIdProvider(partnerId));
    final partnerName = partnerAsync.valueOrNull?.name ?? 'Client';
    final avatarUrl =
        partnerAsync.valueOrNull?.profileImage ??
        'https://i.pravatar.cc/150?u=$partnerId';
    final timeStr = _formatTime(msg.sentAt);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                LawyerChatScreen(clientName: partnerName, avatarUrl: avatarUrl),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundImage: NetworkImage(avatarUrl),
                  onBackgroundImageError: (_, __) {},
                  child: const Icon(Icons.person),
                ),
                if (isUnread)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B00),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        partnerName,
                        style: TextStyle(
                          fontWeight: isUnread
                              ? FontWeight.bold
                              : FontWeight.w600,
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        timeStr,
                        style: TextStyle(
                          fontSize: 12,
                          color: isUnread
                              ? const Color(0xFFFF6B00)
                              : Colors.grey.shade500,
                          fontWeight: isUnread
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          msg.message,
                          style: TextStyle(
                            fontSize: 13,
                            color: isUnread
                                ? Colors.black87
                                : Colors.grey.shade600,
                            fontWeight: isUnread
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isUnread)
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF6B00),
                            shape: BoxShape.circle,
                          ),
                          child: const Text(
                            '1',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final label = _selectedFilter == 'Archived'
        ? 'No archived conversations'
        : _selectedFilter == 'Unread'
        ? 'No unread messages'
        : 'No conversations yet';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 60,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return DateFormat('h:mm a').format(dt);
    if (diff.inDays < 7) return DateFormat('EEE').format(dt);
    return DateFormat('MMM d').format(dt);
  }
}
