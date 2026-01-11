import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:milk_core/milk_core.dart';
import 'package:intl/intl.dart';

/// Provider for delivery routes from Supabase
final routesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final response = await SupabaseService.client
      .from('delivery_routes')
      .select('*, profiles!delivery_routes_delivery_person_id_fkey(full_name, phone)')
      .order('route_date', ascending: false);
  return List<Map<String, dynamic>>.from(response);
});

/// Provider for delivery persons (for route assignment)
final deliveryPersonsForRoutesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final response = await SupabaseService.client
      .from('profiles')
      .select('id, full_name, phone')
      .eq('role', 'delivery');
  return List<Map<String, dynamic>>.from(response);
});

/// Routes Management Screen with Real Data
class RoutesScreen extends ConsumerStatefulWidget {
  const RoutesScreen({super.key});

  @override
  ConsumerState<RoutesScreen> createState() => _RoutesScreenState();
}

class _RoutesScreenState extends ConsumerState<RoutesScreen> {
  String _statusFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final routesAsync = ref.watch(routesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Routes'),
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(routesProvider),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: () => _showCreateRouteDialog(),
            icon: const Icon(Icons.add),
            tooltip: 'Create Route',
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
                _buildFilterChip('Pending', 'pending'),
                const SizedBox(width: 8),
                _buildFilterChip('In Progress', 'in_progress'),
                const SizedBox(width: 8),
                _buildFilterChip('Completed', 'completed'),
              ],
            ),
            const SizedBox(height: 16),
            
            // Routes table
            Expanded(
              child: routesAsync.when(
                data: (routes) {
                  final filtered = _statusFilter == 'all'
                      ? routes
                      : routes.where((r) => r['status'] == _statusFilter).toList();
                  
                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.route_outlined, size: 64, color: colorScheme.onSurfaceVariant),
                          const SizedBox(height: 16),
                          Text('No routes found', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: () => _showCreateRouteDialog(),
                            icon: const Icon(Icons.add),
                            label: const Text('Create First Route'),
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
                        minWidth: 700,
                        columns: const [
                          DataColumn2(label: Text('Date'), size: ColumnSize.M),
                          DataColumn2(label: Text('Delivery Person'), size: ColumnSize.L),
                          DataColumn2(label: Text('Orders'), size: ColumnSize.S),
                          DataColumn2(label: Text('Status'), size: ColumnSize.S),
                          DataColumn2(label: Text('Actions'), size: ColumnSize.M),
                        ],
                        rows: filtered.map((route) {
                          final profile = route['profiles'] as Map<String, dynamic>?;
                          final routeDate = route['route_date'] != null
                              ? DateFormat('dd MMM yyyy').format(DateTime.parse(route['route_date']))
                              : '-';
                          final orderCount = (route['order_sequence'] as List?)?.length ?? 0;
                          final status = route['status'] ?? 'pending';
                          
                          return DataRow2(
                            cells: [
                              DataCell(Text(routeDate, style: const TextStyle(fontWeight: FontWeight.w500))),
                              DataCell(
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(profile?['full_name'] ?? 'Unassigned'),
                                    Text(
                                      profile?['phone'] ?? '-',
                                      style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text('$orderCount', style: TextStyle(color: colorScheme.onPrimaryContainer)),
                                ),
                              ),
                              DataCell(_buildStatusChip(status)),
                              DataCell(
                                Row(
                                  children: [
                                    if (status == 'pending')
                                      IconButton(
                                        onPressed: () => _updateRouteStatus(route, 'in_progress'),
                                        icon: const Icon(Icons.play_arrow_outlined),
                                        tooltip: 'Start Route',
                                      ),
                                    if (status == 'in_progress')
                                      IconButton(
                                        onPressed: () => _updateRouteStatus(route, 'completed'),
                                        icon: const Icon(Icons.check_circle_outline),
                                        tooltip: 'Complete Route',
                                      ),
                                    IconButton(
                                      onPressed: () => _deleteRoute(route),
                                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                                      tooltip: 'Delete',
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
    String label;
    
    switch (status) {
      case 'pending':
        color = AppTheme.warningColor;
        label = 'PENDING';
        break;
      case 'in_progress':
        color = Colors.blue;
        label = 'IN PROGRESS';
        break;
      case 'completed':
        color = AppTheme.successColor;
        label = 'COMPLETED';
        break;
      default:
        color = Colors.grey;
        label = status.toUpperCase();
    }

    return Chip(
      label: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide.none,
      padding: EdgeInsets.zero,
    );
  }

  void _showCreateRouteDialog() {
    final deliveryPersonsAsync = ref.read(deliveryPersonsForRoutesProvider);
    String? selectedPersonId;
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create Delivery Route'),
          content: SizedBox(
            width: 350,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Select Date:'),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 30)),
                    );
                    if (date != null) {
                      setState(() => selectedDate = date);
                    }
                  },
                  icon: const Icon(Icons.calendar_today),
                  label: Text(DateFormat('dd MMM yyyy').format(selectedDate)),
                ),
                const SizedBox(height: 16),
                const Text('Assign Delivery Person:'),
                const SizedBox(height: 8),
                deliveryPersonsAsync.when(
                  data: (persons) => DropdownButtonFormField<String>(
                    value: selectedPersonId,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Select delivery person',
                    ),
                    items: persons.map((p) => DropdownMenuItem(
                      value: p['id'] as String,
                      child: Text(p['full_name'] ?? 'Unknown'),
                    )).toList(),
                    onChanged: (value) => setState(() => selectedPersonId = value),
                  ),
                  loading: () => const CircularProgressIndicator(),
                  error: (e, _) => Text('Error: $e'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: selectedPersonId == null ? null : () async {
                await SupabaseService.client
                    .from('delivery_routes')
                    .insert({
                      'delivery_person_id': selectedPersonId,
                      'route_date': DateFormat('yyyy-MM-dd').format(selectedDate),
                      'status': 'pending',
                      'order_sequence': [],
                    });
                
                ref.invalidate(routesProvider);
                
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Route created successfully')),
                  );
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _updateRouteStatus(Map<String, dynamic> route, String newStatus) async {
    await SupabaseService.client
        .from('delivery_routes')
        .update({'status': newStatus})
        .eq('id', route['id']);
    ref.invalidate(routesProvider);
  }

  void _deleteRoute(Map<String, dynamic> route) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Route'),
        content: const Text('Are you sure you want to delete this route?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await SupabaseService.client
                  .from('delivery_routes')
                  .delete()
                  .eq('id', route['id']);
              ref.invalidate(routesProvider);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Route deleted')),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
