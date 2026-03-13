import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legal_sync/model/lawyer_Model.dart';
import 'package:legal_sync/provider/lawyer_provider.dart';
import 'package:legal_sync/services/lawyer_services.dart';
import 'package:legal_sync/services/email_service.dart';
import 'admin_verification_detail_screen.dart';

class AdminVerificationListScreen extends ConsumerStatefulWidget {
  const AdminVerificationListScreen({super.key});

  @override
  ConsumerState<AdminVerificationListScreen> createState() =>
      _AdminVerificationListScreenState();
}

class _AdminVerificationListScreenState
    extends ConsumerState<AdminVerificationListScreen> {
  int _selectedTabIndex = 0; // 0: All, 1: Pending, 2: Verified, 3: Rejected
  late TextEditingController _searchCtrl;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Lawyer Verification',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Tabs
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Consumer(
              builder: (context, ref, _) {
                final lawyersAsync = ref.watch(allLawyersProvider);
                int allCount = 0;
                int pendingCount = 0;
                int verifiedCount = 0;
                int rejectedCount = 0;

                if (lawyersAsync.value != null) {
                  for (var l in lawyersAsync.value!) {
                    allCount++;
                    final st = l.approvalStatus.toLowerCase();
                    if (st == 'pending') {
                      pendingCount++;
                    } else if (st == 'verified' || st == 'approved') {
                      verifiedCount++;
                    } else if (st == 'rejected') {
                      rejectedCount++;
                    } else if (!l.isApproved) {
                      pendingCount++; // Fallback if approvalStatus is null but not approved
                    } else {
                      verifiedCount++;
                    }
                  }
                }

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _TabItem(
                      title: 'All',
                      count: '($allCount)',
                      isSelected: _selectedTabIndex == 0,
                      onTap: () => setState(() => _selectedTabIndex = 0),
                    ),
                    _TabItem(
                      title: 'Pending',
                      count: '($pendingCount)',
                      color: const Color(0xFFE67E22),
                      isSelected: _selectedTabIndex == 1,
                      onTap: () => setState(() => _selectedTabIndex = 1),
                    ),
                    _TabItem(
                      title: 'Verified',
                      count: '($verifiedCount)',
                      color: const Color(0xFF059669),
                      isSelected: _selectedTabIndex == 2,
                      onTap: () => setState(() => _selectedTabIndex = 2),
                    ),
                    _TabItem(
                      title: 'Rejected',
                      count: '($rejectedCount)',
                      color: const Color(0xFFDC2626),
                      isSelected: _selectedTabIndex == 3,
                      onTap: () => setState(() => _selectedTabIndex = 3),
                    ),
                  ],
                );
              },
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (val) =>
                    setState(() => _searchQuery = val.toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Search by name, Bar ID or city',
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                  icon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                ),
              ),
            ),
          ),

          // List
          Expanded(child: _buildLawyersList()),
        ],
      ),
    );
  }

  List<LawyerModel> _filterLawyers(List<LawyerModel> lawyers) {
    return lawyers.where((l) {
      if (_searchQuery.isNotEmpty) {
        if (!l.name.toLowerCase().contains(_searchQuery) &&
            !(l.location?.toLowerCase().contains(_searchQuery) ?? false) &&
            !(l.email.toLowerCase().contains(_searchQuery))) {
          return false;
        }
      }

      final status = l.approvalStatus.toLowerCase();
      bool isPending =
          status == 'pending' || (!l.isApproved && status != 'rejected');
      bool isVerified =
          status == 'verified' || status == 'approved' || l.isApproved;
      bool isRejected = status == 'rejected';

      if (_selectedTabIndex == 1 && !isPending) return false;
      if (_selectedTabIndex == 2 && !isVerified) return false;
      if (_selectedTabIndex == 3 && !isRejected) return false;

      return true;
    }).toList();
  }

  Widget _buildLawyersList() {
    final lawyersAsync = ref.watch(allLawyersProvider);

    return lawyersAsync.when(
      data: (lawyers) {
        final filtered = _filterLawyers(lawyers);
        if (filtered.isEmpty) {
          return const Center(child: Text('No verification requests found.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final l = filtered[index];
            final status = l.approvalStatus.toUpperCase();
            final Color statusColor;
            if (status == 'VERIFIED' || status == 'APPROVED') {
              statusColor = const Color(0xFF059669);
            } else if (status == 'REJECTED') {
              statusColor = const Color(0xFFDC2626);
            } else {
              statusColor = const Color(0xFFE67E22);
            }

            return _VerificationCard(
              lawyer: l,
              name: l.name,
              barId:
                  'Id: ${l.lawyerId.substring(0, 8)}', // Simulated Bar ID for now
              status: status,
              statusColor: statusColor,
              tag: l.specialization,
              location: l.location ?? 'Unknown location',
              isVerified: status == 'VERIFIED' || status == 'APPROVED',
              onViewDetails: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AdminVerificationDetailScreen(lawyer: l),
                  ),
                );
              },
            );
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: Color(0xFF1E3A8A)),
      ),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }
}

