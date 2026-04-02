import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:legal_sync/services/hearing_service.dart';
import 'package:legal_sync/provider/hearing_provider.dart';

class HearingCheckInScreen extends ConsumerStatefulWidget {
  final String hearingId;

  const HearingCheckInScreen({required this.hearingId, super.key});

  @override
  ConsumerState<HearingCheckInScreen> createState() =>
      _HearingCheckInScreenState();
}

class _HearingCheckInScreenState extends ConsumerState<HearingCheckInScreen> {
  bool? _attended;
  bool _isLoading = false;

  Future<void> _submitCheckIn(bool attended) async {
    setState(() => _isLoading = true);

    try {
      final hearingService = HearingService();
      final currentUser = await _getCurrentUserId();

      if (currentUser == null) throw Exception('User not authenticated');

      await hearingService.markAttendance(
        hearingId: widget.hearingId,
        userId: currentUser,
        attended: attended,
      );

      if (!mounted) return;

      final message = attended
          ? '✅ Attendance recorded - Thank you for joining!'
          : '✅ Absence recorded - We noted you couldn\'t attend';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: const Color(0xFF10B981),
          duration: const Duration(seconds: 3),
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
    // Integrate with your auth provider
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final hearingAsync = ref.watch(getHearingByIdProvider(widget.hearingId));

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Hearing Check-In'),
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

          final now = DateTime.now();
          final hourBeforeHearing = hearing.hearingDate.subtract(
            const Duration(hours: 1),
          );
          final hourAfterHearing = hearing.hearingDate.add(
            const Duration(hours: 1),
          );
          final canCheckIn =
              now.isAfter(hourBeforeHearing) && now.isBefore(hourAfterHearing);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const SizedBox(height: 16),

                // Large Clock Icon
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B00).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(
                      color: const Color(0xFFFF6B00).withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.access_time,
                    size: 64,
                    color: Color(0xFFFF6B00),
                  ),
                ),
                const SizedBox(height: 24),

                // Title
                const Text(
                  'Hearing Check-In',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // Status message
                if (!canCheckIn)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B00).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFFF6B00).withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Text(
                      'You can check in 1 hour before until 1 hour after the hearing time',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFFFF6B00), fontSize: 13),
                    ),
                  )
                else
                  const Text(
                    'It\'s time for your hearing. Let us know if you joined.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
                  ),
                const SizedBox(height: 32),

                // Hearing Details
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
                      _buildDetailItem(
                        icon: Icons.calendar_today,
                        title: 'Date & Time',
                        value: DateFormat(
                          'MMMM dd, yyyy - hh:mm a',
                        ).format(hearing.hearingDate),
                      ),
                      const SizedBox(height: 12),
                      _buildDetailItem(
                        icon: Icons.location_on,
                        title: 'Court',
                        value: hearing.courtName ?? 'To be confirmed by court',
                      ),
                      const SizedBox(height: 12),
                      _buildDetailItem(
                        icon: Icons.video_call,
                        title: 'Mode',
                        value: hearing.modeOfConduct ?? 'Not specified',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Check-In Options
                const Text(
                  'Did you join the hearing?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),

                // Yes, I Joined
                _buildCheckInOption(
                  isSelected: _attended == true,
                  onTap: canCheckIn && !_isLoading
                      ? () => setState(() => _attended = true)
                      : null,
                  icon: Icons.check_circle_outline,
                  label: 'Yes, I Joined',
                  description: 'I attended the hearing',
                  color: const Color(0xFF10B981),
                ),
                const SizedBox(height: 12),

                // No, I Couldn\'t Join
                _buildCheckInOption(
                  isSelected: _attended == false,
                  onTap: canCheckIn && !_isLoading
                      ? () => setState(() => _attended = false)
                      : null,
                  icon: Icons.cancel_outlined,
                  label: 'No, I Couldn\'t Join',
                  description: 'I was unable to attend',
                  color: const Color(0xFFEF4444),
                ),
                const SizedBox(height: 32),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (_attended == null || _isLoading || !canCheckIn)
                        ? null
                        : () => _submitCheckIn(_attended!),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B00),
                      disabledBackgroundColor: const Color(0xFF6B6B6B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
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
                            'Confirm Check-In',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // Info Box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B00).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFFF6B00).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Color(0xFFFF6B00),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          canCheckIn
                              ? 'Your response helps us maintain accurate records'
                              : 'Check-in window closed. Contact your lawyer if needed.',
                          style: const TextStyle(
                            color: Color(0xFFFF6B00),
                            fontSize: 12,
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
                'Error loading hearing',
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

  Widget _buildDetailItem({
    required IconData icon,
    required String title,
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
                title,
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

  Widget _buildCheckInOption({
    required bool isSelected,
    required VoidCallback? onTap,
    required IconData icon,
    required String label,
    required String description,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.15)
              : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : const Color(0xFF252525),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
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
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
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
            if (isSelected) Icon(Icons.check_circle, color: color, size: 24),
          ],
        ),
      ),
    );
  }
}
