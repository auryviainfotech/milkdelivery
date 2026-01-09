import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:milk_core/milk_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// Provider for current delivery person's ID from SharedPreferences
final deliveryPersonIdProvider = FutureProvider<String?>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('delivery_person_id');
});

/// Provider for current delivery person's profile
final deliveryProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final personId = await ref.watch(deliveryPersonIdProvider.future);
  if (personId == null) return null;
  
  final response = await SupabaseService.client
      .from('profiles')
      .select()
      .eq('id', personId)
      .maybeSingle();
  
  return response;
});

/// Provider for today's deliveries assigned to this delivery person
final todayDeliveriesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final personId = await ref.watch(deliveryPersonIdProvider.future);
  if (personId == null) return [];
  
  final today = DateTime.now();
  final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
  
  // Get deliveries for today assigned to this delivery person
  final response = await SupabaseService.client
      .from('deliveries')
      .select('*, orders(*, profiles(full_name, address, phone))')
      .eq('delivery_person_id', personId)
      .eq('scheduled_date', todayStr)
      .order('created_at');
  
  return List<Map<String, dynamic>>.from(response);
});

/// Delivery personnel dashboard with real data
class DeliveryDashboardScreen extends ConsumerStatefulWidget {
  const DeliveryDashboardScreen({super.key});

  @override
  ConsumerState<DeliveryDashboardScreen> createState() => _DeliveryDashboardScreenState();
}

class _DeliveryDashboardScreenState extends ConsumerState<DeliveryDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final profileAsync = ref.watch(deliveryProfileProvider);
    final deliveriesAsync = ref.watch(todayDeliveriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getGreeting(),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            profileAsync.when(
              data: (profile) => Text(profile?['full_name'] ?? 'Delivery Person'),
              loading: () => const Text('Loading...'),
              error: (_, __) => const Text('Delivery Person'),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(todayDeliveriesProvider),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
          IconButton(
            onPressed: () async {
              // Clear saved profile data
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('delivery_person_id');
              await prefs.remove('delivery_person_name');
              if (context.mounted) context.go('/login');
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(todayDeliveriesProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Today's summary cards
              deliveriesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (deliveries) {
                  final completed = deliveries.where((d) => d['status'] == 'delivered').length;
                  final pending = deliveries.where((d) => d['status'] == 'pending' || d['status'] == 'in_transit').length;
                  final issues = deliveries.where((d) => d['status'] == 'issue').length;
                  
                  return Column(
                    children: [
                      // Stats Row
                      Row(
                        children: [
                          Expanded(
                            child: _buildSummaryCard(
                              context,
                              icon: Icons.check_circle,
                              iconColor: AppTheme.successColor,
                              value: '$completed',
                              label: 'Completed',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildSummaryCard(
                              context,
                              icon: Icons.pending,
                              iconColor: AppTheme.pendingColor,
                              value: '$pending',
                              label: 'Pending',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildSummaryCard(
                              context,
                              icon: Icons.warning,
                              iconColor: AppTheme.warningColor,
                              value: '$issues',
                              label: 'Issues',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Deliveries Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Today's Deliveries",
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${deliveries.length} total',
                            style: TextStyle(color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // Delivery Cards
                      if (deliveries.isEmpty)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              children: [
                                Icon(Icons.check_circle_outline, size: 48, color: colorScheme.primary),
                                const SizedBox(height: 16),
                                const Text('No deliveries assigned for today!'),
                                const SizedBox(height: 8),
                                Text(
                                  'Pull down to refresh',
                                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ...deliveries.map((delivery) => _buildDeliveryCard(context, delivery)),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning! ☀️';
    if (hour < 17) return 'Good Afternoon! 🌤️';
    return 'Good Evening! 🌙';
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

  Widget _buildDeliveryCard(BuildContext context, Map<String, dynamic> delivery) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final status = delivery['status'] ?? 'pending';
    final isDelivered = status == 'delivered';
    
    // Get customer info from nested order/profile
    final order = delivery['orders'] as Map<String, dynamic>?;
    final customer = order?['profiles'] as Map<String, dynamic>?;
    final customerName = customer?['full_name'] ?? 'Customer';
    final address = customer?['address'] ?? 'Address not available';
    final phone = customer?['phone'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: isDelivered 
                      ? AppTheme.successColor.withOpacity(0.2)
                      : colorScheme.primaryContainer,
                  child: Text(
                    customerName[0].toUpperCase(),
                    style: TextStyle(
                      color: isDelivered 
                          ? AppTheme.successColor
                          : colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customerName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          decoration: isDelivered ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      if (phone.isNotEmpty)
                        Row(
                          children: [
                            Icon(Icons.phone, size: 12, color: colorScheme.primary),
                            const SizedBox(width: 4),
                            Text(
                              phone,
                              style: TextStyle(color: colorScheme.primary, fontSize: 12),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                // Call Button
                if (phone.isNotEmpty)
                  IconButton(
                    onPressed: () => _makeCall(phone),
                    icon: Icon(Icons.phone, color: colorScheme.primary),
                    tooltip: 'Call Customer',
                    style: IconButton.styleFrom(
                      backgroundColor: colorScheme.primaryContainer,
                    ),
                  ),
                const SizedBox(width: 4),
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDelivered 
                        ? AppTheme.successColor.withOpacity(0.1)
                        : AppTheme.pendingColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isDelivered ? '✓ Delivered' : 'Pending',
                    style: TextStyle(
                      color: isDelivered ? AppTheme.successColor : AppTheme.pendingColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Address
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 16, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    address,
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Action Buttons
            if (!isDelivered)
              Row(
                children: [
                  // Navigate Button
                  if (address.isNotEmpty && address != 'Address not available')
                    IconButton.filledTonal(
                      onPressed: () => _openMaps(address),
                      icon: const Icon(Icons.navigation),
                      tooltip: 'Navigate',
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _reportIssue(delivery),
                      icon: const Icon(Icons.warning_amber, size: 18),
                      label: const Text('Report Issue'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.warningColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: () => _markAsDelivered(delivery),
                      icon: const Icon(Icons.check_circle, size: 18),
                      label: const Text('Mark Delivered'),
                    ),
                  ),
                ],
              ),
          ],
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

  Future<void> _openMaps(String address) async {
    final encodedAddress = Uri.encodeComponent(address);
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$encodedAddress');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _markAsDelivered(Map<String, dynamic> delivery) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delivery'),
        content: const Text('Mark this delivery as completed?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Delivered'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await SupabaseService.client.from('deliveries').update({
          'status': 'delivered',
          'delivered_at': DateTime.now().toIso8601String(),
        }).eq('id', delivery['id']);
        
        ref.invalidate(todayDeliveriesProvider);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Marked as delivered!'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _reportIssue(Map<String, dynamic> delivery) async {
    final issueController = TextEditingController();
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Issue'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('What happened with this delivery?'),
            const SizedBox(height: 16),
            TextField(
              controller: issueController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'e.g., Customer not home, wrong address, etc.',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.warningColor),
            child: const Text('Report'),
          ),
        ],
      ),
    );

    if (confirmed == true && issueController.text.trim().isNotEmpty) {
      try {
        await SupabaseService.client.from('deliveries').update({
          'status': 'issue',
          'issue_notes': issueController.text.trim(),
        }).eq('id', delivery['id']);
        
        ref.invalidate(todayDeliveriesProvider);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Issue reported')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }
}
