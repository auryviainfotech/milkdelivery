import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:milk_core/milk_core.dart';

/// Wallets Management Screen
class WalletsScreen extends StatefulWidget {
  const WalletsScreen({super.key});

  @override
  State<WalletsScreen> createState() => _WalletsScreenState();
}

class _WalletsScreenState extends State<WalletsScreen> {
  final _searchController = TextEditingController();

  final List<Map<String, dynamic>> _transactions = [
    {'id': '1', 'customer': 'Rahul Sharma', 'type': 'credit', 'amount': 500.0, 'reason': 'UPI Recharge', 'paymentId': 'upi_123456', 'date': '2024-01-15 10:30'},
    {'id': '2', 'customer': 'Rahul Sharma', 'type': 'debit', 'amount': 50.0, 'reason': 'Daily subscription', 'paymentId': null, 'date': '2024-01-15 06:00'},
    {'id': '3', 'customer': 'Priya Singh', 'type': 'credit', 'amount': 1000.0, 'reason': 'UPI Recharge', 'paymentId': 'upi_234567', 'date': '2024-01-14 15:45'},
    {'id': '4', 'customer': 'Amit Kumar', 'type': 'debit', 'amount': 70.0, 'reason': 'Weekly subscription', 'paymentId': null, 'date': '2024-01-14 06:00'},
    {'id': '5', 'customer': 'Vikram Patel', 'type': 'credit', 'amount': 200.0, 'reason': 'Admin credit', 'paymentId': 'admin_123', 'date': '2024-01-13 12:00'},
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Calculate stats
    final totalCredits = _transactions
        .where((t) => t['type'] == 'credit')
        .fold(0.0, (sum, t) => sum + t['amount']);
    final totalDebits = _transactions
        .where((t) => t['type'] == 'debit')
        .fold(0.0, (sum, t) => sum + t['amount']);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallets & Transactions'),
        actions: [
          SizedBox(
            width: 300,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search transactions...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 16),
          FilledButton.icon(
            onPressed: _addManualCredit,
            icon: const Icon(Icons.add),
            label: const Text('Add Credit'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Stats row
            Row(
              children: [
                Expanded(
                  child: _buildStatsCard(
                    context,
                    icon: Icons.arrow_upward,
                    label: 'Total Credits',
                    value: '₹${totalCredits.toStringAsFixed(0)}',
                    color: AppTheme.successColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatsCard(
                    context,
                    icon: Icons.arrow_downward,
                    label: 'Total Debits',
                    value: '₹${totalDebits.toStringAsFixed(0)}',
                    color: AppTheme.errorColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatsCard(
                    context,
                    icon: Icons.account_balance_wallet,
                    label: 'Net Balance',
                    value: '₹${(totalCredits - totalDebits).toStringAsFixed(0)}',
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Transactions table
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recent Transactions',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: DataTable2(
                          columnSpacing: 12,
                          horizontalMargin: 12,
                          minWidth: 800,
                          columns: const [
                            DataColumn2(label: Text('Customer'), size: ColumnSize.M),
                            DataColumn2(label: Text('Type'), size: ColumnSize.S),
                            DataColumn2(label: Text('Amount'), size: ColumnSize.S),
                            DataColumn2(label: Text('Reason'), size: ColumnSize.L),
                            DataColumn2(label: Text('Payment ID'), size: ColumnSize.M),
                            DataColumn2(label: Text('Date'), size: ColumnSize.M),
                          ],
                          rows: _transactions.map((txn) {
                            final isCredit = txn['type'] == 'credit';
                            
                            return DataRow2(
                              cells: [
                                DataCell(Text(txn['customer'], style: const TextStyle(fontWeight: FontWeight.w500))),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: (isCredit ? AppTheme.successColor : AppTheme.errorColor).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isCredit ? Icons.add : Icons.remove,
                                          size: 14,
                                          color: isCredit ? AppTheme.successColor : AppTheme.errorColor,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          isCredit ? 'Credit' : 'Debit',
                                          style: TextStyle(
                                            color: isCredit ? AppTheme.successColor : AppTheme.errorColor,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    '${isCredit ? '+' : '-'}₹${txn['amount'].toStringAsFixed(0)}',
                                    style: TextStyle(
                                      color: isCredit ? AppTheme.successColor : AppTheme.errorColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                DataCell(Text(txn['reason'])),
                                DataCell(Text(txn['paymentId'] ?? '-')),
                                DataCell(Text(txn['date'])),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _addManualCredit() {
    final customerController = TextEditingController();
    final amountController = TextEditingController();
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Manual Credit'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: customerController,
                decoration: const InputDecoration(
                  labelText: 'Customer Name/Phone',
                  border: OutlineInputBorder(),
                ),
              ),
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
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Refund, Bonus',
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
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Credit added successfully')),
              );
            },
            child: const Text('Add Credit'),
          ),
        ],
      ),
    );
  }
}
