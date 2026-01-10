import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:milk_core/milk_core.dart';
import 'package:intl/intl.dart';

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
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.access_time, size: 16, color: AppTheme.warningColor),
                      SizedBox(width: 8),
                      Text(
                        'Cutoff: 10:00 PM',
                        style: TextStyle(color: AppTheme.warningColor, fontWeight: FontWeight.w500),
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
                        title: Text(customerName, style: const TextStyle(fontWeight: FontWeight.w600)),
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
                            const SizedBox(width: 8),
                            Text('₹${(sub['total_amount'] ?? 0).toStringAsFixed(0)}', 
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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

  void _pauseSubscription(Map<String, dynamic> sub) async {
    await SupabaseService.client
        .from('subscriptions')
        .update({'status': 'paused'})
        .eq('id', sub['id']);
    ref.invalidate(subscriptionsProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subscription paused')),
      );
    }
  }

  void _resumeSubscription(Map<String, dynamic> sub) async {
    await SupabaseService.client
        .from('subscriptions')
        .update({'status': 'active'})
        .eq('id', sub['id']);
    ref.invalidate(subscriptionsProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subscription resumed')),
      );
    }
  }

  void _viewDetails(Map<String, dynamic> sub, Map<String, dynamic>? profile) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(profile?['full_name'] ?? 'Subscription Details'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow(Icons.phone, 'Phone', profile?['phone'] ?? '-'),
              _buildInfoRow(Icons.location_on, 'Address', profile?['address'] ?? '-'),
              _buildInfoRow(Icons.shopping_bag, 'Product', _getProductName(sub['product_id'])),
              _buildInfoRow(Icons.repeat, 'Plan', sub['plan_type'] ?? '-'),
              _buildInfoRow(Icons.numbers, 'Quantity', '${sub['quantity'] ?? 1}'),
              _buildInfoRow(Icons.currency_rupee, 'Amount', '₹${sub['total_amount'] ?? 0}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_result != null ? 'Orders Generated!' : 'Generate Tomorrow\'s Orders'),
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
        ],
      );
    }

    return const Text(
      'This will create delivery orders for all active subscriptions for tomorrow.\n\n'
      'Orders will be automatically assigned to delivery persons based on PIN code matching.',
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
        child: const Text('Generate'),
      ),
    ];
  }

  Future<void> _generate() async {
    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final result = await OrderGenerationService.generateOrdersForDate(tomorrow);
      
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
