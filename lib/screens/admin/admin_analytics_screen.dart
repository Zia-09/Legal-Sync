import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:legal_sync/provider/case_provider.dart';
import 'package:legal_sync/provider/client_provider.dart';
import 'package:legal_sync/provider/lawyer_provider.dart';
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

    final filteredCases = cases
        .where((c) => _isDateInRange(c.createdAt))
        .toList();
    final filteredLawyers = lawyers
        .where((l) => _isDateInRange(l.joinedAt.toDate()))
        .toList();
    final filteredClients = clients
        .where((c) => _isDateInRange(c.joinedAt.toDate()))
        .toList();

    int newLeads = filteredLawyers.length + filteredClients.length;
    int revenue =
        filteredCases
            .where(
              (c) =>
                  c.status.toLowerCase() == 'closed' ||
                  c.status.toLowerCase() == 'completed' ||
                  c.status.toLowerCase() == 'resolved',
            )
            .length *
        500;

    return '''
LegalSync Admin Report
Filter: $_selectedFilter
-------------------------
New Leads: $newLeads
New Cases: ${filteredCases.length}
Est. Revenue: \$$revenue
    ''';
  }

  void _shareReport() {
    Share.share(_generateReportText(), subject: 'LegalSync Analytics Report');
  }

  void _downloadCsv() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exporting report...'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Color(0xFF1E3A8A),
      ),
    );
    Share.share(_generateReportText(), subject: 'LegalSync CSV Export');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Analytics & Growth',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Color(0xFF1E3A8A)),
            onPressed: _shareReport,
          ),
          IconButton(
            icon: const Icon(Icons.download_outlined, color: Color(0xFF1E3A8A)),
            onPressed: _downloadCsv,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(25),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: const Color(0xFF1E3A8A),
              unselectedLabelColor: const Color(0xFF6B7280),
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              tabs: const [
                Tab(text: 'Case Stats'),
                Tab(text: 'User Growth'),
              ],
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
    return _FilterChip(
      label: label == 'Custom' && _customDateRange != null
          ? '${_customDateRange!.start.day}/${_customDateRange!.start.month} - ${_customDateRange!.end.day}/${_customDateRange!.end.month}'
          : label,
      isSelected: _selectedFilter == label,
      onTap: () async {
        if (label == 'Custom') {
          final range = await showDateRangePicker(
            context: context,
            initialDateRange: _customDateRange,
            firstDate: DateTime(2020),
            lastDate: DateTime.now(),
            builder: (context, child) {
              return Theme(
                data: ThemeData.light().copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: Color(0xFF1E3A8A),
                  ),
                ),
                child: child!,
              );
            },
          );
          if (range != null) {
            setState(() {
              _selectedFilter = 'Custom';
              _customDateRange = range;
            });
          }
        } else {
          setState(() {
            _selectedFilter = label;
            _customDateRange = null;
          });
        }
      },
    );
  }

  bool _isDateInRange(DateTime date) {
    final now = DateTime.now();
    switch (_selectedFilter) {
      case 'Today':
        return date.year == now.year &&
            date.month == now.month &&
            date.day == now.day;
      case 'This Week':
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        return date.isAfter(startOfWeek.subtract(const Duration(days: 1)));
      case 'Month':
        return date.year == now.year && date.month == now.month;
      case 'Custom':
        if (_customDateRange == null) return true;
        return date.isAfter(
              _customDateRange!.start.subtract(const Duration(days: 1)),
            ) &&
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

    final filteredCases = cases
        .where((c) => _isDateInRange(c.createdAt))
        .toList();
    final filteredLawyers = lawyers
        .where((l) => _isDateInRange(l.joinedAt.toDate()))
        .toList();
    final filteredClients = clients
        .where((c) => _isDateInRange(c.joinedAt.toDate()))
        .toList();

    // Stats calculations
    final newLeadsCount = filteredLawyers.length + filteredClients.length;

    Duration totalResponseTime = Duration.zero;
    int respondedCasesCount = 0;
    for (var c in filteredCases) {
      if (c.updatedAt != null) {
        totalResponseTime += c.updatedAt!.difference(c.createdAt);
        respondedCasesCount++;
      }
    }
    final avgResponseTime = respondedCasesCount > 0
        ? (totalResponseTime.inMinutes / respondedCasesCount).round()
        : 0;

    // Revenue mock calculation: 500 per closed case
    final revenue =
        filteredCases
            .where(
              (c) =>
                  c.status.toLowerCase() == 'closed' ||
                  c.status.toLowerCase() == 'completed' ||
                  c.status.toLowerCase() == 'resolved',
            )
            .length *
        500;

    // Case Distribution Data
    final Map<String, int> typeCounts = {};
    for (var c in filteredCases) {
      final type = c.caseType?.isNotEmpty == true ? c.caseType! : 'General';
      typeCounts[type] = (typeCounts[type] ?? 0) + 1;
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time Filters
          Row(
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
          const SizedBox(height: 24),

          // Case Distribution
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
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
                      'Case Distribution',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Icon(Icons.info_outline, color: Colors.grey[400], size: 18),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    // Dynamic Pie Chart
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: filteredCases.isEmpty
                          ? const Center(
                              child: Text(
                                'No cases',
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : PieChart(
                              PieChartData(
                                sectionsSpace: 2,
                                centerSpaceRadius: 35,
                                sections: typeCounts.entries
                                    .toList()
                                    .asMap()
                                    .entries
                                    .map((entry) {
                                      final idx = entry.key;
                                      final stat = entry.value;
                                      final double percentage =
                                          (stat.value / filteredCases.length) *
                                          100;
                                      final colors = [
                                        const Color(0xFF1E3A8A),
                                        const Color(0xFFE67E22),
                                        const Color(0xFF059669),
                                        Colors.red,
                                        Colors.purple,
                                      ];
                                      return PieChartSectionData(
                                        color: colors[idx % colors.length],
                                        value: percentage,
                                        title:
                                            '${percentage.toStringAsFixed(0)}%',
                                        radius: 12,
                                        titleStyle: const TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      );
                                    })
                                    .toList(),
                              ),
                            ),
                    ),
                    const SizedBox(width: 24),
                    // Legend
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: typeCounts.entries
                            .toList()
                            .asMap()
                            .entries
                            .map((entry) {
                              final idx = entry.key;
                              final stat = entry.value;
                              final double percentage =
                                  (stat.value / filteredCases.length) * 100;
                              final colors = [
                                const Color(0xFF1E3A8A),
                                const Color(0xFFE67E22),
                                const Color(0xFF059669),
                                Colors.red,
                                Colors.purple,
                              ];
                              return _LegendItem(
                                color: colors[idx % colors.length],
                                label: stat.key,
                                percentage: '${percentage.toStringAsFixed(0)}%',
                              );
                            })
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Key Performance Metrics
          const Text(
            'Key Performance Metrics',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 16),
          _MetricRow(
            title: 'New Leads',
            value: newLeadsCount.toString(),
            growth: '+Active',
            isPositive: true,
          ),
          _MetricRow(
            title: 'Avg Response Time',
            value: '${avgResponseTime}m',
            growth: 'Tracking',
            isPositive: avgResponseTime < 60,
          ),
          _MetricRow(
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
    final months = List.generate(5, (i) {
      return DateTime(now.year, now.month - i, 1);
    }).reversed.toList();

    List<FlSpot> clientSpots = [];
    List<FlSpot> lawyerSpots = [];
    List<String> monthLabels = [];
    double maxVal = 5;

    for (int i = 0; i < 5; i++) {
      final monthStart = months[i];
      final nextMonth = DateTime(monthStart.year, monthStart.month + 1, 1);

      int cCount = clients.where((c) {
        final dt = c.joinedAt.toDate();
        return dt.isAfter(monthStart.subtract(const Duration(days: 1))) &&
            dt.isBefore(nextMonth);
      }).length;

      int lCount = lawyers.where((l) {
        final dt = l.joinedAt.toDate();
        return dt.isAfter(monthStart.subtract(const Duration(days: 1))) &&
            dt.isBefore(nextMonth);
      }).length;

      if (cCount > maxVal) maxVal = cCount.toDouble();
      if (lCount > maxVal) maxVal = lCount.toDouble();

      clientSpots.add(FlSpot(i.toDouble(), cCount.toDouble()));
      lawyerSpots.add(FlSpot(i.toDouble(), lCount.toDouble()));
      monthLabels.add(DateFormat('MMM').format(monthStart));
    }

    final topLawyers = List.of(lawyers)
      ..sort((a, b) => b.rating.compareTo(a.rating));
    final displayLawyers = topLawyers.take(3).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Growth Chart Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'User Growth',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '+12% from last month',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 4,
                          backgroundColor: Color(0xFFE67E22),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'LAWYERS',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const CircleAvatar(
                          radius: 4,
                          backgroundColor: Color(0xFF1E3A8A),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'CLIENTS',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                SizedBox(
                  height: 150,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(show: false),
                      titlesData: FlTitlesData(
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() >= 0 &&
                                  value.toInt() < monthLabels.length) {
                                return Text(
                                  monthLabels[value.toInt()],
                                  style: const TextStyle(
                                    color: Colors.grey,
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
                      maxY: maxVal + (maxVal * 0.2), // 20% padding
                      lineBarsData: [
                        LineChartBarData(
                          spots: clientSpots,
                          isCurved: true,
                          color: const Color(0xFF1E3A8A),
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: const Color(
                              0xFF1E3A8A,
                            ).withValues(alpha: 0.1),
                          ),
                        ),
                        LineChartBarData(
                          spots: lawyerSpots,
                          isCurved: true,
                          color: const Color(0xFFE67E22),
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: const Color(
                              0xFFE67E22,
                            ).withValues(alpha: 0.1),
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
              const Text(
                'Top Performing Lawyers',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to users management with focus on lawyers
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const AdminUserManagementScreen(initialSearch: ''),
                    ),
                  );
                },
                child: const Text(
                  'View All',
                  style: TextStyle(color: Color(0xFF1E3A8A)),
                ),
              ),
            ],
          ),

          // Lawyer List
          if (displayLawyers.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  "No Lawyers available",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ...displayLawyers.map((l) {
            return _TopLawyerItem(
              name: l.name,
              court: '${l.specialization} • ${l.location ?? "Unknown"}',
              rating: (l.rating > 0 ? l.rating : l.aiScore).toStringAsFixed(1),
              subtitle: 'RATING',
              avatarColor: Colors.blue,
            );
          }),
        ],
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

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final String percentage;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(radius: 4, backgroundColor: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(color: Color(0xFF4B5563), fontSize: 12),
              ),
            ],
          ),
          Text(
            percentage,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String title;
  final String value;
  final String growth;
  final bool isPositive;

  const _MetricRow({
    required this.title,
    required this.value,
    required this.growth,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
          ),
          Row(
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isPositive
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                      color: isPositive ? Colors.green : Colors.red,
                      size: 10,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      growth,
                      style: TextStyle(
                        color: isPositive ? Colors.green : Colors.red,
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
}

class _TopLawyerItem extends StatelessWidget {
  final String name;
  final String court;
  final String rating;
  final String subtitle;
  final Color avatarColor;

  const _TopLawyerItem({
    required this.name,
    required this.court,
    required this.rating,
    required this.subtitle,
    required this.avatarColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: avatarColor.withValues(alpha: 0.2),
        child: Icon(Icons.person, color: avatarColor),
      ),
      title: Text(
        name,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
      subtitle: Text(
        court,
        style: const TextStyle(color: Colors.grey, fontSize: 11),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            rating,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.grey, fontSize: 8),
          ),
        ],
      ),
    );
  }
}
