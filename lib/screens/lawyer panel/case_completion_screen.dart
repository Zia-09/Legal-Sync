import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:legal_sync/services/case_service.dart';
import 'package:legal_sync/provider/case_provider.dart';

class CaseCompletionScreen extends ConsumerStatefulWidget {
  final String caseId;

  const CaseCompletionScreen({required this.caseId, super.key});

  @override
  ConsumerState<CaseCompletionScreen> createState() =>
      _CaseCompletionScreenState();
}

class _CaseCompletionScreenState extends ConsumerState<CaseCompletionScreen> {
  late TextEditingController _notesController;
  String _selectedOutcome = 'won';
  bool _isLoading = false;

  final List<Map<String, dynamic>> _outcomes = [
    {
      'value': 'won',
      'label': 'Won (Favorable)',
      'icon': Icons.emoji_events,
      'color': Color(0xFF10B981),
      'description': "Court ruled in client's favor",
    },
    {
      'value': 'lost',
      'label': 'Lost (Unfavorable)',
      'icon': Icons.cancel,
      'color': Color(0xFFEF4444),
      'description': 'Court ruled against client',
    },
    {
      'value': 'settled',
      'label': 'Settled',
      'icon': Icons.handshake,
      'color': Color(0xFF3B82F6),
      'description': 'Both parties reached agreement',
    },
    {
      'value': 'dismissed',
      'label': 'Dismissed',
      'icon': Icons.gavel,
      'color': Color(0xFF8B5CF6),
      'description': 'Case thrown out or withdrawn',
    },
    {
      'value': 'appealed',
      'label': 'Appealed',
      'icon': Icons.trending_up,
      'color': Color(0xFFFF6B00),
      'description': 'Case appealed to higher court',
    },
  ];

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitCompletion() async {
    if (_notesController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter outcome details'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final caseService = CaseService();
      await caseService.markCaseWithOutcome(
        caseId: widget.caseId,
        outcome: _selectedOutcome,
        outcomeNotes: _notesController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Case marked as complete'),
          backgroundColor: Color(0xFF10B981),
        ),
      );

      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) Navigator.pop(context);
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: ${e.toString()}'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final caseAsync = ref.watch(getCaseByIdProvider(widget.caseId));

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Mark Case Complete'),
        elevation: 0,
      ),
      body: caseAsync.when(
        data: (caseModel) {
          if (caseModel == null) {
            return Center(
              child: Text(
                'Case not found',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Case Details Card
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
                      Text(
                        'Case Details',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow('Case ID', caseModel.caseId),
                      _buildDetailRow('Title', caseModel.title),
                      _buildDetailRow(
                        'Created',
                        DateFormat('MMM dd, yyyy').format(caseModel.createdAt),
                      ),
                      _buildDetailRow('Status', caseModel.status),
                      if (caseModel.completedHearings > 0)
                        _buildDetailRow(
                          'Hearings Completed',
                          '${caseModel.completedHearings}',
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Select Outcome
                Text(
                  'Select Case Outcome',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                ..._outcomes.map((outcome) {
                  final isSelected = _selectedOutcome == outcome['value'];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedOutcome = outcome['value']);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? outcome['color'].withValues(alpha: 0.15)
                              : const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? outcome['color']
                                : const Color(0xFF252525),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: outcome['color'].withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                outcome['icon'],
                                color: outcome['color'],
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    outcome['label'],
                                    style: TextStyle(
                                      color: outcome['color'],
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    outcome['description'],
                                    style: const TextStyle(
                                      color: Color(0xFF6B6B6B),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_circle,
                                color: outcome['color'],
                                size: 24,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 24),

                // Outcome Notes
                Text(
                  'Outcome Details & Notes',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Provide detailed information about the case outcome. This will be sent to the client.',
                  style: const TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _notesController,
                  maxLines: 6,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText:
                        'Court ruled in client favor. Awarded damages of 50,000 or more.',
                    hintStyle: const TextStyle(
                      color: Color(0xFF6B6B6B),
                      fontSize: 14,
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
                  ),
                ),
                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading
                            ? null
                            : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFF3A3A3A)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitCompletion,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6B00),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: const Color(0xFF6B6B6B),
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
                                'Mark Complete',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                      ),
                    ),
                  ],
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
                          'The client will receive an email notification with the outcome and your notes. Your case statistics will be updated automatically.',
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
              Text(
                'Error loading case',
                style: const TextStyle(
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
