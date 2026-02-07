import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:milk_core/milk_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../widgets/shop_order_card.dart';

/// Provider for current delivery person's ID
final deliveryPersonIdProvider = FutureProvider<String?>((ref) async {
  // Primary source: Authenticated Supabase User
  final authUser = SupabaseService.currentUser;
  if (authUser != null) {
    debugPrint('🔐 [PROVIDER] Using Auth User ID: ${authUser.id}');
    return authUser.id;
  }
  
  // Fallback: SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  final prefId = prefs.getString('delivery_person_id');
  debugPrint('💾 [PROVIDER] Using Prefs ID: $prefId');
  return prefId;
});

/// Provider for current delivery person's profile
final deliveryProfileProvider =
    FutureProvider<Map<String, dynamic>?>((ref) async {
  final personId = await ref.watch(deliveryPersonIdProvider.future);
  if (personId == null) return null;

  final response = await SupabaseService.client
      .from('profiles')
      .select()
      .eq('id', personId)
      .maybeSingle();

  return response;
});

String _formatDateForQuery(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

String _normalizeDateValue(dynamic value) {
  if (value is DateTime) {
    return _formatDateForQuery(value);
  }
  final text = value?.toString() ?? '';
  if (text.length >= 10) {
    return text.substring(0, 10);
  }
  return text;
}

/// Fetch deliveries with all related data
Future<List<Map<String, dynamic>>> _fetchDeliveriesForDate(
  String personId,
  String dateStr,
) async {
  try {
    // First, get deliveries
    debugPrint('🔍 [DELIVERY] Fetching deliveries for person=$personId date=$dateStr');
    final deliveries = await SupabaseService.client
        .from('deliveries')
        .select('*')
        .eq('delivery_person_id', personId)
        .eq('scheduled_date', dateStr)
        .order('created_at');

    debugPrint('🔍 [DELIVERY] Found ${deliveries.length} deliveries');
    
    if (deliveries.isEmpty) {
      // Debug: check if there are ANY deliveries for this date (regardless of person)
      final allDeliveries = await SupabaseService.client
          .from('deliveries')
          .select('id, delivery_person_id, scheduled_date, status')
          .eq('scheduled_date', dateStr);
      debugPrint('🔍 [DELIVERY] Total deliveries for $dateStr (all persons): ${allDeliveries.length}');
      for (final d in allDeliveries) {
        debugPrint('🔍 [DELIVERY]   id=${d['id']}, person=${d['delivery_person_id']}, status=${d['status']}');
      }
      return [];
    }

    // Get unique order IDs
    final orderIds = deliveries
        .map((d) => d['order_id'] as String?)
        .where((id) => id != null)
        .toSet()
        .toList();
    
    if (orderIds.isEmpty) {
      return List<Map<String, dynamic>>.from(deliveries);
    }

    // Fetch orders with nested data
    // NOTE: Using separate queries to avoid FK hint issues
    List<dynamic> orders = [];
    try {
      orders = await SupabaseService.client
          .from('orders')
          .select('''
            *,
            order_items (
              id, product_id, quantity, price,
              products (id, name, unit, image_url, emoji)
            )
          ''')
          .inFilter('id', orderIds);
      debugPrint('🔍 [DELIVERY] Fetched ${orders.length} orders');
    } catch (e) {
      debugPrint('🔍 [DELIVERY] Error fetching orders: $e');
    }

    // Fetch profiles for each order's user_id separately (avoids FK hint issues)
    final userIds = orders
        .map((o) => o['user_id'] as String?)
        .where((id) => id != null)
        .toSet()
        .toList();
    
    Map<String, Map<String, dynamic>> profilesMap = {};
    if (userIds.isNotEmpty) {
      try {
        final profiles = await SupabaseService.client
            .from('profiles')
            .select('id, full_name, phone, address')
            .inFilter('id', userIds);
        for (final p in profiles) {
          profilesMap[p['id'] as String] = Map<String, dynamic>.from(p);
        }
        debugPrint('🔍 [DELIVERY] Fetched ${profiles.length} profiles');
      } catch (e) {
        debugPrint('🔍 [DELIVERY] Error fetching profiles: $e');
      }
    }

    // Fetch subscriptions for orders that have subscription_id
    final subscriptionIds = orders
        .map((o) => o['subscription_id'] as String?)
        .where((id) => id != null)
        .toSet()
        .toList();
    
    Map<String, Map<String, dynamic>> subscriptionsMap = {};
    if (subscriptionIds.isNotEmpty) {
      try {
        final subs = await SupabaseService.client
            .from('subscriptions')
            .select('*, products (id, name, unit, image_url)')
            .inFilter('id', subscriptionIds);
        for (final s in subs) {
          subscriptionsMap[s['id'] as String] = Map<String, dynamic>.from(s);
        }
        debugPrint('🔍 [DELIVERY] Fetched ${subs.length} subscriptions');
      } catch (e) {
        debugPrint('🔍 [DELIVERY] Error fetching subscriptions: $e');
      }
    }

    // Build orders map with nested data
    final ordersMap = <String, Map<String, dynamic>>{};
    for (final order in orders) {
      final orderMap = Map<String, dynamic>.from(order);
      final userId = order['user_id'] as String?;
      final subId = order['subscription_id'] as String?;
      
      // Attach profile data
      if (userId != null && profilesMap.containsKey(userId)) {
        orderMap['profiles'] = profilesMap[userId];
      }
      // Attach subscription data
      if (subId != null && subscriptionsMap.containsKey(subId)) {
        orderMap['subscriptions'] = subscriptionsMap[subId];
      }
      
      ordersMap[order['id'] as String] = orderMap;
    }

    // Merge orders into deliveries
    final result = <Map<String, dynamic>>[];
    for (final delivery in deliveries) {
      final merged = Map<String, dynamic>.from(delivery);
      final orderId = delivery['order_id'] as String?;
      if (orderId != null && ordersMap.containsKey(orderId)) {
        merged['orders'] = ordersMap[orderId];
      }
      result.add(merged);
    }

    debugPrint('🔍 [DELIVERY] Returning ${result.length} merged deliveries');
    return result;
    
  } catch (e, stack) {
    debugPrint('❌ [DELIVERY] FATAL ERROR in _fetchDeliveriesForDate: $e');
    debugPrint('Stack: $stack');
    return [];
  }
}

/// Provider for today's deliveries assigned to this delivery person
final todayDeliveriesProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final personId = await ref.watch(deliveryPersonIdProvider.future);


  if (personId == null) {

    return [];
  }

  final today = DateTime.now();
  final todayStr = _formatDateForQuery(today);


  try {
    final todayDeliveries = await _fetchDeliveriesForDate(personId, todayStr);

    if (todayDeliveries.isNotEmpty) {
      return todayDeliveries;
    }

    // No deliveries found for today, check next available date

    final nextDateResult = await SupabaseService.client
        .from('deliveries')
        .select('scheduled_date')
        .eq('delivery_person_id', personId)
        .gte('scheduled_date', todayStr)
        .order('scheduled_date')
        .limit(1);


    if (nextDateResult.isEmpty) {

      return [];
    }

    final nextDateStr =
        _normalizeDateValue(nextDateResult.first['scheduled_date']);

    
    if (nextDateStr.isEmpty) {
      return [];
    }

    return _fetchDeliveriesForDate(personId, nextDateStr);
  } catch (e, stack) {

    return [];
  }
});

