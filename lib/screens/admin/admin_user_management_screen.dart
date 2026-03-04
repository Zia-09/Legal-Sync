import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legal_sync/model/client_Model.dart';
import 'package:legal_sync/model/lawyer_Model.dart';
import 'package:legal_sync/provider/client_provider.dart';
import 'package:legal_sync/provider/lawyer_provider.dart';
import 'package:legal_sync/services/client_services.dart';
import 'package:legal_sync/services/lawyer_services.dart';

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
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'User Management',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: widget.initialSearch != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        actions: [
          if (_searchQuery.isEmpty)
            IconButton(
              icon: const Icon(Icons.search, color: Color(0xFF1F2937)),
              onPressed: () {
                // Focus search bar logic could be here
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Segmented Control Tabs
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
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
                  hintText: 'Search by name or email...',
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

          // List Header / Filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _filterStatus,
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      color: Color(0xFF1E3A8A),
                    ),
                    style: const TextStyle(
                      color: Color(0xFF1E3A8A),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
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
                  'USER INFORMATION',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'ACTION',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

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
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<LawyerModel> _filterLawyers(List<LawyerModel> lawyers) {
    return lawyers.where((l) {
      if (_filterStatus != 'All' &&
          l.status.toLowerCase() != _filterStatus.toLowerCase())
        return false;
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
          c.status.toLowerCase() != _filterStatus.toLowerCase())
        return false;
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
          return const Center(child: Text('No lawyers found.'));
        }
        return ListView.builder(
          shrinkWrap: false,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 20),
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
        child: CircularProgressIndicator(color: Color(0xFF1E3A8A)),
      ),
      error: (err, stack) {
        print('❌ Lawyers Error: $err');
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Color(0xFFDC2626),
                  size: 48,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Unable to Load Lawyers',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please check your internet connection',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.refresh(allLawyersProvider),
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
          return const Center(child: Text('No clients found.'));
        }
        return ListView.builder(
          shrinkWrap: false,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 20),
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
        child: CircularProgressIndicator(color: Color(0xFF1E3A8A)),
      ),
      error: (err, stack) {
        print('❌ Clients Error: $err');
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Color(0xFFDC2626),
                  size: 48,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Unable to Load Clients',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please check your internet connection',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.refresh(allClientsProvider),
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
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return const Color(0xFF059669);
      case 'suspended':
        return const Color(0xFFDC2626);
      case 'pending':
        return const Color(0xFFE67E22);
      default:
        return Colors.grey;
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$name status updated to $newStatus'),
          backgroundColor: const Color(0xFF059669),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update status: $e'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      margin: const EdgeInsets.only(bottom: 1),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
            child: const Icon(Icons.person, color: Color(0xFF1E3A8A)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
                const SizedBox(height: 2),
                Text(
                  location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.grey),
            onSelected: (value) async {
              if (value == 'delete') {
                bool confirm =
                    await showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Confirm Delete'),
                        content: Text(
                          'Are you sure you want to delete $name? This action cannot be undone.',
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
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ) ??
                    false;
                if (confirm && context.mounted) {
                  try {
                    if (isLawyer) {
                      await LawyerService().deleteLawyer(id);
                    } else {
                      await ClientService().deleteClient(id);
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Delete failed: $e')),
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
                  child: Text('Activate User'),
                ),
              if (status.toLowerCase() != 'suspended')
                const PopupMenuItem(
                  value: 'suspended',
                  child: Text('Suspend User'),
                ),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete User', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
