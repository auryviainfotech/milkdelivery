import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milk_core/milk_core.dart';
import '../../../shared/providers/auth_providers.dart';
import 'package:intl/intl.dart';

/// Provider for subscription detail with pause status
final subscriptionWithPauseProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, id) async {
  final response = await SupabaseService.client
      .from('subscriptions')
      .select('*, products(name, emoji)')
      .eq('id', id)
      .maybeSingle();
  return response;
});

/// Subscription detail screen for managing a specific subscription
class SubscriptionDetailScreen extends ConsumerStatefulWidget {
  final String subscriptionId;

  const SubscriptionDetailScreen({super.key, required this.subscriptionId});

  @override
  ConsumerState<SubscriptionDetailScreen> createState() => _SubscriptionDetailScreenState();
}

class _SubscriptionDetailScreenState extends ConsumerState<SubscriptionDetailScreen> {
  bool _isUpdating = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final subAsync = ref.watch(subscriptionWithPauseProvider(widget.subscriptionId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription Details'),
      ),
      body: subAsync.when(
        data: (sub) {
          if (sub == null) return const Center(child: Text('Subscription not found'));

          final isPaused = sub['is_paused'] as bool? ?? false;
          final productName = sub['products']?['name'] ?? 'Milk';
          final productEmoji = sub['products']?['emoji'] ?? '🥛';
          final quantity = sub['quantity'] ?? 1;
          final startDate = DateTime.tryParse(sub['start_date'] ?? '') ?? DateTime.now();
          final endDate = DateTime.tryParse(sub['end_date'] ?? '') ?? DateTime.now();
          final planType = sub['plan_type'] ?? 'daily';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Banner
                if (isPaused)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.pause_circle, color: Colors.orange),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Subscription is PAUSED - No deliveries until resumed',
                            style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(productEmoji, style: const TextStyle(fontSize: 32)),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    productName,
                                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isPaused ? Colors.orange : AppTheme.successColor,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      isPaused ? 'PAUSED' : 'ACTIVE',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 32),
                        _buildDetailRow('Quantity', '$quantity units daily', theme),
                        _buildDetailRow('Plan Type', planType.toUpperCase(), theme),
                        _buildDetailRow('Start Date', DateFormat('MMM d, yyyy').format(startDate), theme),
                        _buildDetailRow('End Date', DateFormat('MMM d, yyyy').format(endDate), theme),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Pause/Resume Button
                SizedBox(
                  width: double.infinity,
                  child: _isUpdating
                      ? const Center(child: CircularProgressIndicator())
                      : isPaused
                          ? FilledButton.icon(
                              onPressed: () => _togglePause(false),
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('Resume Subscription'),
                              style: FilledButton.styleFrom(backgroundColor: AppTheme.successColor),
                            )
                          : OutlinedButton.icon(
                              onPressed: () => _togglePause(true),
                              icon: const Icon(Icons.pause),
                              label: const Text('Pause Subscription'),
                              style: OutlinedButton.styleFrom(foregroundColor: Colors.orange),
                            ),
                ),
                const SizedBox(height: 12),
                
                // Cancel Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showCancelConfirmation(),
                    icon: const Icon(Icons.close),
                    label: const Text('Cancel Subscription'),
                    style: OutlinedButton.styleFrom(foregroundColor: AppTheme.errorColor),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, __) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Future<void> _togglePause(bool pause) async {
    setState(() => _isUpdating = true);
    
    try {
      await SupabaseService.client
          .from('subscriptions')
          .update({
            'is_paused': pause,
            'paused_at': pause ? DateTime.now().toIso8601String() : null,
          })
          .eq('id', widget.subscriptionId);
      
      ref.invalidate(subscriptionWithPauseProvider(widget.subscriptionId));
      ref.invalidate(userSubscriptionsProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(pause ? 'Subscription paused' : 'Subscription resumed'),
            backgroundColor: pause ? Colors.orange : AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorColor),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  void _showCancelConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Subscription?'),
        content: const Text('This will permanently cancel your subscription. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep Subscription'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await _cancelSubscription();
            },
            style: FilledButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelSubscription() async {
    setState(() => _isUpdating = true);
    
    try {
      await SupabaseService.client
          .from('subscriptions')
          .update({'status': 'cancelled'})
          .eq('id', widget.subscriptionId);
      
      ref.invalidate(userSubscriptionsProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subscription cancelled'), backgroundColor: AppTheme.errorColor),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorColor),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Widget _buildDetailRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          Text(value, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