/// Delivery personnel dashboard with real data
class DeliveryDashboardScreen extends ConsumerStatefulWidget {
  const DeliveryDashboardScreen({super.key});

  @override
  ConsumerState<DeliveryDashboardScreen> createState() =>
      _DeliveryDashboardScreenState();
}

class _DeliveryDashboardScreenState
    extends ConsumerState<DeliveryDashboardScreen> {
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
                                onPressed: () =>
                                    ref.invalidate(todayDeliveriesProvider),
                                icon: Icon(Icons.refresh,
                                    size: 20,
                                    color: colorScheme.onSurfaceVariant),
                                style: IconButton.styleFrom(
                                  backgroundColor:
                                      colorScheme.surfaceContainerHighest,
                                ),
                              ),
                              const SizedBox(width: 8),

                              IconButton.filledTonal(
                                onPressed: () => _showAdminSupportDialog(context),
                                icon: Icon(Icons.support_agent,
                                    size: 20,
                                    color: colorScheme.primary),
                                style: IconButton.styleFrom(
                                  backgroundColor:
                                      colorScheme.primaryContainer,
                                ),
                              ),
                              const SizedBox(width: 8),
                              /* Logout moved to Profile
                              IconButton.filledTonal(
                                onPressed: () async {
                                  final prefs =
                                      await SharedPreferences.getInstance();
                                  await prefs.remove('delivery_person_id');
                                  await prefs.remove('delivery_person_name');
                                  if (context.mounted) context.go('/login');
                                },
                                icon: Icon(Icons.logout,
                                    size: 20,
                                    color: colorScheme.onSurfaceVariant),
                                style: IconButton.styleFrom(
                                  backgroundColor:
                                      colorScheme.surfaceContainerHighest,
                                ),
                              ),
                              */
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
                          final completed = deliveries
                              .where((d) => d['status'] == 'delivered')
                              .length;
                          final pending = deliveries
                              .where((d) =>
                                  d['status'] == 'pending' ||
                                  d['status'] == 'in_transit')
                              .length;
                          final total = deliveries.length;

                          return Row(
                            children: [
                              _buildStatCard('$total', 'Total',
                                  Icons.local_shipping, Colors.white),
                              const SizedBox(width: 8),
                              _buildStatCard('$pending', 'Pending',
                                  Icons.pending_actions, Colors.amber),
                              const SizedBox(width: 8),
                              _buildStatCard('$completed', 'Done',
                                  Icons.check_circle, Colors.greenAccent),
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
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error: $e')),
                    data: (deliveries) {
                      // Split deliveries by order type
                      final milkDeliveries = deliveries.where((d) {
                        final order = d['orders'] as Map<String, dynamic>?;
                        return order?['order_type'] != 'one_time';
                      }).toList();
                      
                      final shopOrders = deliveries.where((d) {
                        final order = d['orders'] as Map<String, dynamic>?;
                        return order?['order_type'] == 'one_time';
                      }).toList();

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
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
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

                          // Empty State
                          if (deliveries.isEmpty)
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  children: [
                                    Icon(Icons.check_circle_outline,
                                        size: 48, color: colorScheme.primary),
                                    const SizedBox(height: 16),
                                    const Text(
                                        'No deliveries assigned for today!'),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Pull down to refresh',
                                      style: TextStyle(
                                          color: colorScheme.onSurfaceVariant),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          // Shop Orders Section (if any)
                          if (shopOrders.isNotEmpty) ...[
                            Row(
                              children: [
                                Icon(Icons.shopping_bag, size: 18, color: Colors.orange.shade700),
                                const SizedBox(width: 6),
                                Text(
                                  'Shop Orders',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange.shade700,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${shopOrders.length}',
                                    style: TextStyle(
                                      color: Colors.orange.shade700,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ...shopOrders.map((delivery) {
                              // Extract address safely
                              final order = delivery['orders'] as Map<String, dynamic>?;
                              final profile = order?['profiles'] as Map<String, dynamic>?;
                              final address = profile?['address'] as String? ?? '';

                              return ShopOrderCard(
                                delivery: delivery,
                                onMarkDelivered: () => _markShopOrderDelivered(delivery),
                                onReportIssue: () => _handleReportIssue(delivery),
                                onNavigate: address.isNotEmpty ? () => _openMaps(address) : null,
                              );
                            }),
                            const SizedBox(height: 24),
                          ],

                          // Milk Deliveries Section (if any)
                          if (milkDeliveries.isNotEmpty) ...[
                            Row(
                              children: [
                                Icon(Icons.local_drink, size: 18, color: colorScheme.primary),
                                const SizedBox(width: 6),
                                Text(
                                  'Milk Subscriptions',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${milkDeliveries.length}',
                                    style: TextStyle(
                                      color: colorScheme.onPrimaryContainer,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ...milkDeliveries.map((delivery) =>
                                _buildDeliveryCard(context, delivery)),
                          ],
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
              context.push('/profile');
              break;
            case 2:
              _showAdminSupportDialog(context);
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
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
          NavigationDestination(
            icon: Icon(Icons.support_agent_outlined),
            selectedIcon: Icon(Icons.support_agent),
            label: 'Support',
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

  Widget _buildStatCard(
      String value, String label, IconData icon, Color color) {
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

  void _showDebugDialog(BuildContext context, WidgetRef ref) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final personId = await ref.read(deliveryPersonIdProvider.future);
      final today = DateTime.now();
      final dateStr = _formatDateForQuery(today);

      final deliveries = await SupabaseService.client
          .from('deliveries')
          .select()
          .eq('delivery_person_id', personId ?? '')
          .eq('scheduled_date', dateStr);

      final allDeliveries = await SupabaseService.client
          .from('deliveries')
          .select()
          .eq('scheduled_date', dateStr);

      if (context.mounted) {
        Navigator.pop(context); // Pop loading
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Debug Data'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Person ID: $personId'),
                  Text('Date: $dateStr'),
                  const Divider(),
                  Text('Assigned Deliveries (${deliveries.length}):'),
                  Text(deliveries.toString()),
                  const Divider(),
                  Text('ALL Deliveries Today (${allDeliveries.length}):'),
                  Text(allDeliveries.map((d) => "Order: ${d['order_id']}, Person: ${d['delivery_person_id']}").join('\n')),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: deliveries.toString()));
                  Navigator.pop(context);
                },
                child: const Text('Copy & Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text(e.toString()),
          ),
        );
      }
    }
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

  Widget _buildDeliveryCard(
      BuildContext context, Map<String, dynamic> delivery) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final status = delivery['status'] ?? 'pending';
    final isDelivered = status == 'delivered';

    // Parse nested data from single query result
    final order = delivery['orders'] as Map<String, dynamic>?;
    final subscription = order?['subscriptions'] as Map<String, dynamic>?;
    final profile = order?['profiles'] as Map<String, dynamic>?;
    final product = subscription?['products'] as Map<String, dynamic>?;
    final orderItems = order?['order_items'] as List<dynamic>?;

    // Extract values
    final customerName = profile?['full_name'] ?? 'Customer';
    final address = profile?['address'] ?? 'No address provided';
    final phone = profile?['phone'] ?? '';
    
    // Determine product name
    String productName = 'Milk';
    if (product != null) {
      productName = product['name'];
    } else if (orderItems != null && orderItems.isNotEmpty) {
      if (orderItems.length == 1) {
        final itemProduct = orderItems.first['products'];
        productName = itemProduct != null ? itemProduct['name'] : 'Product';
      } else {
        productName = '${orderItems.length} Items';
      }
    }

    final unit = product?['unit'] ?? 'L';
    final quantity = subscription?['quantity'] ?? 1;
    final deliverySlot = subscription?['delivery_slot'] ?? subscription?['time_slot'] ?? 'morning';
    final isMorning = deliverySlot == 'morning';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isDelivered ? 0 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isDelivered
            ? BorderSide(
                color: AppTheme.successColor.withOpacity(0.3), width: 1)
            : BorderSide.none,
      ),
      child: Container(
        decoration: isDelivered
            ? null
            : BoxDecoration(
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
            // Header Row: Avatar + Name + Call Button
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: isDelivered
                      ? AppTheme.successColor.withOpacity(0.2)
                      : colorScheme.primaryContainer,
                  child: Text(
                    customerName.isNotEmpty
                        ? customerName[0].toUpperCase()
                        : '?',
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
                          decoration:
                              isDelivered ? TextDecoration.lineThrough : null,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      // For Shop Orders, show items summary here
                      if (orderItems != null && orderItems.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                             orderItems.map((i) {
                               final p = i['products'];
                               return "${p?['name'] ?? 'Item'} x${i['quantity']}";
                             }).join(', '),
                             style: TextStyle(fontSize: 12, color: colorScheme.primary, fontWeight: FontWeight.w500),
                             maxLines: 1,
                             overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.location_on,
                              size: 12, color: colorScheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              address,
                              style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                              softWrap: true,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              ],
            ),
            const SizedBox(height: 8),
            // Badges Row - only show time slot for pending, hide for delivered
            if (!isDelivered)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // Time Slot Badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                          color:
                              isMorning ? Colors.amber.shade700 : Colors.indigo,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isMorning ? 'AM' : 'PM',
                          style: TextStyle(
                            color: isMorning
                                ? Colors.amber.shade700
                                : Colors.indigo,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Product Name Badge
                  Container(
                    constraints: const BoxConstraints(maxWidth: 160),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(orderItems != null && orderItems.isNotEmpty ? Icons.shopping_bag : Icons.local_drink,
                            size: 12, color: Colors.purple.shade700),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            productName,
                            style: TextStyle(
                              color: Colors.purple.shade700,
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Liters Badge (Subscription orders)
                  if (order?['quantity'] !=
                      null) // Removed 'order_type' check as subscription orders have quantity in orders table
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.water_drop,
                              size: 12, color: Colors.blue.shade700),
                          const SizedBox(width: 4),
                          Text(
                            '${order?['quantity'] ?? 1}L',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  // COD Badge (Shop orders)
                  if (order?['payment_method'] == 'cod' ||
                      order?['order_type'] == 'one_time')
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.payments_outlined,
                              size: 12, color: Colors.green.shade700),
                          const SizedBox(width: 4),
                          Text(
                            'Collect ₹${(order?['total_amount'] ?? 0).toStringAsFixed(0)}',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Status Badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.pendingColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Pending',
                      style: TextStyle(
                        color: AppTheme.pendingColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 12),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(height: 1),
            ),

            // Product Details Row - Enhanced with image
            _buildProductDetailsWidget(
              context,
              product: product,
              quantity: quantity,
              unit: unit,
              productName: productName,
              deliverySlot: deliverySlot,
              isDelivered: isDelivered,
            ),

            const SizedBox(height: 24),

            // Action Buttons - Better layout
            if (!isDelivered)
              Column(
                children: [
                  // First row: Quick actions (Navigate + Call)
                  Row(
                    children: [
                      // Navigate Button
                      if (address.isNotEmpty &&
                          address != 'Address not available')
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
                      if (address.isNotEmpty &&
                          address != 'Address not available')
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
                          onPressed: () => _handleReportIssue(delivery),
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
                          onPressed: () {
                            context.push('/delivery/${delivery['id']}');
                          },
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

  Widget _buildProductDetailsWidget(
    BuildContext context, {
    required Map<String, dynamic>? product,
    required int quantity,
    required String unit,
    required String productName,
    required String deliverySlot,
    required bool isDelivered,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final imageUrl = product?['image_url'] as String?;
    final description = product?['description'] as String?;
    final category = product?['category'] as String?;
    final price = product?['price'];
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDelivered 
            ? colorScheme.surfaceContainerHighest.withOpacity(0.3)
            : colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
              ),
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Center(
                        child: Icon(
                          Icons.local_drink,
                          size: 32,
                          color: colorScheme.primary,
                        ),
                      ),
                    )
                  : Center(
                      child: Icon(
                        Icons.local_drink,
                        size: 32,
                        color: colorScheme.primary,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          // Product Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Name
                Text(
                  productName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    decoration: isDelivered ? TextDecoration.lineThrough : null,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // Quantity and Unit
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$quantity x $unit',
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Category badge
                    if (category != null && category.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: category == 'subscription' 
                              ? Colors.green.withOpacity(0.1)
                              : Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          category == 'subscription' ? 'Subscription' : 'One-time',
                          style: TextStyle(
                            color: category == 'subscription' 
                                ? Colors.green.shade700
                                : Colors.orange.shade700,
                            fontWeight: FontWeight.w500,
                            fontSize: 10,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                // Description (if available)
                if (description != null && description.isNotEmpty)
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                // Delivery Slot
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      deliverySlot == 'morning' ? Icons.wb_sunny : Icons.nights_stay,
                      size: 14,
                      color: deliverySlot == 'morning' 
                          ? Colors.amber.shade700 
                          : Colors.indigo,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${deliverySlot[0].toUpperCase()}${deliverySlot.substring(1)} Delivery',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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
    final uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$encodedAddress');
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
        // Update orders table (only status - no delivered_at column here)
        await SupabaseService.client.from('orders').update({
          'status': 'delivered',
        }).eq('id', delivery['id']);

        // Update deliveries table (has delivered_at column)
        await SupabaseService.client.from('deliveries').update({
          'status': 'delivered',
          'delivered_at': DateTime.now().toIso8601String(),
        }).eq('order_id', delivery['id']);

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
            style:
                FilledButton.styleFrom(backgroundColor: AppTheme.warningColor),
            child: const Text('Report'),
          ),
        ],
      ),
    );

    if (confirmed == true && issueController.text.trim().isNotEmpty) {
      try {
        // Update orders table (only status - issue_notes is in deliveries table)
        await SupabaseService.client.from('orders').update({
          'status': 'failed',
        }).eq('id', delivery['id']);

        // Update deliveries table (has issue_notes column)
        await SupabaseService.client.from('deliveries').update({
          'status': 'issue',
          'issue_notes': issueController.text.trim(),
        }).eq('order_id', delivery['id']);

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

  // Admin Support Dialog
  void _showAdminSupportDialog(BuildContext context) {
    const String supportPhone = '9886598059';
    const String supportEmail = 'auddhattyaventures@gmail.com';
    
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outline.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.support_agent,
                size: 40,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Admin Support',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Need help? Contact admin for assistance',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            
            // Contact Options
            // Call Button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  final uri = Uri.parse('tel:$supportPhone');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  }
                },
                icon: const Icon(Icons.phone),
                label: const Text('Call Admin: $supportPhone'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.green,
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            // WhatsApp Button
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: () async {
                  Navigator.pop(context);
                  final uri = Uri.parse(
                    'https://wa.me/91$supportPhone?text=Hi, I need help with a delivery.',
                  );
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                icon: const Icon(Icons.chat),
                label: const Text('WhatsApp Admin'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            // Email Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  final uri = Uri.parse(
                    'mailto:$supportEmail?subject=Delivery App Support Request',
                  );
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  }
                },
                icon: const Icon(Icons.email),
                label: const Text('Email: $supportEmail'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Business info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.business, size: 16, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Text(
                    'Auddhatya Ventures',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
          ],
        ),
      ),
    );
  }

  /// Mark a shop order as delivered (no scanner required)
  void _markShopOrderDelivered(Map<String, dynamic> delivery) async {
    final deliveryId = delivery['id'] as String;
    final order = delivery['orders'] as Map<String, dynamic>?;
    final orderId = order?['id'] as String?;

    try {
      // Update delivery status
      await SupabaseService.client
          .from('deliveries')
          .update({
            'status': 'delivered',
            'delivered_at': DateTime.now().toIso8601String(),
          })
          .eq('id', deliveryId);

      // Update order status
      if (orderId != null) {
        await SupabaseService.client
            .from('orders')
            .update({'status': 'delivered'})
            .eq('id', orderId);
      }

      // Refresh the list
      ref.invalidate(todayDeliveriesProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order marked as delivered!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }



  /// Report an issue with a delivery
  void _handleReportIssue(Map<String, dynamic> delivery) {
    final deliveryId = delivery['id'] as String;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Issue'),
        content: const Text('Contact admin to report issues with this delivery.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _showAdminSupportDialog(context);
            },
            child: const Text('Contact Admin'),
          ),
        ],
      ),
    );
  }
}
