import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legal_sync/provider/auth_provider.dart';
import 'package:legal_sync/provider/case_provider.dart';
import 'package:legal_sync/provider/appointment_provider.dart';
import 'package:legal_sync/provider/lawyer_provider.dart';
import 'package:legal_sync/provider/notification_provider.dart';
import 'package:legal_sync/provider/hearing_provider.dart';
import 'package:legal_sync/model/lawyer_Model.dart';
import 'package:legal_sync/screens/lawyer%20panel/all_consultation_request_screen.dart';
import 'package:legal_sync/screens/lawyer%20panel/lawyer_management_document_screen.dart';
import 'package:legal_sync/screens/lawyer%20panel/lawyer_messages_screen.dart';
import 'package:legal_sync/screens/lawyer%20panel/lawyer_settings_screen.dart';
import 'package:legal_sync/screens/lawyer%20panel/create_case_screen.dart';
import 'package:legal_sync/screens/lawyer%20panel/lawyer_notifications_screen.dart';
import 'package:intl/intl.dart';

class LawyerDashboardScreen extends ConsumerStatefulWidget {
  const LawyerDashboardScreen({super.key});

  @override
  ConsumerState<LawyerDashboardScreen> createState() =>
      _LawyerDashboardScreenState();
}

class _LawyerDashboardScreenState extends ConsumerState<LawyerDashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const _LawyerHomeContent(),
      const LawyerManagementDocumentScreen(),
      const LawyerMessagesScreen(),
      const LawyerSettingsScreen(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: pages[_selectedIndex],
      floatingActionButton: _selectedIndex == 0 || _selectedIndex == 1
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateCaseScreen()),
                );
              },
              backgroundColor: const Color(0xFFFF6B00),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFFFF6B00),
        unselectedItemColor: Colors.grey.shade400,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.normal,
          fontSize: 12,
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.insert_drive_file_outlined),
            activeIcon: Icon(Icons.insert_drive_file),
            label: 'Documents',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ─── Lawyer Home Content ──────────────────────────────────────────────────────

class _LawyerHomeContent extends ConsumerWidget {
  const _LawyerHomeContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    if (user == null) return const Center(child: CircularProgressIndicator());

    final lawyerAsync = ref.watch(getLawyerByIdProvider(user.uid));
    final casesAsync = ref.watch(casesByLawyerProvider(user.uid));
    final consultationAsync = ref.watch(
      streamPendingAppointmentsForLawyerProvider(user.uid),
    );
    final hearingsAsync = ref.watch(streamUpcomingHearingsProvider(user.uid));
    final unreadCountAsync = ref.watch(
      unreadNotificationsCountProvider(user.uid),
    );

