import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:milk_core/milk_core.dart';
import 'package:url_launcher/url_launcher.dart';

/// Today's route list screen
class RouteListScreen extends StatelessWidget {
  const RouteListScreen({super.key});

  // Sample delivery data
  static final List<Map<String, dynamic>> _deliveries = [
    {
      'id': '1',
      'name': 'Rahul Sharma',
      'address': 'House 45, Sector 45, Gurgaon',
      'phone': '+919876543210',
      'product': 'Full Cream 500ml × 2',
      'distance': '1.2 km',
      'status': 'pending',
      'lat': 28.4595,
      'lng': 77.0266,
    },
    {
      'id': '2',
      'name': 'Priya Singh',
      'address': 'Flat 302, DLF Phase 2, Gurgaon',
      'phone': '+919876543211',
      'product': 'Toned Milk 1L × 1',
      'distance': '1.8 km',
      'status': 'pending',
      'lat': 28.4680,
      'lng': 77.0480,
    },
    {
      'id': '3',
      'name': 'Amit Kumar',
      'address': 'Villa 12, Sector 56, Gurgaon',
      'phone': '+919876543212',
      'product': 'Buffalo Milk 500ml × 1',
      'distance': '2.1 km',
      'status': 'pending',
      'lat': 28.4350,
      'lng': 77.0650,
    },
    {
      'id': '4',
      'name': 'Sneha Gupta',
      'address': 'Tower B, Flat 1205, Golf Course Road',
      'phone': '+919876543213',
      'product': 'Full Cream 500ml × 1',
      'distance': '2.5 km',
      'status': 'delivered',
      'lat': 28.4450,
      'lng': 77.0950,
    },
    {
      'id': '5',
      'name': 'Vikram Rathore',
      'address': 'House 78, Sector 47, Gurgaon',
      'phone': '+919876543214',
      'product': 'Toned Milk 1L × 2',
      'distance': '2.8 km',
      'status': 'delivered',
      'lat': 28.4280,
      'lng': 77.0380,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final pendingDeliveries = _deliveries.where((d) => d['status'] == 'pending').toList();
    final completedDeliveries = _deliveries.where((d) => d['status'] == 'delivered').toList();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Today's Deliveries"),
            Text(
              'Mon, 6 Jan 2025',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.pendingColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${pendingDeliveries.length} Pending',
              style: const TextStyle(
                color: AppTheme.pendingColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary bar
          Container(
            padding: const EdgeInsets.all(16),
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            child: Row(
              children: [
                _buildSummaryChip(
                  context,
                  icon: Icons.check_circle,
                  color: AppTheme.successColor,
                  label: '${completedDeliveries.length} Done',
                ),
                const SizedBox(width: 12),
                _buildSummaryChip(
                  context,
                  icon: Icons.pending,
                  color: AppTheme.pendingColor,
                  label: '${pendingDeliveries.length} Pending',
                ),
              ],
            ),
          ),

          // Delivery list
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (pendingDeliveries.isNotEmpty) ...[
                  Text(
                    'Pending',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...pendingDeliveries.asMap().entries.map((entry) {
                    return _buildDeliveryCard(context, entry.key + 1, entry.value);
                  }),
                  const SizedBox(height: 24),
                ],
                if (completedDeliveries.isNotEmpty) ...[
                  Text(
                    'Completed',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...completedDeliveries.map((delivery) {
                    return _buildCompletedCard(context, delivery);
                  }),
                ],
              ],
            ),
          ),

          // Bottom stats bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Today\'s Progress',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        '${completedDeliveries.length}/${_deliveries.length} deliveries',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Earnings',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        '₹${completedDeliveries.length * 50}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.successColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryChip(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryCard(BuildContext context, int index, Map<String, dynamic> delivery) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$index',
                      style: TextStyle(
                        color: colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        delivery['name'],
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        delivery['address'],
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  delivery['distance'],
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                const Text('🥛', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(delivery['product']),
                const Spacer(),
                // Call button
                IconButton.filledTonal(
                  onPressed: () => _makeCall(delivery['phone']),
                  icon: const Icon(Icons.phone, size: 20),
                ),
                const SizedBox(width: 8),
                // Navigate button
                FilledButton.icon(
                  onPressed: () => _openMaps(
                    delivery['lat'],
                    delivery['lng'],
                    delivery['name'],
                  ),
                  icon: const Icon(Icons.navigation, size: 18),
                  label: const Text('Navigate'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Confirm delivery button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => context.push('/delivery/${delivery['id']}'),
                child: const Text('Confirm Delivery'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedCard(BuildContext context, Map<String, dynamic> delivery) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.successColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check,
            color: AppTheme.successColor,
            size: 20,
          ),
        ),
        title: Text(
          delivery['name'],
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        subtitle: Text(
          '🥛 ${delivery['product']}',
          style: TextStyle(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7)),
        ),
        trailing: const Text(
          'Delivered',
          style: TextStyle(
            color: AppTheme.successColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Future<void> _makeCall(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openMaps(double lat, double lng, String label) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
