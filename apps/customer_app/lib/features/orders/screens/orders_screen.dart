import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milk_core/milk_core.dart';
import '../../../shared/providers/auth_providers.dart';
import 'package:intl/intl.dart';

/// Orders history screen
class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final ordersAsync = ref.watch(ordersProvider);
    final subscriptionsAsync = ref.watch(activeSubscriptionsProvider);
    final productsAsync = ref.watch(productsProvider);

    return SafeArea(
      child: Column(
        children: [
          // Custom App Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(
                bottom: BorderSide(color: colorScheme.outlineVariant, width: 1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Orders & Subscriptions',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(ordersProvider);
                ref.invalidate(activeSubscriptionsProvider);
                ref.invalidate(productsProvider);
              },
              child: ordersAsync.when(
                data: (orders) {
                  return subscriptionsAsync.when(
                    data: (subscriptions) {
                      if (orders.isEmpty && subscriptions.isEmpty) {
                        return ListView(
                          children: [
                            const SizedBox(height: 100),
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.receipt_long_outlined, size: 64, color: colorScheme.outlineVariant),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No orders or subscriptions',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'User: ${SupabaseService.currentUser?.id ?? "Not logged in"}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      ref.invalidate(ordersProvider);
                                      ref.invalidate(activeSubscriptionsProvider);
                                    },
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Refresh'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }

                      return ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          if (subscriptions.isNotEmpty) ...[
                            Text(
                              'My Subscriptions',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...subscriptions.map((subscription) {
                              final product = productsAsync.value?.firstWhere(
                                (p) => p.id == subscription.productId,
                                orElse: () => const ProductModel(
                                  id: '', 
                                  name: 'Unknown Product', 
                                  price: 0,
                                  isActive: false,
                                ),
                              );
                              
                              return _buildSubscriptionCard(context, subscription, product);
                            }),
                            const SizedBox(height: 24),
                          ],

                          if (orders.isNotEmpty) ...[
                             Text(
                              'Order History',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...orders.map((order) => _buildOrderCard(context, order)),
                          ] else if (subscriptions.isNotEmpty) ...[
                             Text(
                              'Order History',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(16),
                              alignment: Alignment.center,
                              child: Text(
                                'No daily orders yet',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, __) => Center(child: Text('Error loading subscriptions: $e')),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, __) => Center(child: Text('Error loading orders: $e')),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard(BuildContext context, SubscriptionModel subscription, ProductModel? product) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(product?.emoji ?? '🥛', style: const TextStyle(fontSize: 24)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product?.name ?? 'Loading...',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${subscription.monthlyLiters}L / Month',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(subscription.status.name),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Started: ${_formatDate(subscription.startDate)}',
                  style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
                if (subscription.status == SubscriptionStatus.pending)
                  Text(
                    'Waiting for approval',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, OrderModel order) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDelivered = order.status == OrderStatus.delivered || order.status == OrderStatus.paymentPending;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDate(order.deliveryDate),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                _buildStatusChip(order.status.name), // Use name or map manually
              ],
            ),
            const Divider(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('📦', style: TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (order.items != null && order.items!.isNotEmpty) ...[
                        ...order.items!.map((item) {
                          final product = item.product;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                Text('${product?.emoji ?? '📦'} ', style: const TextStyle(fontSize: 16)),
                                Expanded(
                                  child: Text(
                                    '${product?.name ?? 'Unknown Product'} x ${item.quantity}',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ),
                                Text(
                                  '₹${(item.price * item.quantity).toStringAsFixed(0)}',
                                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 4),
                        Text(
                          'Total: ₹${order.totalAmount?.toStringAsFixed(0) ?? '0'}',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ] else
                        Text(
                          order.subscriptionId != null ? 'Daily Delivery' : 'Shop Order',
                          style: theme.textTheme.bodyLarge,
                        ),

                    ],
                  ),
                ),
              ],
            ),
            if (isDelivered) ...[
              const Divider(height: 16),
              Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    size: 16,
                    color: AppTheme.successColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Delivered successfully',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.successColor,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label = status[0].toUpperCase() + status.substring(1);

    switch (status.toLowerCase()) {
      case 'pending':
        color = Colors.orange;
        label = 'Pending';
      case 'active':
        color = Colors.green;
        label = 'Active';
      case 'delivered':
      case 'paymentpending':
        color = Colors.green;
        label = 'Delivered';
      case 'assigned':
        color = Colors.blue;
        label = 'Assigned';
      case 'failed':
      case 'cancelled':
      case 'expired':
        color = Colors.red;
        label = status[0].toUpperCase() + status.substring(1);
      case 'paused':
        color = Colors.grey;
        label = 'Paused';
      default:
        color = Colors.blue;
        label = status[0].toUpperCase() + status.substring(1);
    }

    return Chip(
      label: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
        ),
      ),
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide.none,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final orderDate = DateTime(date.year, date.month, date.day);

    if (orderDate == today) return 'Today';
    if (orderDate == yesterday) return 'Yesterday';
    return DateFormat('d MMM yyyy').format(date);
  }
}
