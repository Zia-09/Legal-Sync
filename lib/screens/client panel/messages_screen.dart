import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legal_sync/provider/client_provider.dart';
import 'package:legal_sync/provider/chat_provider.dart';
import 'package:legal_sync/model/chat_Model.dart';
import 'home_screen.dart';
import 'case_status_screen.dart';
import 'app_setting_screen.dart';
import 'widgets/chat_widgets.dart';

class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key});

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 3;
  bool _showSearch = false;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clientAsync = ref.watch(currentClientProvider);

    return clientAsync.when(
      data: (client) {
        if (client == null) {
          return const Scaffold(
            backgroundColor: Color(0xFF0F0F0F),
            body: Center(
              child: Text(
                'Please login to view messages',
                style: TextStyle(color: Colors.white),
              ),
            ),
          );
        }

        return ref
            .watch(userMessagesProvider(client.clientId))
            .when(
              data: (messages) {
                // Group messages by chat (receiverId if I am sender, or senderId if I am receiver)
                final chatsMap = <String, ChatMessage>{};
                for (var msg in messages) {
                  final otherId = msg.senderId == client.clientId
                      ? msg.receiverId
                      : msg.senderId;
                  if (!chatsMap.containsKey(otherId) ||
                      msg.sentAt.isAfter(chatsMap[otherId]!.sentAt)) {
                    chatsMap[otherId] = msg;
                  }
                }

                var chatList = chatsMap.values.toList()
                  ..sort((a, b) => b.sentAt.compareTo(a.sentAt));

                // Implementation of real-time search
                // The filtering is now handled by _filterChats
                if (_searchCtrl.text.isNotEmpty) {
                  // Search is active
                }

                // Case-based grouping (Groups tab)
                final caseGroupsMap = <String, List<ChatMessage>>{};
                for (var msg in messages) {
                  if (msg.caseId != null) {
                    if (!caseGroupsMap.containsKey(msg.caseId)) {
                      caseGroupsMap[msg.caseId!] = [];
                    }
                    caseGroupsMap[msg.caseId!]!.add(msg);
                  }
                }
                final caseGroupList = caseGroupsMap.entries.map((e) {
                  final sorted = e.value
                    ..sort((a, b) => b.sentAt.compareTo(a.sentAt));
                  return sorted.first; // Representative message for the group
                }).toList()..sort((a, b) => b.sentAt.compareTo(a.sentAt));

                final unreadCount = messages
                    .where((m) => m.receiverId == client.clientId && !m.isRead)
                    .length;

                return Scaffold(
                  backgroundColor: const Color(0xFF0F0F0F),
                  body: SafeArea(
                    child: Column(
                      children: [
                        // Header
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E1E1E),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.arrow_back_ios_new,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                              const Expanded(
                                child: Center(
                                  child: Text(
                                    'Messages',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () =>
                                    setState(() => _showSearch = !_showSearch),
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E1E1E),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    _showSearch ? Icons.close : Icons.search,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E1E1E),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.more_vert,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Animated search bar
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          height: _showSearch ? 58 : 0,
                          child: _showSearch
                              ? Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    20,
                                    12,
                                    20,
                                    0,
                                  ),
                                  child: Container(
                                    height: 46,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1E1E1E),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(0xFF2A2A2A),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const SizedBox(width: 12),
                                        const Icon(
                                          Icons.search,
                                          color: Color(0xFF6B6B6B),
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: TextField(
                                            controller: _searchCtrl,
                                            onChanged: (val) => setState(() {}),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 13,
                                            ),
                                            decoration: const InputDecoration(
                                              hintText: 'Search messages...',
                                              hintStyle: TextStyle(
                                                color: Color(0xFF5A5A5A),
                                              ),
                                              border: InputBorder.none,
                                              isDense: true,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),

                        const SizedBox(height: 16),

                        // Tab bar
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A1A),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TabBar(
                            controller: _tabController,
                            labelColor: Colors.white,
                            unselectedLabelColor: const Color(0xFF6B6B6B),
                            indicator: BoxDecoration(
                              color: const Color(0xFFFF6B00),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            indicatorSize: TabBarIndicatorSize.tab,
                            dividerColor: Colors.transparent,
                            labelStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            tabs: [
                              const Tab(text: 'All Chats'),
                              Tab(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text('Unread'),
                                    const SizedBox(width: 4),
                                    if (unreadCount > 0)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 5,
                                          vertical: 1,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFF6B00),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Text(
                                          '$unreadCount',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const Tab(text: 'Groups'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              ChatList(
                                chatMessages: _filterChats(chatList),
                                currentUserId: client.clientId,
                                searchQuery: _searchCtrl.text,
                              ),
                              ChatList(
                                chatMessages: _filterChats(
                                  chatList
                                      .where(
                                        (m) =>
                                            m.receiverId == client.clientId &&
                                            !m.isRead,
                                      )
                                      .toList(),
                                ),
                                currentUserId: client.clientId,
                                searchQuery: _searchCtrl.text,
                              ),
                              ChatList(
                                chatMessages: _filterChats(caseGroupList),
                                currentUserId: client.clientId,
                                searchQuery: _searchCtrl.text,
                                isGroup: true,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  bottomNavigationBar: _buildBottomNav(context),
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

  List<ChatMessage> _filterChats(List<ChatMessage> chats) {
    if (_searchCtrl.text.isEmpty) return chats;
    final query = _searchCtrl.text.toLowerCase();
    // Note: We can only filter by message content here because lawyer names are fetched asynchronously in the tiles.
    // However, we could pre-fetch lawyer names or use a more complex state management if needed.
    return chats.where((m) => m.message.toLowerCase().contains(query)).toList();
  }

  Widget _buildBottomNav(BuildContext context) {
    const items = [
      {'label': 'Home'},
      {'label': 'Lawyer'},
      {'label': 'Cases'},
      {'label': 'Chat'},
      {'label': 'Setting'},
    ];
    const icons = [
      Icons.home_outlined,
      Icons.balance_outlined,
      Icons.folder_outlined,
      Icons.chat_bubble_outline,
      Icons.settings_outlined,
    ];
    const activeIcons = [
      Icons.home,
      Icons.balance,
      Icons.folder,
      Icons.chat_bubble,
      Icons.settings,
    ];

    return Container(
      height: 70,
      decoration: const BoxDecoration(
        color: Color(0xFF141414),
        border: Border(top: BorderSide(color: Color(0xFF1E1E1E), width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(5, (index) {
          final isActive = _currentIndex == index;
          return GestureDetector(
            onTap: () {
              if (index == 0) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                  (_) => false,
                );
              } else if (index == 2) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CaseStatusScreen()),
                );
              } else if (index == 4) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AppSettingScreen()),
                );
              } else {
                setState(() => _currentIndex = index);
              }
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isActive ? activeIcons[index] : icons[index],
                  color: isActive
                      ? const Color(0xFFFF6B00)
                      : const Color(0xFF5A5A5A),
                  size: 24,
                ),
                const SizedBox(height: 4),
                Text(
                  items[index]['label']!,
                  style: TextStyle(
                    color: isActive
                        ? const Color(0xFFFF6B00)
                        : const Color(0xFF5A5A5A),
                    fontSize: 10,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
