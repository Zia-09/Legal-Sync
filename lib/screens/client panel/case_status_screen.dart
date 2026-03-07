import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:legal_sync/model/case_Model.dart';

import 'package:legal_sync/provider/case_provider.dart';
import 'package:legal_sync/provider/client_provider.dart';
import 'package:legal_sync/provider/hearing_provider.dart';
import 'package:legal_sync/provider/lawyer_provider.dart';
import 'package:legal_sync/services/case_service.dart';
import 'package:legal_sync/services/document_service.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:legal_sync/screens/client%20panel/messages_screen.dart'; // fallback
import 'package:legal_sync/screens/client%20panel/home_screen.dart';
import 'package:legal_sync/screens/client%20panel/app_setting_screen.dart';
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
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
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

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document uploaded successfully!'),
            backgroundColor: Color(0xFF059669),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
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

                return Scaffold(
                  backgroundColor: const Color(0xFF0F0F0F),
                  body: SafeArea(
                    child: Column(
                      children: [
                        // ── Header ──────────────────────────────────────────
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                          child: Row(
                            children: [
                              const SizedBox(
                                width: 40,
                              ), // Placeholder to balance the right popup menu
                              const Expanded(
                                child: Center(
                                  child: Text(
                                    'Case Status',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              PopupMenuButton<String>(
                                icon: const Icon(
                                  Icons.more_vert,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                color: const Color(0xFF1E1E1E),
                                onSelected: (v) {
                                  if (v == 'refresh') setState(() {});
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                    value: 'refresh',
                                    child: Text(
                                      'Refresh',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'help',
                                    child: Text(
                                      'Get Help',
                                      style: TextStyle(color: Colors.white),
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
                                // Case Summary Card (original gradient style)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFF1E1A10),
                                        Color(0xFF1A1200),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: const Color(
                                        0xFFFF6B00,
                                      ).withValues(alpha: 0.25),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(
                                                0xFFFF6B00,
                                              ).withValues(alpha: 0.2),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(
                                                color: const Color(
                                                  0xFFFF6B00,
                                                ).withValues(alpha: 0.5),
                                              ),
                                            ),
                                            child: Text(
                                              currentCase.caseNumber != null
                                                  ? 'Case # ${currentCase.caseNumber}'
                                                  : 'Case # ${currentCase.caseId.substring(0, 8).toUpperCase()}',
                                              style: const TextStyle(
                                                color: Color(0xFFFF6B00),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          const Spacer(),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(
                                                0xFF059669,
                                              ).withValues(alpha: 0.15),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              currentCase.status,
                                              style: const TextStyle(
                                                color: Color(0xFF059669),
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 14),
                                      _CaseDetailRow(
                                        label: 'Title',
                                        value: currentCase.title,
                                      ),
                                      const SizedBox(height: 6),
                                      _CaseDetailRow(
                                        label: 'Court',
                                        value:
                                            currentCase.courtName ??
                                            'To be assigned',
                                      ),
                                      const SizedBox(height: 6),
                                      _CaseDetailRow(
                                        label: 'Filed',
                                        value: DateFormat(
                                          'MMMM dd, yyyy',
                                        ).format(currentCase.createdAt),
                                      ),
                                      const SizedBox(height: 6),
                                      _CaseDetailRow(
                                        label: 'Type',
                                        value:
                                            currentCase.caseType ?? 'General',
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // ── Case Progress ──────────────────────────
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1A1A1A),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: const Color(0xFF252525),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            'Case Progress',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            '${(progress * 100).toInt()}%',
                                            style: const TextStyle(
                                              color: Color(0xFFFF6B00),
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: LinearProgressIndicator(
                                          value: progress,
                                          backgroundColor: const Color(
                                            0xFF2A2A2A,
                                          ),
                                          valueColor:
                                              const AlwaysStoppedAnimation<
                                                Color
                                              >(Color(0xFFFF6B00)),
                                          minHeight: 8,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Filed',
                                            style: TextStyle(
                                              color: Color(0xFF6B6B6B),
                                              fontSize: 10,
                                            ),
                                          ),
                                          Text(
                                            'Hearing',
                                            style: TextStyle(
                                              color: Color(0xFF6B6B6B),
                                              fontSize: 10,
                                            ),
                                          ),
                                          Text(
                                            'Verdict',
                                            style: TextStyle(
                                              color: Color(0xFF6B6B6B),
                                              fontSize: 10,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // ── Timeline ───────────────────────────────
                                const Text(
                                  'Case Timeline',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1A1A1A),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: const Color(0xFF252525),
                                    ),
                                  ),
                                  child: Column(
                                    children: List.generate(
                                      timeline.length,
                                      (i) => _TimelineTile(
                                        step: timeline[i],
                                        isLast: i == timeline.length - 1,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // ── Case Consultant ────────────────────────
                                const Text(
                                  'Case Consultant',
                                  style: TextStyle(
                                    color: Colors.white,
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
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF1A1A1A),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              border: Border.all(
                                                color: const Color(0xFF252525),
                                              ),
                                            ),
                                            child: const Text(
                                              'Lawyer not yet assigned',
                                              style: TextStyle(
                                                color: Color(0xFF9E9E9E),
                                              ),
                                            ),
                                          );
                                        }
                                        return Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF1A1A1A),
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            border: Border.all(
                                              color: const Color(0xFF252525),
                                            ),
                                          ),
                                          child: Column(
                                            children: [
                                              Row(
                                                children: [
                                                  // Avatar
                                                  Container(
                                                    width: 56,
                                                    height: 56,
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                        0xFF2A2A2A,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            28,
                                                          ),
                                                      border: Border.all(
                                                        color:
                                                            const Color(
                                                              0xFFFF6B00,
                                                            ).withValues(
                                                              alpha: 0.4,
                                                            ),
                                                        width: 2,
                                                      ),
                                                    ),
                                                    child: ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            28,
                                                          ),
                                                      child:
                                                          (lawyer.profileImage !=
                                                                  null &&
                                                              lawyer
                                                                  .profileImage!
                                                                  .isNotEmpty)
                                                          ? Image.network(
                                                              lawyer
                                                                  .profileImage!,
                                                              fit: BoxFit.cover,
                                                              errorBuilder:
                                                                  (
                                                                    _,
                                                                    __,
                                                                    ___,
                                                                  ) => _lawyerInitials(
                                                                    lawyer.name,
                                                                  ),
                                                            )
                                                          : _lawyerInitials(
                                                              lawyer.name,
                                                            ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 14),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          lawyer.name,
                                                          style:
                                                              const TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 16,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                        ),
                                                        const SizedBox(
                                                          height: 3,
                                                        ),
                                                        Text(
                                                          lawyer.specialization,
                                                          style:
                                                              const TextStyle(
                                                                color: Color(
                                                                  0xFF9E9E9E,
                                                                ),
                                                                fontSize: 12,
                                                              ),
                                                        ),
                                                        const SizedBox(
                                                          height: 4,
                                                        ),
                                                        Row(
                                                          children: [
                                                            const Icon(
                                                              Icons.star,
                                                              color: Color(
                                                                0xFFFFB800,
                                                              ),
                                                              size: 12,
                                                            ),
                                                            const SizedBox(
                                                              width: 3,
                                                            ),
                                                            Text(
                                                              '${lawyer.rating} (${lawyer.totalReviews} reviews)',
                                                              style:
                                                                  const TextStyle(
                                                                    color: Color(
                                                                      0xFF9E9E9E,
                                                                    ),
                                                                    fontSize:
                                                                        11,
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
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: OutlinedButton.icon(
                                                      onPressed: () {},
                                                      icon: const Icon(
                                                        Icons.call_outlined,
                                                        size: 16,
                                                        color: Color(
                                                          0xFF2563EB,
                                                        ),
                                                      ),
                                                      label: const Text(
                                                        'Call now',
                                                        style: TextStyle(
                                                          color: Color(
                                                            0xFF2563EB,
                                                          ),
                                                          fontSize: 13,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                      style: OutlinedButton.styleFrom(
                                                        side: const BorderSide(
                                                          color: Color(
                                                            0xFF2563EB,
                                                          ),
                                                        ),
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              vertical: 10,
                                                            ),
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                10,
                                                              ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: ElevatedButton.icon(
                                                      onPressed: () => Navigator.push(
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
                                                      icon: const Icon(
                                                        Icons
                                                            .chat_bubble_outline,
                                                        size: 16,
                                                        color: Colors.white,
                                                      ),
                                                      label: const Text(
                                                        'Chat',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 13,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            const Color(
                                                              0xFF059669,
                                                            ),
                                                        elevation: 0,
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              vertical: 10,
                                                            ),
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                10,
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
                                      loading: () => const Center(
                                        child: CircularProgressIndicator(
                                          color: Color(0xFFFF6B00),
                                        ),
                                      ),
                                      error: (e, _) => Text(
                                        'Failed to load lawyer: $e',
                                        style: const TextStyle(
                                          color: Color(0xFF9E9E9E),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 20),

                                // ── Hearing Updates (REAL DATA) ────────────
                                _HearingUpdatesSection(
                                  caseIds: cases.map((c) => c.caseId).toList(),
                                ),
                                const SizedBox(height: 20),

                                // ── Key Documents ──────────────────────────
                                const Text(
                                  'Key Documents',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                SizedBox(
                                  height: 90,
                                  child: currentCase.documentUrls.isEmpty
                                      ? ListView(
                                          scrollDirection: Axis.horizontal,
                                          physics:
                                              const BouncingScrollPhysics(),
                                          children: [
                                            GestureDetector(
                                              onTap: () => _uploadFile(
                                                currentCase,
                                                client.clientId,
                                              ),
                                              child: const _DocumentChip(
                                                name: 'Add Doc',
                                                icon: Icons.add_circle_outline,
                                                color: Color(0xFFFF6B00),
                                              ),
                                            ),
                                          ],
                                        )
                                      : ListView.builder(
                                          scrollDirection: Axis.horizontal,
                                          physics:
                                              const BouncingScrollPhysics(),
                                          itemCount:
                                              currentCase.documentUrls.length +
                                              1,
                                          itemBuilder: (_, i) {
                                            if (i ==
                                                currentCase
                                                    .documentUrls
                                                    .length) {
                                              return GestureDetector(
                                                onTap: () => _uploadFile(
                                                  currentCase,
                                                  client.clientId,
                                                ),
                                                child: const _DocumentChip(
                                                  name: 'Add Doc',
                                                  icon:
                                                      Icons.add_circle_outline,
                                                  color: Color(0xFFFF6B00),
                                                ),
                                              );
                                            }
                                            final url =
                                                currentCase.documentUrls[i];
                                            String name = url
                                                .split('/')
                                                .last
                                                .split('?')
                                                .first;
                                            name = Uri.decodeComponent(name);
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                right: 10,
                                              ),
                                              child: _DocumentChip(
                                                name: name,
                                                icon:
                                                    name.toLowerCase().endsWith(
                                                      '.pdf',
                                                    )
                                                    ? Icons.picture_as_pdf
                                                    : Icons.image_outlined,
                                                color: const Color(0xFF2563EB),
                                                onTap: () async {
                                                  final uri = Uri.parse(url);
                                                  if (await canLaunchUrl(uri)) {
                                                    await launchUrl(uri);
                                                  } else {
                                                    if (context.mounted) {
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        const SnackBar(
                                                          content: Text(
                                                            'Could not open document',
                                                          ),
                                                        ),
                                                      );
                                                    }
                                                  }
                                                },
                                              ),
                                            );
                                          },
                                        ),
                                ),
                                const SizedBox(height: 20),

                                // ── Quick Actions ──────────────────────────
                                const Text(
                                  'Quick Actions',
                                  style: TextStyle(
                                    color: Colors.white,
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
                                      onTap: () {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Opening meeting scheduler…',
                                            ),
                                            backgroundColor: Color(0xFF2563EB),
                                          ),
                                        );
                                      },
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
                                      label: 'Contact Support',
                                      icon: Icons.support_agent,
                                      color: const Color(0xFF059669),
                                      onTap: () {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Connecting to legal support…',
                                            ),
                                            backgroundColor: Color(0xFF059669),
                                          ),
                                        );
                                      },
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
              error: (e, _) => _scaffoldWithContent(
                Center(
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
    bottomNavigationBar: _buildBottomNav(context),
  );

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
          return GestureDetector(
            onTap: () => setState(() => _selectedCaseIndex = index),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20),
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
                child: Text(
                  'Case ${index + 1}',
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF9E9E9E),
                    fontSize: 13,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
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
      decoration: const BoxDecoration(
        color: Color(0xFF141414),
        border: Border(top: BorderSide(color: Color(0xFF1E1E1E), width: 1)),
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
                  color: isActive
                      ? const Color(0xFFFF6B00)
                      : const Color(0xFF5A5A5A),
                  size: 24,
                ),
                const SizedBox(height: 4),
                Text(
                  item['label'] as String,
                  style: TextStyle(
                    color: isActive
                        ? const Color(0xFFFF6B00)
                        : const Color(0xFF5A5A5A),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Hearing Updates',
              style: TextStyle(
                color: Colors.white,
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
              return const Text(
                'No upcoming hearings scheduled yet',
                style: TextStyle(color: Color(0xFF6B6B6B), fontSize: 13),
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

class _CaseDetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _CaseDetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 52,
          child: Text(
            label,
            style: const TextStyle(color: Color(0xFF6B6B6B), fontSize: 12),
          ),
        ),
        const Text(
          ':  ',
          style: TextStyle(color: Color(0xFF6B6B6B), fontSize: 12),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Color(0xFFDDDDDD),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

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
  const _TimelineTile({required this.step, required this.isLast});

  @override
  Widget build(BuildContext context) {
    Color dotColor;
    IconData dotIcon;
    switch (step.status) {
      case TimelineStatus.done:
        dotColor = const Color(0xFF059669);
        dotIcon = Icons.check_circle;
        break;
      case TimelineStatus.active:
        dotColor = const Color(0xFFFFB800);
        dotIcon = Icons.radio_button_checked;
        break;
      case TimelineStatus.pending:
        dotColor = const Color(0xFF3A3A3A);
        dotIcon = Icons.radio_button_unchecked;
        break;
    }

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
                          ? const Color(0xFF6B6B6B)
                          : Colors.white,
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

  const _HearingUpdateCard({
    required this.date,
    required this.title,
    required this.subtitle,
    this.description,
    required this.isRecent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isRecent
              ? const Color(0xFFFF6B00).withValues(alpha: 0.3)
              : const Color(0xFF252525),
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
                  : const Color(0xFF252525),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isRecent ? Icons.gavel : Icons.history,
              color: isRecent
                  ? const Color(0xFFFF6B00)
                  : const Color(0xFF6B6B6B),
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
                    color: isRecent
                        ? const Color(0xFFFF6B00)
                        : const Color(0xFF6B6B6B),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF9E9E9E),
                    fontSize: 11,
                  ),
                ),
                if (description != null && description!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A).withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF333333)),
                    ),
                    child: Text(
                      description!,
                      style: const TextStyle(
                        color: Color(0xFFCCCCCC),
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

class _DocumentChip extends StatelessWidget {
  final String name;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  const _DocumentChip({
    required this.name,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () {},
      child: Container(
        width: 85,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF252525)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 6),
            Text(
              name,
              style: const TextStyle(
                color: Color(0xFFCCCCCC),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
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
