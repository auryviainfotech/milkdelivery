import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:milk_core/milk_core.dart';
import 'package:intl/intl.dart';

/// Provider for shop orders (one_time orders) with customer info and order items
final shopOrdersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final response = await SupabaseService.client
      .from('orders')
      .select('*, profiles(id, full_name, phone, address), order_items(*, products(name, price, emoji))')
      .eq('order_type', 'one_time')
      .order('created_at', ascending: false);
  return List<Map<String, dynamic>>.from(response);
});

/// Provider for delivery persons
final deliveryPersonsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final response = await SupabaseService.client
      .from('profiles')
      .select('id, full_name, phone')
      .eq('role', 'delivery');
  return List<Map<String, dynamic>>.from(response);
});

/// Shop Orders Management Screen - Shows all one-time/shop orders
class ShopOrdersScreen extends ConsumerStatefulWidget {
  const ShopOrdersScreen({super.key});

  @override
  ConsumerState<ShopOrdersScreen> createState() => _ShopOrdersScreenState();
}

class _ShopOrdersScreenState extends ConsumerState<ShopOrdersScreen> {
  String _statusFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final ordersAsync = ref.watch(shopOrdersProvider);
    final deliveryPersonsAsync = ref.watch(deliveryPersonsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop Orders'),
        actions: [
          IconButton(
            onPressed: () {
              ref.invalidate(shopOrdersProvider);
              ref.invalidate(deliveryPersonsProvider);
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Filter row
            Row(
              children: [
                Wrap(
                  spacing: 8,
                  children: [
                    _buildFilterChip('All', 'all'),
                    _buildFilterChip('Pending', 'pending'),
                    _buildFilterChip('Assigned', 'assigned'),
                    _buildFilterChip('Delivered', 'delivered'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Stats
            ordersAsync.when(
              data: (orders) {
                final filtered = _filterOrders(orders);
                final pending = filtered.where((o) => o['status'] == 'pending').length;
                final assigned = filtered.where((o) => o['status'] == 'assigned').length;

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final isSmall = constraints.maxWidth < 600;
                    return Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        SizedBox(
                          width: isSmall ? constraints.maxWidth : (constraints.maxWidth - 32) / 3,
                          child: _buildStatCardSimple('Total', filtered.length, Icons.shopping_bag, colorScheme.primary),
                        ),
                        SizedBox(
                          width: isSmall ? constraints.maxWidth : (constraints.maxWidth - 32) / 3,
                          child: _buildStatCardSimple('Pending Assignment', pending, Icons.pending_actions, AppTheme.warningColor),
                        ),
                        SizedBox(
                          width: isSmall ? constraints.maxWidth : (constraints.maxWidth - 32) / 3,
                          child: _buildStatCardSimple('Assigned', assigned, Icons.assignment_ind, Colors.blue),
                        ),
                      ],
                    );
                  },
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 16),

            // Orders table
            Expanded(
              child: ordersAsync.when(
                data: (orders) {
                  final filtered = _filterOrders(orders);

                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_bag_outlined, size: 64, color: colorScheme.onSurfaceVariant),
                          const SizedBox(height: 16),
                          Text('No shop orders found', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    );
                  }

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: DataTable2(
                        columnSpacing: 12,
                        horizontalMargin: 12,
                        minWidth: 1000,
                        columns: const [
                          DataColumn2(label: Text('Date'), size: ColumnSize.S),
                          DataColumn2(label: Text('Customer'), size: ColumnSize.M),
                          DataColumn2(label: Text('Products'), size: ColumnSize.L),
                          DataColumn2(label: Text('Total'), size: ColumnSize.S),
                          DataColumn2(label: Text('Status'), size: ColumnSize.S),
                          DataColumn2(label: Text('Actions'), size: ColumnSize.M),
                        ],
                        rows: filtered.map((order) {
                          final customer = order['profiles'] as Map<String, dynamic>?;
                          final items = order['order_items'] as List<dynamic>? ?? [];
                          final deliveryDate = order['delivery_date'] != null
                              ? DateFormat('dd MMM').format(DateTime.parse(order['delivery_date']))
                              : '-';
                          final status = order['status'] ?? 'pending';
                          final total = order['total_amount'] ?? 0;

                          // Build products string
                          final productNames = items.map((item) {
                            final product = item['products'] as Map<String, dynamic>?;
                            final qty = item['quantity'] ?? 1;
                            return '${product?['emoji'] ?? '📦'} ${product?['name'] ?? 'Unknown'} x$qty';
                          }).join(', ');

                          return DataRow2(
                            color: WidgetStateProperty.resolveWith((states) {
                              if (status == 'delivered') {
                                return AppTheme.successColor.withOpacity(0.05);
                              } else if (status == 'pending') {
                                return AppTheme.warningColor.withOpacity(0.05);
                              }
                              return null;
                            }),
                            cells: [
                              DataCell(Text(deliveryDate)),
                              DataCell(
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(customer?['full_name'] ?? 'Unknown', 
                                         style: const TextStyle(fontWeight: FontWeight.w500)),
                                    Text(customer?['phone'] ?? '-', 
                                         style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                                  ],
                                ),
                              ),
                              DataCell(
                                Text(
                                  productNames.isEmpty ? '-' : productNames,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              DataCell(Text('₹${total.toStringAsFixed(0)}')),
                              DataCell(_buildStatusChip(status)),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (status == 'pending')
                                      deliveryPersonsAsync.when(
                                        data: (persons) => ElevatedButton.icon(
                                          onPressed: () => _showAssignDialog(order, persons),
                                          icon: const Icon(Icons.person_add, size: 16),
                                          label: const Text('Assign'),
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          ),
                                        ),
                                        loading: () => const SizedBox(width: 80, child: LinearProgressIndicator()),
                                        error: (_, __) => const Text('Error'),
                                      ),
                                    if (status == 'assigned') ...[
                                      IconButton(
                                        onPressed: () => _markDelivered(order),
                                        icon: const Icon(Icons.check_circle, color: AppTheme.successColor),
                                        tooltip: 'Mark Delivered',
                                      ),
                                      IconButton(
                                        onPressed: () => _unassignOrder(order),
                                        icon: const Icon(Icons.person_remove, color: AppTheme.errorColor),
                                        tooltip: 'Unassign',
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _filterOrders(List<Map<String, dynamic>> orders) {
    if (_statusFilter == 'all') return orders;
    return orders.where((o) => o['status'] == _statusFilter).toList();
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _statusFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _statusFilter = value);
      },
    );
  }

  Widget _buildStatCardSimple(String label, int count, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$count', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
                  Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;
    IconData icon;

    switch (status) {
      case 'pending':
        color = AppTheme.warningColor;
        label = 'PENDING';
        icon = Icons.pending_actions;
        break;
      case 'assigned':
        color = Colors.blue;
        label = 'ASSIGNED';
        icon = Icons.assignment_ind;
        break;
      case 'delivered':
        color = AppTheme.successColor;
        label = 'DELIVERED';
        icon = Icons.check_circle;
        break;
      default:
        color = Colors.grey;
        label = status.toUpperCase();
        icon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _showAssignDialog(Map<String, dynamic> order, List<Map<String, dynamic>> deliveryPersons) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assign Delivery Person'),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: deliveryPersons.map((person) => ListTile(
              leading: CircleAvatar(child: Text(person['full_name']?[0] ?? '?')),
              title: Text(person['full_name'] ?? 'Unknown'),
              subtitle: Text(person['phone'] ?? '-'),
              onTap: () {
                Navigator.pop(context);
                _assignDeliveryPerson(order, person);
              },
            )).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _assignDeliveryPerson(Map<String, dynamic> order, Map<String, dynamic> person) async {
    try {
      final orderId = order['id'] as String;
      final personId = person['id'] as String;
      final deliveryDate = order['delivery_date'] ?? DateTime.now().toIso8601String().split('T')[0];

      // Create delivery record
      await SupabaseService.client.from('deliveries').insert({
        'order_id': orderId,
        'delivery_person_id': personId,
        'scheduled_date': deliveryDate,
        'status': 'pending',
      });

      // Update order status
      await SupabaseService.client
          .from('orders')
          .update({'status': 'assigned'})
          .eq('id', orderId);

      ref.invalidate(shopOrdersProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Assigned to ${person['full_name']}'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorColor),
        );
      }
    }
  }

  void _unassignOrder(Map<String, dynamic> order) async {
    try {
      final orderId = order['id'] as String;

      // Delete delivery record
      await SupabaseService.client
          .from('deliveries')
          .delete()
          .eq('order_id', orderId)
          .eq('status', 'pending');

      // Update order status
      await SupabaseService.client
          .from('orders')
          .update({'status': 'pending'})
          .eq('id', orderId);

      ref.invalidate(shopOrdersProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order unassigned'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorColor),
        );
      }
    }
  }

  void _markDelivered(Map<String, dynamic> order) async {
    try {
      final orderId = order['id'] as String;

      // Update order status
      await SupabaseService.client
          .from('orders')
          .update({'status': 'delivered'})
          .eq('id', orderId);

      // Update delivery status
      await SupabaseService.client
          .from('deliveries')
          .update({
            'status': 'delivered',
            'delivered_at': DateTime.now().toIso8601String(),
          })
          .eq('order_id', orderId);

      ref.invalidate(shopOrdersProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Marked as delivered'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorColor),
        );
      }
    }
  }
}
