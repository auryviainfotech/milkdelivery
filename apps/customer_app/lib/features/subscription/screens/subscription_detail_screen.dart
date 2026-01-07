import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milk_core/milk_core.dart';
import '../../../shared/providers/auth_providers.dart';
import 'package:intl/intl.dart';

/// Subscription detail screen for managing a specific subscription
class SubscriptionDetailScreen extends ConsumerWidget {
  final String subscriptionId;

  const SubscriptionDetailScreen({super.key, required this.subscriptionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final subAsync = ref.watch(subscriptionDetailProvider(subscriptionId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription Details'),
      ),
      body: subAsync.when(
        data: (sub) {
          if (sub == null) return const Center(child: Text('Subscription not found'));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                              child: const Text('🥛', style: TextStyle(fontSize: 32)),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Daily Milk',
                                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'Active Subscription',
                                    style: TextStyle(color: AppTheme.successColor, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 32),
                        _buildDetailRow('Quantity', '${sub.quantity} units daily', theme),
                        _buildDetailRow('Start Date', DateFormat('MMM d, yyyy').format(sub.startDate), theme),
                        _buildDetailRow('End Date', DateFormat('MMM d, yyyy').format(sub.endDate), theme),
                        _buildDetailRow('Frequency', 'Daily', theme),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Pause functionality coming soon!')),
                      );
                    },
                    icon: const Icon(Icons.pause),
                    label: const Text('Pause Subscription'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Cancel functionality coming soon!')),
                      );
                    },
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
