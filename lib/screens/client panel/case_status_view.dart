import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:legal_sync/model/case_Model.dart';
import 'package:legal_sync/provider/case_provider.dart';
import 'package:legal_sync/provider/client_provider.dart';
import 'package:legal_sync/provider/hearing_provider.dart';
import 'package:legal_sync/provider/lawyer_provider.dart';
import 'package:legal_sync/provider/theme_provider.dart';
import 'package:legal_sync/services/case_service.dart';
import 'package:legal_sync/services/document_service.dart';
import 'package:legal_sync/provider/document_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:legal_sync/screens/client%20panel/messages_screen.dart'; // fallback
import 'package:legal_sync/screens/client%20panel/home_screen.dart';
import 'package:legal_sync/screens/client%20panel/app_setting_screen.dart';
import 'package:legal_sync/utils/animations.dart';
import 'chat_detail_screen.dart';

class CaseStatusScreen extends ConsumerStatefulWidget {
  const CaseStatusScreen({super.key});

  @override
  ConsumerState<CaseStatusScreen> createState() => _CaseStatusScreenState();
}

class _CaseStatusScreenState extends ConsumerState<CaseStatusScreen> {
  int _currentIndex = 2;
  int _selectedCaseIndex = 0;

  // ─── Timeline builder from real case data ────────────────────────────────
  List<_TimelineStep> _buildTimeline(CaseModel c) {
    final df = DateFormat('MMM dd');
    final steps = <_TimelineStep>[];

    // 1. Registered
    steps.add(
      _TimelineStep(
        date: df.format(c.createdAt),
        title: 'Case Registered',
        status: TimelineStatus.done,
        subtitle: 'Case successfully filed',
      ),
    );

    // 2. Lawyer assigned
    steps.add(
      _TimelineStep(
        date: '---',
        title: 'Lawyer Assigned',
        status: TimelineStatus.done,
        subtitle: 'Professional counsel assigned',
      ),
    );

    // 3. Current status
    final lower = c.status.toLowerCase();
    TimelineStatus currentSt = TimelineStatus.active;
    if (lower == 'closed' || lower == 'resolved' || lower == 'verdict') {
      currentSt = TimelineStatus.done;
    }
    steps.add(
      _TimelineStep(
        date: df.format(c.updatedAt ?? c.createdAt),
        title: 'Current: ${c.status.toUpperCase()}',
        status: currentSt,
        subtitle: c.remarks ?? 'Processing case details',
      ),
    );

    // 4. Hearing (if set)
    if (c.hearingDate != null) {
      final isPast = c.hearingDate!.isBefore(DateTime.now());
      steps.add(
        _TimelineStep(
          date: df.format(c.hearingDate!),
          title: 'Court Hearing',
          status: isPast ? TimelineStatus.done : TimelineStatus.pending,
          subtitle: c.courtName ?? 'Court room to be assigned',
        ),
      );
    }

    return steps;
  }

  double _calculateProgress(String status) {
    switch (status.toLowerCase()) {
      case 'registered':
        return 0.2;
      case 'lawyer assigned':
        return 0.4;
      case 'document verification':
        return 0.6;
      case 'hearing scheduled':
        return 0.8;
      case 'closed':
      case 'resolved':
      case 'verdict':
        return 1.0;
      default:
        return 0.3;
    }
  }

