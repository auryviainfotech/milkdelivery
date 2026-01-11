import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../../shared/providers/auth_providers.dart';
import 'package:milk_core/milk_core.dart';
import '../../../services/razorpay_service.dart';

/// Wallet screen with balance and Razorpay payments
class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  final _customAmountController = TextEditingController();
  bool _isLoading = false;
  double _pendingAmount = 0;

  @override
  void initState() {
    super.initState();
    _initRazorpay();
  }

  void _initRazorpay() {
    RazorpayService.init(
      onSuccess: _handlePaymentSuccess,
      onError: _handlePaymentError,
    );
  }

  @override
  void dispose() {
    _customAmountController.dispose();
    RazorpayService.dispose();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    // Add money to wallet after successful payment
    final user = SupabaseService.currentUser;
    if (user != null) {
      try {
        await WalletRepository.creditWallet(
          userId: user.id,
          amount: _pendingAmount,
          description: 'Wallet recharge via Razorpay',
          paymentId: response.paymentId,
        );
      } catch (e) {
        print('Error crediting wallet: $e');
      }
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
      ref.invalidate(walletProvider);
      
      // Show success dialog
      _showSuccessDialog(_pendingAmount, response.paymentId ?? 'N/A');
    }
    _pendingAmount = 0;
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: ${response.message ?? "Unknown error"}'),
          backgroundColor: Colors.red,
        ),
      );
    }
    _pendingAmount = 0;
  }

  void _showSuccessDialog(double amount, String paymentId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 64),
        title: const Text('Money Added!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '₹${amount.toStringAsFixed(0)}',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  const Text('✅ Added to Wallet', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Payment ID: $paymentId', style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  // Open Razorpay checkout
  Future<void> _payWithRazorpay(double amount) async {
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount')),
      );
      return;
    }

    setState(() => _isLoading = true);
    _pendingAmount = amount;
    
    try {
      final user = SupabaseService.currentUser;
      final profile = await SupabaseService.client
          .from('profiles')
          .select('full_name, phone')
          .eq('id', user?.id ?? '')
          .maybeSingle();
      
      Navigator.pop(context); // Close bottom sheet
      
      RazorpayService.openCheckout(
        amount: amount,
        orderId: 'WALLET${DateTime.now().millisecondsSinceEpoch}',
        description: 'Wallet Recharge',
        email: user?.email ?? 'customer@milkdelivery.com',
        phone: profile?['phone']?.toString().replaceAll('+91', '') ?? '',
        name: profile?['full_name'] ?? '',
      );
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  // Show payment options bottom sheet
  void _showPaymentOptions(double amount) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add ₹${amount.toStringAsFixed(0)} to Wallet',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Pay securely with Razorpay',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
              ),
              const SizedBox(height: 16),
              
              // All payment options via Razorpay
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildPaymentIcon('G', 'GPay'),
                        _buildPaymentIcon('P', 'PhonePe'),
                        _buildPaymentIcon('₿', 'Paytm'),
                        _buildPaymentIcon('💳', 'Cards'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _isLoading ? null : () => _payWithRazorpay(amount),
                        icon: _isLoading 
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.payment),
                        label: Text(_isLoading ? 'Processing...' : 'Pay ₹${amount.toStringAsFixed(0)}'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Security note
              Row(
                children: [
                  Icon(Icons.verified_user, color: Colors.green.shade700, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Secured by Razorpay • UPI, Cards, Net Banking',
                      style: TextStyle(color: Colors.green.shade700, fontSize: 11),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentIcon(String icon, String label) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(icon, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
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
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _customAmountController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                prefixText: '₹ ',
                                hintText: 'Enter amount',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () {
                              final amount = double.tryParse(_customAmountController.text) ?? 0;
                              if (amount > 0) {
                                _showPaymentOptions(amount);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Add',
                                style: TextStyle(
                                  color: colorScheme.onPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Security info
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
                        'Secure payments via Razorpay - UPI, Cards, Net Banking',
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

              // Transaction list from database
              Consumer(
                builder: (context, ref, child) {
                  final transactionsAsync = ref.watch(walletTransactionsProvider);
                  
                  return transactionsAsync.when(
                    data: (transactions) {
                      if (transactions.isEmpty) {
                        return const Center(
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
                        );
                      }
                      
                      return Column(
                        children: transactions.map((tx) {
                          final isCredit = tx.type == 'credit';
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isCredit 
                                    ? Colors.green.shade50 
                                    : Colors.red.shade50,
                                child: Icon(
                                  isCredit ? Icons.add : Icons.remove,
                                  color: isCredit ? Colors.green : Colors.red,
                                ),
                              ),
                              title: Text(
                                tx.description ?? (isCredit ? 'Money Added' : 'Deduction'),
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              subtitle: Text(
                                tx.createdAt != null 
                                    ? '${tx.createdAt!.day}/${tx.createdAt!.month}/${tx.createdAt!.year}'
                                    : '',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                              trailing: Text(
                                '${isCredit ? '+' : '-'}₹${tx.amount.toStringAsFixed(0)}',
                                style: TextStyle(
                                  color: isCredit ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error: $e')),
                  );
                },
              ),
            ],
          ),
    );
  }
}
