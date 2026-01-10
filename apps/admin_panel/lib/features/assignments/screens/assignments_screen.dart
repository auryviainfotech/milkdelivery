import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milk_core/milk_core.dart';

/// Provider for customers with active subscriptions only
final customersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  // First get customer IDs with active subscriptions
  final subsResponse = await SupabaseService.client
      .from('subscriptions')
      .select('user_id')
      .eq('status', 'active');
  
  final subscribedUserIds = (subsResponse as List)
      .map((s) => s['user_id'] as String)
      .toSet()
      .toList();
  
  if (subscribedUserIds.isEmpty) {
    return [];
  }
  
  // Then fetch only those customers with their assignment info
  final response = await SupabaseService.client
      .from('profiles')
      .select('*, assigned_delivery_person:assigned_delivery_person_id(id, full_name, phone)')
      .eq('role', 'customer')
      .inFilter('id', subscribedUserIds)
      .order('full_name');
  return List<Map<String, dynamic>>.from(response);
});

/// Provider for delivery persons (role = 'delivery')
final deliveryPersonsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final response = await SupabaseService.client
      .from('profiles')
      .select('*')
      .eq('role', 'delivery')
      .order('full_name');
  return List<Map<String, dynamic>>.from(response);
});

/// Provider for customer count per delivery person
final customerCountProvider = FutureProvider<Map<String, int>>((ref) async {
  final response = await SupabaseService.client
      .from('profiles')
      .select('assigned_delivery_person_id')
      .eq('role', 'customer')
      .not('assigned_delivery_person_id', 'is', null);
  
  final counts = <String, int>{};
  for (final row in response) {
    final dpId = row['assigned_delivery_person_id'] as String?;
    if (dpId != null) {
      counts[dpId] = (counts[dpId] ?? 0) + 1;
    }
  }
  return counts;
});

/// Assignments Screen - Manual Customer-to-Delivery Person Assignment
class AssignmentsScreen extends ConsumerStatefulWidget {
  const AssignmentsScreen({super.key});

