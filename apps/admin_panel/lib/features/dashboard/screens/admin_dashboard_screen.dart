import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milk_core/milk_core.dart';
import 'package:fl_chart/fl_chart.dart';

/// Provider for dashboard stats
final dashboardStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  // Get customer count
  final customersResponse = await SupabaseService.client
      .from('profiles')
      .select('id')
      .eq('role', 'customer');
  final customerCount = customersResponse.length;
  
  // Get active subscription count
  final subsResponse = await SupabaseService.client
      .from('subscriptions')
      .select('id')
      .eq('status', 'active');
  final activeSubCount = subsResponse.length;
  
  // Get today's deliveries
  final today = DateTime.now();
  final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
  final deliveriesResponse = await SupabaseService.client
      .from('deliveries')
      .select('id')
      .eq('scheduled_date', todayStr);
  final todayDeliveries = deliveriesResponse.length;
  
  // Get total revenue from subscriptions
  final revenueResponse = await SupabaseService.client
      .from('subscriptions')
      .select('total_amount');
  double totalRevenue = 0;
  for (final sub in revenueResponse) {
    totalRevenue += (sub['total_amount'] as num?)?.toDouble() ?? 0;
  }
  
  return {
    'customers': customerCount,
    'activeSubscriptions': activeSubCount,
    'todayDeliveries': todayDeliveries,
    'totalRevenue': totalRevenue,
  };
});

/// Admin Dashboard Screen with real stats
class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(dashboardStatsProvider),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats Cards
            statsAsync.when(
              data: (stats) => _buildStatsRow(context, stats),
              loading: () => _buildStatsRowLoading(context),
              error: (e, _) => _buildStatsRow(context, {
                'customers': 0,
                'activeSubscriptions': 0,
                'todayDeliveries': 0,
                'totalRevenue': 0.0,
              }),
            ),
            const SizedBox(height: 24),

            // Charts Row
            LayoutBuilder(
              builder: (context, constraints) {
                final availableWidth = constraints.maxWidth;
                final chartWidth = (availableWidth - 24) / 3;

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: chartWidth * 2,
                      child: _buildRevenueChart(context),
                    ),
                    const SizedBox(width: 24),
                    SizedBox(
                      width: chartWidth,
                      child: _buildSubscriptionPieChart(context),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // Recent Activity
            _buildRecentActivity(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRowLoading(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 800;
        final cardWidth = isWide ? (constraints.maxWidth - 48) / 4 : (constraints.maxWidth - 16) / 2;
        
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: List.generate(4, (_) => SizedBox(
            width: cardWidth,
            height: 140,
            child: const Card(
              child: Center(child: CircularProgressIndicator()),
            ),
          )),
        );
      },
    );
  }

  Widget _buildStatsRow(BuildContext context, Map<String, dynamic> stats) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 800;
        final cardWidth = isWide ? (constraints.maxWidth - 48) / 4 : (constraints.maxWidth - 16) / 2;
        
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildStatCard(
              context,
              title: 'Total Customers',
              value: '${stats['customers'] ?? 0}',
              icon: Icons.people,
              color: Colors.blue,
              width: cardWidth,
            ),
            _buildStatCard(
              context,
              title: 'Active Subscriptions',
              value: '${stats['activeSubscriptions'] ?? 0}',
              icon: Icons.subscriptions,
              color: Colors.green,
              width: cardWidth,
            ),
            _buildStatCard(
              context,
              title: 'Today\'s Deliveries',
              value: '${stats['todayDeliveries'] ?? 0}',
              icon: Icons.local_shipping,
              color: Colors.orange,
              width: cardWidth,
            ),
            _buildStatCard(
              context,
              title: 'Total Revenue',
              value: '₹${((stats['totalRevenue'] ?? 0) as num).toStringAsFixed(0)}',
              icon: Icons.currency_rupee,
              color: Colors.purple,
              width: cardWidth,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required double width,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: width,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 16),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRevenueChart(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Revenue Overview',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 20000,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: colorScheme.outlineVariant,
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (value, meta) => Text(
                          '₹${(value / 1000).toStringAsFixed(0)}k',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
                          if (value.toInt() < months.length) {
                            return Text(
                              months[value.toInt()],
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 12,
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: const [
                        FlSpot(0, 45000),
                        FlSpot(1, 52000),
                        FlSpot(2, 48000),
                        FlSpot(3, 61000),
                        FlSpot(4, 58000),
                        FlSpot(5, 72000),
                      ],
                      isCurved: true,
                      color: colorScheme.primary,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      belowBarData: BarAreaData(
                        show: true,
                        color: colorScheme.primary.withOpacity(0.1),
                      ),
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionPieChart(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Subscription Types',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 50,
                  sections: [
                    PieChartSectionData(
                      value: 45,
                      title: '45%',
                      color: Colors.blue,
                      radius: 40,
                      titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    PieChartSectionData(
                      value: 30,
                      title: '30%',
                      color: Colors.green,
                      radius: 40,
                      titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    PieChartSectionData(
                      value: 15,
                      title: '15%',
                      color: Colors.orange,
                      radius: 40,
                      titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    PieChartSectionData(
                      value: 10,
                      title: '10%',
                      color: Colors.purple,
                      radius: 40,
                      titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildLegendItem('Full Cream', Colors.blue, '45%'),
            _buildLegendItem('Toned', Colors.green, '30%'),
            _buildLegendItem('Buffalo', Colors.orange, '15%'),
            _buildLegendItem('Double Toned', Colors.purple, '10%'),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, String percentage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 8),
          Text(label),
          const Spacer(),
          Text(percentage, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildQuickAction(
                  context,
                  icon: Icons.person_add,
                  label: 'Add Customer',
                  color: Colors.blue,
                ),
                _buildQuickAction(
                  context,
                  icon: Icons.subscriptions,
                  label: 'View Subscriptions',
                  color: Colors.green,
                ),
                _buildQuickAction(
                  context,
                  icon: Icons.local_shipping,
                  label: 'Generate Orders',
                  color: Colors.orange,
                ),
                _buildQuickAction(
                  context,
                  icon: Icons.bar_chart,
                  label: 'View Reports',
                  color: Colors.purple,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