class _TabItem extends StatelessWidget {
  final String title;
  final String count;
  final Color? color;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabItem({
    required this.title,
    required this.count,
    this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.only(bottom: 12, top: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? const Color(0xFF1E3A8A) : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '$title ',
                style: TextStyle(
                  color: isSelected
                      ? const Color(0xFF1E3A8A)
                      : Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              TextSpan(
                text: count,
                style: TextStyle(
                  color:
                      color ??
                      (isSelected
                          ? const Color(0xFF1E3A8A)
                          : Colors.grey.shade400),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VerificationCard extends StatelessWidget {
  final LawyerModel lawyer;
  final String name;
  final String barId;
  final String status;
  final Color statusColor;
  final String tag;
  final String location;
  final bool isVerified;
  final VoidCallback? onViewDetails;

  const _VerificationCard({
    required this.lawyer,
    required this.name,
    required this.barId,
    required this.status,
    required this.statusColor,
    required this.tag,
    required this.location,
    this.isVerified = false,
    this.onViewDetails,
  });

  void _updateStatus(
    BuildContext context,
    String newStatus,
    bool isApproved,
  ) async {
    try {
      await LawyerService().updateLawyer(
        lawyerId: lawyer.lawyerId,
        data: {'isApproved': isApproved, 'approvalStatus': newStatus},
      );
      if (isApproved) {
        // Send email message
        try {
          await EmailService().sendProfessionalEmail(
            to: lawyer.email,
            subject: 'Congratulations! Your LegalSync Account is Verified',
            htmlContent:
                '''
              <div style="font-family: Arial, sans-serif; max-width: 600px; margin: auto; padding: 20px; border: 1px solid #eee; border-radius: 10px;">
                <h2 style="color: #16A34A; text-align: center;">Welcome to LegalSync Elite, Counselor ${lawyer.name}!</h2>
                <p style="font-size: 16px; color: #333;">Great news! Our administration team has verified your advocate identity card and credentials.</p>
                <p style="color: #666;">Your account is now <strong>Active and Approved</strong>. You can log in to the Lawyer Portal to start accepting clients and managing your cases.</p>
                <div style="background-color: #f9f9f9; padding: 15px; border-radius: 5px; margin: 20px 0;">
                  <p style="margin: 0; color: #16A34A;"><strong>Status:</strong> Verified Professional</p>
                </div>
                <p style="text-align: center; font-size: 12px; color: #aaa;">&copy; 2026 LegalSync Elite. Excellence in legal management.</p>
              </div>
            ''',
          );
        } catch (e) {
          debugPrint('Failed to send verification email: $e');
        }

        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Verification completed and Email sent to ${lawyer.email}!',
            ),
            backgroundColor: const Color(0xFF059669),
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Update failed: $e'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
                child: lawyer.profileImage != null
                    ? ClipOval(
                        child: Image.network(
                          lawyer.profileImage!,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Icon(
                        Icons.person,
                        color: Color(0xFF1E3A8A),
                        size: 28,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Bar ID: $barId',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF1E3A8A,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            tag,
                            style: const TextStyle(
                              color: Color(0xFF1E3A8A),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.location_on,
                          size: 12,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          location,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 11,
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
          if (isVerified || status == 'REJECTED')
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onViewDetails,
                icon: const Icon(
                  Icons.remove_red_eye_outlined,
                  size: 16,
                  color: Color(0xFF1E3A8A),
                ),
                label: const Text(
                  'View Details',
                  style: TextStyle(color: Color(0xFF1E3A8A)),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF1E3A8A)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            )
          else
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onViewDetails,
                    icon: const Icon(
                      Icons.remove_red_eye_outlined,
                      size: 16,
                      color: Colors.grey,
                    ),
                    label: const Text(
                      'View Details',
                      style: TextStyle(color: Color(0xFF4B5563)),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _updateStatus(context, 'verified', true),
                        icon: const Icon(
                          Icons.check_circle_outline,
                          size: 16,
                          color: Color(0xFF059669),
                        ),
                        label: const Text(
                          'Approve',
                          style: TextStyle(color: Color(0xFF059669)),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF059669)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _updateStatus(context, 'rejected', false),
                        icon: const Icon(
                          Icons.cancel_outlined,
                          size: 16,
                          color: Color(0xFFDC2626),
                        ),
                        label: const Text(
                          'Reject',
                          style: TextStyle(color: Color(0xFFDC2626)),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFDC2626)),
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
        ],
      ),
    );
  }
}
