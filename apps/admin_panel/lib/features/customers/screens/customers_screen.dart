import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:milk_core/milk_core.dart';

/// Provider for customers (profiles with role = customer)
final customersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final response = await SupabaseService.client
      .from('profiles')
      .select('*')
      .eq('role', 'customer')
      .order('created_at', ascending: false);
  return List<Map<String, dynamic>>.from(response);
});

/// Provider for subscription counts per customer
final customerSubscriptionsProvider = FutureProvider<Map<String, int>>((ref) async {
  final response = await SupabaseService.client
      .from('subscriptions')
      .select('user_id, status')
      .eq('status', 'active');
  
  final Map<String, int> counts = {};
  for (final sub in response) {
    final userId = sub['user_id']?.toString() ?? '';
    counts[userId] = (counts[userId] ?? 0) + 1;
  }
  return counts;
});

/// Provider for wallet balances - Now showing liters remaining
final customerLitersProvider = FutureProvider<Map<String, Map<String, dynamic>>>((ref) async {
  final response = await SupabaseService.client
      .from('profiles')
      .select('id, liters_remaining, subscription_status')
      .eq('role', 'customer');
  
  final Map<String, Map<String, dynamic>> data = {};
  for (final profile in response) {
    final userId = profile['id']?.toString() ?? '';
    data[userId] = {
      'liters': (profile['liters_remaining'] as num?)?.toDouble() ?? 0.0,
      'status': profile['subscription_status'] ?? 'inactive',
    };
  }
  return data;
});

