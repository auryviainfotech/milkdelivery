import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:milk_core/milk_core.dart';
import 'package:intl/intl.dart';

/// Provider for wallet transactions from Supabase
final walletsDataProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  // Get all wallets with user info
  final wallets = await SupabaseService.client
      .from('wallets')
      .select('*, profiles!wallets_user_id_fkey(full_name, phone)')
      .order('updated_at', ascending: false);
  
  // Get recent transactions
  final transactions = await SupabaseService.client
      .from('wallet_transactions')
      .select('*, wallets!wallet_transactions_wallet_id_fkey(user_id, profiles!wallets_user_id_fkey(full_name))')
      .order('created_at', ascending: false)
      .limit(50);
  
  return {
    'wallets': List<Map<String, dynamic>>.from(wallets),
    'transactions': List<Map<String, dynamic>>.from(transactions),
  };
});

/// Wallets Management Screen with Real Data
class WalletsScreen extends ConsumerStatefulWidget {
  const WalletsScreen({super.key});

  @override
  ConsumerState<WalletsScreen> createState() => _WalletsScreenState();
}

class _WalletsScreenState extends ConsumerState<WalletsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final walletsAsync = ref.watch(walletsDataProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallets & Transactions'),
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(walletsDataProvider),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 16),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All Wallets'),
            Tab(text: 'Transactions'),
          ],
        ),
      ),
      body: walletsAsync.when(
        data: (data) {
          final wallets = data['wallets'] as List<Map<String, dynamic>>;
          final transactions = data['transactions'] as List<Map<String, dynamic>>;
          
          return TabBarView(
            controller: _tabController,
            children: [
              _buildWalletsTab(wallets, colorScheme),
              _buildTransactionsTab(transactions, colorScheme),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildWalletsTab(List<Map<String, dynamic>> wallets, ColorScheme colorScheme) {
    if (wallets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance_wallet_outlined, size: 64, color: colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text('No wallets found', style: TextStyle(color: colorScheme.onSurfaceVariant)),
          ],
        ),
      );
    }
    
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: DataTable2(
            columnSpacing: 12,
            horizontalMargin: 12,
            minWidth: 600,
            columns: const [
              DataColumn2(label: Text('Customer'), size: ColumnSize.L),
              DataColumn2(label: Text('Balance'), size: ColumnSize.M),
              DataColumn2(label: Text('Last Updated'), size: ColumnSize.M),
              DataColumn2(label: Text('Actions'), size: ColumnSize.S),
            ],
            rows: wallets.map((wallet) {
              final profile = wallet['profiles'] as Map<String, dynamic>?;
              final balance = (wallet['balance'] as num?)?.toDouble() ?? 0;
              final updatedAt = wallet['updated_at'] != null 
                  ? DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(wallet['updated_at']))
                  : '-';
              
              return DataRow2(
                cells: [
                  DataCell(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(profile?['full_name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w500)),
                        Text(profile?['phone'] ?? '-', style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  DataCell(
                    Text(
                      '₹${balance.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: balance > 0 ? AppTheme.successColor : colorScheme.onSurface,
                      ),
                    ),
                  ),
                  DataCell(Text(updatedAt)),
                  DataCell(
                    IconButton(
                      onPressed: () => _showAddBalanceDialog(wallet),
                      icon: const Icon(Icons.add_circle_outline),
                      tooltip: 'Add Balance',
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionsTab(List<Map<String, dynamic>> transactions, ColorScheme colorScheme) {
    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 64, color: colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text('No transactions found', style: TextStyle(color: colorScheme.onSurfaceVariant)),
          ],
        ),
      );
    }
    
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: DataTable2(
            columnSpacing: 12,
            horizontalMargin: 12,
            minWidth: 700,
            columns: const [
              DataColumn2(label: Text('Date'), size: ColumnSize.M),
              DataColumn2(label: Text('Customer'), size: ColumnSize.L),
              DataColumn2(label: Text('Type'), size: ColumnSize.S),
              DataColumn2(label: Text('Amount'), size: ColumnSize.S),
              DataColumn2(label: Text('Reason'), size: ColumnSize.L),
            ],
            rows: transactions.map((tx) {
              final isCredit = tx['type'] == 'credit';
              final amount = (tx['amount'] as num?)?.toDouble() ?? 0;
              final createdAt = tx['created_at'] != null 
                  ? DateFormat('dd MMM, HH:mm').format(DateTime.parse(tx['created_at']))
                  : '-';
              
              // Get customer name from nested data
              String customerName = 'Unknown';
              final walletData = tx['wallets'] as Map<String, dynamic>?;
              if (walletData != null) {
                final profileData = walletData['profiles'] as Map<String, dynamic>?;
                customerName = profileData?['full_name'] ?? 'Unknown';
              }
              
              return DataRow2(
                cells: [
                  DataCell(Text(createdAt)),
                  DataCell(Text(customerName)),
                  DataCell(
                    Chip(
                      label: Text(
                        isCredit ? 'CREDIT' : 'DEBIT',
                        style: TextStyle(
                          color: isCredit ? AppTheme.successColor : AppTheme.errorColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      backgroundColor: (isCredit ? AppTheme.successColor : AppTheme.errorColor).withOpacity(0.1),
                      side: BorderSide.none,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  DataCell(
                    Text(
                      '${isCredit ? '+' : '-'}₹${amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isCredit ? AppTheme.successColor : AppTheme.errorColor,
                      ),
                    ),
                  ),
                  DataCell(Text(tx['reason'] ?? '-')),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _showAddBalanceDialog(Map<String, dynamic> wallet) {
    final amountController = TextEditingController();
    final reasonController = TextEditingController();
    final profile = wallet['profiles'] as Map<String, dynamic>?;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Balance - ${profile?['full_name'] ?? 'Customer'}'),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
                  hintText: 'e.g., Prepaid recharge',
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
              if (amount <= 0) return;
              
              // Update wallet balance
              final currentBalance = (wallet['balance'] as num?)?.toDouble() ?? 0;
              await SupabaseService.client
                  .from('wallets')
                  .update({
                    'balance': currentBalance + amount,
                    'updated_at': DateTime.now().toIso8601String(),
                  })
                  .eq('id', wallet['id']);
              
              // Record transaction
              await SupabaseService.client
                  .from('wallet_transactions')
                  .insert({
                    'wallet_id': wallet['id'],
                    'amount': amount,
                    'type': 'credit',
                    'reason': reasonController.text.trim().isNotEmpty 
                        ? reasonController.text.trim() 
                        : 'Admin credit',
                  });
              
              ref.invalidate(walletsDataProvider);
              
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('₹${amount.toStringAsFixed(0)} added successfully')),
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
