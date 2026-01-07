import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/providers/auth_providers.dart';
import 'package:milk_core/milk_core.dart';
import '../../../services/upi_payment_service.dart';

/// Wallet screen with balance and UPI payments
class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  final _customAmountController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _customAmountController.dispose();
    super.dispose();
  }

  // Open UPI app
  Future<void> _payWithUpi(double amount, String appType) async {
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount')),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final success = await UpiPaymentService.initiatePayment(
        amount: amount,
        transactionId: UpiPaymentService.generateTransactionId(),
        preferredApp: appType,
      );
      
      if (success) {
        // For demo: Add money after launching (in real app, you'd verify payment via backend)
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ref.invalidate(walletProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('₹${amount.toStringAsFixed(0)} added successfully!')),
          );
          Navigator.pop(context); // Close bottom sheet
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open payment app. Make sure it is installed.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment failed: $e')),
        );
      }
    }
  }

  // Show payment options bottom sheet
  void _showPaymentOptions(double amount) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pay ₹${amount.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose payment method',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              
              // Google Pay
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: const Text('G', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                ),
                title: const Text('Google Pay'),
                subtitle: const Text('Recommended'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _payWithUpi(amount, 'gpay'),
              ),
              
              const Divider(),
              
              // PhonePe
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.phone_android, color: Colors.purple.shade700),
                ),
                title: const Text('PhonePe'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _payWithUpi(amount, 'phonepe'),
              ),
              
              const Divider(),
              
              // Paytm
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.payment, color: Colors.blue.shade700),
                ),
                title: const Text('Paytm'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _payWithUpi(amount, 'paytm'),
              ),
              
              const Divider(),
              
              // Other UPI
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.more_horiz),
                ),
                title: const Text('Other UPI Apps'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _payWithUpi(amount, 'generic'),
              ),
              
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final walletAsync = ref.watch(walletProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallet'),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Balance Card
              Card(
                color: colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.account_balance_wallet, color: colorScheme.onPrimaryContainer, size: 24),
                          const SizedBox(width: 8),
                          Text('Wallet Balance', style: TextStyle(color: colorScheme.onPrimaryContainer)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      walletAsync.when(
                        data: (wallet) => Text(
                          '₹${(wallet?.balance ?? 0.0).toStringAsFixed(2)}',
                          style: theme.textTheme.displaySmall?.copyWith(
                            color: colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        loading: () => const CircularProgressIndicator(),
                        error: (_, __) => Text('₹0.00', style: theme.textTheme.displaySmall),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Add Money section
              Text('Add Money', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              // Amount buttons
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [100, 200, 500, 1000].map((amount) {
                  return ActionChip(
                    avatar: const Icon(Icons.add, size: 18),
                    label: Text('₹$amount'),
                    onPressed: () => _showPaymentOptions(amount.toDouble()),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Custom amount input
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Custom Amount', style: theme.textTheme.titleSmall),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _customAmountController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          prefixText: '₹ ',
                          hintText: 'Enter amount',
                          border: const OutlineInputBorder(),
                          suffixIcon: TextButton(
                            onPressed: () {
                              final amount = double.tryParse(_customAmountController.text);
                              if (amount != null && amount > 0) {
                                _showPaymentOptions(amount);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Enter a valid amount')),
                                );
                              }
                            },
                            child: const Text('Pay'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // UPI info banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.verified_user, color: Colors.green.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Secure UPI payments via Google Pay, PhonePe & more',
                        style: TextStyle(color: Colors.green.shade700, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Transactions section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Recent Transactions', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  TextButton(onPressed: () {}, child: const Text('View All')),
                ],
              ),
              const SizedBox(height: 12),

              // Transaction list
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.history, size: 48, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No recent transactions', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildTransaction(BuildContext context, IconData icon, Color color, String title, String amount, String date) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title),
        subtitle: Text(date),
        trailing: Text(
          amount,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
