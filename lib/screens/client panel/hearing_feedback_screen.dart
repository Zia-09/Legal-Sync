import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:legal_sync/services/hearing_service.dart';
import 'package:legal_sync/provider/hearing_provider.dart';

class HearingFeedbackScreen extends ConsumerStatefulWidget {
  final String hearingId;

  const HearingFeedbackScreen({required this.hearingId, super.key});

  @override
  ConsumerState<HearingFeedbackScreen> createState() =>
      _HearingFeedbackScreenState();
}

class _HearingFeedbackScreenState extends ConsumerState<HearingFeedbackScreen> {
  late TextEditingController _feedbackController;
  int _selectedRating = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _feedbackController = TextEditingController();
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (_feedbackController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please share your feedback'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final hearingService = HearingService();
      final currentUser = await _getCurrentUserId();

      if (currentUser == null) throw Exception('User not authenticated');

      await hearingService.submitHearingFeedback(
        hearingId: widget.hearingId,
        userId: currentUser,
        feedback: _feedbackController.text.trim(),
        qualityRating: _selectedRating > 0 ? _selectedRating : null,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Feedback submitted successfully'),
          backgroundColor: Color(0xFF10B981),
          duration: Duration(seconds: 2),
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
        title: const Text('Hearing Feedback'),
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

          final isAfterHearing = DateTime.now().isAfter(hearing.hearingDate);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status
                if (!isAfterHearing)
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
                    child: const Text(
                      'Please share your feedback after the hearing concludes',
                      style: TextStyle(color: Color(0xFFFF6B00), fontSize: 13),
                    ),
                  )
                else
                  const Text(
                    'Thank you for attending. Please share your experience.',
                    style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
                  ),
                const SizedBox(height: 16),

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
                      _buildDetailRow(
                        icon: Icons.calendar_today,
                        label: 'Hearing Date',
                        value: DateFormat(
                          'MMMM dd, yyyy - hh:mm a',
                        ).format(hearing.hearingDate),
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        icon: Icons.location_on,
                        label: 'Court',
                        value: hearing.courtName ?? 'Not specified',
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        icon: Icons.gavel,
                        label: 'Type',
                        value: hearing.hearingType ?? 'General Hearing',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Rating
                Text(
                  'How was your experience?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Rate the quality of the hearing (optional)',
                  style: const TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),

                // Star Rating
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final rating = index + 1;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedRating = _selectedRating == rating
                                ? 0
                                : rating;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Icon(
                            _selectedRating >= rating
                                ? Icons.star
                                : Icons.star_border,
                            color: _selectedRating >= rating
                                ? const Color(0xFFFF6B00)
                                : const Color(0xFF6B6B6B),
                            size: 40,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 24),

                // Feedback Text
                Text(
                  'Share Your Feedback',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tell us about the hearing outcome, judge remarks, evidence presented, verdict expectations, or any other relevant details.',
                  style: const TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: _feedbackController,
                  maxLines: 8,
                  maxLength: 1000,
                  enabled: !_isLoading,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText:
                        'The hearing went well. The judge seemed favorable to our arguments. Evidence was presented clearly...',
                    hintStyle: const TextStyle(
                      color: Color(0xFF6B6B6B),
                      fontSize: 13,
                    ),
                    filled: true,
                    fillColor: const Color(0xFF1A1A1A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF252525)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF252525)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: Color(0xFFFF6B00),
                        width: 2,
                      ),
                    ),
                    counterStyle: const TextStyle(
                      color: Color(0xFF6B6B6B),
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitFeedback,
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
                            'Submit Feedback',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),

                // Cancel Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFF3A3A3A)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Skip for Now'),
                  ),
                ),
                const SizedBox(height: 16),

                // Info Box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Color(0xFF3B82F6),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Your feedback helps us maintain detailed case records and is valuable for future reference.',
                          style: const TextStyle(
                            color: Color(0xFF3B82F6),
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

  Widget _buildDetailRow({
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
}
