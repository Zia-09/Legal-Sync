import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:legal_sync/services/hearing_service.dart';
import 'package:legal_sync/provider/hearing_provider.dart';

class HearingResponseScreen extends ConsumerStatefulWidget {
  final String hearingId;

  const HearingResponseScreen({required this.hearingId, super.key});

  @override
  ConsumerState<HearingResponseScreen> createState() =>
      _HearingResponseScreenState();
}

class _HearingResponseScreenState extends ConsumerState<HearingResponseScreen> {
  String? _selectedResponse;
  bool _isLoading = false;

  Future<void> _submitResponse(String status) async {
    setState(() => _isLoading = true);

    try {
      final hearingService = HearingService();
      final currentUser = await _getCurrentUserId();

      if (currentUser == null) throw Exception('User not authenticated');

      await hearingService.updateParticipationStatus(
        hearingId: widget.hearingId,
        userId: currentUser,
        status: status,
      );

      if (!mounted) return;

      final statusText = status == 'accepted'
          ? 'confirmed your attendance'
          : status == 'declined'
          ? 'declined the hearing'
          : 'marked as busy';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ You have $statusText'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );

      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) Navigator.pop(context, true);
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: ${e.toString()}'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<String?> _getCurrentUserId() async {
    // This would typically come from your auth provider
    // For now, returning null - integrate with your actual auth
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final hearingAsync = ref.watch(getHearingByIdProvider(widget.hearingId));

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Hearing Invitation'),
        elevation: 0,
      ),
      body: hearingAsync.when(
        data: (hearing) {
          if (hearing == null) {
            return Center(
              child: Text(
                'Hearing not found',
                style: const TextStyle(color: Colors.white),
              ),
            );
          }

          final isUpcoming = hearing.hearingDate.isAfter(DateTime.now());

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Banner
                if (!isUpcoming)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B00).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFFF6B00).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: const [
                        Icon(
                          Icons.info_outline,
                          color: Color(0xFFFF6B00),
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'This hearing has already passed',
                            style: TextStyle(
                              color: Color(0xFFFF6B00),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Hearing Details Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF252525)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHearingDetailRow(
                        icon: Icons.calendar_today,
                        label: 'Date & Time',
                        value: DateFormat(
                          'MMMM dd, yyyy - hh:mm a',
                        ).format(hearing.hearingDate),
                      ),
                      const SizedBox(height: 16),
                      _buildHearingDetailRow(
                        icon: Icons.location_on,
                        label: 'Court',
                        value: hearing.courtName ?? 'To be confirmed by court',
                      ),
                      const SizedBox(height: 16),
                      _buildHearingDetailRow(
                        icon: Icons.video_call,
                        label: 'Mode',
                        value: hearing.modeOfConduct ?? 'Not specified',
                      ),
                      if (hearing.hearingType != null) ...[
                        const SizedBox(height: 16),
                        _buildHearingDetailRow(
                          icon: Icons.gavel,
                          label: 'Type',
                          value: hearing.hearingType!,
                        ),
                      ],
                      if (hearing.notes != null &&
                          hearing.notes!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(
                                  Icons.note,
                                  color: Color(0xFF9CA3AF),
                                  size: 16,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Notes',
                                  style: TextStyle(
                                    color: Color(0xFF9CA3AF),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              hearing.notes!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Response Options
                if (isUpcoming) ...[
                  Text(
                    'Will you attend this hearing?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildResponseOption(
                    statusCode: 'accepted',
                    label: 'Yes, I\'ll Attend',
                    description: 'Confirm your attendance',
                    icon: Icons.check_circle_outline,
                    color: const Color(0xFF10B981),
                    isSelected: _selectedResponse == 'accepted',
                    onTap: _isLoading
                        ? null
                        : () {
                            setState(() => _selectedResponse = 'accepted');
                          },
                  ),
                  const SizedBox(height: 10),
                  _buildResponseOption(
                    statusCode: 'busy',
                    label: 'I\'m Busy or Unsure',
                    description: 'You might not be able to attend',
                    icon: Icons.schedule,
                    color: const Color(0xFFFF6B00),
                    isSelected: _selectedResponse == 'busy',
                    onTap: _isLoading
                        ? null
                        : () {
                            setState(() => _selectedResponse = 'busy');
                          },
                  ),
                  const SizedBox(height: 10),
                  _buildResponseOption(
                    statusCode: 'declined',
                    label: 'No, I Can\'t Attend',
                    description: 'Cannot attend this hearing',
                    icon: Icons.cancel_outlined,
                    color: const Color(0xFFEF4444),
                    isSelected: _selectedResponse == 'declined',
                    onTap: _isLoading
                        ? null
                        : () {
                            setState(() => _selectedResponse = 'declined');
                          },
                  ),
                  const SizedBox(height: 24),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _selectedResponse == null || _isLoading
                          ? null
                          : () => _submitResponse(_selectedResponse!),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6B00),
                        disabledBackgroundColor: const Color(0xFF6B6B6B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Confirm Response',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                    ),
                  ),
                ] else ...[
                  // Past Hearing Info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF252525)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(
                              Icons.info_outline,
                              color: Color(0xFFFF6B00),
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'This hearing has already taken place',
                              style: TextStyle(
                                color: Color(0xFFFF6B00),
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (hearing.status == 'completed') ...[
                          const Text(
                            'Status: Completed',
                            style: TextStyle(
                              color: Color(0xFF10B981),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (hearing.hearingFeedback != null) ...[
                            const SizedBox(height: 12),
                            const Text(
                              'Feedback:',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              hearing.hearingFeedback!,
                              style: const TextStyle(
                                color: Color(0xFFC0C0C0),
                                fontSize: 13,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B00)),
          ),
        ),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Color(0xFFEF4444),
                size: 48,
              ),
              const SizedBox(height: 16),
              const Text(
                'Error loading hearing details',
                style: TextStyle(
                  color: Color(0xFFEF4444),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHearingDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFFFF6B00), size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResponseOption({
    required String statusCode,
    required String label,
    required String description,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.15)
              : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : const Color(0xFF252525),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected) Icon(Icons.check_circle, color: color, size: 22),
          ],
        ),
      ),
    );
  }
}
