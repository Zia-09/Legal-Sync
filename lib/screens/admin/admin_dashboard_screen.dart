import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legal_sync/provider/case_provider.dart';
import 'package:legal_sync/provider/client_provider.dart';
import 'package:legal_sync/provider/lawyer_provider.dart';
import 'package:legal_sync/provider/notification_provider.dart';
import 'package:legal_sync/config/admin_theme.dart';
import 'package:intl/intl.dart';

import 'admin_analytics_screen.dart';
import 'admin_cases_screen.dart';
import 'admin_notifications_screen.dart';
import 'admin_profile_screen.dart';
import 'admin_settings_screen.dart';
import 'admin_user_management_screen.dart';
import 'admin_verification_list_screen.dart';

// ─── Admin Dashboard Shell ─────────────────────────────────────────────────
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    _AdminHomeTab(),
    AdminUserManagementScreen(),
    AdminCasesScreen(),
    AdminSettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _ensureAdminAuth();
  }

  Future<void> _ensureAdminAuth() async {
    // Admin must be authenticated via the login screen (role == 'admin' in Firestore).
    // No hardcoded credentials here.
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AdminTheme.buildAdminTheme(),
      child: Scaffold(
        backgroundColor: AdminTheme.primaryDark,
        body: IndexedStack(index: _currentIndex, children: _screens),
        bottomNavigationBar: _buildBottomNav(context),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AdminTheme.cardDark,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AdminTheme.primary,
        unselectedItemColor: AdminTheme.textTertiary,
        showUnselectedLabels: true,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        backgroundColor: AdminTheme.cardDark,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Users'),
          BottomNavigationBarItem(icon: Icon(Icons.folder), label: 'Cases'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

// ─── Home Tab (Real-time dashboard content) ────────────────────────────────
class _AdminHomeTab extends ConsumerStatefulWidget {
  const _AdminHomeTab();

  @override
  ConsumerState<_AdminHomeTab> createState() => _AdminHomeTabState();
}

class _AdminHomeTabState extends ConsumerState<_AdminHomeTab>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fade = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allLawyers = ref.watch(allLawyersProvider);
    final allCases = ref.watch(allCasesProvider);
    final allClients = ref.watch(allClientsProvider);
    final pendingVerifications = ref.watch(pendingLawyerApprovalsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(context),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search bar
                    _buildSearchBar(context),
                    const SizedBox(height: 24),

                    // Stats grid
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final cardW = (constraints.maxWidth - 16) / 2;
                        final aspect = (cardW / 150).clamp(0.7, 1.1);
                        return GridView.count(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          childAspectRatio: aspect,
                      children: [
                        _StatCard(
                          title: 'Total Lawyers',
                          value: allLawyers.value?.length ?? 0,
                          icon: Icons.business_center,
                          color: AdminTheme.statBlue,
                          isLoading: allLawyers.isLoading,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const AdminVerificationListScreen(),
                            ),
                          ),
                        ),
                        _StatCard(
                          title: 'Active Cases',
                          value:
                              allCases.value
                                  ?.where(
                                    (c) =>
                                        c.status.toLowerCase().contains(
                                              'active',
                                            ) ||
                                        c.status.toLowerCase().contains(
                                              'ongoing',
                                            ) ||
                                        c.status.toLowerCase().contains(
                                              'in_progress',
                                            ),
                                  )
                                  .length ??
                              0,
                          icon: Icons.folder,
                          color: AdminTheme.statGreen,
                          isLoading: allCases.isLoading,
                          onTap: () {
                            final parent = context
                                .findAncestorStateOfType<
                                    _AdminDashboardScreenState>();
                            parent?.setState(() => parent._currentIndex = 2);
                          },
                        ),
                        _StatCard(
                          title: 'Pending Verifications',
                          value: pendingVerifications.value?.length ?? 0,
                          icon: Icons.verified_user,
                          color: AdminTheme.warning,
                          isLoading: pendingVerifications.isLoading,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const AdminVerificationListScreen(),
                            ),
                          ),
                        ),
                        _StatCard(
                          title: 'Total Clients',
                          value: allClients.value?.length ?? 0,
                          icon: Icons.people,
                          color: AdminTheme.statPurple,
                          isLoading: allClients.isLoading,
                          onTap: () {
                            final parent = context
                                .findAncestorStateOfType<
                                    _AdminDashboardScreenState>();
                            parent?.setState(() => parent._currentIndex = 1);
                          },
                        ),
                      ],
                        );
                      },
                    ),
                    const SizedBox(height: 32),

                    // Quick Actions
                    _buildSectionHeader('QUICK ACTIONS', null),
                    const SizedBox(height: 16),
                    _buildQuickActions(context),
                    const SizedBox(height: 32),

                    // Recent Activity
                    _buildSectionHeader('RECENT ACTIVITY', () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminVerificationListScreen(),
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                    _RecentActivityList(),
                    const SizedBox(height: 32),

                    // Registration Trends
                    _RegistrationTrendsChart(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AdminTheme.cardDark,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AdminTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.gavel,
              color: AdminTheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LegalSync',
                style: const TextStyle(
                  color: AdminTheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                'ADMIN PORTAL',
                style: TextStyle(
                  color: AdminTheme.textTertiary.withValues(alpha: 0.8),
                  fontSize: 10,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        // Notification icon with live badge
        Consumer(
          builder: (ctx, ref, _) {
            final unreadAsync = ref.watch(
              unreadNotificationsCountProvider('admin'),
            );
            final unreadCount = unreadAsync.value ?? 0;
            return IconButton(
              icon: Stack(
                children: [
                  const Icon(
                    Icons.notifications_none,
                    color: AdminTheme.textPrimary,
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 2,
                      top: 4,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: const BoxDecoration(
                          color: AdminTheme.warning,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminNotificationsScreen(),
                ),
              ),
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16, left: 8),
          child: GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminProfileScreen()),
            ),
            child: const CircleAvatar(
              radius: 16,
              backgroundColor: AdminTheme.info,
              child: Icon(Icons.person, size: 20, color: AdminTheme.textPrimary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final allLawyers = ref.watch(allLawyersProvider);
    final allCases = ref.watch(allCasesProvider);
    final allClients = ref.watch(allClientsProvider);
    final query = _searchCtrl.text.trim().toLowerCase();

    // Live results when query is non-empty
    final showResults = query.isNotEmpty;
    final matchedLawyers = showResults && allLawyers.value != null
        ? allLawyers.value!.where((l) =>
            l.name.toLowerCase().contains(query) ||
            l.email.toLowerCase().contains(query)).take(3).toList()
        : <dynamic>[];
    final matchedClients = showResults && allClients.value != null
        ? allClients.value!.where((c) =>
            c.name.toLowerCase().contains(query) ||
            c.email.toLowerCase().contains(query)).take(3).toList()
        : <dynamic>[];
    final matchedCases = showResults && allCases.value != null
        ? allCases.value!.where((c) =>
            c.title.toLowerCase().contains(query)).take(3).toList()
        : <dynamic>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: AdminTheme.searchBarDecoration(),
          child: TextField(
            controller: _searchCtrl,
            onSubmitted: (q) {
              if (q.trim().isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        AdminUserManagementScreen(initialSearch: q.trim()),
                  ),
                );
              }
            },
            decoration: InputDecoration(
              hintText: 'Search lawyers, cases or clients...',
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
                        setState(() {});
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
            style: const TextStyle(color: AdminTheme.textPrimary),
            onChanged: (_) => setState(() {}),
          ),
        ),
        // Live results dropdown
        if (showResults)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: AdminTheme.cardDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AdminTheme.accentDark),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (matchedLawyers.isNotEmpty) ...
                  matchedLawyers.map((l) => _SearchResultTile(
                    icon: Icons.gavel,
                    iconColor: AdminTheme.statBlue,
                    title: l.name,
                    subtitle: 'Lawyer • ${l.email}',
                    onTap: () {
                      _searchCtrl.clear();
                      setState(() {});
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => AdminUserManagementScreen(initialSearch: l.name),
                      ));
                    },
                  )),
                if (matchedClients.isNotEmpty) ...
                  matchedClients.map((c) => _SearchResultTile(
                    icon: Icons.person,
                    iconColor: AdminTheme.statPurple,
                    title: c.name,
                    subtitle: 'Client • ${c.email}',
                    onTap: () {
                      _searchCtrl.clear();
                      setState(() {});
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => AdminUserManagementScreen(initialSearch: c.name),
                      ));
                    },
                  )),
                if (matchedCases.isNotEmpty) ...
                  matchedCases.map((c) => _SearchResultTile(
                    icon: Icons.folder_open,
                    iconColor: AdminTheme.warning,
                    title: c.title,
                    subtitle: 'Case • ${c.status}',
                    onTap: () {
                      _searchCtrl.clear();
                      setState(() {});
                      final parent = context.findAncestorStateOfType<_AdminDashboardScreenState>();
                      parent?.setState(() => parent._currentIndex = 2);
                    },
                  )),
                if (matchedLawyers.isEmpty && matchedClients.isEmpty && matchedCases.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'No results found',
                      style: TextStyle(color: AdminTheme.textTertiary, fontSize: 13),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback? onViewAll) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: AdminTheme.sectionHeaderStyle(),
        ),
        if (onViewAll != null)
          TextButton(
            onPressed: onViewAll,
            child: const Text(
              'View All',
              style: TextStyle(
                color: AdminTheme.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      (
        'Reports',
        Icons.insert_chart,
        AdminTheme.warning,
        () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminAnalyticsScreen()),
        ),
      ),
      (
        'Verify Bar',
        Icons.verified,
        AdminTheme.success,
        () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const AdminVerificationListScreen(),
          ),
        ),
      ),
      (
        'Users',
        Icons.people,
        AdminTheme.info,
        () {
          // Navigate to Users tab in parent
          final parent = context.findAncestorStateOfType<_AdminDashboardScreenState>();
          parent?.setState(() => parent._currentIndex = 1);
        },
      ),
      (
        'Cases',
        Icons.folder,
        AdminTheme.statGreen,
        () {
          // Navigate to Cases tab in parent
          final parent = context.findAncestorStateOfType<_AdminDashboardScreenState>();
          parent?.setState(() => parent._currentIndex = 2);
        },
      ),
      (
        'Settings',
        Icons.settings,
        AdminTheme.textTertiary,
        () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminSettingsScreen()),
        ),
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: actions
            .map(
              (a) => _QuickActionItem(
                title: a.$1,
                icon: a.$2,
                bgColor: a.$3,
                onTap: a.$4,
              ),
            )
            .toList(),
      ),
    );
  }
}

