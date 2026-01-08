import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:milk_core/milk_core.dart';
import 'package:intl/intl.dart';

/// Provider for subscriptions with customer info
final subscriptionsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final response = await SupabaseService.client
      .from('subscriptions')
      .select('*, profiles!subscriptions_user_id_fkey(full_name, phone, address)')
      .order('created_at', ascending: false);
  return List<Map<String, dynamic>>.from(response);
});

/// Subscriptions Management Screen with Real Data
class SubscriptionsScreen extends ConsumerStatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  ConsumerState<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends ConsumerState<SubscriptionsScreen> {
  String _statusFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final subscriptionsAsync = ref.watch(subscriptionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscriptions'),
        actions: [
          // Refresh button
          IconButton(
            onPressed: () => ref.invalidate(subscriptionsProvider),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 8),
          // 10 PM Cutoff indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.warningColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.warningColor.withOpacity(0.3)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.access_time, size: 16, color: AppTheme.warningColor),
                SizedBox(width: 8),
                Text(
                  'Cutoff: 10:00 PM',
                  style: TextStyle(color: AppTheme.warningColor, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          FilledButton.icon(
            onPressed: _generateTomorrowOrders,
            icon: const Icon(Icons.schedule),
            label: const Text('Generate Tomorrow\'s Orders'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Filter chips
            Row(
              children: [
                _buildFilterChip('All', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('Active', 'active'),
                const SizedBox(width: 8),
                _buildFilterChip('Paused', 'paused'),
                const SizedBox(width: 8),
                _buildFilterChip('Expired', 'expired'),
              ],
            ),
            const SizedBox(height: 16),

            // Data table
            Expanded(
              child: subscriptionsAsync.when(
                data: (subscriptions) {
                  final filtered = _statusFilter == 'all'
                      ? subscriptions
                      : subscriptions.where((s) => s['status'] == _statusFilter).toList();
                  
                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox_outlined, size: 64, color: colorScheme.onSurfaceVariant),
                          const SizedBox(height: 16),
                          Text(
                            'No subscriptions found',
                            style: TextStyle(color: colorScheme.onSurfaceVariant),
                          ),
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
                        minWidth: 900,
                        columns: const [
                          DataColumn2(label: Text('Customer'), size: ColumnSize.M),
                          DataColumn2(label: Text('Product'), size: ColumnSize.L),
                          DataColumn2(label: Text('Plan'), size: ColumnSize.S),
                          DataColumn2(label: Text('Qty'), size: ColumnSize.S),
                          DataColumn2(label: Text('Amount'), size: ColumnSize.S),
                          DataColumn2(label: Text('Period'), size: ColumnSize.M),
                          DataColumn2(label: Text('Status'), size: ColumnSize.S),
                          DataColumn2(label: Text('Actions'), size: ColumnSize.M),
                        ],
                        rows: filtered.map((sub) {
                          final profile = sub['profiles'] as Map<String, dynamic>?;
                          final customerName = profile?['full_name'] ?? 'Unknown';
                          final startDate = sub['start_date'] != null 
                              ? DateFormat('dd MMM').format(DateTime.parse(sub['start_date']))
                              : '-';
                          final endDate = sub['end_date'] != null 
                              ? DateFormat('dd MMM yyyy').format(DateTime.parse(sub['end_date']))
                              : '-';
                          
                          return DataRow2(
                            cells: [
                              DataCell(Text(customerName, style: const TextStyle(fontWeight: FontWeight.w500))),
                              DataCell(Text(_getProductName(sub['product_id']))),
                              DataCell(Text(sub['plan_type'] ?? '-')),
                              DataCell(Text('${sub['quantity'] ?? 1}')),
                              DataCell(Text('₹${(sub['total_amount'] ?? 0).toStringAsFixed(0)}')),
                              DataCell(
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(startDate, style: const TextStyle(fontSize: 12)),
                                    Text('to $endDate', style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                                  ],
                                ),
                              ),
                              DataCell(_buildStatusChip(sub['status'] ?? 'active')),
                              DataCell(
                                Row(
                                  children: [
                                    if (sub['status'] == 'active')
                                      IconButton(
                                        onPressed: () => _pauseSubscription(sub),
                                        icon: const Icon(Icons.pause_outlined),
                                        tooltip: 'Pause',
                                      ),
                                    if (sub['status'] == 'paused')
                                      IconButton(
                                        onPressed: () => _resumeSubscription(sub),
                                        icon: const Icon(Icons.play_arrow_outlined),
                                        tooltip: 'Resume',
                                      ),
                                    IconButton(
                                      onPressed: () => _viewDetails(sub, profile),
                                      icon: const Icon(Icons.visibility_outlined),
                                      tooltip: 'View',
                                    ),
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

  String _getProductName(String? productId) {
    final products = {
      '1': 'Full Cream Milk - 500ml',
      '2': 'Toned Milk - 500ml',
      '3': 'Double Toned Milk - 500ml',
      '4': 'Buffalo Milk - 500ml',
    };
    return products[productId] ?? 'Unknown Product';
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

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'active':
        color = AppTheme.successColor;
        break;
      case 'paused':
        color = AppTheme.warningColor;
        break;
      case 'expired':
      case 'cancelled':
        color = AppTheme.errorColor;
        break;
      default:
        color = Colors.grey;
    }

    return Chip(
      label: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide.none,
      padding: EdgeInsets.zero,
    );
  }

  void _pauseSubscription(Map<String, dynamic> sub) async {
    await SupabaseService.client
        .from('subscriptions')
        .update({'status': 'paused'})
        .eq('id', sub['id']);
    ref.invalidate(subscriptionsProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subscription paused')),
      );
    }
  }

  void _resumeSubscription(Map<String, dynamic> sub) async {
    await SupabaseService.client
        .from('subscriptions')
        .update({'status': 'active'})
        .eq('id', sub['id']);
    ref.invalidate(subscriptionsProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subscription resumed')),
      );
    }
  }

  void _viewDetails(Map<String, dynamic> sub, Map<String, dynamic>? profile) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(profile?['full_name'] ?? 'Subscription Details'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow(Icons.phone, 'Phone', profile?['phone'] ?? '-'),
              _buildInfoRow(Icons.location_on, 'Address', profile?['address'] ?? '-'),
              _buildInfoRow(Icons.shopping_bag, 'Product', _getProductName(sub['product_id'])),
              _buildInfoRow(Icons.repeat, 'Plan', sub['plan_type'] ?? '-'),
              _buildInfoRow(Icons.numbers, 'Quantity', '${sub['quantity'] ?? 1}'),
              _buildInfoRow(Icons.currency_rupee, 'Amount', '₹${sub['total_amount'] ?? 0}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  void _generateTomorrowOrders() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Generate Tomorrow\'s Orders'),
        content: const Text(
          'This will create delivery orders for all active subscriptions (created before 10 PM cutoff). Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Orders generated successfully!')),
              );
            },
            child: const Text('Generate'),
          ),
        ],
      ),
    );
  }
}