    return lawyerAsync.when(
      data: (lawyer) {
        if (lawyer == null) {
          return const Center(child: Text('Lawyer data not found'));
        }
        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, lawyer, unreadCountAsync.value ?? 0),
                const SizedBox(height: 16),
                casesAsync.when(
                  data: (cases) => _buildSummaryCards(cases),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                ),
                const SizedBox(height: 24),
                consultationAsync.when(
                  data: (requests) =>
                      _buildConsultationRequests(context, ref, requests),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                ),
                const SizedBox(height: 24),
                hearingsAsync.when(
                  data: (hearings) => _buildSchedule(hearings),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    LawyerModel lawyer,
    int unreadCount,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      color: Colors.white,
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFFFF6B00),
            backgroundImage:
                lawyer.profileImage != null && lawyer.profileImage!.isNotEmpty
                ? NetworkImage(lawyer.profileImage!)
                : null,
            child: lawyer.profileImage == null || lawyer.profileImage!.isEmpty
                ? const Icon(Icons.person, color: Colors.white, size: 22)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome Back,',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                ),
                Text(
                  lawyer.name,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Search icon
          GestureDetector(
            onTap: () {
              showSearch(context: context, delegate: _LawyerSearchDelegate());
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.search, color: Colors.black87, size: 20),
            ),
          ),
          const SizedBox(width: 8),
          // Notification icon
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const LawyerNotificationsScreen(),
                ),
              );
            },
            child: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.notifications_none,
                    color: Colors.black87,
                    size: 20,
                  ),
                ),
                if (unreadCount > 0)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF6B00),
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        unreadCount > 9 ? '9+' : unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(List<dynamic> cases) {
    final total = cases.length;
    final active = cases.where((c) => c.status == 'active').length;
    final pending = cases.where((c) => c.status == 'pending').length;
    final closed = cases
        .where((c) => c.status == 'closed' || c.status == 'completed')
        .length;

    // Simple percentage calculation relative to total
    final activePercent = total > 0 ? (active / total * 100).round() : 0;
    final pendingPercent = total > 0 ? (pending / total * 100).round() : 0;
    final closedPercent = total > 0 ? (closed / total * 100).round() : 0;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _buildStatCard(
            'Total Cases',
            total.toString(),
            '$activePercent% active',
            true,
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            'Active Cases',
            active.toString(),
            '+$activePercent%',
            true,
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            'Pending',
            pending.toString(),
            '+$pendingPercent%',
            pendingPercent >= 0,
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            'Completed',
            closed.toString(),
            '+$closedPercent%',
            true,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String count,
    String percentage,
    bool isPositive,
  ) {
    return Container(
      width: 120,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            count,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                color: isPositive ? Colors.green : Colors.red,
                size: 11,
              ),
              const SizedBox(width: 2),
              Text(
                percentage,
                style: TextStyle(
                  color: isPositive ? Colors.green : Colors.red,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConsultationRequests(
    BuildContext context,
    WidgetRef ref,
    List<dynamic> requests,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Consultation Requests (${requests.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AllConsultationRequestScreen(),
                  ),
                ),
                child: Text(
                  'View All',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (requests.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 40,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No pending consultation requests',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                ],
              ),
            )
          else
            ...requests
                .take(2)
                .map(
                  (req) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildConsultationCard(
                      context,
                      ref,
                      appointmentId: req.appointmentId,
                      name: 'Client ID: ${req.clientId.substring(0, 5)}...',
                      priority: 'CONSULTATION',
                      priorityColor: Colors.red.shade50,
                      priorityTextColor: Colors.red,
                      topic: req.adminNote ?? 'Legal Consultation Request',
                      time: DateFormat('h:mm a').format(req.scheduledAt),
                      avatarUrl: 'https://i.pravatar.cc/150?u=${req.clientId}',
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildConsultationCard(
    BuildContext context,
    WidgetRef ref, {
    required String appointmentId,
    required String name,
    required String priority,
    required Color priorityColor,
    required Color priorityTextColor,
    required String topic,
    required String time,
    required String avatarUrl,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(avatarUrl),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: priorityColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            priority,
                            style: TextStyle(
                              color: priorityTextColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '• $time',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      topic,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => ref
                      .read(appointmentStateProvider.notifier)
                      .rejectAppointment(appointmentId),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
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
                child: ElevatedButton.icon(
                  onPressed: () => ref
                      .read(appointmentStateProvider.notifier)
                      .approveAppointment(appointmentId),
                  icon: const Icon(
                    Icons.check_circle_outline,
                    size: 16,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'Accept',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    backgroundColor: const Color(0xFFFF6B00),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
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

  Widget _buildSchedule(List<dynamic> hearings) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Upcoming Hearings',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          if (hearings.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                'No upcoming hearings scheduled',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            )
          else
            ...hearings
                .take(3)
                .map(
                  (hearing) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildScheduleItem(
                      time: DateFormat('h:mm a').format(hearing.scheduledAt),
                      title: hearing.hearingType,
                      subtitle:
                          'Room: ${hearing.courtRoom ?? 'TBD'} | ${hearing.modeOfConduct}',
                      iconColor: const Color(0xFFFF6B00),
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildScheduleItem({
    required String time,
    required String title,
    required String subtitle,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              time,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 4,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Simple Search Delegate ───────────────────────────────────────────────────

class _LawyerSearchDelegate extends SearchDelegate<String> {
  @override
  List<Widget> buildActions(BuildContext context) => [
    IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
  ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () => close(context, ''),
  );

  @override
  Widget buildResults(BuildContext context) =>
      Center(child: Text('Searching: $query'));

  @override
  Widget buildSuggestions(BuildContext context) =>
      const Center(child: Text('Search for cases, clients...'));
}