// ─── Real-time Recent Activity ─────────────────────────────────────────────
class _RecentActivityList extends ConsumerWidget {
  const _RecentActivityList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lawyers = ref.watch(allLawyersProvider);
    final cases = ref.watch(allCasesProvider);

    final events = <Map<String, dynamic>>[];

    if (lawyers.value != null) {
      final sorted = [...lawyers.value!]
        ..sort((a, b) => b.joinedAt.toDate().compareTo(a.joinedAt.toDate()));
      for (final l in sorted.take(3)) {
        events.add({
          'icon': Icons.person_add,
          'bg': AdminTheme.info,
          'title': l.name,
          'desc': 'registered from ${l.location ?? 'unknown'}',
          'time': _timeAgo(l.joinedAt.toDate()),
          'at': l.joinedAt.toDate(),
        });
      }
    }

    if (cases.value != null) {
      final sorted = [...cases.value!]
        ..sort(
          (a, b) => (b.updatedAt ?? b.createdAt).compareTo(
            a.updatedAt ?? a.createdAt,
          ),
        );
      for (final c in sorted.take(2)) {
        events.add({
          'icon': Icons.folder_open,
          'bg': AdminTheme.warning,
          'title': c.title,
          'desc': 'case ${c.status}',
          'time': _timeAgo(c.updatedAt ?? c.createdAt),
          'at': c.updatedAt ?? c.createdAt,
        });
      }
    }

