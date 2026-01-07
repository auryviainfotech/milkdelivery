import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:milk_core/milk_core.dart';
import 'package:url_launcher/url_launcher.dart';

/// Provider for today's deliveries from Supabase
final deliveriesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final today = DateTime.now();
  final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
  
  // Fetch active subscriptions with user profiles
  final response = await SupabaseService.client
      .from('subscriptions')
      .select('''
        id,
        product_id,
        plan_type,
        quantity,
        status,
        total_amount,
        profiles!inner(id, full_name, phone, address)
      ''')
      .eq('status', 'active');

  // Map product IDs to names
  const productNames = {
    '1': 'Full Cream Milk 500ml',
    '2': 'Toned Milk 500ml',
    '3': 'Double Toned Milk 500ml',
    '4': 'Buffalo Milk 500ml',
  };

  final deliveries = (response as List).map((sub) {
    final profile = sub['profiles'];
    return {
      'id': sub['id'],
      'name': profile['full_name'] ?? 'Customer',
      'phone': profile['phone'] ?? '',
      'address': profile['address'] ?? 'Address not provided',
      'product': '${productNames[sub['product_id']] ?? 'Milk'} × ${sub['quantity']}',
      'plan': sub['plan_type'],
      'status': 'pending',
    };
  }).toList();

  return deliveries;
});

/// Today's route list screen - Fetches from Supabase
class RouteListScreen extends ConsumerWidget {
  const RouteListScreen({super.key});

  // Fallback dummy data if Supabase fails
  static final List<Map<String, dynamic>> _fallbackDeliveries = [
    {
      'id': '1',
      'name': 'Rahul Sharma',
      'phone': '+919876543210',
      'address': 'House 45, Sector 45, Gurgaon',
      'product': 'Full Cream Milk 500ml × 2',
      'plan': 'daily',
      'status': 'pending',
    },
    {
      'id': '2',
      'name': 'Priya Singh',
      'phone': '+919876543211',
      'address': 'Flat 302, DLF Phase 2, Gurgaon',
      'product': 'Toned Milk 500ml × 1',
      'plan': 'weekly',
      'status': 'pending',
    },
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final deliveriesAsync = ref.watch(deliveriesProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text("Today's Deliveries"),
      ),
      body: deliveriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _buildDeliveryList(context, _fallbackDeliveries),
        data: (deliveries) {
          if (deliveries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_shipping_outlined, size: 64, color: colorScheme.onSurfaceVariant),
                  const SizedBox(height: 16),
                  Text(
                    'No deliveries for today',
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

  Widget _buildDeliveryList(BuildContext context, List<Map<String, dynamic>> deliveries) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
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
              return _DeliveryCard(
                delivery: delivery,
                index: index + 1,
                onCall: () => _makeCall(delivery['phone']),
                onNavigate: () => _openMaps(delivery['address']),
                onConfirm: () => context.push('/delivery/${delivery['id']}'),
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
  final VoidCallback onConfirm;

  const _DeliveryCard({
    required this.delivery,
    required this.index,
    required this.onCall,
    required this.onNavigate,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with index and name
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: colorScheme.primary,
                  radius: 16,
                  child: Text(
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
                        delivery['name'],
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        delivery['phone'],
                        style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                // Plan badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    delivery['plan']?.toString().toUpperCase() ?? 'DAILY',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSecondaryContainer,
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
                    delivery['address'],
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Product
            Row(
              children: [
                const Text('🥛', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    delivery['product'],
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
                    label: const Text('Navigate'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
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
