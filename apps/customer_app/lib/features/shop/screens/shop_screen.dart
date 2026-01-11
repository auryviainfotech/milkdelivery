import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:milk_core/milk_core.dart';
import '../../../services/razorpay_service.dart';
import '../../../shared/providers/auth_providers.dart';

/// Shop screen for one-time purchases (Butter, Ghee, Paneer, etc.)
/// These products are NOT part of the subscription wallet system
/// Payment is via UPI/Card/Net Banking through Razorpay
class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  final Map<String, int> _cart = {};
  bool _isProcessing = false;

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
    RazorpayService.dispose();
    super.dispose();
  }

  double get _cartTotal {
    double total = 0;
    final products = ref.read(oneTimeProductsProvider).valueOrNull ?? [];
    for (final entry in _cart.entries) {
      final product = products.where((p) => p.id == entry.key).firstOrNull;
      if (product != null) {
        total += product.price * entry.value;
      }
    }
    return total;
  }

  int get _cartItemCount => _cart.values.fold(0, (a, b) => a + b);

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    // Create one-time order
    final user = SupabaseService.currentUser;
    if (user == null) return;

    try {
      // Create the order
      final orderResponse = await SupabaseService.client.from('orders').insert({
        'user_id': user.id,
        'delivery_date': DateTime.now().add(const Duration(days: 1)).toIso8601String().split('T')[0],
        'status': 'pending',
        'order_type': 'one_time',
      }).select().single();

      final orderId = orderResponse['id'] as String;

      // Add order items
      final products = ref.read(oneTimeProductsProvider).valueOrNull ?? [];
      for (final entry in _cart.entries) {
        final product = products.where((p) => p.id == entry.key).firstOrNull;
        if (product != null) {
          await SupabaseService.client.from('order_items').insert({
            'order_id': orderId,
            'product_id': entry.key,
            'quantity': entry.value,
            'price': product.price,
          });
        }
      }

      if (mounted) {
        setState(() {
          _isProcessing = false;
          _cart.clear();
        });
        _showSuccessDialog(response.paymentId ?? 'N/A');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating order: $e')),
        );
      }
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (mounted) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: ${response.message ?? "Unknown error"}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSuccessDialog(String paymentId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 64),
        title: const Text('Order Placed!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Your order will be delivered tomorrow morning.'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('Payment ID: $paymentId', style: const TextStyle(fontSize: 12)),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/orders');
            },
            child: const Text('View Orders'),
          ),
        ],
      ),
    );
  }

  void _checkout() async {
    if (_cartTotal <= 0) return;

    setState(() => _isProcessing = true);

    try {
      final user = SupabaseService.currentUser;
      final profile = await SupabaseService.client
          .from('profiles')
          .select('full_name, phone')
          .eq('id', user?.id ?? '')
          .maybeSingle();

      RazorpayService.openCheckout(
        amount: _cartTotal,
        orderId: 'SHOP${DateTime.now().millisecondsSinceEpoch}',
        description: 'One-time Purchase',
        email: user?.email ?? 'customer@milkdelivery.com',
        phone: profile?['phone']?.toString().replaceAll('+91', '') ?? '',
        name: profile?['full_name'] ?? '',
      );
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final productsAsync = ref.watch(oneTimeProductsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop'),
        actions: [
          if (_cartItemCount > 0)
            Badge(
              label: Text('$_cartItemCount'),
              child: IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () => _showCartSheet(),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.shopping_cart_outlined),
              onPressed: () {},
            ),
        ],
      ),
      body: productsAsync.when(
        data: (products) {
          if (products.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.store_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No products available', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.62,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              final productId = product.id;
              final quantity = _cart[productId] ?? 0;

              return Card(
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Text(
                          product.emoji,
                          style: const TextStyle(fontSize: 32),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.name,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        product.unit,
                        style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant),
                      ),
                      const Spacer(),
                      // Price and Add button row
                      Row(
                        children: [
                          Text(
                            '₹${product.price.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                              fontSize: 14,
                            ),
                          ),
                          const Spacer(),
                          if (quantity == 0)
                            GestureDetector(
                              onTap: () => setState(() => _cart[productId] = 1),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Add',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                            )
                          else
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      if (quantity > 1) {
                                        _cart[productId] = quantity - 1;
                                      } else {
                                        _cart.remove(productId);
                                      }
                                    });
                                  },
                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: colorScheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Icon(Icons.remove, size: 14, color: colorScheme.onPrimaryContainer),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 6),
                                  child: Text('$quantity', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                                GestureDetector(
                                  onTap: () => setState(() => _cart[productId] = quantity + 1),
                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: colorScheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Icon(Icons.add, size: 14, color: colorScheme.onPrimaryContainer),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      bottomNavigationBar: _cartTotal > 0
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isProcessing ? null : _checkout,
                    icon: _isProcessing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.payment),
                    label: Text(
                      _isProcessing
                          ? 'Processing...'
                          : 'Pay ₹${_cartTotal.toStringAsFixed(0)}',
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  void _showCartSheet() {
    final products = ref.read(oneTimeProductsProvider).valueOrNull ?? [];
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Cart',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ..._cart.entries.map((entry) {
                final product = products.where((p) => p.id == entry.key).firstOrNull;
                if (product == null) return const SizedBox.shrink();
                return ListTile(
                  leading: Text(product.emoji, style: const TextStyle(fontSize: 24)),
                  title: Text(product.name),
                  subtitle: Text('₹${product.price.toStringAsFixed(0)} x ${entry.value}'),
                  trailing: Text(
                    '₹${(product.price * entry.value).toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                );
              }),
              const Divider(),
              ListTile(
                title: const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
                trailing: Text(
                  '₹${_cartTotal.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
