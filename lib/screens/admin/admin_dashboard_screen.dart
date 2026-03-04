import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legal_sync/provider/case_provider.dart';
import 'package:legal_sync/provider/client_provider.dart';
import 'package:legal_sync/provider/lawyer_provider.dart';
import 'package:legal_sync/provider/notification_provider.dart';
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
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF1E3A8A),
        unselectedItemColor: const Color(0xFF9CA3AF),
        showUnselectedLabels: true,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        backgroundColor: Colors.white,
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
      backgroundColor: const Color(0xFFF5F7FA),
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
                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 1.05,
                      children: [
                        _StatCard(
                          title: 'Total Lawyers',
                          value: allLawyers.value?.length ?? 0,
                          icon: Icons.business_center,
                          color: const Color(0xFF1E3A8A),
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
                                        c.status.toLowerCase() == 'active' ||
                                        c.status.toLowerCase() == 'in_progress',
                                  )
                                  .length ??
                              0,
                          icon: Icons.folder,
                          color: const Color(0xFF059669),
                          isLoading: allCases.isLoading,
                          onTap: () {},
                        ),
                        _StatCard(
                          title: 'Pending Verifications',
                          value: pendingVerifications.value?.length ?? 0,
                          icon: Icons.verified_user,
                          color: const Color(0xFFE67E22),
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
                          color: const Color(0xFF7C3AED),
                          isLoading: allClients.isLoading,
                          onTap: () {},
                        ),
                      ],
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
      backgroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.gavel, color: Color(0xFF1E3A8A), size: 20),
          ),
          const SizedBox(width: 8),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LegalSync',
                style: TextStyle(
                  color: Color(0xFF1E3A8A),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                'ADMIN PORTAL',
                style: TextStyle(
                  color: Color(0xFF6B7280),
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
                    color: Color(0xFF1F2937),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 2,
                      top: 4,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE67E22),
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
              backgroundColor: Color(0xFF1E3A8A),
              child: Icon(Icons.person, size: 20, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchCtrl,
        onSubmitted: (query) {
          if (query.trim().isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    AdminUserManagementScreen(initialSearch: query.trim()),
              ),
            );
          }
        },
        decoration: InputDecoration(
          hintText: 'Search lawyers, cases or clients...',
          hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
          prefixIcon: const Icon(
            Icons.search,
            color: Color(0xFF9CA3AF),
            size: 20,
          ),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: Color(0xFF9CA3AF),
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
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback? onViewAll) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF4B5563),
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        if (onViewAll != null)
          TextButton(
            onPressed: onViewAll,
            child: const Text(
              'View All',
              style: TextStyle(
                color: Color(0xFF1E3A8A),
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
        const Color(0xFFE67E22),
        () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminAnalyticsScreen()),
        ),
      ),
      (
        'Verify Bar',
        Icons.verified,
        const Color(0xFF059669),
        () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const AdminVerificationListScreen(),
          ),
        ),
      ),
      (
        'Support',
        Icons.support_agent,
        const Color(0xFF7C3AED),
        () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Support center coming soon!'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Color(0xFF7C3AED),
          ),
        ),
      ),
      (
        'System',
        Icons.settings,
        const Color(0xFF4B5563),
        () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminSettingsScreen()),
        ),
      ),
    ];

    return SizedBox(
      height: 90,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
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
          'bg': const Color(0xFF1E3A8A),
          'title': l.name,
          'desc': 'registered from ${l.location ?? 'unknown location'}.',
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
          'bg': const Color(0xFFE67E22),
          'title': c.title,
          'desc': 'case ${c.status}.',
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
            child: CircularProgressIndicator(color: Color(0xFF1E3A8A)),
          ),
        );
      }

      if (lawyers.hasError || cases.hasError) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Text(
            'Unable to load recent activity.',
            style: TextStyle(color: Colors.grey),
          ),
        );
      }

      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'No recent activity.',
          style: TextStyle(color: Colors.grey),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
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
              const Text(
                'REGISTRATION TRENDS',
                style: TextStyle(
                  color: Color(0xFF4B5563),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF059669).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  growthLabel,
                  style: const TextStyle(
                    color: Color(0xFF059669),
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
                child: CircularProgressIndicator(color: Color(0xFF1E3A8A)),
              ),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: counts.entries.map((entry) {
                final ratio = maxCount == 0 ? 0.0 : entry.value / maxCount;
                final barH = (ratio * 90).clamp(6.0, 90.0);
                final label = DateFormat('EEE').format(entry.key);
                return Column(
                  children: [
                    Container(
                      width: 30,
                      height: 100,
                      alignment: Alignment.bottomCenter,
                      child: TweenAnimationBuilder(
                        tween: Tween<double>(begin: 0, end: barH),
                        duration: const Duration(milliseconds: 1000),
                        curve: Curves.easeOutBack,
                        builder: (ctx, double h, _) => Container(
                          width: 24,
                          height: h,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E3A8A),
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
                        color: Color(0xFF1E3A8A),
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      style: const TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontSize: 10,
                      ),
                    ),
                  ],
                );
              }).toList(),
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const Spacer(),
            if (isLoading)
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2, color: color),
              )
            else
              TweenAnimationBuilder(
                tween: IntTween(begin: 0, end: value),
                duration: const Duration(milliseconds: 900),
                builder: (_, int v, __) => Text(
                  _fmt(v),
                  style: const TextStyle(
                    color: Color(0xFF1F2937),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(height: 2),
            Text(
              title,
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 24,
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
                  'REVIEW NOW',
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
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        width: 72,
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: bgColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF4B5563),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
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
              color: iconBg.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconBg, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF4B5563),
                      height: 1.4,
                    ),
                    children: [
                      TextSpan(
                        text: '$title ',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      TextSpan(text: description),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: const TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Providers (local to this file) ────────────────────────────────────────
final allNotificationsProvider = StreamProvider((ref) {
  return FirebaseFirestore.instance
      .collection('notifications')
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map((snap) => snap.docs);
});
