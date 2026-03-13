import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legal_sync/provider/auth_provider.dart';
import 'package:legal_sync/provider/document_provider.dart';
import 'package:legal_sync/provider/case_provider.dart';
import 'package:legal_sync/provider/client_provider.dart';
import 'package:legal_sync/model/document_Model.dart';
import 'package:legal_sync/model/case_Model.dart';
import 'package:legal_sync/model/client_Model.dart';
import 'package:intl/intl.dart';

class LawyerManagementDocumentScreen extends ConsumerStatefulWidget {
  const LawyerManagementDocumentScreen({super.key});

  @override
  ConsumerState<LawyerManagementDocumentScreen> createState() =>
      _LawyerManagementDocumentScreenState();
}

class _LawyerManagementDocumentScreenState
    extends ConsumerState<LawyerManagementDocumentScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _selectedTabIndex = 0; // 0: All Documents, 1: Pending Reviews
  String _selectedCaseFilter = 'All cases';
  String _selectedClientFilter = 'All Clients';
  String _selectedTypeFilter = 'All';

  final List<String> _documentTypes = [
    'All',
    'Evidence',
    'Contracts',
    'Affidavits',
  ];

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    if (user == null) return const Center(child: CircularProgressIndicator());

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark
        ? const Color(0xFF121212)
        : const Color(0xFFF7F9FC);
    final appBarBg = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    final documentsAsync = ref.watch(documentsByLawyerProvider(user.uid));
    final casesAsync = ref.watch(casesByLawyerProvider(user.uid));

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: appBarBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Manage Document',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: documentsAsync.when(
        data: (documents) {
          final filteredDocs = _applyFilters(documents);
          final cases = casesAsync.value ?? [];
          final clients = ref.watch(allClientsProvider).value ?? [];

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopSnapshotCard(documents),
                const SizedBox(height: 20),
                _buildFilterSection(cases, documents, clients),
                const SizedBox(height: 24),
                _buildClientUploadsList(filteredDocs, cases, clients),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }

  List<DocumentModel> _applyFilters(List<DocumentModel> docs) {
    return docs.where((doc) {
      // Tab filter (Pending Reviews = 1)
      if (_selectedTabIndex == 1 && doc.isApprovedForClient) return false;

      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final nameMatch = doc.fileName?.toLowerCase().contains(query) ?? false;
        final descMatch =
            doc.description?.toLowerCase().contains(query) ?? false;
        if (!nameMatch && !descMatch) return false;
      }

      // Case filter
      if (_selectedCaseFilter != 'All cases' &&
          doc.caseId != _selectedCaseFilter) {
        return false;
      }

      // Type filter
      if (_selectedTypeFilter != 'All' &&
          doc.fileType.toLowerCase() != _selectedTypeFilter.toLowerCase()) {
        return false;
      }

      return true;
    }).toList();
  }

  Widget _buildTopSnapshotCard(List<DocumentModel> documents) {
    final pending = documents
        .where((d) => !d.isApprovedForClient && !d.isRejected)
        .length;
    final approved = documents.where((d) => d.isApprovedForClient).length;
    final rejected = documents.where((d) => d.isRejected).length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF131D31), // Dark Navy
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Review and manage documents uploaded by clients or pending your review.',
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSnapshotItem(
                'Pending',
                pending.toString(),
                const Color(0xFFFF6B00),
              ), // Orange
              _buildSnapshotItem('Approved', approved.toString(), Colors.green),
              _buildSnapshotItem('Rejected', rejected.toString(), Colors.red),
            ],
          ),
          const SizedBox(height: 16),
          // Search Bar on top of Navy card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                icon: Icon(Icons.search, color: Colors.white54),
                hintText: 'Search cases or client...',
                hintStyle: TextStyle(color: Colors.white54, fontSize: 13),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSnapshotItem(String title, String count, Color countColor) {
    return Column(
      children: [
        Text(
          count,
          style: TextStyle(
            color: countColor,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterSection(
    List<dynamic> cases,
    List<DocumentModel> documents,
    List<dynamic> clients,
  ) {
    final caseItems = [
      'All cases',
      ...cases.map((c) => c.caseNumber as String),
    ];

    final clientIds = documents.map((d) => d.uploadedBy).toSet();
    final clientItems = [
      'All Clients',
      ...clients
          .where((c) => clientIds.contains(c.clientId))
          .map((c) => c.name as String),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filter Documents',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedTabIndex = 0;
                    _selectedCaseFilter = 'All cases';
                    _selectedClientFilter = 'All Clients';
                    _selectedTypeFilter = 'All';
                    _searchQuery = '';
                    _searchController.clear();
                  });
                },
                child: const Text(
                  'Reset All',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFFF6B00),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Tab Switcher
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                _buildTab('All Documents', 0),
                _buildTab('Pending Reviews', 1),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Dropdown Filters
          Row(
            children: [
              Expanded(
                child: _buildFilterDropdown(
                  'CASE',
                  _selectedCaseFilter,
                  caseItems,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFilterDropdown(
                  'CLIENT',
                  _selectedClientFilter,
                  clientItems,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Document Types Chips
          const Text(
            'DOCUMENT TYPE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _documentTypes
                  .map((type) => _buildTypeChip(type))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String title, int index) {
    bool isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTabIndex = index;
          });
        },
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.black87 : Colors.grey.shade600,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterDropdown(
    String label,
    String selectedValue,
    List<String> items, {
    bool hideLabel = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!hideLabel)
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
              letterSpacing: 1,
            ),
          ),
        if (!hideLabel) const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedValue,
              isExpanded: true,
              icon: Icon(
                Icons.keyboard_arrow_down,
                color: Colors.grey.shade600,
              ),
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              items: items
                  .map(
                    (item) => DropdownMenuItem(value: item, child: Text(item)),
                  )
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    if (label == 'CASE') _selectedCaseFilter = val;
                    if (label == 'CLIENT') _selectedClientFilter = val;
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeChip(String label) {
    bool isSelected = _selectedTypeFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTypeFilter = label;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF6B00) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFFF6B00) : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildClientUploadsList(
    List<DocumentModel> docs,
    List<dynamic> cases,
    List<dynamic> clients,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Client Uploads',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                '${docs.length} documents found',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (docs.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 50.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.folder_open_outlined,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Documents Found',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No documents match the current filters.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            ...docs.map((doc) {
              // Fix: type 'Null' is not a subtype of type 'CaseModel' or 'ClientModel'
              // Using iterable equality check or where + firstOrNull would be safer
              final caseObj = cases.cast<CaseModel?>().firstWhere(
                (c) => c?.caseId == doc.caseId,
                orElse: () => null,
              );
              final clientObj = clients.cast<ClientModel?>().firstWhere(
                (c) => c?.clientId == doc.uploadedBy,
                orElse: () => null,
              );

              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: _buildDocumentListItem(
                  docId: doc.documentId,
                  docTitle: doc.fileName ?? 'Untitled Document',
                  clientName:
                      'Uploaded by: ${clientObj?.name ?? doc.uploadedBy}',
                  caseName: 'Case: ${caseObj?.caseNumber ?? doc.caseId}',
                  iconType: doc.isPDF
                      ? Icons.picture_as_pdf
                      : (doc.isImage ? Icons.image : Icons.description),
                  iconColor: doc.isPDF
                      ? Colors.red.shade400
                      : (doc.isImage
                            ? Colors.purple.shade400
                            : Colors.blue.shade400),
                  statusLabel: doc.isApprovedForClient ? 'APPROVED' : 'PENDING',
                  statusColor: doc.isApprovedForClient
                      ? Colors.green
                      : const Color(0xFFFF6B00),
                  date:
                      'Submitted: ${DateFormat('dd MMM yyyy').format(doc.uploadedAt)}',
                  isPending: !doc.isApprovedForClient,
                ),
              );
            }),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildDocumentListItem({
    required String docId,
    required String docTitle,
    required String clientName,
    required String caseName,
    required IconData iconType,
    required Color iconColor,
    required String statusLabel,
    required Color statusColor,
    required String date,
    bool isPending = false,
  }) {
    final user = ref.watch(authStateProvider).value;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(iconType, color: iconColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      docTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      clientName,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      caseName,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, thickness: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (isPending && user != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          minimumSize: const Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          ref
                              .read(documentStateProvider.notifier)
                              .approveDocument(docId, user.uid);
                        },
                        child: const Text(
                          'Approve',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  if (isPending && user != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          minimumSize: const Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          _showRejectDialog(context, ref, docId);
                        },
                        child: const Text(
                          'Reject',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: Colors.orange.shade700,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    date,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.remove_red_eye_outlined,
                      size: 16,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.more_vert,
                      size: 16,
                      color: Colors.black87,
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

  void _showRejectDialog(BuildContext context, WidgetRef ref, String docId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Document'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter reason for rejection...',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref
                  .read(documentStateProvider.notifier)
                  .rejectDocument(docId, reason: controller.text);
              Navigator.pop(context);
            },
            child: const Text('Reject', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
