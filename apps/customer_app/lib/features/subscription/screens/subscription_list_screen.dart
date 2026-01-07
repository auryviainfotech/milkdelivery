import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:milk_core/milk_core.dart';
import '../../../services/upi_payment_service.dart';

/// 4 Hardcoded milk products
final List<Map<String, dynamic>> _products = [
  {
    'id': '1',
    'name': 'Full Cream Milk',
    'price': 35.0,
    'unit': '500ml',
    'emoji': '🥛',
    'description': 'Rich & creamy, 6% fat content',
  },
  {
    'id': '2',
    'name': 'Toned Milk',
    'price': 30.0,
    'unit': '500ml',
    'emoji': '🥛',
    'description': 'Balanced nutrition, 3% fat content',
  },
  {
    'id': '3',
    'name': 'Double Toned Milk',
    'price': 28.0,
    'unit': '500ml',
    'emoji': '🥛',
    'description': 'Light & healthy, 1.5% fat content',
  },
  {
    'id': '4',
    'name': 'Buffalo Milk',
    'price': 45.0,
    'unit': '500ml',
    'emoji': '🦬',
    'description': 'Premium quality, high protein',
  },
];

/// Subscription list and new subscription screen
class SubscriptionListScreen extends ConsumerStatefulWidget {
  const SubscriptionListScreen({super.key});

  @override
  ConsumerState<SubscriptionListScreen> createState() => _SubscriptionListScreenState();
}

class _SubscriptionListScreenState extends ConsumerState<SubscriptionListScreen> {
  String? _selectedProductId;
  String _selectedPlan = 'daily';
  int _quantity = 1;
  bool _isProcessing = false;

  double get _pricePerDay {
    if (_selectedProductId == null) return 0;
    final product = _products.firstWhere((p) => p['id'] == _selectedProductId);
    return (product['price'] as double) * _quantity;
  }

  double get _totalPrice {
    switch (_selectedPlan) {
      case 'weekly':
        return _pricePerDay * 7;
      case 'monthly':
        return _pricePerDay * 30;
      default:
        return _pricePerDay * 30; // Show monthly for daily plan
    }
  }

  String get _planLabel {
    switch (_selectedPlan) {
      case 'weekly':
        return 'Weekly (7 days)';
      case 'monthly':
        return 'Monthly (30 days)';
      default:
        return 'Daily (per month)';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscribe to Milk'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product selection
                  Text(
                    'Select Product',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.85,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: _products.length,
                    itemBuilder: (context, index) {
                      final product = _products[index];
                      final isSelected = _selectedProductId == product['id'];
                      return _buildProductCard(product, isSelected);
                    },
                  ),
                  const SizedBox(height: 24),

                  // Quantity selector
                  if (_selectedProductId != null) ...[
                    Text(
                      'Quantity (per delivery)',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton.filledTonal(
                            onPressed: _quantity > 1
                                ? () => setState(() => _quantity--)
                                : null,
                            icon: const Icon(Icons.remove),
                          ),
                          Container(
                            width: 60,
                            alignment: Alignment.center,
                            child: Text(
                              '$_quantity',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton.filledTonal(
                            onPressed: _quantity < 5
                                ? () => setState(() => _quantity++)
                                : null,
                            icon: const Icon(Icons.add),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Plan selection
                    Text(
                      'Select Plan',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildPlanChip('daily', 'Daily'),
                        const SizedBox(width: 8),
                        _buildPlanChip('weekly', 'Weekly'),
                        const SizedBox(width: 8),
                        _buildPlanChip('monthly', 'Monthly'),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Price display
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _planLabel,
                            style: TextStyle(color: colorScheme.onPrimaryContainer),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '₹${_totalPrice.toStringAsFixed(0)}',
                            style: theme.textTheme.headlineLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                          if (_selectedPlan == 'daily')
                            Text(
                              '₹${_pricePerDay.toStringAsFixed(0)}/day',
                              style: TextStyle(color: colorScheme.onPrimaryContainer),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Subscribe button
          if (_selectedProductId != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: FilledButton(
                  onPressed: _isProcessing ? null : _handleSubscribe,
                  child: _isProcessing
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Subscribe Now'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product, bool isSelected) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: () => setState(() => _selectedProductId = product['id']),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primaryContainer : colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outline.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(product['emoji'], style: const TextStyle(fontSize: 36)),
            const SizedBox(height: 8),
            Text(
              product['name'],
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: isSelected ? colorScheme.onPrimaryContainer : null,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              product['unit'],
              style: theme.textTheme.bodySmall?.copyWith(
                color: isSelected
                    ? colorScheme.onPrimaryContainer.withOpacity(0.7)
                    : colorScheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            Text(
              '₹${(product['price'] as double).toStringAsFixed(0)}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanChip(String value, String label) {
    final isSelected = _selectedPlan == value;
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => setState(() => _selectedPlan = value),
        selectedColor: colorScheme.primary,
        labelStyle: TextStyle(
          color: isSelected ? colorScheme.onPrimary : null,
        ),
        showCheckmark: false,
      ),
    );
  }

  Future<void> _handleSubscribe() async {
    // Show address dialog
    final address = await _showAddressDialog();
    if (address == null || address.isEmpty) return;

    setState(() => _isProcessing = true);

    try {
      // Get selected product
      final product = _products.firstWhere((p) => p['id'] == _selectedProductId);
      
      // Initiate UPI payment
      final paymentSuccess = await UpiPaymentService.initiatePayment(
        context: context,
        amount: _totalPrice,
        description: '${product['name']} - $_planLabel subscription',
      );

      if (paymentSuccess && mounted) {
        // Save subscription to Supabase
        await _saveSubscription(product, address);
        
        // Navigate to success screen
        if (mounted) {
          context.go('/order-success', extra: {
            'product': product['name'],
            'plan': _planLabel,
            'quantity': _quantity,
            'price': _totalPrice,
            'address': address,
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<String?> _showAddressDialog() async {
    final controller = TextEditingController();
    
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delivery Address'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your complete delivery address:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'House No., Street, Landmark, City, PIN',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(context, controller.text.trim());
              }
            },
            child: const Text('Proceed to Pay'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveSubscription(Map<String, dynamic> product, String address) async {
    final user = SupabaseService.currentUser;
    if (user == null) return;

    // Update user's address
    await SupabaseService.client.from('profiles').upsert({
      'id': user.id,
      'address': address,
    });

    // Create subscription
    final startDate = DateTime.now();
    final endDate = _selectedPlan == 'weekly'
        ? startDate.add(const Duration(days: 7))
        : startDate.add(const Duration(days: 30));

    await SupabaseService.client.from('subscriptions').insert({
      'user_id': user.id,
      'product_id': product['id'],
      'plan_type': _selectedPlan,
      'quantity': _quantity,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'status': 'active',
      'total_amount': _totalPrice,
    });
  }
}
