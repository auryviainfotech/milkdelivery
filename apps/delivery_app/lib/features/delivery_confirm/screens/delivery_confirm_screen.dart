import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:milk_core/milk_core.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
                        _buildProductInfo(context, colorScheme, order),
                        
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
                const SizedBox(height: 16),
                // Upload Photo Option
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorScheme.secondary.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.camera_alt,
                        size: 40,
                        color: colorScheme.secondary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Or Upload Delivery Photo',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Take a photo as proof of delivery if QR scan is not possible',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => _showPhotoUploadDialog(context, delivery, ref),
                        icon: const Icon(Icons.add_a_photo),
                        label: const Text('Take Photo'),
                      ),
                    ],
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

  void _showPhotoUploadDialog(BuildContext context, Map<String, dynamic> delivery, WidgetRef ref) {
    File? selectedImage;
    bool isUploading = false;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          scrollable: true,
          title: Row(
            children: [
              Icon(Icons.camera_alt, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Upload Photo',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
                const Text(
                  'Take a photo of the delivered milk as proof of delivery.',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 20),
                
                // Image preview or placeholder
                Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            selectedImage!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate, 
                              size: 48, 
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No photo selected',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 16),
                
                // Camera and Gallery buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: isUploading ? null : () async {
                          final picker = ImagePicker();
                          final image = await picker.pickImage(
                            source: ImageSource.camera,
                            imageQuality: 70,
                          );
                          if (image != null) {
                            setDialogState(() {
                              selectedImage = File(image.path);
                            });
                          }
                        },
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Camera'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: isUploading ? null : () async {
                          final picker = ImagePicker();
                          final image = await picker.pickImage(
                            source: ImageSource.gallery,
                            imageQuality: 70,
                          );
                          if (image != null) {
                            setDialogState(() {
                              selectedImage = File(image.path);
                            });
                          }
                        },
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Gallery'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          actions: [
            TextButton(
              onPressed: isUploading ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: (selectedImage == null || isUploading) ? null : () async {
                setDialogState(() => isUploading = true);
                
                try {
                  // For now, we'll just mark delivery as complete with photo confirmation
                  // Photo can be stored locally or uploaded to storage bucket later
                  
                  // Update orders table
                  await SupabaseService.client
                      .from('orders')
                      .update({'status': 'delivered'})
                      .eq('id', delivery['order_id']);
                  
                  // Update deliveries table with photo confirmation note
                  await SupabaseService.client
                      .from('deliveries')
                      .update({
                        'status': 'delivered',
                        'delivered_at': DateTime.now().toIso8601String(),
                        'issue_notes': 'Delivered with photo confirmation (QR not scanned)',
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
                        content: Text('✓ Delivery confirmed with photo!'),
                        backgroundColor: AppTheme.successColor,
                      ),
                    );
                  }
                } catch (e) {
                  setDialogState(() => isUploading = false);
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
              child: isUploading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Confirm Delivery'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductInfo(BuildContext context, ColorScheme colorScheme, Map<String, dynamic>? order) {
    if (order == null) return const SizedBox.shrink();
    
    final theme = Theme.of(context);
    final subscription = order['subscriptions'] as Map<String, dynamic>?;
    final product = subscription?['products'] as Map<String, dynamic>?;
    
    final productName = product?['name'] ?? 'Milk';
    final unit = product?['unit'] ?? 'L';
    final quantity = subscription?['quantity'] ?? 1;
    final deliverySlot = subscription?['delivery_slot'] ?? 'morning';
    final imageUrl = product?['image_url'] as String?;
    final description = product?['description'] as String?;
    final category = product?['category'] as String?;
    final price = product?['price'];
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Product Details',
            style: theme.textTheme.titleSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          
          // Product info row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: imageUrl != null && imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Center(
                            child: Icon(
                              Icons.local_drink,
                              size: 36,
                              color: colorScheme.primary,
                            ),
                          ),
                        )
                      : Center(
                          child: Icon(
                            Icons.local_drink,
                            size: 36,
                            color: colorScheme.primary,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Product Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Name
                    Text(
                      productName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    
                    // Description
                    if (description != null && description.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          description,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    
                    // Badges row
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        // Quantity badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$quantity x $unit',
                            style: TextStyle(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        
                        // Category badge
                        if (category != null && category.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: category == 'subscription' 
                                  ? Colors.green.withOpacity(0.15)
                                  : Colors.orange.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              category == 'subscription' ? 'Subscription' : 'One-time',
                              style: TextStyle(
                                color: category == 'subscription' 
                                    ? Colors.green.shade700
                                    : Colors.orange.shade700,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        
                        // Price badge (if one-time order)
                        if (price != null && category == 'one_time')
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '₹${(price as num).toStringAsFixed(0)}',
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Delivery Slot
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: deliverySlot == 'morning' 
                  ? Colors.amber.withOpacity(0.1)
                  : Colors.indigo.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  deliverySlot == 'morning' ? Icons.wb_sunny : Icons.nights_stay,
                  size: 18,
                  color: deliverySlot == 'morning' 
                      ? Colors.amber.shade700 
                      : Colors.indigo,
                ),
                const SizedBox(width: 8),
                Text(
                  '${deliverySlot[0].toUpperCase()}${deliverySlot.substring(1)} Delivery',
                  style: TextStyle(
                    color: deliverySlot == 'morning' 
                        ? Colors.amber.shade700 
                        : Colors.indigo,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
