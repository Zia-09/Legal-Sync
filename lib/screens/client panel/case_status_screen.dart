import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:legal_sync/provider/client_provider.dart';
import 'package:legal_sync/provider/case_provider.dart';
import 'package:legal_sync/provider/lawyer_provider.dart';
import 'package:legal_sync/model/case_Model.dart';
import 'package:legal_sync/services/case_service.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'messages_screen.dart';
import 'home_screen.dart';
import 'app_setting_screen.dart';
import 'widgets/case_status_widgets.dart';

class CaseStatusScreen extends ConsumerStatefulWidget {
  const CaseStatusScreen({super.key});

  @override
  ConsumerState<CaseStatusScreen> createState() => _CaseStatusScreenState();
}

class _CaseStatusScreenState extends ConsumerState<CaseStatusScreen> {
  int _currentIndex = 2;

  List<TimelineStep> _buildTimeline(CaseModel caseModel) {
    final List<TimelineStep> timeline = [];
    final df = DateFormat('MMM dd');

    // Step 1: Registered
    timeline.add(
      TimelineStep(
        date: df.format(caseModel.createdAt),
        title: 'Case Registered',
        status: TimelineStatus.done,
        subtitle: 'Case successfully filed',
      ),
    );

    // Step 2: Lawyer Assigned (assuming all cases in this screen have a lawyer)
    timeline.add(
      const TimelineStep(
        date: '---',
        title: 'Lawyer Assigned',
        status: TimelineStatus.done,
        subtitle: 'Professional counsel assigned',
      ),
    );

    // Step 3: Current Status
    TimelineStatus currentStatus = TimelineStatus.active;
    if (caseModel.status.toLowerCase() == 'closed' ||
        caseModel.status.toLowerCase() == 'resolved') {
      currentStatus = TimelineStatus.done;
    }

    timeline.add(
      TimelineStep(
        date: df.format(caseModel.updatedAt ?? caseModel.createdAt),
        title: 'Current Status: ${caseModel.status.toUpperCase()}',
        status: currentStatus,
        subtitle: caseModel.remarks ?? 'Processing case details',
      ),
    );

    // Step 4: Hearing
    if (caseModel.hearingDate != null) {
      bool isPast = caseModel.hearingDate!.isBefore(DateTime.now());
      timeline.add(
        TimelineStep(
          date: df.format(caseModel.hearingDate!),
          title: 'Court Hearing',
          status: isPast ? TimelineStatus.done : TimelineStatus.pending,
          subtitle: caseModel.courtName ?? 'Court room to be assigned',
        ),
      );
    }

    return timeline;
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
        return 0.1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final clientAsync = ref.watch(currentClientProvider);

    return clientAsync.when(
      data: (client) {
        if (client == null) {
          return _buildScaffoldWithContent(
            const Center(
              child: Text(
                'Please login to view case status',
                style: TextStyle(color: Colors.white),
              ),
            ),
          );
        }

        return ref
            .watch(casesByClientProvider(client.clientId))
            .when(
              data: (cases) {
                if (cases.isEmpty) {
                  return _buildEmptyState();
                }
                final currentCase = cases.first;
                final timeline = _buildTimeline(currentCase);
                final progress = _calculateProgress(currentCase.status);

                return Scaffold(
                  backgroundColor: const Color(0xFF0F0F0F),
                  body: SafeArea(
                    child: Column(
                      children: [
                        _buildHeader(context),
                        const SizedBox(height: 16),
                        Expanded(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSummaryCard(currentCase),
                                const SizedBox(height: 20),
                                _buildProgressCard(progress),
                                const SizedBox(height: 20),
                                _buildTimelineCard(timeline),
                                const SizedBox(height: 20),
                                _buildConsultantCard(currentCase),
                                const SizedBox(height: 20),
                                _buildHearingUpdates(currentCase),
                                const SizedBox(height: 20),
                                _buildKeyDocuments(currentCase),
                                const SizedBox(height: 20),
                                _buildQuickActions(currentCase),
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
              loading: () => const Scaffold(
                backgroundColor: Color(0xFF0F0F0F),
                body: Center(
                  child: CircularProgressIndicator(color: Color(0xFFFF6B00)),
                ),
              ),
              error: (e, st) => _buildScaffoldWithContent(
                Center(
                  child: Text(
                    'Error: ${e.toString()}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            );
      },
      loading: () => const Scaffold(
        backgroundColor: Color(0xFF0F0F0F),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFFF6B00)),
        ),
      ),
      error: (e, st) => _buildScaffoldWithContent(
        Center(
          child: Text(
            'Auth Error: ${e.toString()}',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
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
            icon: const Icon(Icons.more_vert, color: Colors.white, size: 20),
            onSelected: (value) {
              if (value == 'refresh') {
                setState(() {});
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'refresh',
                child: Text('Refresh Case Data'),
              ),
              const PopupMenuItem(value: 'help', child: Text('Get Help')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(CaseModel caseModel) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E1A10), Color(0xFF1A1200)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFFF6B00).withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B00).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFFF6B00).withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  'Case # ${caseModel.caseId.toUpperCase()}',
                  style: const TextStyle(
                    color: Color(0xFFFF6B00),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF059669).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  caseModel.status.toUpperCase(),
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
          CaseDetailRow(
            label: 'Court',
            value: caseModel.courtName ?? 'To be assigned',
          ),
          const SizedBox(height: 6),
          CaseDetailRow(
            label: 'Filed',
            value: DateFormat('MMMM dd, yyyy').format(caseModel.createdAt),
          ),
          const SizedBox(height: 6),
          CaseDetailRow(label: 'Type', value: '${caseModel.caseType} Lawsuit'),
        ],
      ),
    );
  }

  Widget _buildProgressCard(double progress) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF252525)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              backgroundColor: const Color(0xFF2A2A2A),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFFFF6B00),
              ),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineCard(List<TimelineStep> timeline) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
            border: Border.all(color: const Color(0xFF252525)),
          ),
          child: Column(
            children: List.generate(timeline.length, (i) {
              return TimelineTile(
                step: timeline[i],
                isLast: i == timeline.length - 1,
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildConsultantCard(CaseModel caseModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
          builder: (context, ref, child) {
            final lawyerAsync = ref.watch(
              getLawyerByIdProvider(caseModel.lawyerId),
            );
            return lawyerAsync.when(
              data: (lawyer) {
                if (lawyer == null) {
                  return const Text(
                    'Lawyer not assigned yet',
                    style: TextStyle(color: Colors.white),
                  );
                }
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF252525)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2A2A2A),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: const Color(
                                  0xFFFF6B00,
                                ).withValues(alpha: 0.4),
                                width: 2,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(28),
                              child:
                                  (lawyer.profileImage != null &&
                                      lawyer.profileImage!.isNotEmpty)
                                  ? Image.network(
                                      lawyer.profileImage!,
                                      fit: BoxFit.cover,
                                    )
                                  : Center(
                                      child: Text(
                                        lawyer.name.isNotEmpty
                                            ? lawyer.name
                                                  .substring(0, 1)
                                                  .toUpperCase()
                                            : 'L',
                                        style: const TextStyle(
                                          color: Color(0xFFFF6B00),
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lawyer.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  lawyer.specialization,
                                  style: const TextStyle(
                                    color: Color(0xFF9E9E9E),
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.star,
                                      color: Color(0xFFFFB800),
                                      size: 12,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      '${lawyer.rating} (${lawyer.totalReviews} reviews)',
                                      style: const TextStyle(
                                        color: Color(0xFF9E9E9E),
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
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {},
                              icon: const Icon(
                                Icons.call_outlined,
                                size: 16,
                                color: Color(0xFF2563EB),
                              ),
                              label: const Text(
                                'Call now',
                                style: TextStyle(
                                  color: Color(0xFF2563EB),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: Color(0xFF2563EB),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const MessagesScreen(),
                                  ),
                                );
                              },
                              icon: const Icon(
                                Icons.chat_bubble_outline,
                                size: 16,
                                color: Colors.white,
                              ),
                              label: const Text(
                                'Chat',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF059669),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
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
                child: CircularProgressIndicator(color: Color(0xFFFF6B00)),
              ),
              error: (e, st) => const Text('Failed to load lawyer details'),
            );
          },
        ),
      ],
    );
  }

  Widget _buildHearingUpdates(CaseModel caseModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hearing Updates',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 14),
        if (caseModel.hearingDate != null)
          HearingUpdateCard(
            date: DateFormat('MMM dd, HH:mm').format(caseModel.hearingDate!),
            title: 'Upcoming Hearing',
            subtitle: caseModel.courtName ?? 'Court room to be assigned',
            isRecent: true,
          )
        else
          const Text(
            'No hearing scheduled yet',
            style: TextStyle(color: Color(0xFF6B6B6B), fontSize: 13),
          ),
      ],
    );
  }

  Widget _buildKeyDocuments(CaseModel caseModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: caseModel.documentUrls.length + 1,
            itemBuilder: (context, index) {
              if (index == caseModel.documentUrls.length) {
                return GestureDetector(
                  onTap: () => _uploadFile(caseModel.caseId),
                  child: const DocumentChip(
                    name: 'Add Doc',
                    icon: Icons.add_circle_outline,
                    color: Color(0xFFFF6B00),
                  ),
                );
              }
              final url = caseModel.documentUrls[index];
              final name = url.split('/').last.split('?').first;
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: DocumentChip(
                  name: name,
                  icon: name.endsWith('.pdf')
                      ? Icons.picture_as_pdf
                      : Icons.image_outlined,
                  color: const Color(0xFF2563EB),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(CaseModel caseModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
            QuickActionButton(
              label: 'Upload File',
              icon: Icons.upload_file,
              color: const Color(0xFFFF6B00),
              onTap: () => _uploadFile(caseModel.caseId),
            ),
            QuickActionButton(
              label: 'Schedule',
              icon: Icons.calendar_month_outlined,
              color: const Color(0xFF2563EB),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Opening meeting scheduler...'),
                    backgroundColor: Color(0xFF2563EB),
                  ),
                );
              },
            ),
            QuickActionButton(
              label: 'Add Notes',
              icon: Icons.note_add_outlined,
              color: const Color(0xFF7C3AED),
              onTap: () => _showAddNoteDialog(caseModel.caseId),
            ),
            QuickActionButton(
              label: 'Contact Support',
              icon: Icons.support_agent,
              color: const Color(0xFF059669),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Connecting to legal support...'),
                    backgroundColor: Color(0xFF059669),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  void _uploadFile(String caseId) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'png', 'docx'],
      );

      if (result == null) return;
      final path = result.files.single.path;
      if (path == null) return;
      File file = File(path);
      if (!context.mounted) return;

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Uploading document...'),
          backgroundColor: Color(0xFFFF6B00),
        ),
      );

      final url = await CaseService().uploadCaseDocument(caseId, file);

      if (context.mounted) {
        if (url != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Document uploaded successfully!'),
              backgroundColor: Color(0xFF059669),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAddNoteDialog(String caseId) {
    final TextEditingController noteController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Add Case Note',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: noteController,
          style: const TextStyle(color: Colors.white),
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Enter your note here...',
            hintStyle: const TextStyle(color: Color(0xFF6B6B6B)),
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Color(0xFF333333)),
              borderRadius: BorderRadius.circular(10),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Color(0xFFFF6B00)),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF6B6B6B)),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (noteController.text.isNotEmpty) {
                await CaseService().addCaseNote(caseId, noteController.text);
                if (context.mounted) Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B00),
            ),
            child: const Text('Add Note'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return _buildScaffoldWithContent(
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
  }

  Widget _buildScaffoldWithContent(Widget content) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: SafeArea(child: content),
      bottomNavigationBar: _buildBottomNav(context),
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

// ──────────────────────────────────────────────────────────────────────────────
