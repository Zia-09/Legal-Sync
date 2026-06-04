import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legal_sync/model/client_Model.dart';
import 'package:legal_sync/model/lawyer_Model.dart';
import 'package:legal_sync/provider/client_provider.dart';
import 'package:legal_sync/provider/lawyer_provider.dart';
import 'package:legal_sync/services/client_services.dart';
import 'package:legal_sync/services/lawyer_services.dart';
import 'package:legal_sync/config/admin_theme.dart';

class AdminUserManagementScreen extends ConsumerStatefulWidget {
  final String? initialSearch;

  const AdminUserManagementScreen({super.key, this.initialSearch});

  @override
  ConsumerState<AdminUserManagementScreen> createState() =>
      _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState
    extends ConsumerState<AdminUserManagementScreen> {
  int _selectedTabIndex = 0; // 0 for Lawyers, 1 for Clients
  late TextEditingController _searchCtrl;
  String _searchQuery = '';
  String _filterStatus = 'All';

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController(text: widget.initialSearch ?? '');
    _searchQuery = _searchCtrl.text.toLowerCase();
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
          // Segmented Control Tabs
          Container(
            color: AdminTheme.cardDark,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Container(
              decoration: BoxDecoration(
                color: AdminTheme.surfaceDark,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  _buildSegmentedTab(
                    0,
                    'Lawyers',
                    ref.watch(allLawyersProvider).value?.length ?? 0,
                  ),
                  _buildSegmentedTab(
                    1,
                    'Clients',
                    ref.watch(allClientsProvider).value?.length ?? 0,
                  ),
                ],
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
                  hintText: 'Search by name or email...',
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

          // List Header / Filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _filterStatus,
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      color: AdminTheme.primary,
                    ),
                    style: const TextStyle(
                      color: AdminTheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    dropdownColor: AdminTheme.cardDark,
                    items: ['All', 'Active', 'Suspended', 'Pending']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _filterStatus = val);
                    },
                  ),
                ),
                Consumer(
                  builder: (context, ref, _) {
                    int count = 0;
                    if (_selectedTabIndex == 0) {
                      final d = ref.watch(allLawyersProvider).value;
                      if (d != null) count = _filterLawyers(d).length;
                    } else {
                      final d = ref.watch(allClientsProvider).value;
                      if (d != null) count = _filterClients(d).length;
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

          // User List
          Expanded(
            child: _selectedTabIndex == 0
                ? _buildLawyersList()
                : _buildClientsList(),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: AdminTheme.cardDark,
      elevation: 0,
      title: const Text(
        'User Management',
        style: TextStyle(
          color: AdminTheme.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      leading: null,
      centerTitle: false,
    );
  }

  Widget _buildSegmentedTab(int index, String title, int count) {
    bool isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _selectedTabIndex = index;
          _filterStatus = 'All'; // reset filter on tab switch
        }),
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
                    fontSize: 13,
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

  List<LawyerModel> _filterLawyers(List<LawyerModel> lawyers) {
    return lawyers.where((l) {
      if (_filterStatus != 'All' &&
          l.status.toLowerCase() != _filterStatus.toLowerCase()) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        if (!l.name.toLowerCase().contains(_searchQuery) &&
            !l.email.toLowerCase().contains(_searchQuery)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  List<ClientModel> _filterClients(List<ClientModel> clients) {
    return clients.where((c) {
      if (_filterStatus != 'All' &&
          c.status.toLowerCase() != _filterStatus.toLowerCase()) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        if (!c.name.toLowerCase().contains(_searchQuery) &&
            !c.email.toLowerCase().contains(_searchQuery)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  Widget _buildLawyersList() {
    final lawyersAsync = ref.watch(allLawyersProvider);

    return lawyersAsync.when(
      data: (lawyers) {
        final filtered = _filterLawyers(lawyers);
        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person_off_outlined,
                  size: 48,
                  color: AdminTheme.textTertiary.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'No lawyers found',
                  style: TextStyle(
                    color: AdminTheme.textSecondary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          shrinkWrap: false,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final l = filtered[index];
            return _UserRowItem(
              id: l.lawyerId,
              name: l.name,
              email: l.email,
              location: l.location ?? 'Unknown location',
              status: l.status.toUpperCase(),
              statusColor: _getStatusColor(l.status),
              isLawyer: true,
            );
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AdminTheme.primary),
      ),
      error: (err, stack) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: AdminTheme.danger,
                  size: 48,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Unable to Load Lawyers',
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
                  style: TextStyle(
                    color: AdminTheme.textTertiary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.refresh(allLawyersProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildClientsList() {
    final clientsAsync = ref.watch(allClientsProvider);

    return clientsAsync.when(
      data: (clients) {
        final filtered = _filterClients(clients);
        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person_off_outlined,
                  size: 48,
                  color: AdminTheme.textTertiary.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'No clients found',
                  style: TextStyle(
                    color: AdminTheme.textSecondary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          shrinkWrap: false,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final c = filtered[index];
            return _UserRowItem(
              id: c.clientId,
              name: c.name,
              email: c.email,
              location: c.address ?? 'Unknown location',
              status: c.status.toUpperCase(),
              statusColor: _getStatusColor(c.status),
              isLawyer: false,
            );
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AdminTheme.primary),
      ),
      error: (err, stack) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: AdminTheme.danger,
                  size: 48,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Unable to Load Clients',
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
                  style: TextStyle(
                    color: AdminTheme.textTertiary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.refresh(allClientsProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return AdminTheme.success;
      case 'suspended':
        return AdminTheme.danger;
      case 'pending':
        return AdminTheme.warning;
      default:
        return AdminTheme.textTertiary;
    }
  }
}

class _UserRowItem extends StatelessWidget {
  final String id;
  final String name;
  final String email;
  final String location;
  final String status;
  final Color statusColor;
  final bool isLawyer;

  const _UserRowItem({
    required this.id,
    required this.name,
    required this.email,
    required this.location,
    required this.status,
    required this.statusColor,
    required this.isLawyer,
  });

  void _updateStatus(BuildContext context, String newStatus) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (isLawyer) {
        await LawyerService().updateLawyer(
          lawyerId: id,
          data: {'status': newStatus},
        );
      } else {
        await ClientService().updateClient(
          clientId: id,
          data: {'status': newStatus},
        );
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text('$name status updated to $newStatus'),
          backgroundColor: AdminTheme.success,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to update status: $e'),
          backgroundColor: AdminTheme.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AdminTheme.cardDark,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AdminTheme.primary.withValues(alpha: 0.15),
            child: Icon(
              isLawyer ? Icons.gavel : Icons.person,
              color: AdminTheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          color: AdminTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AdminTheme.textTertiary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AdminTheme.textTertiary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AdminTheme.textTertiary),
            color: AdminTheme.cardDark,
            onSelected: (value) async {
              if (value == 'delete') {
                bool confirm =
                    await showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: AdminTheme.cardDark,
                        title: const Text(
                          'Confirm Delete',
                          style: TextStyle(color: AdminTheme.textPrimary),
                        ),
                        content: Text(
                          'Are you sure you want to delete $name? This action cannot be undone.',
                          style: const TextStyle(
                            color: AdminTheme.textSecondary,
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text(
                              'Delete',
                              style: TextStyle(color: AdminTheme.danger),
                            ),
                          ),
                        ],
                      ),
                    ) ??
                    false;
                if (confirm && context.mounted) {
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    if (isLawyer) {
                      await LawyerService().deleteLawyer(id);
                    } else {
                      await ClientService().deleteClient(id);
                    }
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('$name deleted successfully'),
                        backgroundColor: AdminTheme.success,
                      ),
                    );
                  } catch (e) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('Delete failed: $e'),
                        backgroundColor: AdminTheme.danger,
                      ),
                    );
                  }
                }
              } else {
                _updateStatus(context, value);
              }
            },
            itemBuilder: (context) => [
              if (status.toLowerCase() != 'active')
                const PopupMenuItem(
                  value: 'active',
                  child: Text(
                    'Activate User',
                    style: TextStyle(color: AdminTheme.success),
                  ),
                ),
              if (status.toLowerCase() != 'suspended')
                const PopupMenuItem(
                  value: 'suspended',
                  child: Text(
                    'Suspend User',
                    style: TextStyle(color: AdminTheme.warning),
                  ),
                ),
              const PopupMenuItem(
                value: 'delete',
                child: Text(
                  'Delete User',
                  style: TextStyle(color: AdminTheme.danger),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
