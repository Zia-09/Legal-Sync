import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legal_sync/model/case_Model.dart';
import 'package:legal_sync/provider/case_provider.dart';
import 'package:legal_sync/provider/client_provider.dart';
import 'package:legal_sync/provider/auth_provider.dart';
import 'package:intl/intl.dart';

class LawyerCasesScreen extends ConsumerStatefulWidget {
  const LawyerCasesScreen({super.key});

  @override
  ConsumerState<LawyerCasesScreen> createState() => _LawyerCasesScreenState();
}

class _LawyerCasesScreenState extends ConsumerState<LawyerCasesScreen> {
  int _selectedTabIndex = 0; // 0: Active, 1: Resolved, 2: Pending
  late TextEditingController _searchCtrl;
  String _searchQuery = '';
  String _selectedCategory = 'All';

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
    final user = ref.watch(authStateProvider).value;
    if (user == null)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'My Cases',
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
                  final casesAsync = ref.watch(casesByLawyerProvider(user.uid));
                  int activeCount = 0;
                  int resolvedCount = 0;
                  int pendingCount = 0;

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

          // Showing results count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Consumer(
                  builder: (context, ref, _) {
                    final casesAsync = ref.watch(
                      casesByLawyerProvider(user.uid),
                    );
                    int count = 0;
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

          // List of Cases
          Expanded(child: _buildCasesList(user.uid)),
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
          ),
          child: Center(
            child: Text(
              '$title ($count)',
              style: TextStyle(
                color: isSelected
                    ? const Color(0xFFFF6B00)
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
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6B00),
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

      return true;
    }).toList();
  }

  Widget _buildCasesList(String lawyerId) {
    final casesAsync = ref.watch(casesByLawyerProvider(lawyerId));
    final clientsAsync = ref.watch(allClientsProvider);

    return casesAsync.when(
      data: (cases) {
        final filtered = _filterCases(cases);
        if (filtered.isEmpty) {
          return const Center(child: Text('No cases found.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 20),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final c = filtered[index];
            String clName = 'Unknown Client';
            if (clientsAsync.value != null) {
              final cl = clientsAsync.value!
                  .where((client) => client.clientId == c.clientId)
                  .firstOrNull;
              if (cl != null) clName = cl.name;
            }

            return _CaseItem(caseModel: c, clientName: clName);
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: Color(0xFFFF6B00)),
      ),
      error: (err, _) => Center(child: Text('Error: $err')),
    );
  }
}

class _CaseItem extends StatelessWidget {
  final CaseModel caseModel;
  final String clientName;

  const _CaseItem({required this.caseModel, required this.clientName});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B00).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  caseModel.caseType ?? 'General',
                  style: const TextStyle(
                    color: Color(0xFFFF6B00),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                DateFormat('dd MMM yyyy').format(caseModel.createdAt),
                style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            caseModel.title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.person_outline, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                'Client: $clientName',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _StatusDot(_getStatusColor(caseModel.status)),
                  const SizedBox(width: 6),
                  Text(
                    caseModel.status.toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(caseModel.status),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'in_progress':
        return Colors.green;
      case 'resolved':
      case 'closed':
      case 'completed':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}

class _StatusDot extends StatelessWidget {
  final Color color;
  const _StatusDot(this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
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
          color: isSelected ? const Color(0xFFFF6B00) : Colors.white,
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
