import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:milk_core/milk_core.dart';
import '../../../shared/providers/auth_providers.dart';

/// Shop screen for one-time purchases (Butter, Ghee, Paneer, etc.)
/// These products are NOT part of the subscription system
/// Payment is Cash on Delivery (COD) only
class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  final Map<String, int> _cart = {};
  bool _isProcessing = false;

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

  void _placeOrder() async {
    if (_cartTotal <= 0) return;

    setState(() => _isProcessing = true);

    try {
      final user = SupabaseService.currentUser;
      if (user == null) throw Exception('Not logged in');

      // Get user profile (select all to avoid column-not-exists errors)
      final profile = await SupabaseService.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      final address = profile?['address'] as String? ?? '';
      if (address.isEmpty) {
        if (mounted) {
          setState(() => _isProcessing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please update your address in profile first')),
          );
        }
        return;
      }

      // Create the order with COD payment method
      final deliveryDateStr = DateTime.now().toIso8601String().split('T')[0];
      debugPrint('🛒 [SHOP] Calculated Delivery Date: $deliveryDateStr (Local: ${DateTime.now()})');

      final orderResponse = await SupabaseService.client.from('orders').insert({
        'user_id': user.id,
        'delivery_date': deliveryDateStr,  // Same day for testing
        'status': 'pending',
        'order_type': 'one_time',
        'payment_method': 'cod',
        'payment_status': 'pending',
        'total_amount': _cartTotal,
        'delivery_address': address,
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

      // Note: Delivery assignment is now done manually by admin via Admin Panel
      // The shop order will appear in Admin Panel > Shop Orders for assignment
      debugPrint('✅ [SHOP] Order created: $orderId. Admin will assign delivery person.');
      
      // Invalidate orders provider so it shows immediately in orders list
      ref.invalidate(ordersProvider);

      if (mounted) {
        setState(() {
          _isProcessing = false;
          _cart.clear();
        });
        _showSuccessDialog();
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

  void _showSuccessDialog() {
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
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.payments_outlined, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Cash on Delivery\nPay when you receive your order',
                      style: TextStyle(fontSize: 12, color: Colors.orange.shade700),
                    ),
                  ),
                ],
              ),
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

          // Separate products into sections
          final milkProducts = products.where((p) => p.category == 'subscription').toList();
          final otherProducts = products.where((p) => p.category != 'subscription').toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (milkProducts.isNotEmpty) ...[
                Text(
                  'Extra Milk (One-Time)',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                _buildProductGrid(milkProducts, colorScheme),
                const SizedBox(height: 24),
              ],
              
              if (otherProducts.isNotEmpty) ...[
                Text(
                  'Groceries & Others',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                 const SizedBox(height: 8),
                _buildProductGrid(otherProducts, colorScheme),
              ],
            ],
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // COD info banner
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.local_shipping, color: Colors.orange.shade700, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Cash on Delivery • Pay when you receive',
                              style: TextStyle(fontSize: 12, color: Colors.orange.shade700),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _isProcessing ? null : _placeOrder,
                        icon: _isProcessing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.shopping_bag),
                        label: Text(
                          _isProcessing
                              ? 'Placing Order...'
                              : 'Place Order • ₹${_cartTotal.toStringAsFixed(0)}',
                        ),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildProductGrid(List<ProductModel> products, ColorScheme colorScheme) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
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
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.payments_outlined, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    Text('Payment: Cash on Delivery', style: TextStyle(color: Colors.orange.shade700, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
