import 'package:flutter/material.dart';
import 'package:milk_core/milk_core.dart';
import 'package:fl_chart/fl_chart.dart';

/// Admin Dashboard Screen with stats and charts
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            onPressed: () {},
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
            _buildStatsRow(context),
            const SizedBox(height: 24),

            // Charts Row
            LayoutBuilder(
              builder: (context, constraints) {
                final availableWidth = constraints.maxWidth;
                final chartWidth = (availableWidth - 24) / 3; // 2:1 ratio with spacing

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Revenue Chart
                    SizedBox(
                      width: chartWidth * 2,
                      child: _buildRevenueChart(context),
                    ),
                    const SizedBox(width: 24),

                    // Subscription Types
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

  Widget _buildStatsRow(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 800;
        
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildStatCard(
              context,
              title: 'Total Customers',
              value: '1,247',
              change: '+12%',
              isPositive: true,
              icon: Icons.people,
              color: Colors.blue,
              width: isWide ? (constraints.maxWidth - 48) / 4 : (constraints.maxWidth - 16) / 2,
            ),
            _buildStatCard(
              context,
              title: 'Active Subscriptions',
              value: '892',
              change: '+8%',
              isPositive: true,
              icon: Icons.subscriptions,
              color: Colors.green,
              width: isWide ? (constraints.maxWidth - 48) / 4 : (constraints.maxWidth - 16) / 2,
            ),
            _buildStatCard(
              context,
              title: 'Today\'s Orders',
              value: '156',
              change: '-3%',
              isPositive: false,
              icon: Icons.shopping_bag,
              color: Colors.orange,
              width: isWide ? (constraints.maxWidth - 48) / 4 : (constraints.maxWidth - 16) / 2,
            ),
            _buildStatCard(
              context,
              title: 'Monthly Revenue',
              value: '₹2,45,890',
              change: '+15%',
              isPositive: true,
              icon: Icons.currency_rupee,
              color: Colors.purple,
              width: isWide ? (constraints.maxWidth - 48) / 4 : (constraints.maxWidth - 16) / 2,
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
    required String change,
    required bool isPositive,
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isPositive 
                          ? AppTheme.successColor.withValues(alpha: 0.1)
                          : AppTheme.errorColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                          size: 14,
                          color: isPositive ? AppTheme.successColor : AppTheme.errorColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          change,
                          style: TextStyle(
                            color: isPositive ? AppTheme.successColor : AppTheme.errorColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
                        color: colorScheme.primary.withValues(alpha: 0.1),
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
    // final colorScheme = Theme.of(context).colorScheme;

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
            _buildLegendItem('Organic', Colors.purple, '10%'),
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
    // final colorScheme = Theme.of(context).colorScheme;

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
                  'Recent Activity',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildActivityItem(
              context,
              icon: Icons.person_add,
              color: Colors.blue,
              title: 'New customer registered',
              subtitle: 'Rahul Sharma - +91 98765 43210',
              time: '2 mins ago',
            ),
            _buildActivityItem(
              context,
              icon: Icons.subscriptions,
              color: Colors.green,
              title: 'New subscription activated',
              subtitle: 'Full Cream Milk - Daily Plan',
              time: '15 mins ago',
            ),
            _buildActivityItem(
              context,
              icon: Icons.account_balance_wallet,
              color: Colors.orange,
              title: 'Wallet recharged',
              subtitle: '₹500 added by Priya Singh',
              time: '1 hour ago',
            ),
            _buildActivityItem(
              context,
              icon: Icons.local_shipping,
              color: Colors.purple,
              title: 'Delivery completed',
              subtitle: '156 orders delivered today',
              time: '2 hours ago',
              showDivider: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required String time,
    bool showDivider = true,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          title: Text(title),
          subtitle: Text(
            subtitle,
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
          trailing: Text(
            time,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
        ),
        if (showDivider) const Divider(),
      ],
    );
  }
}
