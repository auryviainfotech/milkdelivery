import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:milk_core/milk_core.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../dashboard/screens/delivery_dashboard_screen.dart'; // Import shared provider

/// Today's route list screen - Uses shared provider with Dashboard for sync
class RouteListScreen extends ConsumerWidget {
  const RouteListScreen({super.key});

  // Fallback dummy data if Supabase fails


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    // Use shared provider from dashboard for auto-sync
    final deliveriesAsync = ref.watch(todayDeliveriesProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Deliveries'),
      ),
      body: deliveriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, __) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: colorScheme.error),
              const SizedBox(height: 16),
              Text('Error loading deliveries', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => ref.refresh(todayDeliveriesProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (deliveries) {
          if (deliveries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_shipping_outlined, size: 64, color: colorScheme.onSurfaceVariant),
                  const SizedBox(height: 16),
                  Text(
                    'No upcoming deliveries',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Check back later for new orders',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            );
          }
          return _buildDeliveryList(context, deliveries);
        },
      ),
    );
  }

  Widget _buildDeliveryList(BuildContext context, List<Map<String, dynamic>> rawDeliveries) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Transform raw Supabase data to flat format for cards
    final deliveries = rawDeliveries.map((delivery) {
      final order = delivery['orders'] as Map<String, dynamic>?;
      final profile = order?['profiles'] as Map<String, dynamic>?;
      
      return {
        'id': delivery['id'],
        'name': profile?['full_name'] ?? 'Customer',
        'phone': profile?['phone'] ?? '',
        'address': profile?['address'] ?? 'Address not provided',
        'product': 'Milk Delivery',
        'status': delivery['status'] ?? 'pending',
        'scheduled_date': delivery['scheduled_date'],
        'plan': 'daily', // Default plan
      };
    }).toList();
    
    final pendingCount = deliveries.where((d) => d['status'] == 'pending').length;

    return Column(
      children: [
        // Summary bar
        Container(
          padding: const EdgeInsets.all(16),
          color: colorScheme.primaryContainer,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text(
                    '${deliveries.length}',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  Text('Total', style: TextStyle(color: colorScheme.onPrimaryContainer)),
                ],
              ),
              Column(
                children: [
                  Text(
                    '$pendingCount',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.pendingColor,
                    ),
                  ),
                  const Text('Pending', style: TextStyle(color: AppTheme.pendingColor)),
                ],
              ),
            ],
          ),
        ),

        // Delivery list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: deliveries.length,
            itemBuilder: (context, index) {
              final delivery = deliveries[index];
              final isDelivered = delivery['status'] == 'delivered';
              // Extract customer info from nested structure
              final order = delivery['orders'] as Map<String, dynamic>?;
              final customer = order?['profiles'] as Map<String, dynamic>?;
              final phone = customer?['phone'] ?? delivery['phone'] ?? '';
              final address = customer?['address'] ?? delivery['address'] ?? '';
              
              return _DeliveryCard(
                delivery: delivery,
                index: index + 1,
                onCall: () => _makeCall(phone),
                onNavigate: () => _openMaps(address),
                onConfirm: isDelivered ? null : () => context.push('/delivery/${delivery['id']}'),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _makeCall(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openMaps(String address) async {
    final encodedAddress = Uri.encodeComponent(address);
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$encodedAddress');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

/// Delivery Card widget
class _DeliveryCard extends StatelessWidget {
  final Map<String, dynamic> delivery;
  final int index;
  final VoidCallback onCall;
  final VoidCallback onNavigate;
  final VoidCallback? onConfirm; // Nullable for delivered items

  const _DeliveryCard({
    required this.delivery,
    required this.index,
    required this.onCall,
    required this.onNavigate,
    this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDelivered = delivery['status'] == 'delivered';
    
    // Get customer info from nested order/profile (same as dashboard)
    final order = delivery['orders'] as Map<String, dynamic>?;
    final customer = order?['profiles'] as Map<String, dynamic>?;
    final customerName = customer?['full_name'] ?? delivery['name'] ?? 'Customer';
    final address = customer?['address'] ?? delivery['address'] ?? 'Address not provided';
    final phone = customer?['phone'] ?? delivery['phone'] ?? '';
    final deliverySlot = delivery['delivery_slot'] ?? 'morning';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isDelivered ? AppTheme.successColor.withValues(alpha: 0.1) : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with index and name
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: isDelivered ? AppTheme.successColor : colorScheme.primary,
                  radius: 16,
                  child: isDelivered 
                      ? const Icon(Icons.check, color: Colors.white, size: 18)
                      : Text(
                          '$index',
                          style: TextStyle(color: colorScheme.onPrimary, fontWeight: FontWeight.bold),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customerName,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      if (phone.isNotEmpty)
                        Text(
                          phone,
                          style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDelivered ? AppTheme.successColor : colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isDelivered ? 'DELIVERED' : (deliverySlot == 'morning' ? 'AM' : 'PM'),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isDelivered ? Colors.white : colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Address
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_on, color: colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    address,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                IconButton.filledTonal(
                  onPressed: onCall,
                  icon: const Icon(Icons.phone),
                  tooltip: 'Call',
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onNavigate,
                    icon: const Icon(Icons.navigation, size: 18),
                    label: const Text('Nav'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: isDelivered
                      ? FilledButton.icon(
                          onPressed: null,
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('Done', overflow: TextOverflow.ellipsis),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.successColor,
                            disabledBackgroundColor: AppTheme.successColor.withValues(alpha: 0.5),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                        )
                      : FilledButton(
                          onPressed: onConfirm,
                          child: const Text('Confirm'),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
