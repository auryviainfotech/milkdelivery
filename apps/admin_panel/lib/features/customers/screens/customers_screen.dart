import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:milk_core/milk_core.dart';

/// Customers Management Screen
class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, dynamic>> _customers = [
    {'id': '1', 'name': 'Rahul Sharma', 'phone': '+91 98765 43210', 'address': '123, Green Park, Delhi', 'subscriptions': 2, 'wallet': 450.0, 'status': 'active'},
    {'id': '2', 'name': 'Priya Singh', 'phone': '+91 87654 32109', 'address': '456, Sector 18, Noida', 'subscriptions': 1, 'wallet': 200.0, 'status': 'active'},
    {'id': '3', 'name': 'Amit Kumar', 'phone': '+91 76543 21098', 'address': '789, Vasant Kunj, Delhi', 'subscriptions': 1, 'wallet': 850.0, 'status': 'active'},
    {'id': '4', 'name': 'Sneha Gupta', 'phone': '+91 65432 10987', 'address': '321, Lajpat Nagar, Delhi', 'subscriptions': 0, 'wallet': 0.0, 'status': 'inactive'},
    {'id': '5', 'name': 'Vikram Patel', 'phone': '+91 54321 09876', 'address': '654, Greater Noida', 'subscriptions': 3, 'wallet': 1200.0, 'status': 'active'},
  ];

  List<Map<String, dynamic>> get _filteredCustomers {
    if (_searchQuery.isEmpty) return _customers;
    return _customers.where((c) {
      final searchLower = _searchQuery.toLowerCase();
      return c['name'].toLowerCase().contains(searchLower) ||
          c['phone'].contains(searchLower) ||
          c['address'].toLowerCase().contains(searchLower);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
          OutlinedButton.icon(
            onPressed: () {
              // TODO: Export customers
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Exporting customers...')),
              );
            },
            icon: const Icon(Icons.download),
            label: const Text('Export'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
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
                DataColumn2(label: Text('Status'), size: ColumnSize.S),
                DataColumn2(label: Text('Actions'), size: ColumnSize.M),
              ],
              rows: _filteredCustomers.map((customer) {
                final isActive = customer['status'] == 'active';
                
                return DataRow2(
                  cells: [
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            customer['name'],
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            customer['address'],
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    DataCell(Text(customer['phone'])),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${customer['subscriptions']}',
                          style: TextStyle(
                            color: colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        '₹${customer['wallet'].toStringAsFixed(0)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: customer['wallet'] > 0 ? AppTheme.successColor : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    DataCell(
                      Chip(
                        label: Text(
                          isActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                            color: isActive ? AppTheme.successColor : AppTheme.errorColor,
                            fontSize: 12,
                          ),
                        ),
                        backgroundColor: (isActive 
                            ? AppTheme.successColor 
                            : AppTheme.errorColor).withValues(alpha: 0.1),
                        side: BorderSide.none,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                    DataCell(
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => _viewCustomerDetails(customer),
                            icon: const Icon(Icons.visibility_outlined),
                            tooltip: 'View Details',
                          ),
                          IconButton(
                            onPressed: () => _addWalletBalance(customer),
                            icon: const Icon(Icons.account_balance_wallet_outlined),
                            tooltip: 'Add Balance',
                          ),
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.history_outlined),
                            tooltip: 'View History',
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
    );
  }

  void _viewCustomerDetails(Map<String, dynamic> customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(customer['name']),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow(Icons.phone, 'Phone', customer['phone']),
              _buildInfoRow(Icons.location_on, 'Address', customer['address']),
              _buildInfoRow(Icons.subscriptions, 'Subscriptions', '${customer['subscriptions']} active'),
              _buildInfoRow(Icons.account_balance_wallet, 'Wallet Balance', '₹${customer['wallet'].toStringAsFixed(2)}'),
              _buildInfoRow(Icons.circle, 'Status', customer['status'].toString().toUpperCase()),
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

  void _addWalletBalance(Map<String, dynamic> customer) {
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Balance - ${customer['name']}'),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Current Balance: ₹${customer['wallet'].toStringAsFixed(2)}'),
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
            onPressed: () {
              final amount = double.tryParse(amountController.text) ?? 0;
              if (amount > 0) {
                setState(() {
                  customer['wallet'] += amount;
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('₹${amount.toStringAsFixed(0)} added to wallet')),
                );
              }
            },
            child: const Text('Add Balance'),
          ),
        ],
      ),
    );
  }
}
