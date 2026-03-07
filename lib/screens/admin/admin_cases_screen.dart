import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legal_sync/model/case_Model.dart';
import 'package:legal_sync/provider/case_provider.dart';
import 'package:legal_sync/provider/client_provider.dart';
import 'package:legal_sync/provider/lawyer_provider.dart';
import 'package:intl/intl.dart';

class AdminCasesScreen extends ConsumerStatefulWidget {
  const AdminCasesScreen({super.key});

  @override
  ConsumerState<AdminCasesScreen> createState() => _AdminCasesScreenState();
}

class _AdminCasesScreenState extends ConsumerState<AdminCasesScreen> {
  int _selectedTabIndex = 0; // 0: Active, 1: Resolved, 2: Pending
  late TextEditingController _searchCtrl;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _selectedDate = 'This Month';

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
          'Cases Management',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading:
            null, // Removed back arrow because this is part of IndexedStack bottom nav
        actions: [
          if (_searchQuery.isEmpty)
            IconButton(
              icon: const Icon(Icons.search, color: Color(0xFF1F2937)),
              onPressed: () {
                // Focus on search input logically
              },
            ),
          IconButton(
            icon: const Icon(Icons.filter_list, color: Color(0xFF1F2937)),
            onPressed: () => _showFilterBottomSheet(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Segmented Tabs
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Consumer(
                builder: (context, ref, _) {
                  final casesAsync = ref.watch(allCasesProvider);
                  int activeCount = 0;
                  int resolvedCount = 0;
                  int pendingCount = 0;

                  if (casesAsync.hasError) {
                    return const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _TabPlaceholder('Active', 0),
                        _TabPlaceholder('Resolved', 0),
                        _TabPlaceholder('Pending', 0),
                      ],
                    );
                  }

                  if (casesAsync.value != null) {
                    for (var c in casesAsync.value!) {
                      final status = c.status.toLowerCase();
                      if (status == 'active' || status == 'in_progress') {
                        activeCount++;
                      } else if (status == 'resolved' ||
                          status == 'closed' ||
                          status == 'completed') {
                        resolvedCount++;
                      } else if (status == 'pending') {
                        pendingCount++;
                      }
                    }
                  }

                  return Row(
                    children: [
                      _buildSegmentedTab(0, 'Active', activeCount),
                      _buildSegmentedTab(1, 'Resolved', resolvedCount),
                      _buildSegmentedTab(2, 'Pending', pendingCount),
                    ],
                  );
                },
              ),
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (val) =>
                    setState(() => _searchQuery = val.toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Search by case title...',
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Colors.grey,
                    size: 20,
                  ),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Colors.grey,
                            size: 18,
                          ),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),

          // Filters row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _showFilterBottomSheet(context),
                  icon: const Icon(Icons.tune, size: 16, color: Colors.grey),
                  label: const Text(
                    'Filters',
                    style: TextStyle(color: Colors.grey),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                Consumer(
                  builder: (context, ref, _) {
                    final casesAsync = ref.watch(allCasesProvider);
                    int count = 0;

                    if (casesAsync.hasError) {
                      return const Text(
                        'SHOWING 0 RESULTS',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }

                    if (casesAsync.value != null) {
                      count = _filterCases(casesAsync.value!).length;
                    }
                    return Text(
                      'SHOWING $count RESULTS',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  'CASE DETAILS',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'STATUS',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // List of Cases
          Expanded(child: _buildCasesList()),
        ],
      ),
    );
  }

  Widget _buildSegmentedTab(int index, String title, int count) {
    bool isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              '$title ($count)',
              style: TextStyle(
                color: isSelected
                    ? const Color(0xFF1E3A8A)
                    : const Color(0xFF6B7280),
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filter Cases',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Category',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        [
                              'All',
                              'Civil Law',
                              'Criminal Law',
                              'Family Law',
                              'Corporate Law',
                            ]
                            .map(
                              (c) => _FilterChip(
                                label: c,
                                isSelected: _selectedCategory == c,
                                onTap: () {
                                  setModalState(() => _selectedCategory = c);
                                  setState(() => _selectedCategory = c);
                                },
                              ),
                            )
                            .toList(),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Date Range',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children:
                        ['All Time', 'This Month', 'Last Month', 'This Year']
                            .map(
                              (d) => _FilterChip(
                                label: d,
                                isSelected: _selectedDate == d,
                                onTap: () {
                                  setModalState(() => _selectedDate = d);
                                  setState(() => _selectedDate = d);
                                },
                              ),
                            )
                            .toList(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Apply Filters',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  List<CaseModel> _filterCases(List<CaseModel> cases) {
    return cases.where((c) {
      if (_searchQuery.isNotEmpty &&
          !c.title.toLowerCase().contains(_searchQuery)) {
        return false;
      }
      if (_selectedCategory != 'All' && c.caseType != _selectedCategory) {
        return false;
      }

      final status = c.status.toLowerCase();
      if (_selectedTabIndex == 0 &&
          !(status == 'active' || status == 'in_progress')) {
        return false;
      }
      if (_selectedTabIndex == 1 &&
          !(status == 'resolved' ||
              status == 'closed' ||
              status == 'completed')) {
        return false;
      }
      if (_selectedTabIndex == 2 && status != 'pending') return false;

      if (_selectedDate != 'All Time') {
        final now = DateTime.now();
        final caseDate = c.createdAt;
        if (_selectedDate == 'This Month' &&
            (caseDate.month != now.month || caseDate.year != now.year)) {
          return false;
        }
        if (_selectedDate == 'Last Month') {
          final lastMonth = now.month == 1 ? 12 : now.month - 1;
          final lastMonthYear = now.month == 1 ? now.year - 1 : now.year;
          if (caseDate.month != lastMonth || caseDate.year != lastMonthYear) {
            return false;
          }
        }
        if (_selectedDate == 'This Year' && caseDate.year != now.year) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  Widget _buildCasesList() {
    final casesAsync = ref.watch(allCasesProvider);
    final lawyersAsync = ref.watch(allLawyersProvider);
    final clientsAsync = ref.watch(allClientsProvider);

    return casesAsync.when(
      data: (cases) {
        final filtered = _filterCases(cases);
        if (filtered.isEmpty) {
          return const Center(child: Text('No cases found.'));
        }
        return ListView.builder(
          shrinkWrap: false,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 20),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final c = filtered[index];

            // Resolve names safely
            String clName = 'Unknown Client';
            if (clientsAsync.value != null) {
              final cl = clientsAsync.value!
                  .where((client) => client.clientId == c.clientId)
                  .firstOrNull;
              if (cl != null) clName = cl.name;
            }
            String lwName = 'Unassigned';
            if (lawyersAsync.value != null && c.lawyerId.isNotEmpty) {
              final lw = lawyersAsync.value!
                  .where((lawyer) => lawyer.lawyerId == c.lawyerId)
                  .firstOrNull;
              if (lw != null) lwName = lw.name;
            }

            final dateStr = c.hearingDate != null
                ? 'Next Hearing: ${DateFormat('dd MMM yyyy').format(c.hearingDate!)}'
                : 'Created: ${DateFormat('dd MMM yyyy').format(c.createdAt)}';

            return _CaseRowItem(
              caseModel: c,
              clientName: clName,
              lawyerName: lwName,
              dateStr: dateStr,
              statusColor: _getStatusColor(c.status),
            );
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: Color(0xFF1E3A8A)),
      ),
      error: (err, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize:
                MainAxisSize.min, // Prevents expanding to entire height
            children: [
              const Icon(
                Icons.error_outline,
                color: Color(0xFFDC2626),
                size: 48,
              ),
              const SizedBox(height: 16),
              const Text(
                'Unable to Load Cases',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Flexible(
                // Important constraints
                child: SingleChildScrollView(
                  child: Text(
                    'Error: ${err.toString().split('\\n').first}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(allCasesProvider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'in_progress':
      case 'ongoing':
        return const Color(0xFF059669);
      case 'resolved':
      case 'closed':
      case 'completed':
        return const Color(0xFF1E3A8A);
      case 'pending':
        return const Color(0xFFDC2626);
      default:
        return Colors.grey;
    }
  }
}

class _CaseRowItem extends StatelessWidget {
  final CaseModel caseModel;
  final String clientName;
  final String lawyerName;
  final String dateStr;
  final Color statusColor;

  const _CaseRowItem({
    required this.caseModel,
    required this.clientName,
    required this.lawyerName,
    required this.dateStr,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      margin: const EdgeInsets.only(bottom: 1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.folder_open, color: Color(0xFF1E3A8A)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '#${caseModel.caseId.substring(0, 8)}',
                      style: const TextStyle(
                        color: Color(0xFF1E3A8A),
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      caseModel.caseType ?? 'General',
                      style: const TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  caseModel.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.person, size: 12, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Client: $clientName',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.gavel, size: 12, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Lawyer: $lawyerName',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  dateStr,
                  style: const TextStyle(
                    color: Color(0xFFE67E22),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  caseModel.status.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: Colors.grey),
                onPressed: () {
                  // Navigate to Case Details Screen using context
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Viewing details for ${caseModel.title}'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: const Color(0xFF1E3A8A),
                    ),
                  );
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TabPlaceholder extends StatelessWidget {
  final String title;
  final int count;

  const _TabPlaceholder(this.title, this.count);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: Text(
            '$title ($count)',
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E3A8A) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade600,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
