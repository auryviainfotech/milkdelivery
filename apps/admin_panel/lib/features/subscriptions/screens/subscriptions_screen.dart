import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:milk_core/milk_core.dart';

/// Subscriptions Management Screen
class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  String _statusFilter = 'all';

  final List<Map<String, dynamic>> _subscriptions = [
    {'id': '1', 'customer': 'Rahul Sharma', 'product': 'Full Cream Milk - 500ml', 'plan': 'Daily', 'quantity': 1, 'startDate': '2024-01-01', 'endDate': '2024-01-31', 'status': 'active'},
    {'id': '2', 'customer': 'Priya Singh', 'product': 'Toned Milk - 1L', 'plan': 'Daily', 'quantity': 2, 'startDate': '2024-01-05', 'endDate': '2024-02-05', 'status': 'active'},
    {'id': '3', 'customer': 'Amit Kumar', 'product': 'Buffalo Milk - 500ml', 'plan': 'Weekly', 'quantity': 1, 'startDate': '2024-01-10', 'endDate': '2024-01-17', 'status': 'expired'},
    {'id': '4', 'customer': 'Vikram Patel', 'product': 'Organic Milk - 500ml', 'plan': 'Daily', 'quantity': 1, 'startDate': '2024-01-15', 'endDate': '2024-02-15', 'status': 'paused'},
  ];

  List<Map<String, dynamic>> get _filteredSubscriptions {
    if (_statusFilter == 'all') return _subscriptions;
    return _subscriptions.where((s) => s['status'] == _statusFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscriptions'),
        actions: [
          // 10 PM Cutoff indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.warningColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.warningColor.withValues(alpha: 0.3)),
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
              child: Card(
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
                      DataColumn2(label: Text('Period'), size: ColumnSize.M),
                      DataColumn2(label: Text('Status'), size: ColumnSize.S),
                      DataColumn2(label: Text('Actions'), size: ColumnSize.M),
                    ],
                    rows: _filteredSubscriptions.map((sub) {
                      return DataRow2(
                        cells: [
                          DataCell(Text(sub['customer'], style: const TextStyle(fontWeight: FontWeight.w500))),
                          DataCell(Text(sub['product'])),
                          DataCell(Text(sub['plan'])),
                          DataCell(Text('${sub['quantity']}')),
                          DataCell(
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(sub['startDate'], style: const TextStyle(fontSize: 12)),
                                Text('to ${sub['endDate']}', style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                              ],
                            ),
                          ),
                          DataCell(_buildStatusChip(sub['status'])),
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
                                  onPressed: () {},
                                  icon: const Icon(Icons.edit_outlined),
                                  tooltip: 'Edit',
                                ),
                                IconButton(
                                  onPressed: () {},
                                  icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                                  tooltip: 'Cancel',
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide.none,
      padding: EdgeInsets.zero,
    );
  }

  void _pauseSubscription(Map<String, dynamic> sub) {
    setState(() => sub['status'] = 'paused');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Subscription paused')),
    );
  }

  void _resumeSubscription(Map<String, dynamic> sub) {
    setState(() => sub['status'] = 'active');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Subscription resumed')),
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
