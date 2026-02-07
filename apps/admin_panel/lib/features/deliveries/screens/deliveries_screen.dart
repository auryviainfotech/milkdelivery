import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:milk_core/milk_core.dart';
import 'package:intl/intl.dart';

/// Provider for deliveries with order and customer info
final deliveriesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final response = await SupabaseService.client
      .from('deliveries')
      .select('*, orders(*, profiles(full_name, phone, address)), profiles!deliveries_delivery_person_id_fkey(full_name)')
      .order('created_at', ascending: false);
  return List<Map<String, dynamic>>.from(response);
});

/// Deliveries Management Screen - Shows all delivery statuses
class DeliveriesScreen extends ConsumerStatefulWidget {
  const DeliveriesScreen({super.key});

  @override
  ConsumerState<DeliveriesScreen> createState() => _DeliveriesScreenState();
}

class _DeliveriesScreenState extends ConsumerState<DeliveriesScreen> {
  String _statusFilter = 'all';
  String _dateFilter = 'today';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final deliveriesAsync = ref.watch(deliveriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Deliveries'),
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(deliveriesProvider),
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
            // Filter row - responsive
            Wrap(
              spacing: 16,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              children: [
                // Status filters
                Wrap(
                  spacing: 8,
                  children: [
                    _buildFilterChip('All', 'all'),
                    _buildFilterChip('Pending', 'pending'),
                    _buildFilterChip('Delivered', 'delivered'),
                    _buildFilterChip('Issues', 'issue'),
                  ],
                ),
                // Date filter
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'today', label: Text('Today')),
                    ButtonSegment(value: 'week', label: Text('This Week')),
                    ButtonSegment(value: 'all', label: Text('All Time')),
                  ],
                  selected: {_dateFilter},
                  onSelectionChanged: (selected) {
                    setState(() => _dateFilter = selected.first);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Stats cards
            deliveriesAsync.when(
              data: (deliveries) {
                final filtered = _filterDeliveries(deliveries);
                final pending = filtered.where((d) => d['status'] == 'pending').length;
                final delivered = filtered.where((d) => d['status'] == 'delivered').length;
                final issues = filtered.where((d) => d['status'] == 'issue').length;

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final isSmall = constraints.maxWidth < 700;
                    return Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        SizedBox(
                          width: isSmall ? constraints.maxWidth : (constraints.maxWidth - 48) / 4,
                          child: _buildStatCardSimple('Total', filtered.length, Icons.local_shipping, colorScheme.primary),
                        ),
                        SizedBox(
                          width: isSmall ? constraints.maxWidth : (constraints.maxWidth - 48) / 4,
                          child: _buildStatCardSimple('Pending', pending, Icons.pending_actions, AppTheme.warningColor),
                        ),
                        SizedBox(
                          width: isSmall ? constraints.maxWidth : (constraints.maxWidth - 48) / 4,
                          child: _buildStatCardSimple('Delivered', delivered, Icons.check_circle, AppTheme.successColor),
                        ),
                        SizedBox(
                          width: isSmall ? constraints.maxWidth : (constraints.maxWidth - 48) / 4,
                          child: _buildStatCardSimple('Issues', issues, Icons.error_outline, AppTheme.errorColor),
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

            // Deliveries table
            Expanded(
              child: deliveriesAsync.when(
                data: (deliveries) {
                  final filtered = _filterDeliveries(deliveries);

                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.local_shipping_outlined, size: 64, color: colorScheme.onSurfaceVariant),
                          const SizedBox(height: 16),
                          Text('No deliveries found', style: TextStyle(color: colorScheme.onSurfaceVariant)),
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
                          DataColumn2(label: Text('Date'), size: ColumnSize.S),
                          DataColumn2(label: Text('Customer'), size: ColumnSize.L),
                          DataColumn2(label: Text('Address'), size: ColumnSize.L),
                          DataColumn2(label: Text('Delivery Person'), size: ColumnSize.M),
                          DataColumn2(label: Text('Status'), size: ColumnSize.S),
                          DataColumn2(label: Text('Actions'), size: ColumnSize.S),
                        ],
                        rows: filtered.map((delivery) {
                          final order = delivery['orders'] as Map<String, dynamic>?;
                          final customer = order?['profiles'] as Map<String, dynamic>?;
                          final deliveryPerson = delivery['profiles'] as Map<String, dynamic>?;
                          
                          final scheduledDate = delivery['scheduled_date'] != null
                              ? DateFormat('dd MMM').format(DateTime.parse(delivery['scheduled_date']))
                              : '-';
                          final status = delivery['status'] ?? 'pending';

                          return DataRow2(
                            color: WidgetStateProperty.resolveWith((states) {
                              if (status == 'delivered') {
                                return AppTheme.successColor.withOpacity(0.05);
                              } else if (status == 'issue') {
                                return AppTheme.errorColor.withOpacity(0.05);
                              }
                              return null;
                            }),
                            cells: [
                              DataCell(Text(scheduledDate)),
                              DataCell(
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(customer?['full_name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w500)),
                                    Text(customer?['phone'] ?? '-', style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                                  ],
                                ),
                              ),
                              DataCell(
                                Text(
                                  customer?['address'] ?? '-',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              DataCell(Text(deliveryPerson?['full_name'] ?? 'Unassigned')),
                              DataCell(_buildStatusChip(status)),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (status == 'pending')
                                      IconButton(
                                        onPressed: () => _markDelivered(delivery),
                                        icon: const Icon(Icons.check, color: AppTheme.successColor),
                                        tooltip: 'Mark Delivered',
                                      ),
                                    IconButton(
                                      onPressed: () => _viewDetails(delivery, customer, deliveryPerson),
                                      icon: const Icon(Icons.visibility_outlined),
                                      tooltip: 'View Details',
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

  List<Map<String, dynamic>> _filterDeliveries(List<Map<String, dynamic>> deliveries) {
    var filtered = deliveries;

    // Apply status filter
    if (_statusFilter != 'all') {
      filtered = filtered.where((d) => d['status'] == _statusFilter).toList();
    }

    // Apply date filter
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (_dateFilter == 'today') {
      filtered = filtered.where((d) {
        if (d['scheduled_date'] == null) return false;
        final date = DateTime.parse(d['scheduled_date']);
        return date.year == today.year && date.month == today.month && date.day == today.day;
      }).toList();
    } else if (_dateFilter == 'week') {
      final weekStart = today.subtract(Duration(days: today.weekday - 1));
      filtered = filtered.where((d) {
        if (d['scheduled_date'] == null) return false;
        final date = DateTime.parse(d['scheduled_date']);
        return date.isAfter(weekStart.subtract(const Duration(days: 1)));
      }).toList();
    }

    return filtered;
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
      case 'in_transit':
        color = Colors.blue;
        label = 'IN TRANSIT';
        icon = Icons.local_shipping;
        break;
      case 'delivered':
        color = AppTheme.successColor;
        label = 'DELIVERED';
        icon = Icons.check_circle;
        break;
      case 'issue':
        color = AppTheme.errorColor;
        label = 'ISSUE';
        icon = Icons.error;
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
          Text(
            label,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  void _markDelivered(Map<String, dynamic> delivery) async {
    await SupabaseService.client
        .from('deliveries')
        .update({
          'status': 'delivered',
          'delivered_at': DateTime.now().toIso8601String(),
        })
        .eq('id', delivery['id']);

    // Also update order status
    final orderId = delivery['order_id'];
    if (orderId != null) {
      await SupabaseService.client
          .from('orders')
          .update({'status': 'delivered'})
          .eq('id', orderId);
    }

    ref.invalidate(deliveriesProvider);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Delivery marked as complete'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }

  void _viewDetails(Map<String, dynamic> delivery, Map<String, dynamic>? customer, Map<String, dynamic>? deliveryPerson) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delivery Details'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow(Icons.person, 'Customer', customer?['full_name'] ?? '-'),
              _buildInfoRow(Icons.phone, 'Phone', customer?['phone'] ?? '-'),
              _buildInfoRow(Icons.location_on, 'Address', customer?['address'] ?? '-'),
              _buildInfoRow(Icons.delivery_dining, 'Delivery Person', deliveryPerson?['full_name'] ?? 'Unassigned'),
              _buildInfoRow(Icons.calendar_today, 'Scheduled', delivery['scheduled_date'] ?? '-'),
              _buildInfoRow(Icons.info, 'Status', delivery['status']?.toUpperCase() ?? '-'),
              if (delivery['delivered_at'] != null)
                _buildInfoRow(Icons.check_circle, 'Delivered At', 
                  DateFormat('dd MMM yyyy HH:mm').format(DateTime.parse(delivery['delivered_at']))),
              if (delivery['issue_notes'] != null)
                _buildInfoRow(Icons.warning, 'Issue Notes', delivery['issue_notes']),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
