import 'package:flutter/material.dart';
import 'package:milk_core/milk_core.dart';
import 'package:url_launcher/url_launcher.dart';

/// A card widget specifically for Shop Orders (one-time purchases)
/// Displays product list, customer info, and simple "Mark Delivered" action
class ShopOrderCard extends StatelessWidget {
  final Map<String, dynamic> delivery;
  final VoidCallback onMarkDelivered;
  final VoidCallback? onReportIssue;
  final VoidCallback? onNavigate;

  const ShopOrderCard({
    super.key,
    required this.delivery,
    required this.onMarkDelivered,
    this.onReportIssue,
    this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final status = delivery['status'] ?? 'pending';
    final isDelivered = status == 'delivered';

    // Parse nested order data
    final order = delivery['orders'] as Map<String, dynamic>?;
    final profile = order?['profiles'] as Map<String, dynamic>?;
    final orderItems = order?['order_items'] as List<dynamic>? ?? [];

    // Extract values
    final customerName = profile?['full_name'] ?? 'Customer';
    final address = profile?['address'] ?? 'No address';
    final phone = profile?['phone'] ?? '';
    final totalAmount = order?['total_amount'] ?? 0;
    final paymentMethod = order?['payment_method'] ?? 'cod';

    final isDark = theme.brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isDelivered ? 0 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isDelivered
            ? BorderSide(color: AppTheme.successColor.withOpacity(0.3), width: 1)
            : BorderSide(
                color: isDark ? Colors.orange.shade700 : Colors.transparent,
                width: isDark ? 1 : 0,
              ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: isDelivered
              ? null
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          Colors.orange.withOpacity(0.15),
                          Colors.orange.withOpacity(0.05),
                        ]
                      : [
                          Colors.orange.shade50,
                          Colors.orange.shade100.withOpacity(0.3),
                        ],
                ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Shop Order Badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.orange.shade700 : Colors.orange.shade700,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shopping_bag, size: 14, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'SHOP ORDER',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (isDelivered)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.successColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 14, color: AppTheme.successColor),
                        const SizedBox(width: 4),
                        Text(
                          'DELIVERED',
                          style: TextStyle(
                            color: AppTheme.successColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Customer Info
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: isDark ? Colors.orange.shade900 : Colors.orange.shade100,
                  child: Text(
                    customerName.isNotEmpty ? customerName[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: isDark ? Colors.orange.shade100 : Colors.orange.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customerName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          decoration: isDelivered ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 12, color: colorScheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              address,
                              style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (phone.isNotEmpty && !isDelivered)
                  IconButton.filledTonal(
                    onPressed: () => _makeCall(phone),
                    icon: const Icon(Icons.phone, size: 18),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.green.withOpacity(0.2),
                      foregroundColor: Colors.green,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Products List
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surface.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Items Ordered',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...orderItems.map((item) {
                    final product = item['products'] as Map<String, dynamic>?;
                    final productName = product?['name'] ?? 'Product';
                    final emoji = product?['emoji'] ?? '📦';
                    final qty = item['quantity'] ?? 1;
                    final price = item['price'] ?? 0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Text(emoji, style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              productName,
                              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                            ),
                          ),
                          Text(
                            'x$qty',
                            style: TextStyle(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '₹${(price * qty).toStringAsFixed(0)}',
                            style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    );
                  }),
                  const Divider(height: 16),
                  // Total
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        paymentMethod == 'cod' ? 'Collect Cash:' : 'Total:',
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: paymentMethod == 'cod'
                              ? Colors.green.withOpacity(0.2)
                              : colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '₹${totalAmount.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: paymentMethod == 'cod'
                                ? Colors.green
                                : colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Action Buttons
            if (!isDelivered)
              Row(
                children: [
                  if (onNavigate != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onNavigate,
                        icon: const Icon(Icons.navigation, size: 18),
                        label: const Text('Nav'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colorScheme.primary,
                          side: BorderSide(color: colorScheme.primary.withOpacity(0.5)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  if (onNavigate != null) const SizedBox(width: 8),
                  if (onReportIssue != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onReportIssue,
                        icon: const Icon(Icons.warning_amber, size: 18),
                        label: const Text('Issue'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.warningColor,
                          side: BorderSide(color: AppTheme.warningColor.withOpacity(0.5)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  if (onReportIssue != null) const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: onMarkDelivered,
                      icon: const Icon(Icons.check_circle, size: 20),
                      label: const Text('Delivered'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: AppTheme.successColor,
                      ),
                    ),
                  ),
                ],
              ),

          ],
        ),
      ),
    );
  }

  void _makeCall(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
