import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:milk_core/milk_core.dart';

/// Delivery personnel dashboard
class DeliveryDashboardScreen extends StatelessWidget {
  const DeliveryDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Good Morning! 👋',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const Text('Rajesh Kumar'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_outlined),
          ),
          IconButton(
            onPressed: () => context.go('/login'),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Today's summary cards
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    context,
                    icon: Icons.check_circle,
                    iconColor: AppTheme.successColor,
                    value: '5',
                    label: 'Completed',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    context,
                    icon: Icons.pending,
                    iconColor: AppTheme.pendingColor,
                    value: '12',
                    label: 'Pending',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    context,
                    icon: Icons.warning,
                    iconColor: AppTheme.warningColor,
                    value: '1',
                    label: 'Issues',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Earnings Card
            Card(
              color: colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Today's Earnings",
                            style: TextStyle(
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '₹250',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'This Week',
                          style: TextStyle(
                            color: colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '₹1,450',
                          style: TextStyle(
                            color: colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Start Deliveries Button
            FilledButton(
              onPressed: () => context.push('/routes'),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_shipping),
                  SizedBox(width: 8),
                  Text('Start Today\'s Deliveries'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Upcoming deliveries preview
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Next Deliveries',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: () => context.push('/routes'),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Preview cards
            _buildDeliveryPreviewCard(
              context,
              name: 'Rahul Sharma',
              address: 'Sector 45, Gurgaon',
              product: 'Full Cream 500ml × 2',
              distance: '1.2 km',
            ),
            _buildDeliveryPreviewCard(
              context,
              name: 'Priya Singh',
              address: 'DLF Phase 2, Gurgaon',
              product: 'Toned Milk 1L × 1',
              distance: '1.8 km',
            ),
            _buildDeliveryPreviewCard(
              context,
              name: 'Amit Kumar',
              address: 'Sector 56, Gurgaon',
              product: 'Buffalo Milk 500ml × 1',
              distance: '2.1 km',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryPreviewCard(
    BuildContext context, {
    required String name,
    required String address,
    required String product,
    required String distance,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colorScheme.primaryContainer,
          child: Text(
            name[0],
            style: TextStyle(color: colorScheme.onPrimaryContainer),
          ),
        ),
        title: Text(name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              address,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  '🥛 $product',
                  style: theme.textTheme.bodySmall,
                ),
                const Spacer(),
                Icon(
                  Icons.location_on,
                  size: 14,
                  color: colorScheme.primary,
                ),
                Text(
                  distance,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}
