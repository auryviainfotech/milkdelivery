import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:milk_core/milk_core.dart';
import 'package:intl/intl.dart';
import '../../../shared/config/app_config.dart';

/// Provider for subscriptions with customer info
final subscriptionsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final response = await SupabaseService.client
      .from('subscriptions')
      .select('*, profiles!subscriptions_user_id_fkey(full_name, phone, address)')
      .order('created_at', ascending: false);
  return List<Map<String, dynamic>>.from(response);
});

/// Subscriptions Management Screen with Real Data
class SubscriptionsScreen extends ConsumerStatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  ConsumerState<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends ConsumerState<SubscriptionsScreen> {
  String _statusFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final subscriptionsAsync = ref.watch(subscriptionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscriptions'),
        actions: [
          // Refresh button
          IconButton(
            onPressed: () => ref.invalidate(subscriptionsProvider),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Generate button
            Wrap(
              spacing: 16,
              runSpacing: 12,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Cutoff indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.warningColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.warningColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.access_time, size: 16, color: AppTheme.warningColor),
                      const SizedBox(width: 8),
                      Text(
                        'Cutoff: ${AppConfig.orderCutoffDisplay}',
                        style: const TextStyle(color: AppTheme.warningColor, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                // GENERATE BUTTON
                FilledButton.icon(
                  onPressed: _generateTomorrowOrders,
                  icon: const Icon(Icons.schedule),
                  label: const Text('Generate Tomorrow\'s Orders'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Filter chips
            Wrap(
              spacing: 8,
              children: [
                _buildFilterChip('All', 'all'),
                _buildFilterChip('Pending', 'pending'),
                _buildFilterChip('Active', 'active'),
                _buildFilterChip('Paused', 'paused'),
                _buildFilterChip('Expired', 'expired'),
              ],
            ),
            const SizedBox(height: 16),

            // Subscriptions list
            subscriptionsAsync.when(
              data: (subscriptions) {
                // Filter logic - check is_paused for paused status
                final filtered = _statusFilter == 'all'
                    ? subscriptions
                    : _statusFilter == 'paused'
                        ? subscriptions.where((s) => s['is_paused'] == true).toList()
                        : subscriptions.where((s) => s['status'] == _statusFilter && s['is_paused'] != true).toList();
                
                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(48),
                      child: Column(
                        children: [
                          Icon(Icons.inbox_outlined, size: 64, color: colorScheme.onSurfaceVariant),
                          const SizedBox(height: 16),
                          Text(
                            'No subscriptions found',
                            style: TextStyle(color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                
                return Column(
                  children: filtered.map((sub) {
                    final profile = sub['profiles'] as Map<String, dynamic>?;
                    final customerName = profile?['full_name'] ?? 'Unknown Customer';
                    final startDate = sub['start_date'] != null 
                        ? DateFormat('dd MMM yyyy').format(DateTime.parse(sub['start_date']))
                        : '-';
                    final endDate = sub['end_date'] != null 
                        ? DateFormat('dd MMM yyyy').format(DateTime.parse(sub['end_date']))
                        : '-';
                    final isPaused = sub['is_paused'] == true;
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isPaused ? Colors.orange.shade100 : colorScheme.primaryContainer,
                          child: isPaused 
                              ? const Icon(Icons.pause, color: Colors.orange)
                              : Text(customerName[0].toUpperCase()),
                        ),
                        title: Row(
                          children: [
                            Text(customerName, style: const TextStyle(fontWeight: FontWeight.w600)),
                            if (sub['special_request'] != null) ...[
                              const SizedBox(width: 8),
                              const Icon(Icons.priority_high, size: 16, color: Colors.orange),
                            ],
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${_getProductName(sub['product_id'])} • ${sub['plan_type'] ?? 'daily'} • Qty: ${sub['quantity'] ?? 1}'),
                            Text('$startDate to $endDate', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildStatusChip(isPaused ? 'paused' : (sub['status'] ?? 'active')),
                          ],
                        ),
                        onTap: () => _viewDetails(sub, profile),
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: Padding(padding: EdgeInsets.all(48), child: CircularProgressIndicator())),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ],
        ),
      ),
    );
  }

  String _getProductName(String? productId) {
    final products = {
      '1': 'Full Cream Milk - 500ml',
      '2': 'Toned Milk - 500ml',
      '3': 'Double Toned Milk - 500ml',
      '4': 'Buffalo Milk - 500ml',
    };
    return products[productId] ?? 'Unknown Product';
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _statusFilter == value;
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _statusFilter = value);
      },
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'pending':
        color = Colors.orange;
        break;
      case 'active':
        color = AppTheme.successColor;
        break;
      case 'paused':
        color = AppTheme.warningColor;
        break;
      case 'expired':
      case 'cancelled':
        color = AppTheme.errorColor;
        break;
      default:
        color = Colors.grey;
    }

    return Chip(
      label: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide.none,
      padding: EdgeInsets.zero,
    );
  }



  void _viewDetails(Map<String, dynamic> sub, Map<String, dynamic>? profile) {
    final isPending = sub['status'] == 'pending';
    final litersController = TextEditingController(text: '${sub['monthly_liters'] ?? 30}');
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(profile?['full_name'] ?? 'Subscription Details'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(Icons.phone, 'Phone', profile?['phone'] ?? '-'),
                _buildInfoRow(Icons.location_on, 'Address', sub['delivery_address'] ?? profile?['address'] ?? '-'),
                _buildInfoRow(Icons.shopping_bag, 'Product', _getProductName(sub['product_id'])),
                _buildInfoRow(Icons.water_drop, 'Monthly Liters', '${sub['monthly_liters'] ?? 30} L'),
                _buildInfoRow(Icons.numbers, 'Quantity/Delivery', '${sub['quantity'] ?? 1}'),
                _buildInfoRow(Icons.weekend, 'Skip Weekends', sub['skip_weekends'] == true ? 'Yes' : 'No'),
                if (sub['special_request'] != null)
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(children: [
                          Icon(Icons.priority_high, size: 16, color: Colors.orange),
                          SizedBox(width: 8),
                          Text('Special Request', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                        ]),
                        const SizedBox(height: 4),
                        Text(sub['special_request'] ?? '', style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                // Activation Section for Pending subscriptions
                if (isPending) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green.shade700),
                            const SizedBox(width: 8),
                            Text('Activate Subscription', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade700)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: litersController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Initial Liters to Add',
                            hintText: 'Enter liters after payment collection',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            prefixIcon: const Icon(Icons.water_drop),
                            suffixText: 'Liters',
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () => _activateSubscription(dialogContext, sub['id'], sub['user_id'], litersController.text),
                            icon: const Icon(Icons.check),
                            label: const Text('Activate & Add Liters'),
                            style: FilledButton.styleFrom(backgroundColor: Colors.green),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _activateSubscription(BuildContext dialogContext, String subscriptionId, String userId, String litersText) async {
    final liters = double.tryParse(litersText) ?? 0;
    if (liters <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid liters amount')),
      );
      return;
    }
    
    try {
      // Update subscription status to active
      await SupabaseService.client
          .from('subscriptions')
          .update({'status': 'active'})
          .eq('id', subscriptionId);
      
      // Add liters to customer profile
      await SupabaseService.client
          .from('profiles')
          .update({
            'liters_remaining': liters,
            'subscription_status': 'active',
          })
          .eq('id', userId);
      
      // Close dialog first
      if (dialogContext.mounted) {
        Navigator.pop(dialogContext);
      }
      
      // Then show snackbar and refresh using parent context
      if (mounted) {
        ref.invalidate(subscriptionsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Subscription activated! Added $liters liters to customer.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  void _generateTomorrowOrders() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _GenerateOrdersDialog(
        onComplete: () => ref.invalidate(subscriptionsProvider),
      ),
    );
  }
}

/// Dialog for generating orders with progress
class _GenerateOrdersDialog extends StatefulWidget {
  final VoidCallback onComplete;
  
  const _GenerateOrdersDialog({required this.onComplete});

  @override
  State<_GenerateOrdersDialog> createState() => _GenerateOrdersDialogState();
}

class _GenerateOrdersDialogState extends State<_GenerateOrdersDialog> {
  bool _isProcessing = false;
  Map<String, int>? _result;
  String? _error;
  bool _generateForToday = false; // Default to Tomorrow to avoid accidental double-billing in production

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_result != null ? 'Orders Generated!' : 'Generate Orders'),
      content: _buildContent(),
      actions: _buildActions(),
    );
  }

  Widget _buildContent() {
    if (_isProcessing) {
      return const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Processing subscriptions...'),
        ],
      );
    }

    if (_error != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: AppTheme.errorColor, size: 48),
          const SizedBox(height: 16),
          Text('Error: $_error'),
        ],
      );
    }

    if (_result != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, color: AppTheme.successColor, size: 48),
          const SizedBox(height: 16),
          _buildResultRow(Icons.shopping_cart, 'Orders Created', _result!['orders_created'] ?? 0),
          _buildResultRow(Icons.local_shipping, 'Deliveries Assigned', _result!['deliveries_assigned'] ?? 0),
          if ((_result!['unassigned'] ?? 0) > 0)
            _buildResultRow(Icons.warning_amber, 'Unassigned (no matching delivery person)', _result!['unassigned'] ?? 0, isWarning: true),
          if ((_result!['failed'] ?? 0) > 0)
            _buildResultRow(Icons.error_outline, 'Skipped (Likely deleted products)', _result!['failed'] ?? 0, isWarning: true),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'This will create delivery orders for all active subscriptions.\n'
          'Existing orders for the selected date will be skipped.',
        ),
        const SizedBox(height: 16),
        const Text('Target Date:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: RadioListTile<bool>(
                title: const Text('Tomorrow'),
                subtitle: Text(DateFormat('MMM dd').format(DateTime.now().add(const Duration(days: 1)))),
                value: false,
                groupValue: _generateForToday,
                onChanged: (v) => setState(() => _generateForToday = v!),
              ),
            ),
            Expanded(
              child: RadioListTile<bool>(
                title: const Text('Today'),
                subtitle: Text(DateFormat('MMM dd').format(DateTime.now())),
                value: true,
                groupValue: _generateForToday,
                onChanged: (v) => setState(() => _generateForToday = v!),
              ),
            ),
          ],
        ),
        if (_generateForToday)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_amber, size: 16, color: Colors.orange),
                SizedBox(width: 8),
                Expanded(child: Text('Only use "Today" for testing or if cron job failed.', style: TextStyle(fontSize: 12, color: Colors.orange))),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildResultRow(IconData icon, String label, int count, {bool isWarning = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: isWarning ? AppTheme.warningColor : AppTheme.successColor),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
          Text('$count', style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  List<Widget> _buildActions() {
    if (_result != null || _error != null) {
      return [
        FilledButton(
          onPressed: () {
            widget.onComplete();
            Navigator.pop(context);
          },
          child: const Text('Close'),
        ),
      ];
    }

    return [
      TextButton(
        onPressed: _isProcessing ? null : () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: _isProcessing ? null : _generate,
        child: Text(_generateForToday ? 'Generate for TODAY' : 'Generate for TOMORROW'),
      ),
    ];
  }

  Future<void> _generate() async {
    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      final targetDate = _generateForToday ? DateTime.now() : DateTime.now().add(const Duration(days: 1));
      final result = await OrderGenerationService.generateOrdersForDate(targetDate);
      
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _result = result;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _error = e.toString();
        });
      }
    }
  }
}
