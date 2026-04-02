import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:legal_sync/model/appoinment_model.dart';
import 'package:legal_sync/model/client_Model.dart';
import 'package:legal_sync/provider/appointment_provider.dart';
import 'package:legal_sync/provider/auth_provider.dart';
import 'package:legal_sync/provider/client_provider.dart';

class AllConsultationRequestScreen extends ConsumerStatefulWidget {
  const AllConsultationRequestScreen({super.key});

  @override
  ConsumerState<AllConsultationRequestScreen> createState() =>
      _AllConsultationRequestScreenState();
}

class _AllConsultationRequestScreenState
    extends ConsumerState<AllConsultationRequestScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<AppointmentModel> _acceptedRequests = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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

    final authState = ref.watch(authStateProvider);
    final currentUser = authState.value;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Consultation Requests')),
        body: const Center(child: Text('Not authenticated')),
      );
    }

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
          _buildPendingList(currentUser.uid),
          _buildAcceptedList(),
          _buildHistoryList(),
        ],
      ),
    );
  }

  Widget _buildPendingList(String lawyerId) {
    final appointmentsAsync = ref.watch(
      streamPendingAppointmentsForLawyerProvider(lawyerId),
    );
    final clientsAsync = ref.watch(allClientsProvider);

    return appointmentsAsync.when(
      data: (appointments) {
        return clientsAsync.when(
          data: (clients) {
            if (appointments.isEmpty) {
              return const Center(child: Text('No pending requests.'));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: appointments.length,
              itemBuilder: (context, index) {
                final appointment = appointments[index];
                final client = clients.firstWhere(
                  (c) => c.clientId == appointment.clientId,
                  orElse: () => ClientModel(
                    clientId: appointment.clientId,
                    name: 'Unknown Client',
                    email: '',
                    phone: '',
                    profileImage: null,
                    caseIds: [],
                    walletBalance: 0,
                    hasPendingPayment: false,
                    isVerified: false,
                    status: 'active',
                    joinedAt: Timestamp.now(),
                  ),
                );

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildConsultationCard(
                    appointment: appointment,
                    client: client,
                    showActions: true,
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error: $error')),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }

  Widget _buildAcceptedList() {
    if (_acceptedRequests.isEmpty) {
      return const Center(child: Text('No accepted requests yet.'));
    }
    return const Center(child: Text('Feature coming soon'));
  }

  Widget _buildHistoryList() {
    return const Center(child: Text('No history available.'));
  }

  Widget _buildConsultationCard({
    required AppointmentModel appointment,
    required ClientModel client,
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
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage:
                      (client.profileImage != null &&
                          client.profileImage!.isNotEmpty)
                      ? NetworkImage(client.profileImage!)
                      : null,
                  child:
                      (client.profileImage == null ||
                          client.profileImage!.isEmpty)
                      ? Icon(
                          Icons.person,
                          size: 20,
                          color: Colors.grey.shade600,
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Text(
                  client.name,
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
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'CONSULTATION',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      DateFormat('h:mm a').format(appointment.scheduledAt),
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  appointment.adminNote ?? 'Legal Consultation Request',
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
                            // Decline logic
                            ref
                                .read(appointmentStateProvider.notifier)
                                .rejectAppointment(appointment.appointmentId);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Declined consultation with ${client.name}',
                                ),
                                backgroundColor: Colors.orange,
                                duration: const Duration(seconds: 2),
                              ),
                            );
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
                          onPressed: () {
                            // Accept logic
                            ref
                                .read(appointmentStateProvider.notifier)
                                .approveAppointment(appointment.appointmentId);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Accepted consultation with ${client.name}',
                                ),
                                backgroundColor: Colors.green,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
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
