import 'package:flutter/material.dart';

class AllConsultationRequestScreen extends StatefulWidget {
  const AllConsultationRequestScreen({super.key});

  @override
  State<AllConsultationRequestScreen> createState() =>
      _AllConsultationRequestScreenState();
}

class ConsultationRequest {
  final String id;
  final String clientName;
  final String priority;
  final Color priorityColor;
  final Color priorityBg;
  final String timeText;
  final String category;
  final String avatarUrl;

  ConsultationRequest({
    required this.id,
    required this.clientName,
    required this.priority,
    required this.priorityColor,
    required this.priorityBg,
    required this.timeText,
    required this.category,
    required this.avatarUrl,
  });
}

class _AllConsultationRequestScreenState
    extends State<AllConsultationRequestScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<ConsultationRequest> _pendingRequests = [
    ConsultationRequest(
      id: '1',
      clientName: 'Michael Henderson',
      priority: 'High Priority',
      priorityColor: Colors.red.shade700,
      priorityBg: Colors.red.shade50,
      timeText: '12 mins ago',
      category: 'Corporate Litigation',
      avatarUrl: 'https://i.pravatar.cc/150?img=12',
    ),
    ConsultationRequest(
      id: '2',
      clientName: 'Sarah Miller',
      priority: 'Standard',
      priorityColor: Colors.blue.shade700,
      priorityBg: Colors.blue.shade50,
      timeText: '1 hour ago',
      category: 'Real Estate Law',
      avatarUrl: 'https://i.pravatar.cc/150?img=5',
    ),
    ConsultationRequest(
      id: '3',
      clientName: 'Robert Smith',
      priority: 'Standard',
      priorityColor: Colors.blue.shade700,
      priorityBg: Colors.blue.shade50,
      timeText: '3 hours ago',
      category: 'Intellectual Property',
      avatarUrl: 'https://i.pravatar.cc/150?img=13',
    ),
  ];

  final List<ConsultationRequest> _acceptedRequests = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  void _acceptRequest(ConsultationRequest request) {
    setState(() {
      _pendingRequests.remove(request);
      _acceptedRequests.add(request);
    });
    // Optional: Switch to Accepted tab automatically
    // _tabController.animateTo(1);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Accepted consultation with ${request.clientName}'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark
        ? const Color(0xFF121212)
        : const Color(0xFFF7F9FC);
    final appBarBg = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: appBarBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Consultation Requests',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: Colors.black87),
            onPressed: () {
              // Open filters
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFFF6B00),
          unselectedLabelColor: Colors.grey.shade600,
          indicatorColor: const Color(0xFFFF6B00),
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Accepted'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPendingList(),
          _buildAcceptedList(),
          _buildHistoryList(),
        ],
      ),
    );
  }

  Widget _buildPendingList() {
    if (_pendingRequests.isEmpty) {
      return const Center(child: Text('No pending requests.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _pendingRequests.length,
      itemBuilder: (context, index) {
        final request = _pendingRequests[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildConsultationCard(request: request, showActions: true),
        );
      },
    );
  }

  Widget _buildAcceptedList() {
    if (_acceptedRequests.isEmpty) {
      return const Center(child: Text('No accepted requests yet.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _acceptedRequests.length,
      itemBuilder: (context, index) {
        final request = _acceptedRequests[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildConsultationCard(
            request: request,
            showActions: false, // Don't show Accept/Decline once accepted
          ),
        );
      },
    );
  }

  Widget _buildHistoryList() {
    return const Center(child: Text('No history available.'));
  }

  Widget _buildConsultationCard({
    required ConsultationRequest request,
    required bool showActions,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Client Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundImage: NetworkImage(request.avatarUrl),
                ),
                const SizedBox(width: 12),
                Text(
                  request.clientName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: request.priorityBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        request.priority.toUpperCase(),
                        style: TextStyle(
                          color: request.priorityColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      request.timeText,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  request.category,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                if (showActions) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            // Decline logic if needed
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                          child: Text(
                            'Decline',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _acceptRequest(request),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF6B00),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Accept Request',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // View Case/Chat logic
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'View Details',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