    events.sort((a, b) {
      final ta = a['at'] as DateTime;
      final tb = b['at'] as DateTime;
      return tb.compareTo(ta);
    });

    if (events.isEmpty) {
      if (lawyers.isLoading || cases.isLoading) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(color: AdminTheme.primary),
          ),
        );
      }

      if (lawyers.hasError || cases.hasError) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Text(
            'Unable to load recent activity.',
            style: TextStyle(color: AdminTheme.textTertiary),
          ),
        );
      }

      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'No recent activity.',
          style: TextStyle(color: AdminTheme.textTertiary),
        ),
      );
    }

    return Column(
      children: events
          .take(5)
          .map(
            (e) => _ActivityItem(
              icon: e['icon'] as IconData,
              iconBg: e['bg'] as Color,
              title: e['title'] as String,
              description: e['desc'] as String,
              time: e['time'] as String,
            ),
          )
          .toList(),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ─── Real-time Registration Trends Chart ──────────────────────────────────
class _RegistrationTrendsChart extends ConsumerWidget {
  const _RegistrationTrendsChart();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lawyers = ref.watch(allLawyersProvider);

    // Build 7-day count map
    final now = DateTime.now();
    final days = List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));
    final counts = <DateTime, int>{};
    for (final d in days) {
      counts[DateTime(d.year, d.month, d.day)] = 0;
    }

    if (lawyers.value != null) {
      for (final l in lawyers.value!) {
        final joined = l.joinedAt.toDate();
        final key = DateTime(joined.year, joined.month, joined.day);
        if (counts.containsKey(key)) {
          counts[key] = (counts[key] ?? 0) + 1;
        }
      }
    }

    final maxCount = counts.values.fold<int>(1, (a, b) => b > a ? b : a);

    // Growth % this week vs last week
    final thisWeekCount = counts.values.fold<int>(0, (a, b) => a + b);
    final growthLabel = '+$thisWeekCount this week';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AdminTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdminTheme.accentDark),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
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
              Text(
                'REGISTRATION TRENDS',
                style: AdminTheme.sectionHeaderStyle(),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AdminTheme.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  growthLabel,
                  style: const TextStyle(
                    color: AdminTheme.success,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (lawyers.isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(color: AdminTheme.primary),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: counts.entries.map((entry) {
                  final ratio = maxCount == 0 ? 0.0 : entry.value / maxCount;
                  final barH = (ratio * 80).clamp(6.0, 80.0);
                  final label = DateFormat('EEE').format(entry.key);
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 26,
                          height: 100,
                          alignment: Alignment.bottomCenter,
                          child: TweenAnimationBuilder(
                            tween: Tween<double>(begin: 0, end: barH),
                            duration: const Duration(milliseconds: 1000),
                            curve: Curves.easeOutBack,
                            builder: (ctx, double h, _) => Container(
                              width: 20,
                              height: h,
                              decoration: BoxDecoration(
                                color: AdminTheme.primary,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          entry.value.toString(),
                          style: const TextStyle(
                            color: AdminTheme.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          label,
                          style: const TextStyle(
                            color: AdminTheme.textTertiary,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Stat Card ─────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String title;
  final int value;
  final IconData icon;
  final Color color;
  final bool isLoading;
  final VoidCallback? onTap;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.isLoading = false,
    this.onTap,
  });

  String _fmt(int n) => NumberFormat('#,###').format(n);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AdminTheme.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AdminTheme.accentDark),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const Spacer(),
            if (isLoading)
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              )
            else
              TweenAnimationBuilder(
                tween: IntTween(begin: 0, end: value),
                duration: const Duration(milliseconds: 900),
                builder: (_, int v, _) => Text(
                  _fmt(v),
                  style: const TextStyle(
                    color: AdminTheme.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                color: AdminTheme.textTertiary,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 28,
              child: ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: const Text(
                  'Review',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Quick Action ──────────────────────────────────────────────────────────
class _QuickActionItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color bgColor;
  final VoidCallback onTap;

  const _QuickActionItem({
    required this.title,
    required this.icon,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(right: 12),
        child: SizedBox(
          width: 70,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: bgColor.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 26),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AdminTheme.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Activity Item ─────────────────────────────────────────────────────────
class _ActivityItem extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final String title;
  final String description;
  final String time;

  const _ActivityItem({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.description,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconBg, size: 18),
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
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    color: AdminTheme.textTertiary,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            time,
            style: const TextStyle(
              color: AdminTheme.textTertiary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Search Result Tile ────────────────────────────────────────────────────
class _SearchResultTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SearchResultTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 16),
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
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AdminTheme.textTertiary,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AdminTheme.textTertiary,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Providers (local to this file) ────────────────────────────────────────
final allNotificationsProvider = StreamProvider((ref) {
  return FirebaseFirestore.instance
      .collection('notifications')
      .limit(50)
      .snapshots()
      .map((snap) {
        final docs = snap.docs.toList();
        docs.sort((a, b) {
          final aTime =
              (a.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime(0);
          final bTime =
              (b.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime(0);
          return bTime.compareTo(aTime);
        });
        return docs;
      });
});
