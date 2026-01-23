import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../shared/providers/auth_providers.dart';
import 'package:milk_core/milk_core.dart';

/// Provider for user quota data (liters remaining + status)
final userQuotaProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final user = SupabaseService.currentUser;
  if (user == null) return null;
  
  final response = await SupabaseService.client
      .from('profiles')
      .select('liters_remaining, subscription_status, full_name, phone, qr_code')
      .eq('id', user.id)
      .maybeSingle();
  return response;
});

/// Customer Dashboard Screen - Modern Liters Quota Design
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final quotaAsync = ref.watch(userQuotaProvider);
    final subscriptionsAsync = ref.watch(activeSubscriptionsProvider);
    final ordersAsync = ref.watch(ordersProvider);
    final user = SupabaseService.currentUser;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(userQuotaProvider);
          ref.invalidate(activeSubscriptionsProvider);
          ref.invalidate(ordersProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Section - Liters Quota
              _buildHeroSection(context, ref, quotaAsync, user?.id),
              
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Subscription Status Card
                    _buildSubscriptionCard(context, subscriptionsAsync),
                    const SizedBox(height: 20),
                    
                    // Quick Actions Grid
                    Text(
                      'Quick Actions',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    _buildQuickActionsGrid(context),
                    const SizedBox(height: 24),
                    
                    // Recent Deliveries
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recent Deliveries',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        TextButton(
                          onPressed: () => context.push('/orders'),
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildRecentOrders(context, ordersAsync),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context, WidgetRef ref, AsyncValue<Map<String, dynamic>?> quotaAsync, String? userId) {
    final theme = Theme.of(context);
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1E88E5), // Blue
            const Color(0xFF1565C0), // Darker Blue
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getGreeting(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                      quotaAsync.when(
                        data: (data) => Text(
                          '${data?['full_name'] ?? 'User'}! 👋',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        loading: () => Text('Loading...', style: TextStyle(color: Colors.white70)),
                        error: (_, __) => Text('Hello! 👋', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => context.push('/notifications'),
                        icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                      ),
                      GestureDetector(
                        onTap: () => context.go('/profile'),
                        child: CircleAvatar(
                          backgroundColor: Colors.white24,
                          child: quotaAsync.when(
                            data: (data) => Text(
                              (data?['full_name'] ?? 'U')[0].toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            loading: () => const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                            error: (_, __) => const Icon(Icons.person, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Liters Quota Display
              Row(
                children: [
                  // Main Liters Display
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white24,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.water_drop, color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Liters Remaining',
                                style: TextStyle(color: Colors.white70, fontSize: 14),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          quotaAsync.when(
                            data: (data) {
                              final liters = (data?['liters_remaining'] as num?)?.toDouble() ?? 0.0;
                              final status = data?['subscription_status'] ?? 'inactive';
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        liters.toStringAsFixed(1),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 42,
                                          fontWeight: FontWeight.bold,
                                          height: 1,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Padding(
                                        padding: EdgeInsets.only(bottom: 6),
                                        child: Text(
                                          'L',
                                          style: TextStyle(color: Colors.white70, fontSize: 20),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  _buildStatusChip(status),
                                ],
                              );
                            },
                            loading: () => const CircularProgressIndicator(color: Colors.white),
                            error: (_, __) => const Text('0.0 L', style: TextStyle(color: Colors.white, fontSize: 32)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // QR Code Mini Display
                  GestureDetector(
                    onTap: () => context.push('/wallet'), // Goes to LitersQuotaScreen with full QR
                    child: Container(
                      width: 100,
                      height: 140,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (userId != null)
                            QrImageView(
                              data: userId,
                              version: QrVersions.auto,
                              size: 70,
                            ),
                          const SizedBox(height: 8),
                          const Text(
                            'My QR',
                            style: TextStyle(
                              color: Color(0xFF1565C0),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color bgColor;
    Color textColor;
    String label;
    IconData icon;

    switch (status) {
      case 'active':
        bgColor = Colors.green.withOpacity(0.2);
        textColor = Colors.greenAccent;
        label = 'Active';
        icon = Icons.check_circle;
        break;
      case 'pending':
        bgColor = Colors.orange.withOpacity(0.2);
        textColor = Colors.orangeAccent;
        label = 'Pending Approval';
        icon = Icons.hourglass_top;
        break;
      default:
        bgColor = Colors.grey.withOpacity(0.2);
        textColor = Colors.white70;
        label = 'No Subscription';
        icon = Icons.info_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard(BuildContext context, AsyncValue<List<SubscriptionModel>> subscriptionsAsync) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return subscriptionsAsync.when(
      data: (subscriptions) {
        if (subscriptions.isEmpty) {
          return Card(
            elevation: 0,
            color: colorScheme.primaryContainer.withOpacity(0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: colorScheme.primary.withOpacity(0.2)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.add_circle_outline, color: colorScheme.primary, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Start Your Subscription', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text('Get fresh milk delivered daily', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13)),
                      ],
                    ),
                  ),
                  Flexible(
                    child: FilledButton(
                      onPressed: () => context.push('/subscriptions'),
                      child: const Text('Subscribe'),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        
        final sub = subscriptions.first;
        return Card(
          elevation: 0,
          color: Colors.green.shade50,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.green.shade200),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('🥛', style: TextStyle(fontSize: 24)),
            ),
            title: Text('Active Subscription', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade900)),
            subtitle: Text(
              '${sub.monthlyLiters}L / month • ${sub.skipWeekends ? 'Weekdays' : 'Daily'}',
              style: TextStyle(color: Colors.green.shade700),
            ),
            trailing: Icon(Icons.chevron_right, color: Colors.green.shade700),
            onTap: () => context.push('/subscriptions'),
          ),
        );
      },
      loading: () => const Card(child: Padding(padding: EdgeInsets.all(20), child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3))))),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Row(
      children: [
        Expanded(child: _buildActionCard(
          context,
          icon: Icons.water_drop,
          label: 'My Quota',
          color: Colors.blue,
          onTap: () => context.push('/wallet'),
        )),
        const SizedBox(width: 12),
        Expanded(child: _buildActionCard(
          context,
          icon: Icons.add_box,
          label: 'Subscribe',
          color: Colors.green,
          onTap: () => context.push('/subscriptions'),
        )),
        const SizedBox(width: 12),
        Expanded(child: _buildActionCard(
          context,
          icon: Icons.shopping_bag,
          label: 'Shop',
          color: Colors.orange,
          onTap: () => context.push('/shop'),
        )),
        const SizedBox(width: 12),
        Expanded(child: _buildActionCard(
          context,
          icon: Icons.history,
          label: 'Orders',
          color: Colors.purple,
          onTap: () => context.push('/orders'),
        )),
      ],
    );
  }

  Widget _buildActionCard(BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color.withOpacity(0.8))),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentOrders(BuildContext context, AsyncValue<List<OrderModel>> ordersAsync) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return ordersAsync.when(
      data: (orders) {
        if (orders.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(Icons.local_shipping_outlined, size: 48, color: colorScheme.onSurfaceVariant),
                const SizedBox(height: 12),
                Text('No deliveries yet', style: TextStyle(color: colorScheme.onSurfaceVariant)),
              ],
            ),
          );
        }
        
        return Column(
          children: orders.take(3).map((order) {
            final isDelivered = order.status == OrderStatus.delivered;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isDelivered ? Colors.green.shade50 : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isDelivered ? Icons.check_circle : Icons.schedule,
                      color: isDelivered ? Colors.green : Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Milk Delivery', style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text(
                          DateFormat('d MMM, h:mm a').format(order.deliveryDate),
                          style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDelivered ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isDelivered ? 'Delivered' : 'Pending',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDelivered ? Colors.green.shade700 : Colors.orange.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
      loading: () => const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3))),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }
}
