import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:legal_sync/provider/case_provider.dart';
import 'package:legal_sync/provider/client_provider.dart';
import 'package:legal_sync/provider/lawyer_provider.dart';
import 'package:legal_sync/config/admin_theme.dart';
import 'package:legal_sync/screens/admin/admin_user_management_screen.dart';

class AdminAnalyticsScreen extends ConsumerStatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  ConsumerState<AdminAnalyticsScreen> createState() =>
      _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends ConsumerState<AdminAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = 'This Week';
  DateTimeRange? _customDateRange;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _generateReportText() {
    final cases = ref.read(allCasesProvider).value ?? [];
    final lawyers = ref.read(allLawyersProvider).value ?? [];
    final clients = ref.read(allClientsProvider).value ?? [];
    final filteredCases = cases.where((c) => _isDateInRange(c.createdAt)).toList();
    final filteredLawyers = lawyers.where((l) => _isDateInRange(l.joinedAt.toDate())).toList();
    final filteredClients = clients.where((c) => _isDateInRange(c.joinedAt.toDate())).toList();
    final newLeads = filteredLawyers.length + filteredClients.length;
    final revenue = filteredCases
            .where((c) =>
                c.status.toLowerCase() == 'closed' ||
                c.status.toLowerCase() == 'completed' ||
                c.status.toLowerCase() == 'resolved')
            .length *
        500;
    return '''LegalSync Admin Report\nFilter: $_selectedFilter\n-------------------------\nNew Leads: $newLeads\nNew Cases: ${filteredCases.length}\nEst. Revenue: \$$revenue''';
  }

  void _shareReport() {
    SharePlus.instance.share(
      ShareParams(text: _generateReportText(), subject: 'LegalSync Analytics Report'),
    );
  }

  void _downloadCsv() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exporting report...'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AdminTheme.primary,
      ),
    );
    SharePlus.instance.share(
      ShareParams(text: _generateReportText(), subject: 'LegalSync CSV Export'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminTheme.primaryDark,
      appBar: AppBar(
        backgroundColor: AdminTheme.cardDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AdminTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Analytics & Growth',
          style: TextStyle(color: AdminTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: AdminTheme.primary),
            onPressed: _shareReport,
          ),
          IconButton(
            icon: const Icon(Icons.download_outlined, color: AdminTheme.primary),
            onPressed: _downloadCsv,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: AdminTheme.surfaceDark,
              borderRadius: BorderRadius.circular(25),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AdminTheme.primary,
                borderRadius: BorderRadius.circular(25),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: AdminTheme.textTertiary,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: const [Tab(text: 'Case Stats'), Tab(text: 'User Growth')],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildCaseStatsTab(), _buildUserGrowthTab(context)],
      ),
    );
  }

  Widget _buildTimeFilter(String label) {
    final isSelected = _selectedFilter == label;
    final displayLabel = label == 'Custom' && _customDateRange != null
        ? '${_customDateRange!.start.day}/${_customDateRange!.start.month} - ${_customDateRange!.end.day}/${_customDateRange!.end.month}'
        : label;
    return GestureDetector(
      onTap: () async {
        if (label == 'Custom') {
          final range = await showDateRangePicker(
            context: context,
            initialDateRange: _customDateRange,
            firstDate: DateTime(2020),
            lastDate: DateTime.now(),
            builder: (context, child) => Theme(
              data: ThemeData.dark().copyWith(
                colorScheme: const ColorScheme.dark(primary: AdminTheme.primary),
              ),
              child: child!,
            ),
          );
          if (range != null) setState(() { _selectedFilter = 'Custom'; _customDateRange = range; });
        } else {
          setState(() { _selectedFilter = label; _customDateRange = null; });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AdminTheme.primary : AdminTheme.surfaceDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AdminTheme.primary : AdminTheme.accentDark),
        ),
        child: Text(
          displayLabel,
          style: TextStyle(
            color: isSelected ? Colors.white : AdminTheme.textTertiary,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  bool _isDateInRange(DateTime date) {
    final now = DateTime.now();
    switch (_selectedFilter) {
      case 'Today':
        return date.year == now.year && date.month == now.month && date.day == now.day;
      case 'This Week':
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        return date.isAfter(startOfWeek.subtract(const Duration(days: 1)));
      case 'Month':
        return date.year == now.year && date.month == now.month;
      case 'Custom':
        if (_customDateRange == null) return true;
        return date.isAfter(_customDateRange!.start.subtract(const Duration(days: 1))) &&
            date.isBefore(_customDateRange!.end.add(const Duration(days: 1)));
      default:
        return true;
    }
  }

  Widget _buildCaseStatsTab() {
    final casesAsync = ref.watch(allCasesProvider);
    final lawyersAsync = ref.watch(allLawyersProvider);
    final clientsAsync = ref.watch(allClientsProvider);

    final cases = casesAsync.value ?? [];
    final lawyers = lawyersAsync.value ?? [];
    final clients = clientsAsync.value ?? [];

    final filteredCases = cases.where((c) => _isDateInRange(c.createdAt)).toList();
    final filteredLawyers = lawyers.where((l) => _isDateInRange(l.joinedAt.toDate())).toList();
    final filteredClients = clients.where((c) => _isDateInRange(c.joinedAt.toDate())).toList();

    final newLeadsCount = filteredLawyers.length + filteredClients.length;

    Duration totalResponseTime = Duration.zero;
    int respondedCount = 0;
    for (var c in filteredCases) {
      if (c.updatedAt != null) {
        totalResponseTime += c.updatedAt!.difference(c.createdAt);
        respondedCount++;
      }
    }
    final avgResponseTime = respondedCount > 0
        ? (totalResponseTime.inMinutes / respondedCount).round()
        : 0;

    final revenue = filteredCases
            .where((c) =>
                c.status.toLowerCase() == 'closed' ||
                c.status.toLowerCase() == 'completed' ||
                c.status.toLowerCase() == 'resolved')
            .length *
        500;

    final Map<String, int> typeCounts = {};
    for (var c in filteredCases) {
      final type = c.caseType?.isNotEmpty == true ? c.caseType! : 'General';
      typeCounts[type] = (typeCounts[type] ?? 0) + 1;
    }

    final List<Color> chartColors = [
      AdminTheme.primary,
      AdminTheme.warning,
      AdminTheme.success,
      AdminTheme.danger,
      AdminTheme.statPurple,
    ];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildTimeFilter('Today'),
                const SizedBox(width: 8),
                _buildTimeFilter('This Week'),
                const SizedBox(width: 8),
                _buildTimeFilter('Month'),
                const SizedBox(width: 8),
                _buildTimeFilter('Custom'),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Case Distribution Card
          _darkCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Case Distribution',
                      style: TextStyle(
                        color: AdminTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AdminTheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${filteredCases.length} cases',
                        style: const TextStyle(
                          color: AdminTheme.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (filteredCases.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'No cases in this period',
                        style: TextStyle(color: AdminTheme.textTertiary),
                      ),
                    ),
                  )
                else
                  Row(
                    children: [
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 35,
                            sections: typeCounts.entries.toList().asMap().entries.map((entry) {
                              final idx = entry.key;
                              final stat = entry.value;
                              final percentage = (stat.value / filteredCases.length) * 100;
                              return PieChartSectionData(
                                color: chartColors[idx % chartColors.length],
                                value: percentage,
                                title: '${percentage.toStringAsFixed(0)}%',
                                radius: 12,
                                titleStyle: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          children: typeCounts.entries.toList().asMap().entries.map((entry) {
                            final idx = entry.key;
                            final stat = entry.value;
                            final pct = (stat.value / filteredCases.length) * 100;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 4,
                                        backgroundColor: chartColors[idx % chartColors.length],
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        stat.key,
                                        style: const TextStyle(
                                          color: AdminTheme.textSecondary,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '${pct.toStringAsFixed(0)}%',
                                    style: const TextStyle(
                                      color: AdminTheme.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
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
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Key Performance Metrics
          Text('KEY PERFORMANCE METRICS', style: AdminTheme.sectionHeaderStyle()),
          const SizedBox(height: 16),
          _metricCard(
            icon: Icons.people_outline,
            iconColor: AdminTheme.statBlue,
            title: 'New Leads',
            value: newLeadsCount.toString(),
            growth: '+Active',
            isPositive: true,
          ),
          const SizedBox(height: 10),
          _metricCard(
            icon: Icons.timer_outlined,
            iconColor: AdminTheme.warning,
            title: 'Avg Response Time',
            value: '${avgResponseTime}m',
            growth: 'Tracking',
            isPositive: avgResponseTime < 60,
          ),
          const SizedBox(height: 10),
          _metricCard(
            icon: Icons.attach_money,
            iconColor: AdminTheme.success,
            title: 'Est. Revenue (USD)',
            value: '\$${revenue.toStringAsFixed(0)}',
            growth: '+Est.',
            isPositive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildUserGrowthTab(BuildContext context) {
    final lawyersAsync = ref.watch(allLawyersProvider);
    final clientsAsync = ref.watch(allClientsProvider);

    final lawyers = lawyersAsync.value ?? [];
    final clients = clientsAsync.value ?? [];

    final now = DateTime.now();
    final months = List.generate(5, (i) => DateTime(now.year, now.month - i, 1)).reversed.toList();

    List<FlSpot> clientSpots = [];
    List<FlSpot> lawyerSpots = [];
    List<String> monthLabels = [];
    double maxVal = 5;

    for (int i = 0; i < 5; i++) {
      final monthStart = months[i];
      final nextMonth = DateTime(monthStart.year, monthStart.month + 1, 1);
      int cCount = clients.where((c) {
        final dt = c.joinedAt.toDate();
        return dt.isAfter(monthStart.subtract(const Duration(days: 1))) && dt.isBefore(nextMonth);
      }).length;
      int lCount = lawyers.where((l) {
        final dt = l.joinedAt.toDate();
        return dt.isAfter(monthStart.subtract(const Duration(days: 1))) && dt.isBefore(nextMonth);
      }).length;
      if (cCount > maxVal) maxVal = cCount.toDouble();
      if (lCount > maxVal) maxVal = lCount.toDouble();
      clientSpots.add(FlSpot(i.toDouble(), cCount.toDouble()));
      lawyerSpots.add(FlSpot(i.toDouble(), lCount.toDouble()));
      monthLabels.add(DateFormat('MMM').format(monthStart));
    }

    final topLawyers = List.of(lawyers)..sort((a, b) => b.rating.compareTo(a.rating));
    final displayLawyers = topLawyers.take(3).toList();

    // Compute total & growth
    final thisMonthClients = clients.where((c) {
      final dt = c.joinedAt.toDate();
      return dt.year == now.year && dt.month == now.month;
    }).length;
    final lastMonthClients = clients.where((c) {
      final dt = c.joinedAt.toDate();
      final lm = now.month == 1 ? 12 : now.month - 1;
      final ly = now.month == 1 ? now.year - 1 : now.year;
      return dt.year == ly && dt.month == lm;
    }).length;
    final growthPct = lastMonthClients > 0
        ? (((thisMonthClients - lastMonthClients) / lastMonthClients) * 100).toStringAsFixed(0)
        : '—';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _darkCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'User Growth',
                          style: TextStyle(
                            color: AdminTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          lastMonthClients > 0 ? '$growthPct% from last month' : 'Tracking growth',
                          style: const TextStyle(color: AdminTheme.textTertiary, fontSize: 12),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        CircleAvatar(radius: 4, backgroundColor: AdminTheme.warning),
                        const SizedBox(width: 4),
                        Text('LAWYERS', style: AdminTheme.sectionHeaderStyle()),
                        const SizedBox(width: 12),
                        CircleAvatar(radius: 4, backgroundColor: AdminTheme.primary),
                        const SizedBox(width: 4),
                        Text('CLIENTS', style: AdminTheme.sectionHeaderStyle()),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                SizedBox(
                  height: 150,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawHorizontalLine: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (_) => FlLine(
                          color: AdminTheme.accentDark,
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final idx = value.toInt();
                              if (idx >= 0 && idx < monthLabels.length) {
                                return Text(
                                  monthLabels[idx],
                                  style: const TextStyle(
                                    color: AdminTheme.textTertiary,
                                    fontSize: 10,
                                  ),
                                );
                              }
                              return const SizedBox();
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      minX: 0,
                      maxX: 4,
                      minY: 0,
                      maxY: maxVal + (maxVal * 0.2),
                      lineBarsData: [
                        LineChartBarData(
                          spots: clientSpots,
                          isCurved: true,
                          color: AdminTheme.primary,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: AdminTheme.primary.withValues(alpha: 0.1),
                          ),
                        ),
                        LineChartBarData(
                          spots: lawyerSpots,
                          isCurved: true,
                          color: AdminTheme.warning,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: AdminTheme.warning.withValues(alpha: 0.1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('TOP PERFORMING LAWYERS', style: AdminTheme.sectionHeaderStyle()),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminUserManagementScreen(initialSearch: '')),
                ),
                child: const Text(
                  'View All',
                  style: TextStyle(color: AdminTheme.primary, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (displayLawyers.isEmpty)
            _darkCard(
              child: const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'No lawyers available',
                    style: TextStyle(color: AdminTheme.textTertiary),
                  ),
                ),
              ),
            )
          else
            ...displayLawyers.map((l) => _lawyerCard(l.name,
                '${l.specialization} • ${l.location ?? "Unknown"}',
                (l.rating > 0 ? l.rating : l.aiScore).toStringAsFixed(1))),
        ],
      ),
    );
  }

  Widget _darkCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdminTheme.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AdminTheme.accentDark),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _metricCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String growth,
    required bool isPositive,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AdminTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminTheme.accentDark),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: AdminTheme.textTertiary, fontSize: 13),
            ),
          ),
          Row(
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: AdminTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (isPositive ? AdminTheme.success : AdminTheme.danger)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                      color: isPositive ? AdminTheme.success : AdminTheme.danger,
                      size: 10,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      growth,
                      style: TextStyle(
                        color: isPositive ? AdminTheme.success : AdminTheme.danger,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _lawyerCard(String name, String court, String rating) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AdminTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminTheme.accentDark),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AdminTheme.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: AdminTheme.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: AdminTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  court,
                  style: const TextStyle(color: AdminTheme.textTertiary, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                rating,
                style: const TextStyle(
                  color: AdminTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Text(
                'RATING',
                style: TextStyle(color: AdminTheme.textTertiary, fontSize: 8),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