  @override
  ConsumerState<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends ConsumerState<AssignmentsScreen> {
  String _filterStatus = 'all'; // 'all', 'assigned', 'unassigned'
  String _searchQuery = '';
  
  static const int maxCapacity = 20;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final customersAsync = ref.watch(customersProvider);
    final deliveryPersonsAsync = ref.watch(deliveryPersonsProvider);
    final customerCountAsync = ref.watch(customerCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Assignments'),
        actions: [
          IconButton(
            onPressed: () {
              ref.invalidate(customersProvider);
              ref.invalidate(deliveryPersonsProvider);
              ref.invalidate(customerCountProvider);
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Row(
        children: [
          // Left panel - Delivery Persons with capacity
          SizedBox(
            width: 320,
            child: Card(
              margin: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Delivery Persons',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: deliveryPersonsAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(child: Text('Error: $e')),
                      data: (deliveryPersons) => customerCountAsync.when(
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Center(child: Text('Error: $e')),
                        data: (counts) => ListView.builder(
                          itemCount: deliveryPersons.length,
                          itemBuilder: (context, index) {
                            final dp = deliveryPersons[index];
                            final count = counts[dp['id']] ?? 0;
                            final isFull = count >= maxCapacity;
                            
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isFull 
                                    ? Colors.red.shade100 
                                    : colorScheme.primaryContainer,
                                child: Icon(
                                  Icons.delivery_dining,
                                  color: isFull ? Colors.red : colorScheme.primary,
                                ),
                              ),
                              title: Text(dp['full_name'] ?? 'Unknown'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(dp['phone'] ?? ''),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: LinearProgressIndicator(
                                          value: count / maxCapacity,
                                          backgroundColor: Colors.grey.shade200,
                                          color: isFull ? Colors.red : colorScheme.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '$count/$maxCapacity',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isFull ? Colors.red : null,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              isThreeLine: true,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Right panel - Customer list
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filter and search row
                  Row(
                    children: [
                      // Filter chips
                      ChoiceChip(
                        label: const Text('All'),
                        selected: _filterStatus == 'all',
                        onSelected: (_) => setState(() => _filterStatus = 'all'),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Unassigned'),
                        selected: _filterStatus == 'unassigned',
                        onSelected: (_) => setState(() => _filterStatus = 'unassigned'),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Assigned'),
                        selected: _filterStatus == 'assigned',
                        onSelected: (_) => setState(() => _filterStatus = 'assigned'),
                      ),
                      const Spacer(),
                      // Search
                      SizedBox(
                        width: 250,
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search customers...',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Customer list
                  Expanded(
                    child: customersAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(child: Text('Error: $e')),
                      data: (customers) {
                        // Apply filters
                        var filtered = customers.where((c) {
                          final hasAssignment = c['assigned_delivery_person'] != null;
                          if (_filterStatus == 'assigned' && !hasAssignment) return false;
                          if (_filterStatus == 'unassigned' && hasAssignment) return false;
                          
                          if (_searchQuery.isNotEmpty) {
                            final name = (c['full_name'] ?? '').toString().toLowerCase();
                            final address = (c['address'] ?? '').toString().toLowerCase();
                            final phone = (c['phone'] ?? '').toString().toLowerCase();
                            if (!name.contains(_searchQuery) && 
                                !address.contains(_searchQuery) &&
                                !phone.contains(_searchQuery)) {
                              return false;
                            }
                          }
                          return true;
                        }).toList();
                        
                        if (filtered.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.people_outline, size: 64, color: colorScheme.onSurfaceVariant),
                                const SizedBox(height: 16),
                                Text('No customers found', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                              ],
                            ),
                          );
                        }
                        
                        return deliveryPersonsAsync.when(
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (e, _) => Center(child: Text('Error: $e')),
                          data: (deliveryPersons) => customerCountAsync.when(
                            loading: () => const Center(child: CircularProgressIndicator()),
                            error: (e, _) => Center(child: Text('Error: $e')),
                            data: (counts) => ListView.builder(
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final customer = filtered[index];
                                final assignedDP = customer['assigned_delivery_person'];
                                final isAssigned = assignedDP != null;
                                
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  color: isAssigned ? null : Colors.orange.shade50,
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: isAssigned 
                                          ? colorScheme.primaryContainer 
                                          : Colors.orange.shade100,
                                      child: Icon(
                                        isAssigned ? Icons.check : Icons.warning_amber,
                                        color: isAssigned ? colorScheme.primary : Colors.orange,
                                      ),
                                    ),
                                    title: Text(customer['full_name'] ?? 'Unknown'),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(customer['phone'] ?? ''),
                                        Text(
                                          customer['address'] ?? 'No address',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (isAssigned)
                                          Chip(
                                            label: Text(
                                              '📦 ${assignedDP['full_name']}',
                                              style: const TextStyle(fontSize: 12),
                                            ),
                                            backgroundColor: colorScheme.primaryContainer,
                                            padding: EdgeInsets.zero,
                                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          ),
                                      ],
                                    ),
                                    isThreeLine: true,
                                    trailing: PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_vert),
                                      onSelected: (dpId) => _assignCustomer(customer['id'], dpId == 'unassign' ? null : dpId),
                                      itemBuilder: (context) => [
                                        if (isAssigned)
                                          const PopupMenuItem(
                                            value: 'unassign',
                                            child: ListTile(
                                              leading: Icon(Icons.remove_circle_outline, color: Colors.red),
                                              title: Text('Unassign'),
                                              contentPadding: EdgeInsets.zero,
                                            ),
                                          ),
                                        ...deliveryPersons.map((dp) {
                                          final count = counts[dp['id']] ?? 0;
                                          final isFull = count >= maxCapacity;
                                          final isCurrentlyAssigned = assignedDP?['id'] == dp['id'];
                                          
                                          return PopupMenuItem(
                                            value: dp['id'],
                                            enabled: !isFull || isCurrentlyAssigned,
                                            child: ListTile(
                                              leading: Icon(
                                                isCurrentlyAssigned ? Icons.check_circle : Icons.person,
                                                color: isCurrentlyAssigned ? colorScheme.primary : null,
                                              ),
                                              title: Text(dp['full_name'] ?? 'Unknown'),
                                              subtitle: Text('$count/$maxCapacity customers'),
                                              trailing: isFull && !isCurrentlyAssigned
                                                  ? const Icon(Icons.block, color: Colors.red, size: 16)
                                                  : null,
                                              contentPadding: EdgeInsets.zero,
                                            ),
                                          );
                                        }),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _assignCustomer(String customerId, String? deliveryPersonId) async {
    try {
      await SupabaseService.client
          .from('profiles')
          .update({'assigned_delivery_person_id': deliveryPersonId})
          .eq('id', customerId);
      
      ref.invalidate(customersProvider);
      ref.invalidate(customerCountProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(deliveryPersonId == null ? 'Customer unassigned' : 'Customer assigned successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
