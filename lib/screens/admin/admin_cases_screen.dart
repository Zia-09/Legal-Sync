import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legal_sync/model/case_Model.dart';
import 'package:legal_sync/provider/case_provider.dart';
import 'package:legal_sync/provider/client_provider.dart';
import 'package:legal_sync/provider/lawyer_provider.dart';
import 'package:legal_sync/config/admin_theme.dart';
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
      backgroundColor: AdminTheme.primaryDark,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Segmented Tabs
          Container(
            color: AdminTheme.cardDark,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Container(
              decoration: BoxDecoration(
                color: AdminTheme.surfaceDark,
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
                      final status = c.status.toLowerCase().trim();
                      if (status == 'active' ||
                          status == 'in_progress' ||
                          status == 'ongoing') {
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
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Container(
              decoration: AdminTheme.searchBarDecoration(),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (val) =>
                    setState(() => _searchQuery = val.toLowerCase()),
                style: const TextStyle(color: AdminTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search by case title, client or lawyer...',
                  hintStyle: const TextStyle(
                    color: AdminTheme.textTertiary,
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AdminTheme.textTertiary,
                    size: 20,
                  ),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: AdminTheme.textTertiary,
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _showFilterBottomSheet(context),
                  icon: const Icon(
                    Icons.tune,
                    size: 16,
                    color: AdminTheme.primary,
                  ),
                  label: const Text(
                    'Filters',
                    style: TextStyle(color: AdminTheme.primary),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    side: const BorderSide(color: AdminTheme.accentDark),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                Consumer(
                  builder: (context, ref, _) {
                    final casesAsync = ref.watch(allCasesProvider);
                    int count = 0;
                    if (casesAsync.value != null) {
                      count = _filterCases(casesAsync.value!).length;
                    }
                    return Text(
                      'SHOWING $count',
                      style: AdminTheme.sectionHeaderStyle(),
                    );
                  },
                ),
              ],
            ),
          ),

          const Divider(color: AdminTheme.accentDark, height: 1),

          // List of Cases — Expanded so it fills remaining space
          Expanded(child: _buildCasesList()),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: AdminTheme.cardDark,
      elevation: 0,
      title: const Text(
        'Cases Management',
        style: TextStyle(
          color: AdminTheme.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      leading: null,
      centerTitle: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.filter_list, color: AdminTheme.textTertiary),
          onPressed: () => _showFilterBottomSheet(context),
        ),
      ],
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
            color: isSelected ? AdminTheme.cardDark : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isSelected
                        ? AdminTheme.primary
                        : AdminTheme.textTertiary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                Text(
                  count.toString(),
                  style: TextStyle(
                    color: isSelected
                        ? AdminTheme.primary
                        : AdminTheme.textTertiary,
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AdminTheme.cardDark,
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
                          color: AdminTheme.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: AdminTheme.textTertiary,
                        ),
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
                      color: AdminTheme.textPrimary,
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
                      color: AdminTheme.textPrimary,
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
                        backgroundColor: AdminTheme.primary,
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

      final status = c.status.toLowerCase().trim();
      if (_selectedTabIndex == 0 &&
          !(status == 'active' ||
              status == 'in_progress' ||
              status == 'ongoing')) {
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
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.folder_open_outlined,
                  size: 56,
                  color: AdminTheme.textTertiary.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'No cases found',
                  style: TextStyle(
                    color: AdminTheme.textSecondary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Try adjusting your search or filters',
                  style: TextStyle(
                    color: AdminTheme.textTertiary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 8),
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
              onTap: () => _showStatusUpdateBottomSheet(context, c),
            );
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AdminTheme.primary),
      ),
      error: (err, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AdminTheme.danger, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Unable to Load Cases',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AdminTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please check your internet connection',
                textAlign: TextAlign.center,
                style: TextStyle(color: AdminTheme.textTertiary, fontSize: 12),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(allCasesProvider),
                child: const Text('Retry'),
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
        return AdminTheme.success;
      case 'resolved':
      case 'closed':
      case 'completed':
        return AdminTheme.info;
      case 'pending':
        return AdminTheme.danger;
      default:
        return AdminTheme.textTertiary;
    }
  }

  void _showStatusUpdateBottomSheet(BuildContext context, CaseModel caseModel) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AdminTheme.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Update Case Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AdminTheme.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AdminTheme.textTertiary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _StatusOptionTile(
                  title: 'Active (In Progress)',
                  subtitle: 'Case is currently active and ongoing',
                  color: AdminTheme.success,
                  icon: Icons.play_circle_outline,
                  isSelected: caseModel.status.toLowerCase() == 'in_progress' ||
                      caseModel.status.toLowerCase() == 'active' ||
                      caseModel.status.toLowerCase() == 'ongoing',
                  onTap: () async {
                    Navigator.pop(context);
                    try {
                      await ref.read(caseServiceProvider).updateCase(caseModel.caseId, {'status': 'in_progress'});
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Case status updated to Active'),
                            backgroundColor: AdminTheme.success,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: AdminTheme.danger,
                          ),
                        );
                      }
                    }
                  },
                ),
                const SizedBox(height: 12),
                _StatusOptionTile(
                  title: 'Resolved (Closed)',
                  subtitle: 'Case has been resolved or completed',
                  color: AdminTheme.info,
                  icon: Icons.check_circle_outline,
                  isSelected: caseModel.status.toLowerCase() == 'closed' ||
                      caseModel.status.toLowerCase() == 'resolved' ||
                      caseModel.status.toLowerCase() == 'completed',
                  onTap: () async {
                    Navigator.pop(context);
                    try {
                      await ref.read(caseServiceProvider).updateCase(caseModel.caseId, {'status': 'closed'});
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Case status updated to Resolved'),
                            backgroundColor: AdminTheme.info,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: AdminTheme.danger,
                          ),
                        );
                      }
                    }
                  },
                ),
                const SizedBox(height: 12),
                _StatusOptionTile(
                  title: 'Pending',
                  subtitle: 'Case is waiting for lawyer assignment or review',
                  color: AdminTheme.danger,
                  icon: Icons.hourglass_empty,
                  isSelected: caseModel.status.toLowerCase() == 'pending',
                  onTap: () async {
                    Navigator.pop(context);
                    try {
                      await ref.read(caseServiceProvider).updateCase(caseModel.caseId, {'status': 'pending'});
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Case status updated to Pending'),
                            backgroundColor: AdminTheme.danger,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: AdminTheme.danger,
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CaseRowItem extends StatelessWidget {
  final CaseModel caseModel;
  final String clientName;
  final String lawyerName;
  final String dateStr;
  final Color statusColor;
  final VoidCallback? onTap;

  const _CaseRowItem({
    required this.caseModel,
    required this.clientName,
    required this.lawyerName,
    required this.dateStr,
    required this.statusColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: AdminTheme.cardDark,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.only(bottom: 4),
        child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AdminTheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.folder_open, color: AdminTheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '#${caseModel.caseId.substring(0, 8).toUpperCase()}',
                      style: const TextStyle(
                        color: AdminTheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      caseModel.caseType ?? 'General',
                      style: const TextStyle(
                        color: AdminTheme.textTertiary,
                        fontSize: 10,
                      ),
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
                    color: AdminTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.person,
                      size: 12,
                      color: AdminTheme.textTertiary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Client: $clientName',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AdminTheme.textTertiary,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(
                      Icons.gavel,
                      size: 12,
                      color: AdminTheme.textTertiary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Lawyer: $lawyerName',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AdminTheme.textTertiary,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  dateStr,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
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
            ],
          ),
        ],
      ),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AdminTheme.textTertiary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              Text(
                count.toString(),
                style: const TextStyle(
                  color: AdminTheme.textTertiary,
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                ),
              ),
            ],
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
          color: isSelected ? AdminTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AdminTheme.primary : AdminTheme.accentDark,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AdminTheme.textTertiary,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _StatusOptionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _StatusOptionTile({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : AdminTheme.accentDark,
            width: isSelected ? 2 : 1,
          ),
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.transparent,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AdminTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AdminTheme.textTertiary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check, color: color, size: 20),
          ],
        ),
      ),
    );
  }
}
