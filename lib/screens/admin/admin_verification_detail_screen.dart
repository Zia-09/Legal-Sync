import 'package:flutter/material.dart';
import 'package:legal_sync/model/lawyer_Model.dart';
import 'package:legal_sync/services/lawyer_services.dart';

class AdminVerificationDetailScreen extends StatefulWidget {
  final LawyerModel lawyer;
  const AdminVerificationDetailScreen({super.key, required this.lawyer});

  @override
  State<AdminVerificationDetailScreen> createState() =>
      _AdminVerificationDetailScreenState();
}

class _AdminVerificationDetailScreenState
    extends State<AdminVerificationDetailScreen> {
  int _selectedTabIndex = 0;

  void _updateStatus(
    BuildContext context,
    String newStatus,
    bool isApproved,
  ) async {
    try {
      await LawyerService().updateLawyer(
        lawyerId: widget.lawyer.lawyerId,
        data: {'isApproved': isApproved, 'approvalStatus': newStatus},
      );
      if (!context.mounted) return;
      if (isApproved) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification Email sent to ${widget.lawyer.email}!'),
            backgroundColor: const Color(0xFF059669),
          ),
        );
      }
      Navigator.pop(context);
    } catch (e) {
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
    final l = widget.lawyer;
    final isPending =
        l.approvalStatus.toLowerCase() == 'pending' ||
        (!l.isApproved && l.approvalStatus.toLowerCase() != 'rejected');

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Lawyer Details',
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
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz, color: Color(0xFF1F2937)),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Info
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: const Color(0xFF1E3A8A),
                        child: l.profileImage != null
                            ? ClipOval(
                                child: Image.network(
                                  l.profileImage!,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 40,
                              ),
                      ),
                      if (isPending)
                        const CircleAvatar(
                          radius: 12,
                          backgroundColor: Color(0xFFE67E22),
                          child: Icon(
                            Icons.hourglass_empty,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isPending
                              ? const Color(0xFFFEF3C7)
                              : const Color(0xFFD1FAE5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isPending
                              ? 'Verification Pending'
                              : (l.isApproved ? 'Verified' : 'Rejected'),
                          style: TextStyle(
                            color: isPending
                                ? const Color(0xFFD97706)
                                : (l.isApproved
                                      ? const Color(0xFF059669)
                                      : const Color(0xFFDC2626)),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '• ${l.specialization}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Internal Tabs
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _SubTab(
                        title: 'Personal Info',
                        isSelected: _selectedTabIndex == 0,
                        onTap: () => setState(() => _selectedTabIndex = 0),
                      ),
                      _SubTab(
                        title: 'Credentials',
                        isSelected: _selectedTabIndex == 1,
                        onTap: () => setState(() => _selectedTabIndex = 1),
                      ),
                      _SubTab(
                        title: 'Documents',
                        isSelected: _selectedTabIndex == 2,
                        onTap: () => setState(() => _selectedTabIndex = 2),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Content Form
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_selectedTabIndex == 0) ...[
                    const Text(
                      'Identity Details',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          _DetailRow(label: 'Email', value: l.email),
                          const Divider(height: 24),
                          _DetailRow(label: 'Mobile', value: l.phone),
                          const Divider(height: 24),
                          _DetailRow(
                            label: 'Location',
                            value: l.location ?? 'Not provided',
                          ),
                        ],
                      ),
                    ),
                  ] else if (_selectedTabIndex == 1) ...[
                    const Text(
                      'Professional Credentials',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          _DetailRow(
                            label: 'Specialization',
                            value: l.specialization,
                          ),
                          const Divider(height: 24),
                          _DetailRow(
                            label: 'Experience',
                            value: l.experience ?? 'N/A',
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    const Text(
                      'Documents',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          if (l.idCardDocument != null) ...[
                            ListTile(
                              leading: const Icon(
                                Icons.picture_as_pdf,
                                color: Colors.red,
                              ),
                              title: const Text(
                                'ID Card / Bar Council Document',
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.open_in_new),
                                onPressed: () {
                                  // Open logic
                                },
                              ),
                            ),
                          ] else ...[
                            const Center(child: Text("No documents uploaded.")),
                          ],
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 48),

                  if (isPending) ...[
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                _updateStatus(context, 'rejected', false),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFDC2626),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: const Icon(Icons.close, color: Colors.white),
                            label: const Text(
                              'Reject',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                _updateStatus(context, 'verified', true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF059669),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: const Icon(Icons.check, color: Colors.white),
                            label: const Text(
                              'Approve',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubTab extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;
  const _SubTab({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? const Color(0xFF1E3A8A) : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? const Color(0xFF1E3A8A) : Colors.grey,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }
}