  // ─── File upload ─────────────────────────────────────────────────────────
  Future<void> _uploadFile(CaseModel currentCase, String clientId) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'png', 'docx'],
      );
      if (result == null) return;
      final path = result.files.single.path;
      if (path == null) return;
      final file = File(path);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Uploading document…'),
          backgroundColor: Color(0xFFFF6B00),
        ),
      );
      await DocumentService().uploadAndSaveDocument(
        file: file,
        caseId: currentCase.caseId,
        lawyerId: currentCase.lawyerId,
        uploadedBy: clientId,
        fileType: path.endsWith('.pdf')
            ? 'pdf'
            : (path.endsWith('.docx') ? 'doc' : 'image'),
        description: 'Uploaded by client',
        tags: ['client_upload'],
        isConfidential: false,
      );

      // Add to case document urls for backward compatibility with UI
      final docUrl = await DocumentService().uploadFile(
        file: file,
        caseId: currentCase.caseId,
        fileName: file.path.split('/').last,
      );
      await CaseService().addDocument(currentCase.caseId, docUrl);

      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Document uploaded successfully!'),
          backgroundColor: Color(0xFF059669),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAddNoteDialog(String caseId) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Add Case Note',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: Colors.white),
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Enter your note here…',
            hintStyle: const TextStyle(color: Color(0xFF6B6B6B)),
            filled: true,
            fillColor: const Color(0xFF2A2A2A),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF333333)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFFF6B00)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF6B6B6B)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Note added locally'),
                  backgroundColor: Color(0xFF059669),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B00),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Save Note',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final clientAsync = ref.watch(currentClientProvider);

    return clientAsync.when(
      data: (client) {
        if (client == null) {
          return _scaffoldWithContent(
            const Center(
              child: Text(
                'Please log in to view case status',
                style: TextStyle(color: Colors.white),
              ),
            ),
          );
        }

        return ref
            .watch(casesByClientProvider(client.clientId))
            .when(
              data: (cases) {
                if (cases.isEmpty) return _buildEmptyState();

                if (_selectedCaseIndex >= cases.length) _selectedCaseIndex = 0;
                final currentCase = cases[_selectedCaseIndex];
                final timeline = _buildTimeline(currentCase);
                final progress = _calculateProgress(currentCase.status);

                final themeMode = ref.watch(themeModeProvider);
                final isDark =
                    themeMode.value == ThemeMode.dark ||
                    (themeMode.value == ThemeMode.system &&
                        MediaQuery.of(context).platformBrightness ==
                            Brightness.dark);

                final bgColor = isDark
                    ? const Color(0xFF0F0F0F)
                    : const Color(0xFFF8F9FA);
                final cardColor = isDark
                    ? const Color(0xFF1E1E1E)
                    : const Color(0xFFFFFFFF);
                final textColor = isDark
                    ? Colors.white
                    : const Color(0xFF1A1A1A);
                final subTextColor = isDark
                    ? const Color(0xFF9E9E9E)
                    : const Color(0xFF6C757D);
                final borderColor = isDark
                    ? const Color(0xFF2A2A2A)
                    : const Color(0xFFE9ECEF);

                return Scaffold(
                  backgroundColor: bgColor,
                  body: SafeArea(
                    child: Column(
                      children: [
                        // ── Header ──────────────────────────────────────────
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                          child: Row(
                            children: [
                              const SizedBox(width: 40),
                              const Expanded(
                                child: Center(
                                  child: Text(
                                    'Case Status',
                                    style: TextStyle(
                                      color: Colors
                                          .white, // Explicitly white for premium look
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              PopupMenuButton<String>(
                                icon: Icon(
                                  Icons.more_vert,
                                  color: textColor,
                                  size: 20,
                                ),
                                color: cardColor,
                                onSelected: (v) {
                                  if (v == 'refresh') setState(() {});
                                },
                                itemBuilder: (_) => [
                                  PopupMenuItem(
                                    value: 'refresh',
                                    child: Text(
                                      'Refresh',
                                      style: TextStyle(color: textColor),
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'help',
                                    child: Text(
                                      'Get Help',
                                      style: TextStyle(color: textColor),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // ── Multi-case selector ──────────────────────────────
                        if (cases.length > 1) _buildCaseSelector(cases),

                        const SizedBox(height: 16),

                        Expanded(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // ── Case Summary Card ───────────────────────
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: cardColor,
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(color: borderColor),
                                    boxShadow: [
                                      if (!isDark)
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.03,
                                          ),
                                          blurRadius: 15,
                                          offset: const Offset(0, 8),
                                        ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 50,
                                            height: 50,
                                            decoration: BoxDecoration(
                                              color: const Color(
                                                0xFFFF6B00,
                                              ).withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            child: const Icon(
                                              Icons.gavel_rounded,
                                              color: Color(0xFFFF6B00),
                                              size: 24,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  currentCase.caseNumber != null
                                                      ? 'Case # ${currentCase.caseNumber}'
                                                      : 'Case # ${currentCase.caseId.substring(0, 8).toUpperCase()}',
                                                  style: const TextStyle(
                                                    color: Color(0xFFFF6B00),
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  currentCase.title,
                                                  style: TextStyle(
                                                    color: textColor,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 24),
                                      Divider(color: borderColor, height: 1),
                                      const SizedBox(height: 20),
                                      Row(
                                        children: [
                                          _buildInfoColumn(
                                            'Court',
                                            currentCase.courtName ?? 'Pending',
                                            subTextColor,
                                            textColor,
                                          ),
                                          _buildInfoColumn(
                                            'Filed',
                                            DateFormat(
                                              'MMM dd, yyyy',
                                            ).format(currentCase.createdAt),
                                            subTextColor,
                                            textColor,
                                          ),
                                          _buildInfoColumn(
                                            'Type',
                                            currentCase.caseType ?? 'General',
                                            subTextColor,
                                            textColor,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // ── Case Progress ────────────────────────────
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Case progress',
                                          style: TextStyle(
                                            color: textColor,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          '${(progress * 100).toInt()} %',
                                          style: const TextStyle(
                                            color: Color(0xFFFF6B00),
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(100),
                                      child: LinearProgressIndicator(
                                        value: progress,
                                        backgroundColor: borderColor,
                                        valueColor:
                                            const AlwaysStoppedAnimation<Color>(
                                              Color(0xFFFF6B00),
                                            ),
                                        minHeight: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),

                                // ── Timeline ───────────────────────────────
                                Text(
                                  'Case Timeline',
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: cardColor,
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(color: borderColor),
                                  ),
                                  child: Column(
                                    children: List.generate(
                                      timeline.length,
                                      (i) => _TimelineTile(
                                        step: timeline[i],
                                        isLast: i == timeline.length - 1,
                                        isDark: isDark,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // ── Case Consultant ────────────────────────
                                Text(
                                  'Case Consultant',
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Consumer(
                                  builder: (context, r, _) {
                                    final lawyerAsync = r.watch(
                                      getLawyerByIdProvider(
                                        currentCase.lawyerId,
                                      ),
                                    );
                                    return lawyerAsync.when(
                                      data: (lawyer) {
                                        if (lawyer == null) {
                                          return Container(
                                            padding: const EdgeInsets.all(20),
                                            decoration: BoxDecoration(
                                              color: cardColor,
                                              borderRadius:
                                                  BorderRadius.circular(24),
                                              border: Border.all(
                                                color: borderColor,
                                              ),
                                            ),
                                            child: Text(
                                              'Lawyer not yet assigned',
                                              style: TextStyle(
                                                color: subTextColor,
                                              ),
                                            ),
                                          );
                                        }
                                        return Container(
                                          padding: const EdgeInsets.all(24),
                                          decoration: BoxDecoration(
                                            color: cardColor,
                                            borderRadius: BorderRadius.circular(
                                              30,
                                            ),
                                            border: Border.all(
                                              color: borderColor,
                                            ),
                                            boxShadow: [
                                              if (!isDark)
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.02),
                                                  blurRadius: 15,
                                                  offset: const Offset(0, 5),
                                                ),
                                            ],
                                          ),
                                          child: Column(
                                            children: [
                                              Center(
                                                child: Stack(
                                                  children: [
                                                    Container(
                                                      width: 80,
                                                      height: 80,
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        border: Border.all(
                                                          color: const Color(
                                                            0xFFFF6B00,
                                                          ),
                                                          width: 2.5,
                                                        ),
                                                      ),
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets.all(
                                                              3.0,
                                                            ),
                                                        child: CircleAvatar(
                                                          radius: 36,
                                                          backgroundColor:
                                                              borderColor,
                                                          backgroundImage:
                                                              (lawyer.profileImage !=
                                                                      null &&
                                                                  lawyer
                                                                      .profileImage!
                                                                      .isNotEmpty)
                                                              ? NetworkImage(
                                                                  lawyer
                                                                      .profileImage!,
                                                                )
                                                              : null,
                                                          child:
                                                              (lawyer.profileImage ==
                                                                      null ||
                                                                  lawyer
                                                                      .profileImage!
                                                                      .isEmpty)
                                                              ? _lawyerInitials(
                                                                  lawyer.name,
                                                                )
                                                              : null,
                                                        ),
                                                      ),
                                                    ),
                                                    Positioned(
                                                      right: 4,
                                                      bottom: 4,
                                                      child: Container(
                                                        width: 14,
                                                        height: 14,
                                                        decoration:
                                                            BoxDecoration(
                                                              color:
                                                                  const Color(
                                                                    0xFF059669,
                                                                  ),
                                                              shape: BoxShape
                                                                  .circle,
                                                              border: Border.all(
                                                                color:
                                                                    cardColor,
                                                                width: 2,
                                                              ),
                                                            ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(height: 16),
                                              Text(
                                                lawyer.name,
                                                style: TextStyle(
                                                  color: textColor,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                lawyer.specialization,
                                                style: TextStyle(
                                                  color: subTextColor,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              const SizedBox(height: 24),
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child:
                                                        _buildConsultantAction(
                                                          label: 'Call now',
                                                          icon: Icons
                                                              .phone_outlined,
                                                          color: const Color(
                                                            0xFF7C3AED,
                                                          ),
                                                          onTap: () {},
                                                        ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: _buildConsultantAction(
                                                      label: 'Chat',
                                                      icon: Icons
                                                          .chat_bubble_outline,
                                                      color: const Color(
                                                        0xFF059669,
                                                      ),
                                                      onTap: () => Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (_) =>
                                                              ChatDetailScreen(
                                                                receiverId: lawyer
                                                                    .lawyerId,
                                                                lawyer: lawyer,
                                                              ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                      loading: () => Container(
                                        height: 150,
                                        decoration: BoxDecoration(
                                          color: cardColor,
                                          borderRadius: BorderRadius.circular(
                                            24,
                                          ),
                                        ),
                                        child: const Center(
                                          child: CircularProgressIndicator(
                                            color: Color(0xFFFF6B00),
                                          ),
                                        ),
                                      ),
                                      error: (e, _) => Text(
                                        'Error: $e',
                                        style: TextStyle(color: subTextColor),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 24),

                                // ── Hearing Updates ──────────────────────────
                                _HearingUpdatesSection(
                                  caseIds: cases.map((c) => c.caseId).toList(),
                                ),
                                const SizedBox(height: 24),

                                // ── Case Documents ───────────────────────────
                                _CaseDocumentsSection(
                                  caseId: currentCase.caseId,
                                  clientId: client.clientId,
                                  onUploadTap: () =>
                                      _uploadFile(currentCase, client.clientId),
                                ),
                                const SizedBox(height: 24),

                                // ── Quick Actions ────────────────────────────
                                Text(
                                  'Quick Actions',
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                GridView.count(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 2.4,
                                  children: [
                                    _QuickActionButton(
                                      label: 'Upload File',
                                      icon: Icons.upload_file,
                                      color: const Color(0xFFFF6B00),
                                      onTap: () => _uploadFile(
                                        currentCase,
                                        client.clientId,
                                      ),
                                    ),
                                    _QuickActionButton(
                                      label: 'Schedule',
                                      icon: Icons.calendar_month_outlined,
                                      color: const Color(0xFF2563EB),
                                      onTap: () {},
                                    ),
                                    _QuickActionButton(
                                      label: 'Add Notes',
                                      icon: Icons.note_add_outlined,
                                      color: const Color(0xFF7C3AED),
                                      onTap: () => _showAddNoteDialog(
                                        currentCase.caseId,
                                      ),
                                    ),
                                    _QuickActionButton(
                                      label: 'Support',
                                      icon: Icons.support_agent,
                                      color: const Color(0xFF059669),
                                      onTap: () {},
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 30),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  bottomNavigationBar: _buildBottomNav(context),
                );
              },
              loading: () => Scaffold(
                backgroundColor: const Color(0xFF0F0F0F),
                body: const Center(
                  child: CircularProgressIndicator(color: Color(0xFFFF6B00)),
                ),
              ),
              error: (e, _) => Scaffold(
                backgroundColor: const Color(0xFF0F0F0F),
                body: Center(
                  child: Text(
                    'Error: $e',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            );
      },
      loading: () => Scaffold(
        backgroundColor: const Color(0xFF0F0F0F),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFFFF6B00)),
        ),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: const Color(0xFF0F0F0F),
        body: Center(
          child: Text(
            'Auth error: $e',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
    );
  }

  // ─── Small helpers ────────────────────────────────────────────────────────
  Widget _lawyerInitials(String name) => Center(
    child: Text(
      name.isNotEmpty ? name[0].toUpperCase() : 'L',
      style: const TextStyle(
        color: Color(0xFFFF6B00),
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    ),
  );

  Widget _scaffoldWithContent(Widget content) => Scaffold(
    backgroundColor: const Color(0xFF0F0F0F),
    body: SafeArea(child: content),
  );

  Widget _buildInfoColumn(
    String label,
    String value,
    Color labelColor,
    Color valueColor,
  ) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: labelColor,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildConsultantAction({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() => _scaffoldWithContent(
    Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.folder_open, color: Color(0xFF3A3A3A), size: 64),
          const SizedBox(height: 16),
          const Text(
            'No active cases found',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B00),
            ),
            child: const Text('Go to Home'),
          ),
        ],
      ),
    ),
  );

  Widget _buildCaseSelector(List<CaseModel> cases) {
    return Container(
      height: 48,
      margin: const EdgeInsets.only(top: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: cases.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedCaseIndex == index;
          final caseItem = cases[index];

          // Display case reference (number or title)
          final caseLabel = caseItem.caseNumber?.isNotEmpty == true
              ? caseItem.caseNumber!
              : caseItem.title.length > 15
              ? '${caseItem.title.substring(0, 15)}...'
              : caseItem.title;

          return AnimationUtils.scaleAnimation(
            child: GestureDetector(
              onTap: () => setState(() => _selectedCaseIndex = index),
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFFF6B00)
                      : const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? Colors.transparent
                        : const Color(0xFF2A2A2A),
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        caseLabel,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF9E9E9E),
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        caseItem.status.toUpperCase(),
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white70
                              : const Color(0xFF6B6B6B),
                          fontSize: 9,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark =
        themeMode.value == ThemeMode.dark ||
        (themeMode.value == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);

    final navBgColor = isDark ? const Color(0xFF141414) : Colors.white;
    final navBorderColor = isDark
        ? const Color(0xFF1E1E1E)
        : const Color(0xFFE9ECEF);
    final unselectedColor = isDark ? const Color(0xFF5A5A5A) : Colors.grey;

    final items = [
      {'icon': Icons.home_outlined, 'activeIcon': Icons.home, 'label': 'Home'},
      {
        'icon': Icons.balance_outlined,
        'activeIcon': Icons.balance,
        'label': 'Lawyer',
      },
      {
        'icon': Icons.folder_outlined,
        'activeIcon': Icons.folder,
        'label': 'Cases',
      },
      {
        'icon': Icons.chat_bubble_outline,
        'activeIcon': Icons.chat_bubble,
        'label': 'Chat',
      },
      {
        'icon': Icons.settings_outlined,
        'activeIcon': Icons.settings,
        'label': 'Setting',
      },
    ];
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: navBgColor,
        border: Border(top: BorderSide(color: navBorderColor, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isActive = _currentIndex == index;
          return GestureDetector(
            onTap: () {
              if (index == 0) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                  (_) => false,
                );
              } else if (index == 3) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MessagesScreen()),
                );
              } else if (index == 4) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AppSettingScreen()),
                );
              } else {
                setState(() => _currentIndex = index);
              }
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isActive
                      ? item['activeIcon'] as IconData
                      : item['icon'] as IconData,
                  color: isActive ? const Color(0xFFFF6B00) : unselectedColor,
                  size: 24,
                ),
                const SizedBox(height: 4),
                Text(
                  item['label'] as String,
                  style: TextStyle(
                    color: isActive ? const Color(0xFFFF6B00) : unselectedColor,
                    fontSize: 10,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ─── Hearing Updates Section (real data) ────────────────────────────────────

class _HearingUpdatesSection extends ConsumerWidget {
  final List<String> caseIds;
  const _HearingUpdatesSection({required this.caseIds});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hearingsAsync = ref.watch(streamHearingsByCaseIdsProvider(caseIds));
    final themeMode = ref.watch(themeModeProvider);
    final isDark =
        themeMode.value == ThemeMode.dark ||
        (themeMode.value == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);

    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final subTextColor = isDark
        ? const Color(0xFF6B6B6B)
        : const Color(0xFF6C757D);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Hearing Updates',
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (hearingsAsync.value != null && hearingsAsync.value!.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B00).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${hearingsAsync.value!.length} Upcoming',
                  style: const TextStyle(
                    color: Color(0xFFFF6B00),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        hearingsAsync.when(
          data: (hearings) {
            if (hearings.isEmpty) {
              return Text(
                'No upcoming hearings scheduled yet',
                style: TextStyle(color: subTextColor, fontSize: 13),
              );
            }
            return Column(
              children: [
                for (int i = 0; i < hearings.length; i++) ...[
                  _HearingUpdateCard(
                    date: DateFormat(
                      'MMM dd, HH:mm',
                    ).format(hearings[i].hearingDate),
                    title: hearings[i].hearingType ?? 'Hearing',
                    subtitle:
                        hearings[i].courtName ?? 'Court room to be assigned',
                    description: hearings[i].notes,
                    isRecent: i == 0,
                    isDark: isDark,
                  ),
                  if (i < hearings.length - 1) const SizedBox(height: 10),
                ],
              ],
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(
              color: Color(0xFFFF6B00),
              strokeWidth: 2,
            ),
          ),
          error: (e, _) => Text(
            'Error loading hearings: $e',
            style: TextStyle(color: Colors.red.shade400, fontSize: 12),
          ),
        ),
      ],
    );
  }
}

// ─── Supporting widgets (retained from original UI) ──────────────────────────

enum TimelineStatus { done, active, pending }

class _TimelineStep {
  final String date;
  final String title;
  final TimelineStatus status;
  final String subtitle;
  const _TimelineStep({
    required this.date,
    required this.title,
    required this.status,
    required this.subtitle,
  });
}

class _TimelineTile extends StatelessWidget {
  final _TimelineStep step;
  final bool isLast;
  final bool isDark;
  const _TimelineTile({
    required this.step,
    required this.isLast,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final subTextColor = isDark
        ? const Color(0xFF6B6B6B)
        : const Color(0xFF8E8E8E);
    final dotColor = step.status == TimelineStatus.done
        ? const Color(0xFF059669)
        : (step.status == TimelineStatus.active
              ? const Color(0xFFFF6B00)
              : subTextColor);

    final dotIcon = step.status == TimelineStatus.done
        ? Icons.check_circle
        : (step.status == TimelineStatus.active
              ? Icons.radio_button_checked
              : Icons.radio_button_unchecked);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 54,
            child: Text(
              step.date,
              style: const TextStyle(color: Color(0xFF6B6B6B), fontSize: 11),
            ),
          ),
          Column(
            children: [
              Icon(dotIcon, color: dotColor, size: 20),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: const Color(0xFF252525),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: TextStyle(
                      color: step.status == TimelineStatus.pending
                          ? subTextColor
                          : (isDark ? Colors.white : const Color(0xFF1A1A1A)),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    step.subtitle,
                    style: const TextStyle(
                      color: Color(0xFF6B6B6B),
                      fontSize: 11,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HearingUpdateCard extends StatelessWidget {
  final String date;
  final String title;
  final String subtitle;
  final String? description;
  final bool isRecent;
  final bool isDark;

  const _HearingUpdateCard({
    required this.date,
    required this.title,
    required this.subtitle,
    this.description,
    required this.isRecent,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark
        ? const Color(0xFF1A1A1A)
        : const Color(0xFFFFFFFF);
    final borderColor = isDark
        ? const Color(0xFF252525)
        : const Color(0xFFE9ECEF);
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final subTextColor = isDark
        ? const Color(0xFF9E9E9E)
        : const Color(0xFF6C757D);
    final descBgColor = isDark
        ? const Color(0xFF2A2A2A)
        : const Color(0xFFF0F0F0);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isRecent
              ? const Color(0xFFFF6B00).withValues(alpha: 0.3)
              : borderColor,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isRecent
                  ? const Color(0xFFFF6B00).withValues(alpha: 0.12)
                  : borderColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isRecent ? Icons.gavel : Icons.history,
              color: isRecent ? const Color(0xFFFF6B00) : subTextColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date,
                  style: TextStyle(
                    color: isRecent ? const Color(0xFFFF6B00) : subTextColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  title,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(color: subTextColor, fontSize: 11),
                ),
                if (description != null && description!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: descBgColor.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: borderColor),
                    ),
                    child: Text(
                      description!,
                      style: TextStyle(
                        color: subTextColor,
                        fontSize: 11,
                        height: 1.3,
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

class _QuickActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _QuickActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Case Documents Section -------------------------------------------------
class _CaseDocumentsSection extends ConsumerWidget {
  final String caseId;
  final String clientId;
  final VoidCallback onUploadTap;

  const _CaseDocumentsSection({
    required this.caseId,
    required this.clientId,
    required this.onUploadTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docsAsync = ref.watch(documentsByCaseProvider(caseId));
    final themeMode = ref.watch(themeModeProvider);
    final isDark =
        themeMode.value == ThemeMode.dark ||
        (themeMode.value == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);

    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final cardColor = isDark
        ? const Color(0xFF1E1E1E)
        : const Color(0xFFFFFFFF);
    final borderColor = isDark
        ? const Color(0xFF2A2A2A)
        : const Color(0xFFE9ECEF);
    final subTextColor = isDark
        ? const Color(0xFF6B6B6B)
        : const Color(0xFF6C757D);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Case Documents',
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            GestureDetector(
              onTap: onUploadTap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B00).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFFF6B00).withValues(alpha: 0.4),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.upload_file, color: Color(0xFFFF6B00), size: 16),
                    SizedBox(width: 4),
                    Text(
                      'Upload',
                      style: TextStyle(
                        color: Color(0xFFFF6B00),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        docsAsync.when(
          data: (docs) {
            final visible = docs
                .where(
                  (d) =>
                      (d.isApprovedForClient || d.uploadedBy == clientId) &&
                      !d.isRejected,
                )
                .toList();
            if (visible.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Icon(Icons.folder_open, color: subTextColor),
                    const SizedBox(width: 12),
                    Text(
                      'No documents available yet',
                      style: TextStyle(color: subTextColor),
                    ),
                  ],
                ),
              );
            }
            return Column(
              children: visible
                  .map(
                    (doc) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _DocumentRow(
                        doc: doc,
                        uploadedByClient: doc.uploadedBy == clientId,
                        isDark: isDark,
                        cardColor: cardColor,
                        borderColor: borderColor,
                        textColor: textColor,
                        subTextColor: subTextColor,
                      ),
                    ),
                  )
                  .toList(),
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: CircularProgressIndicator(color: Color(0xFFFF6B00)),
            ),
          ),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Error loading documents: $e',
                style: TextStyle(color: subTextColor),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// --- Single document row with eye icon --------------------------------------
class _DocumentRow extends StatelessWidget {
  final dynamic doc;
  final bool uploadedByClient;
  final bool isDark;
  final Color cardColor;
  final Color borderColor;
  final Color textColor;
  final Color subTextColor;

  const _DocumentRow({
    required this.doc,
    this.uploadedByClient = false,
    required this.isDark,
    required this.cardColor,
    required this.borderColor,
    required this.textColor,
    required this.subTextColor,
  });

  @override
  Widget build(BuildContext context) {
    final bool isPdf = doc.isPDF as bool;
    final bool isImage = doc.isImage as bool;
    final String name = (doc.fileName as String?) ?? 'Document';
    final String url = (doc.fileUrl as String?) ?? '';
    final String fileType = (doc.fileType as String?) ?? '';
    final IconData icon = isPdf
        ? Icons.picture_as_pdf
        : (isImage ? Icons.image : Icons.insert_drive_file);
    final Color iconColor = isPdf
        ? Colors.redAccent
        : (isImage ? Colors.purpleAccent : Colors.blueAccent);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      fileType.toUpperCase(),
                      style: TextStyle(
                        color: iconColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (uploadedByClient) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B00).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Uploaded by you',
                          style: TextStyle(
                            color: Color(0xFFFF6B00),
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Eye icon - view button
          GestureDetector(
            onTap: () => _openDocument(context, url, isImage, name),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: borderColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.remove_red_eye_outlined,
                color: Color(0xFFFF6B00),
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openDocument(
    BuildContext context,
    String url,
    bool isImage,
    String name,
  ) {
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document URL not available')),
      );
      return;
    }
    if (isImage) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _InAppImageViewer(imageUrl: url, title: name),
        ),
      );
    } else {
      _launchInBrowser(context, url);
    }
  }

  Future<void> _launchInBrowser(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open document')));
    }
  }
}

// --- Full-screen in-app image viewer with pinch-to-zoom ---------------------
class _InAppImageViewer extends StatefulWidget {
  final String imageUrl;
  final String title;
  const _InAppImageViewer({required this.imageUrl, required this.title});

  @override
  State<_InAppImageViewer> createState() => _InAppImageViewerState();
}

class _InAppImageViewerState extends State<_InAppImageViewer> {
  final TransformationController _ctrl = TransformationController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.zoom_out_map, color: Colors.white),
            onPressed: () => _ctrl.value = Matrix4.identity(),
            tooltip: 'Reset zoom',
          ),
          IconButton(
            icon: const Icon(Icons.open_in_browser, color: Colors.white),
            tooltip: 'Open in browser / download',
            onPressed: () async {
              final uri = Uri.parse(widget.imageUrl);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
          ),
        ],
      ),
      body: InteractiveViewer(
        transformationController: _ctrl,
        panEnabled: true,
        minScale: 0.5,
        maxScale: 5.0,
        child: Center(
          child: Image.network(
            widget.imageUrl,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                      : null,
                  color: const Color(0xFFFF6B00),
                ),
              );
            },
            errorBuilder: (_, _, _) => const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.broken_image, color: Colors.white54, size: 64),
                  SizedBox(height: 12),
                  Text(
                    'Could not load image',
                    style: TextStyle(color: Colors.white54),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
