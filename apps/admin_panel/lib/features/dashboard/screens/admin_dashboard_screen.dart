import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milk_core/milk_core.dart';

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
  
  // Get delivery person count
  final dpResponse = await SupabaseService.client
      .from('profiles')
      .select('id')
      .eq('role', 'delivery');
  final deliveryPersonCount = dpResponse.length;
  
  return {
    'customers': customerCount,
    'activeSubscriptions': activeSubCount,
    'todayDeliveries': todayDeliveries,
    'deliveryPersons': deliveryPersonCount,
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
                'deliveryPersons': 0,
              }),
            ),
            const SizedBox(height: 24),

            // Quick Actions
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
        final cardWidth = isWide ? (constraints.maxWidth - 32) / 4 : (constraints.maxWidth - 16) / 2;
        
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
              title: 'Delivery Persons',
              value: '${stats['deliveryPersons'] ?? 0}',
              icon: Icons.directions_bike,
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
