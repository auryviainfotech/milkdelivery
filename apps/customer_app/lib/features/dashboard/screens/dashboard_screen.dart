import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../shared/providers/auth_providers.dart';
import 'package:milk_core/milk_core.dart';

/// Customer Dashboard Screen - Real Data Version
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final profileAsync = ref.watch(userProfileProvider);
    final walletAsync = ref.watch(walletProvider);
    final subscriptionsAsync = ref.watch(activeSubscriptionsProvider);
    final ordersAsync = ref.watch(ordersProvider);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getGreeting(),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      profileAsync.when(
                        data: (profile) => Text(
                          '${profile?.fullName ?? 'User'}! 👋',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        loading: () => const Text('Loading...', style: TextStyle(fontSize: 16)),
                        error: (_, __) => const Text('Hello! 👋'),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => context.push('/notifications'),
                  icon: const Badge(
                    label: Text('0'),
                    child: Icon(Icons.notifications_outlined),
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => context.go('/profile'),
                  child: profileAsync.when(
                    data: (profile) => CircleAvatar(
                      radius: 20,
                      backgroundColor: colorScheme.primaryContainer,
                      child: Text(
                        (profile?.fullName ?? 'U')[0].toUpperCase(),
                        style: TextStyle(color: colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold),
                      ),
                    ),
                    loading: () => const CircleAvatar(radius: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                    error: (_, __) => const CircleAvatar(radius: 20, child: Icon(Icons.person)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Wallet Balance Card
            Card(
              color: colorScheme.primaryContainer,
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.account_balance_wallet, size: 20, color: colorScheme.onPrimaryContainer),
                        const SizedBox(width: 8),
                        Text(
                          'Wallet Balance',
                          style: theme.textTheme.titleSmall?.copyWith(color: colorScheme.onPrimaryContainer),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    walletAsync.when(
                      data: (wallet) => Text(
                        '₹${(wallet?.balance ?? 0.0).toStringAsFixed(2)}',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                      loading: () => const CircularProgressIndicator(),
                      error: (_, __) => const Text('₹0.00'),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: 130,
                      child: ElevatedButton.icon(
                        onPressed: () => context.push('/wallet'),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Recharge'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 10 PM Cutoff Warning Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.access_time, color: Colors.orange.shade800, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Order before 10 PM for tomorrow\'s delivery',
                      style: TextStyle(
                        color: Colors.orange.shade800,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Active Subscription Card
            subscriptionsAsync.when(
              data: (subscriptions) {
                if (subscriptions.isEmpty) {
                  return Card(
                    elevation: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, color: colorScheme.primary),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'No active subscriptions. Start one to get daily deliveries!',
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () => context.push('/subscriptions'),
                            child: const Text('New Subscription'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                
                final sub = subscriptions.first;
                return Card(
                  elevation: 1,
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('🥛', style: TextStyle(fontSize: 24)),
                    ),
                    title: const Text('Active Subscription'),
                    subtitle: Text('Delivering ${sub.quantity} unit${sub.quantity > 1 ? 's' : ''} daily'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/subscriptions'),
                  ),
                );
              },
              loading: () => const Card(child: Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()))),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),

            // Quick Actions Section
            Text(
              'Quick Actions',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildQuickAction(context, Icons.payment, 'Pay', () => context.push('/wallet')),
                _buildQuickAction(context, Icons.add_box_outlined, 'New', () => context.push('/subscriptions')),
                _buildQuickAction(context, Icons.history, 'History', () => context.push('/orders')),
                _buildQuickAction(context, Icons.shopping_bag_outlined, 'Shop', () => context.push('/shop')),
              ],
            ),
            const SizedBox(height: 24),

            // Recent Orders Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Orders',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                TextButton(
                  onPressed: () => context.push('/orders'),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ordersAsync.when(
              data: (orders) {
                if (orders.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('No recent orders found', style: TextStyle(color: Colors.grey)),
                    ),
                  );
                }
                
                return Column(
                  children: orders.take(3).map((order) {
                    return _buildOrderCard(
                      context,
                      DateFormat('d MMM').format(order.deliveryDate),
                      order.status.name.toUpperCase(),
                      order.status == OrderStatus.delivered ? Colors.green : Colors.orange,
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: colorScheme.primary, size: 24),
          ),
          const SizedBox(height: 8),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, String date, String status, Color statusColor) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(child: Text('🥛', style: TextStyle(fontSize: 24))),
        ),
        title: const Text('Full Cream 500ml'),
        subtitle: Text(date),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            status,
            style: TextStyle(
              color: statusColor.shade700,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }
}

extension ColorShade on Color {
  Color get shade700 {
    final hsl = HSLColor.fromColor(this);
    return hsl.withLightness((hsl.lightness - 0.2).clamp(0.0, 1.0)).toColor();
  }
}
