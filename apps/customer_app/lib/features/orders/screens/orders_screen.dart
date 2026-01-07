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

    return Column(
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
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Orders',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ordersAsync.when(
            data: (orders) {
              if (orders.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long_outlined, size: 64, color: colorScheme.outlineVariant),
                      const SizedBox(height: 16),
                      Text(
                        'No orders yet',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  final isDelivered = order.status == OrderStatus.delivered;
                  
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
                              _buildStatusChip(order.status),
                            ],
                          ),
                          const Divider(height: 16),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text('🥛', style: TextStyle(fontSize: 20)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Daily Delivery',
                                      style: theme.textTheme.bodyLarge,
                                    ),
                                    if (order.subscriptionId != null)
                                      Text(
                                        'Subscription Order',
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
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
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, __) => Center(child: Text('Error loading orders: $e')),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(OrderStatus status) {
    Color color;
    String label;

    switch (status) {
      case OrderStatus.pending:
        color = AppTheme.pendingColor;
        label = 'Pending';
      case OrderStatus.assigned:
        color = Colors.blue;
        label = 'Assigned';
      case OrderStatus.delivered:
        color = AppTheme.successColor;
        label = 'Delivered';
      case OrderStatus.failed:
        color = AppTheme.errorColor;
        label = 'Failed';
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
