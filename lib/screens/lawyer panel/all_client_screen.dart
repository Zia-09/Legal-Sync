import 'package:flutter/material.dart';
import 'package:legal_sync/screens/lawyer%20panel/lawyer_chat_screen.dart';

class AllClientScreen extends StatefulWidget {
  const AllClientScreen({super.key});

  @override
  State<AllClientScreen> createState() => _AllClientScreenState();
}

class _AllClientScreenState extends State<AllClientScreen> {
  // Mock data representing the messages list
  final List<Map<String, dynamic>> _contacts = [
    {
      'name': 'Luisa bibi',
      'id': '#CS-2025-081',
      'clientId': 'client_1',
      'caseType': 'Divorce case',
      'date': 'Submitted: 14 Aug 2025',
      'status': 'PENDING',
      'avatar': 'https://i.pravatar.cc/150?img=1',
      'color': Colors.green, // active status indicator
    },
    {
      'name': 'Silverio',
      'id': '#CS-2025-082',
      'clientId': 'client_2',
      'caseType': 'Civil case',
      'date': 'Submitted: 14 Aug 2025',
      'status': 'COMPLETED',
      'avatar': 'https://i.pravatar.cc/150?img=11',
      'color': Colors.transparent,
    },
    {
      'name': 'Berlin',
      'id': '#CY-2025-081',
      'clientId': 'client_3',
      'caseType': 'Cyber crime',
      'date': 'Submitted: 14 Aug 2025',
      'status': 'PENDING',
      'avatar': 'https://i.pravatar.cc/150?img=12',
      'color': Colors.green,
    },
    {
      'name': 'Jack Reacher',
      'id': '#CS-2025-081',
      'clientId': 'client_4',
      'caseType': 'Divorce case',
      'date': 'Submitted: 14 Aug 2025',
      'status': 'COMPLETED',
      'avatar': 'https://i.pravatar.cc/150?img=13',
      'color': Colors.transparent,
    },
    {
      'name': 'Waqas abid',
      'id': '#CS-2025-085',
      'clientId': 'client_5',
      'caseType': 'Property dispute',
      'date': 'Submitted: 14 Aug 2025',
      'status': 'PENDING',
      'avatar': 'https://i.pravatar.cc/150?img=14',
      'color': Colors.green,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'All Clients',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              itemCount: _contacts.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final contact = _contacts[index];
                return _buildContactCard(contact);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Action for new message
        },
        backgroundColor: const Color(0xFFFF6B00),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        style: const TextStyle(color: Colors.black87, fontSize: 14),
        decoration: InputDecoration(
          icon: Icon(Icons.search, color: Colors.grey.shade500),
          hintText: 'Search cases or client',
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          border: InputBorder.none,
          suffixIcon: Icon(Icons.mic_none, color: Colors.grey.shade500),
        ),
      ),
    );
  }

  Widget _buildContactCard(Map<String, dynamic> contact) {
    bool isCompleted = contact['status'] == 'COMPLETED';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LawyerChatScreen(
              clientName: contact['name'],
              avatarUrl: contact['avatar'],
              receiverId: contact['clientId'],
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundImage: NetworkImage(contact['avatar']),
                    ),
                    if (contact['color'] != Colors.transparent)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: contact['color'],
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            contact['name'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isCompleted
                                  ? Colors.green.shade50
                                  : Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              contact['status'],
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isCompleted
                                    ? Colors.green.shade700
                                    : const Color(0xFFFF6B00),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${contact['id']}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Text(
                            'Case type: ',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blueAccent,
                            ),
                          ),
                          Text(
                            contact['caseType'],
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, thickness: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 14,
                      color: const Color(0xFFFF6B00),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      contact['date'],
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFFF6B00),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Icon(Icons.chevron_right, color: Colors.grey.shade400),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
