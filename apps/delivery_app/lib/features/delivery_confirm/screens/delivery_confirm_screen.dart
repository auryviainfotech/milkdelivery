import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:milk_core/milk_core.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../dashboard/screens/delivery_dashboard_screen.dart';

/// Provider to fetch delivery details using Delivery ID
final deliveryDetailProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, deliveryId) async {
  try {
    // Fetch delivery with order, customer profile, and subscription details
    final response = await SupabaseService.client
        .from('deliveries')
        .select('''
          *,
          orders (
            id,
            user_id,
            subscription_id,
            status,
            total_amount,
            payment_method,
            order_type,
            subscriptions (
              delivery_slot,
              quantity,
              products (name, unit, image_url)
            ),
            profiles (full_name, phone, address)
          )
        ''')
        .eq('id', deliveryId)
        .maybeSingle();
    
    return response;
  } catch (e, stack) {
    return null;
  }
});

/// Delivery confirmation screen
class DeliveryConfirmScreen extends ConsumerWidget {
  final String orderId;

  const DeliveryConfirmScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final deliveryAsync = ref.watch(deliveryDetailProvider(orderId));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Confirm Delivery'),
      ),
      body: deliveryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (delivery) {
          if (delivery == null) {
            return const Center(child: Text('Delivery not found'));
          }
          
          final order = delivery['orders'] as Map<String, dynamic>?;
          final customer = order?['profiles'] as Map<String, dynamic>?;
          final customerName = customer?['full_name'] ?? 'Customer';
          final address = customer?['address'] ?? 'Address not available';
          final phone = customer?['phone'] ?? '';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Customer details card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: colorScheme.primaryContainer,
                              radius: 24,
                              child: Text(
                                customerName.isNotEmpty ? customerName[0].toUpperCase() : 'C',
                                style: TextStyle(
                                  color: colorScheme.onPrimaryContainer,
                                  fontSize: 20,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    customerName,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    address,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),
                        Text(
                          'Delivery Details',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        // Product Info
                        _buildProductInfo(colorScheme, order),
                        
                        const SizedBox(height: 8),
                        Text(
                          'Scheduled: ${delivery['scheduled_date'] ?? 'Today'}',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Scan instruction
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorScheme.primary.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.qr_code_scanner,
                        size: 64,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Scan QR to Confirm',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ask the customer to show their QR code to confirm delivery',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: () => context.push('/scan/$orderId'),
                        icon: const Icon(Icons.qr_code_scanner),
                        label: const Text('Open Scanner'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _showIssueDialog(context, delivery),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colorScheme.error,
                        ),
                        child: const Text('Report Issue'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: () {
                      _showManualConfirmDialog(context, delivery, ref);
                    },
                    child: const Text('Deliver without QR scan'),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showIssueDialog(BuildContext context, Map<String, dynamic> delivery) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Report Issue',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildIssueOption(context, 'Customer not available', delivery),
              _buildIssueOption(context, 'Wrong address', delivery),
              _buildIssueOption(context, 'Customer refused delivery', delivery),
              _buildIssueOption(context, 'Product damaged', delivery),
              const SizedBox(height: 16),
              TextFormField(
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Additional notes (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  // Update order status to failed (issue is not valid for orders table)
                  try {
                    await SupabaseService.client
                        .from('orders')
                        .update({'status': 'failed'})
                        .eq('id', delivery['order_id']);
                    
                    // Update deliveries table with issue status
                    await SupabaseService.client
                        .from('deliveries')
                        .update({'status': 'issue'})
                        .eq('id', delivery['id']);
                  } catch (e) {
                    // Error handled silently
                  }
                  
                  if (context.mounted) {
                    Navigator.pop(context);
                    context.pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Issue reported successfully'),
                        backgroundColor: AppTheme.warningColor,
                      ),
                    );
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                ),
                child: const Text('Submit Issue'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIssueOption(BuildContext context, String text, Map<String, dynamic> delivery) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(text),
        trailing: const Icon(Icons.chevron_right),
        onTap: () async {
          // Report this specific issue
          try {
            await SupabaseService.client
                .from('orders')
                .update({'status': 'failed'})
                .eq('id', delivery['order_id']);
            
            await SupabaseService.client
                .from('deliveries')
                .update({
                  'status': 'issue',
                  'issue_notes': text,
                })
                .eq('id', delivery['id']);
            
            if (context.mounted) {
              Navigator.pop(context);
              context.pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Issue reported: $text'),
                  backgroundColor: AppTheme.warningColor,
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _showManualConfirmDialog(BuildContext context, Map<String, dynamic> delivery, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Manual Confirmation'),
        content: const Text(
          'Are you sure you want to mark this delivery as complete without QR scan? This should only be done if the customer cannot show their QR code.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              // Update order status to delivered
              try {
                // Update orders table (only status - no delivered_at column here)
                await SupabaseService.client
                    .from('orders')
                    .update({'status': 'delivered'})
                    .eq('id', delivery['order_id']);
                
                // Update deliveries table (has delivered_at column)
                await SupabaseService.client
                    .from('deliveries')
                    .update({
                      'status': 'delivered',
                      'delivered_at': DateTime.now().toIso8601String(),
                    })
                    .eq('id', delivery['id']);
                
                // Invalidate providers to refresh dashboard data
                final String orderId = delivery['order_id'] as String;
                ref.invalidate(todayDeliveriesProvider);
                ref.invalidate(deliveryDetailProvider(orderId));
                
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
                
                if (context.mounted) {
                  context.go('/dashboard');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✓ Delivery marked as complete!'),
                      backgroundColor: AppTheme.successColor,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Widget _buildProductInfo(ColorScheme colorScheme, Map<String, dynamic>? order) {
    if (order == null) return const SizedBox.shrink();
    
    final subscription = order['subscriptions'] as Map<String, dynamic>?;
    final product = subscription?['products'] as Map<String, dynamic>?;
    
    final productName = product?['name'] ?? 'Milk';
    final unit = product?['unit'] ?? 'L';
    final quantity = subscription?['quantity'] ?? 1;
    final deliverySlot = subscription?['delivery_slot'] ?? 'morning';
    
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.secondaryContainer.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.inventory_2_outlined, color: colorScheme.secondary, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$quantity $unit $productName',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              Text(
                '${deliverySlot[0].toUpperCase()}${deliverySlot.substring(1)} Delivery',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