/// Customers Management Screen with Real Data
class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final customersAsync = ref.watch(customersProvider);
    final subscriptionsAsync = ref.watch(customerSubscriptionsProvider);
    final litersAsync = ref.watch(customerLitersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
        actions: [
          SizedBox(
            width: 300,
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search customers...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            onPressed: () {
              ref.invalidate(customersProvider);
              ref.invalidate(customerSubscriptionsProvider);
              ref.invalidate(customerLitersProvider);
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: customersAsync.when(
          data: (customers) {
            final subscriptionCounts = subscriptionsAsync.valueOrNull ?? {};
            final litersData = litersAsync.valueOrNull ?? {};
            
            // Filter customers based on search
            final filtered = _searchQuery.isEmpty
                ? customers
                : customers.where((c) {
                    final searchLower = _searchQuery.toLowerCase();
                    final name = (c['full_name'] ?? '').toString().toLowerCase();
                    final phone = (c['phone'] ?? '').toString().toLowerCase();
                    final address = (c['address'] ?? '').toString().toLowerCase();
                    return name.contains(searchLower) ||
                        phone.contains(searchLower) ||
                        address.contains(searchLower);
                  }).toList();
            
            if (filtered.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_outline, size: 64, color: colorScheme.onSurfaceVariant),
                    const SizedBox(height: 16),
                    Text(
                      'No customers found',
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
                    DataColumn2(label: Text('Customer'), size: ColumnSize.L),
                    DataColumn2(label: Text('Phone'), size: ColumnSize.M),
                    DataColumn2(label: Text('Status'), size: ColumnSize.S),
                    DataColumn2(label: Text('Liters'), size: ColumnSize.S),
                    DataColumn2(label: Text('Location'), size: ColumnSize.S),
                    DataColumn2(label: Text('Actions'), size: ColumnSize.M),
                  ],
                  rows: filtered.map((customer) {
                    final id = customer['id']?.toString() ?? '';
                    final subCount = subscriptionCounts[id] ?? 0;
                    final customerLiters = litersData[id];
                    final litersRemaining = customerLiters?['liters'] ?? 0.0;
                    final subStatus = customerLiters?['status'] ?? 'inactive';
                    final hasGpsLocation = customer['latitude'] != null && customer['longitude'] != null;
                    final address = customer['address'] ?? '';
                    final hasAddress = address.isNotEmpty;
                    
                    return DataRow2(
                      cells: [
                        DataCell(
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                customer['full_name'] ?? 'Unknown',
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              Text(
                                customer['address'] ?? 'No address',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        DataCell(Text(customer['phone'] ?? '-')),
                        DataCell(
                          _buildStatusChip(subStatus),
                        ),
                        DataCell(
                          Text(
                            '${litersRemaining.toStringAsFixed(1)} L',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: litersRemaining > 0 ? AppTheme.successColor : colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        DataCell(
                          Tooltip(
                            message: hasAddress ? address : 'No address',
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  hasAddress ? Icons.location_on : Icons.location_off,
                                  color: hasAddress ? AppTheme.successColor : Colors.grey,
                                  size: 18,
                                ),
                                if (hasGpsLocation)
                                  const Icon(Icons.gps_fixed, size: 14, color: Colors.blue),
                              ],
                            ),
                          ),
                        ),
                        DataCell(
                          Row(
                            children: [
                              IconButton(
                                onPressed: () => _viewCustomerDetails(customer, subCount, litersRemaining, subStatus),
                                icon: const Icon(Icons.visibility_outlined),
                                tooltip: 'View Details',
                              ),
                              IconButton(
                                onPressed: () => _editCustomer(customer),
                                icon: const Icon(Icons.edit_outlined),
                                tooltip: 'Edit',
                              ),
                              IconButton(
                                onPressed: () => _addLiters(customer),
                                icon: const Icon(Icons.water_drop_outlined),
                                tooltip: 'Add Liters',
                              ),
                              IconButton(
                                onPressed: () => _deleteCustomer(customer),
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
    );
  }

  void _viewCustomerDetails(Map<String, dynamic> customer, int subCount, double litersRemaining, String subStatus) {
    final hasLocation = customer['latitude'] != null && customer['longitude'] != null;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(customer['full_name'] ?? 'Customer Details'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow(Icons.phone, 'Phone', customer['phone'] ?? '-'),
              _buildInfoRow(Icons.location_on, 'Address', customer['address'] ?? '-'),
              _buildInfoRow(Icons.subscriptions, 'Active Subscriptions', '$subCount'),
              _buildInfoRow(Icons.water_drop, 'Liters Remaining', '${litersRemaining.toStringAsFixed(1)} L'),
              _buildInfoRow(Icons.check_circle, 'Subscription Status', subStatus.toUpperCase()),
              if (customer['qr_code'] != null)
                _buildInfoRow(Icons.qr_code, 'QR Code', customer['qr_code'] ?? '-'),
              if (hasLocation)
                _buildInfoRow(
                  Icons.my_location,
                  'GPS Location',
                  '${customer['latitude']?.toStringAsFixed(4)}, ${customer['longitude']?.toStringAsFixed(4)}',
                ),
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

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'active':
        color = AppTheme.successColor;
        break;
      case 'pending':
        color = Colors.orange;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
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

  Future<void> _deleteCustomer(Map<String, dynamic> customer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Customer?'),
        content: Text(
          'Are you sure you want to delete "${customer['full_name']}"?\n\n'
          'This will also delete all their subscriptions and orders.\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    try {
      final userId = customer['id'];
      
      // Delete related data first (subscriptions)
      await SupabaseService.client
          .from('subscriptions')
          .delete()
          .eq('user_id', userId);
      
      // Delete the profile
      await SupabaseService.client
          .from('profiles')
          .delete()
          .eq('id', userId);
      
      if (mounted) {
        ref.invalidate(customersProvider);
        ref.invalidate(customerSubscriptionsProvider);
        ref.invalidate(customerLitersProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Customer deleted successfully'),
            backgroundColor: Colors.green,
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

  void _editCustomer(Map<String, dynamic> customer) {
    final nameController = TextEditingController(text: customer['full_name'] ?? '');
    final phoneController = TextEditingController(text: customer['phone'] ?? '');
    final addressController = TextEditingController(text: customer['address'] ?? '');

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Edit - ${customer['full_name'] ?? 'Customer'}'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    prefixIcon: Icon(Icons.phone),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: addressController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    prefixIcon: Icon(Icons.location_on),
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              try {
                await SupabaseService.client
                    .from('profiles')
                    .update({
                      'full_name': nameController.text.trim(),
                      'phone': phoneController.text.trim(),
                      'address': addressController.text.trim(),
                    })
                    .eq('id', customer['id']);
                
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
                
                if (mounted) {
                  ref.invalidate(customersProvider);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Customer updated successfully'),
                      backgroundColor: Colors.green,
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
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _addLiters(Map<String, dynamic> customer) {
    final litersController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Liters - ${customer['full_name']}'),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter liters to add to customer quota:'),
              const SizedBox(height: 16),
              TextField(
                controller: litersController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Liters to Add',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.water_drop),
                  suffixText: 'L',
                ),
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
            onPressed: () async {
              final liters = double.tryParse(litersController.text) ?? 0;
              if (liters > 0) {
                final userId = customer['id'];
                
                // Get current liters and add to it
                final current = await SupabaseService.client
                    .from('profiles')
                    .select('liters_remaining')
                    .eq('id', userId)
                    .single();
                final currentLiters = (current['liters_remaining'] as num?)?.toDouble() ?? 0.0;
                
                await SupabaseService.client
                    .from('profiles')
                    .update({
                      'liters_remaining': currentLiters + liters,
                      'subscription_status': 'active',
                    })
                    .eq('id', userId);
                
                ref.invalidate(customerLitersProvider);
                
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${liters.toStringAsFixed(1)} liters added!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            child: const Text('Add Liters'),
          ),
        ],
      ),
    );
  }
}
