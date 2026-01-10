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
  print('DEBUG: Delivery Person ID from prefs: $personId');
  
  if (personId == null) {
    print('DEBUG: No Person ID found! Returning empty.');
    return [];
  }
  
  final today = DateTime.now();
  final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
  print('DEBUG: Fetching orders for date: $todayStr');
  
  try {
    // Get orders for today where the customer is assigned to this delivery person
    // Include subscription to get delivery_slot
    final response = await SupabaseService.client
        .from('orders')
        .select('*, profiles!orders_user_id_fkey(id, full_name, address, phone, assigned_delivery_person_id), subscriptions!orders_subscription_id_fkey(delivery_slot)')
        .eq('delivery_date', todayStr)
        .order('created_at');
    
    // Filter to only orders where customer is assigned to this delivery person
    final filteredOrders = (response as List).where((order) {
      final profile = order['profiles'];
      if (profile == null) return false;
      return profile['assigned_delivery_person_id'] == personId;
    }).toList();
    
    // Sort by time slot (morning first, then evening)
    filteredOrders.sort((a, b) {
      final slotA = a['subscriptions']?['delivery_slot'] ?? 'morning';
      final slotB = b['subscriptions']?['delivery_slot'] ?? 'morning';
      return slotA.compareTo(slotB);
    });
        
    print('DEBUG: Fetched ${filteredOrders.length} orders for assigned customers');
    
    // Transform to the expected format (matching old deliveries structure)
    return filteredOrders.map((order) => <String, dynamic>{
      'id': order['id'],
      'order_id': order['id'],
      'status': order['status'] ?? 'pending',
      'delivered_at': order['delivered_at'],
      'delivery_slot': order['subscriptions']?['delivery_slot'] ?? 'morning',
      'orders': order, // Nest the order for compatibility
    }).toList();
  } catch (e, stack) {
    print('DEBUG: Error fetching orders: $e');
    print(stack);
    return [];
  }
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
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(todayDeliveriesProvider);
            ref.invalidate(deliveryProfileProvider);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Modern Header
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    // Decoration removed for clean look
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top row with actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Greeting Section
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getGreeting(),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 2),
                              profileAsync.when(
                                data: (profile) => Text(
                                  profile?['full_name'] ?? 'Delivery Person',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    color: colorScheme.onSurface,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                loading: () => Text(
                                  'Loading...',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                error: (_, __) => Text(
                                  'Delivery Person',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    color: colorScheme.onSurface,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          // Action buttons
                          Row(
                            children: [
                              IconButton.filledTonal(
                                onPressed: () => ref.invalidate(todayDeliveriesProvider),
                                icon: Icon(Icons.refresh, size: 20, color: colorScheme.onSurfaceVariant),
                                style: IconButton.styleFrom(
                                  backgroundColor: colorScheme.surfaceContainerHighest,
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton.filledTonal(
                                onPressed: () async {
                                  final prefs = await SharedPreferences.getInstance();
                                  await prefs.remove('delivery_person_id');
                                  await prefs.remove('delivery_person_name');
                                  if (context.mounted) context.go('/login');
                                },
                                icon: Icon(Icons.logout, size: 20, color: colorScheme.onSurfaceVariant),
                                style: IconButton.styleFrom(
                                  backgroundColor: colorScheme.surfaceContainerHighest,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Stats Cards Row
                      deliveriesAsync.when(
                        loading: () => const SizedBox(height: 60),
                        error: (_, __) => const SizedBox(height: 60),
                        data: (deliveries) {
                          final completed = deliveries.where((d) => d['status'] == 'delivered').length;
                          final pending = deliveries.where((d) => d['status'] == 'pending' || d['status'] == 'in_transit').length;
                          final total = deliveries.length;
                          
                          return Row(
                            children: [
                              _buildStatCard('$total', 'Total', Icons.local_shipping, Colors.white),
                              const SizedBox(width: 8),
                              _buildStatCard('$pending', 'Pending', Icons.pending_actions, Colors.amber),
                              const SizedBox(width: 8),
                              _buildStatCard('$completed', 'Done', Icons.check_circle, Colors.greenAccent),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              // Content Section
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverToBoxAdapter(
                  child: deliveriesAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error: $e')),
                    data: (deliveries) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Section Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Today's Deliveries",
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${deliveries.length} orders',
                                  style: TextStyle(
                                    color: colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                      
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
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              // Already on Dashboard
              break;
            case 1:
              context.push('/routes');
              break;
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.route_outlined),
            selectedIcon: Icon(Icons.route),
            label: 'Routes',
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning! ☀️';
    if (hour < 17) return 'Good Afternoon! 🌤️';
    return 'Good Evening! 🌙';
  }

  Widget _buildStatCard(String value, String label, IconData icon, Color color) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary,
              colorScheme.primary.withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 11,
              ),
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

  Widget _buildDeliveryCard(BuildContext context, Map<String, dynamic> delivery) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final status = delivery['status'] ?? 'pending';
    final isDelivered = status == 'delivered';
    final deliverySlot = delivery['delivery_slot'] ?? 'morning';
    final isMorning = deliverySlot == 'morning';
    
    // Get customer info from nested order/profile
    final order = delivery['orders'] as Map<String, dynamic>?;
    final customer = order?['profiles'] as Map<String, dynamic>?;
    final customerName = customer?['full_name'] ?? 'Customer';
    final address = customer?['address'] ?? 'Address not available';
    final phone = customer?['phone'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isDelivered ? 0 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isDelivered 
            ? BorderSide(color: AppTheme.successColor.withOpacity(0.3), width: 1)
            : BorderSide.none,
      ),
      child: Container(
        decoration: isDelivered ? null : BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.surface,
              colorScheme.surface.withOpacity(0.95),
            ],
          ),
        ),
        padding: const EdgeInsets.all(20),
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
                const SizedBox(width: 4),
                // Time Slot Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isMorning 
                        ? Colors.amber.withOpacity(0.1)
                        : Colors.indigo.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isMorning ? Icons.wb_sunny : Icons.nights_stay,
                        size: 12,
                        color: isMorning ? Colors.amber.shade700 : Colors.indigo,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isMorning ? 'AM' : 'PM',
                        style: TextStyle(
                          color: isMorning ? Colors.amber.shade700 : Colors.indigo,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ],
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
            
            // Action Buttons - Better layout
            if (!isDelivered)
              Column(
                children: [
                  // First row: Quick actions (Navigate + Call)
                  Row(
                    children: [
                      // Navigate Button
                      if (address.isNotEmpty && address != 'Address not available')
                        Expanded(
                          child: FilledButton.tonalIcon(
                            onPressed: () => _openMaps(address),
                            icon: const Icon(Icons.navigation, size: 20),
                            label: const Text('Navigate'),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      if (address.isNotEmpty && address != 'Address not available')
                        const SizedBox(width: 12),
                      // Call Button  
                      if (phone.isNotEmpty)
                        Expanded(
                          child: FilledButton.tonalIcon(
                            onPressed: () => _makeCall(phone),
                            icon: const Icon(Icons.phone, size: 20),
                            label: const Text('Call'),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Second row: Main actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _reportIssue(delivery),
                          icon: const Icon(Icons.warning_amber, size: 18),
                          label: const Text('Issue'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.warningColor,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton.icon(
                          onPressed: () => context.push('/delivery/${delivery['id']}'),
                          icon: const Icon(Icons.qr_code_scanner, size: 20),
                          label: const Text('Scan & Deliver'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: AppTheme.successColor,
                          ),
                        ),
                      ),
                    ],
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
