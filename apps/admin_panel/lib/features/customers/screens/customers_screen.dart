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

/// Provider for wallet balances
final customerWalletsProvider = FutureProvider<Map<String, double>>((ref) async {
  final response = await SupabaseService.client
      .from('wallets')
      .select('user_id, balance');
  
  final Map<String, double> balances = {};
  for (final wallet in response) {
    final userId = wallet['user_id']?.toString() ?? '';
    balances[userId] = (wallet['balance'] as num?)?.toDouble() ?? 0.0;
  }
  return balances;
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
    final walletsAsync = ref.watch(customerWalletsProvider);

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
              ref.invalidate(customerWalletsProvider);
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
            final walletBalances = walletsAsync.valueOrNull ?? {};
            
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
                    DataColumn2(label: Text('Subscriptions'), size: ColumnSize.S),
                    DataColumn2(label: Text('Wallet'), size: ColumnSize.S),
                    DataColumn2(label: Text('Location'), size: ColumnSize.S),
                    DataColumn2(label: Text('Actions'), size: ColumnSize.M),
                  ],
                  rows: filtered.map((customer) {
                    final id = customer['id']?.toString() ?? '';
                    final subCount = subscriptionCounts[id] ?? 0;
                    final walletBalance = walletBalances[id] ?? 0.0;
                    final hasLocation = customer['latitude'] != null && customer['longitude'] != null;
                    
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
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: subCount > 0 ? colorScheme.primaryContainer : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$subCount',
                              style: TextStyle(
                                color: subCount > 0 ? colorScheme.onPrimaryContainer : Colors.grey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            '₹${walletBalance.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: walletBalance > 0 ? AppTheme.successColor : colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        DataCell(
                          Icon(
                            hasLocation ? Icons.location_on : Icons.location_off,
                            color: hasLocation ? AppTheme.successColor : Colors.grey,
                            size: 20,
                          ),
                        ),
                        DataCell(
                          Row(
                            children: [
                              IconButton(
                                onPressed: () => _viewCustomerDetails(customer, subCount, walletBalance),
                                icon: const Icon(Icons.visibility_outlined),
                                tooltip: 'View Details',
                              ),
                              IconButton(
                                onPressed: () => _addWalletBalance(customer),
                                icon: const Icon(Icons.account_balance_wallet_outlined),
                                tooltip: 'Add Balance',
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

  void _viewCustomerDetails(Map<String, dynamic> customer, int subCount, double walletBalance) {
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
              _buildInfoRow(Icons.account_balance_wallet, 'Wallet Balance', '₹${walletBalance.toStringAsFixed(2)}'),
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

  void _addWalletBalance(Map<String, dynamic> customer) {
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Balance - ${customer['full_name']}'),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter amount to add to wallet:'),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount (₹)',
                  border: OutlineInputBorder(),
                  prefixText: '₹ ',
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
              final amount = double.tryParse(amountController.text) ?? 0;
              if (amount > 0) {
                // Add to wallet
                final userId = customer['id'];
                await SupabaseService.client.from('wallets').upsert({
                  'user_id': userId,
                  'balance': amount,
                }, onConflict: 'user_id');
                
                ref.invalidate(customerWalletsProvider);
                
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('₹${amount.toStringAsFixed(0)} added to wallet')),
                  );
                }
              }
            },
            child: const Text('Add Balance'),
          ),
        ],
      ),
    );
  }
}
