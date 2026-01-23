import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:milk_core/milk_core.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../../shared/providers/auth_providers.dart';

/// Subscription Request Screen
/// User selects product + monthly quantity and submits request
/// Admin will manually activate after offline payment collection
class SubscriptionListScreen extends ConsumerStatefulWidget {
  const SubscriptionListScreen({super.key});

  @override
  ConsumerState<SubscriptionListScreen> createState() => _SubscriptionListScreenState();
}

class _SubscriptionListScreenState extends ConsumerState<SubscriptionListScreen> {
  String? _selectedProductId;
  int _monthlyLiters = 30; // Default 30 liters per month (1L/day)
  bool _isProcessing = false;
  bool _skipWeekends = false;
  
  // Products fetched from Supabase (converted to Map format for UI compatibility)
  List<Map<String, dynamic>> _products = [];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Watch products from Supabase
    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscribe to Milk'),
      ),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading products: $e')),
        data: (productModels) {
          // Convert ProductModel list to Map format for UI compatibility
          _products = productModels.map((p) => <String, dynamic>{
            'id': p.id,
            'name': p.name,
            'price': p.price,
            'unit': p.unit ?? '500ml',
            'emoji': p.emoji,
            'description': p.description ?? '',
          }).toList();
          
          if (_products.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 64, color: colorScheme.onSurfaceVariant),
                  const SizedBox(height: 16),
                  Text('No products available', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  Text('Admin needs to add products first', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12)),
                ],
              ),
            );
          }
          
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Info Banner
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue.shade700),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'How Subscription Works',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade700),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '1. Select product & monthly liters\n2. Submit request\n3. Admin will call you for payment\n4. After payment, your subscription activates',
                                    style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Product selection
                      Text(
                        'Select Product',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.85,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: _products.length,
                        itemBuilder: (context, index) {
                          final product = _products[index];
                          final isSelected = _selectedProductId == product['id'];
                          return _buildProductCard(product, isSelected);
                        },
                      ),
                      const SizedBox(height: 24),

                      // Monthly Liters selector
                      if (_selectedProductId != null) ...[
                        Text(
                          'Monthly Liters',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'How many liters do you need per month?',
                          style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton.filledTonal(
                                onPressed: _monthlyLiters > 5
                                    ? () => setState(() => _monthlyLiters -= 5)
                                    : null,
                                icon: const Icon(Icons.remove),
                              ),
                              Container(
                                width: 100,
                                alignment: Alignment.center,
                                child: Column(
                                  children: [
                                    Text(
                                      '$_monthlyLiters',
                                      style: theme.textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text('Liters/Month', style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                                  ],
                                ),
                              ),
                              IconButton.filledTonal(
                                onPressed: _monthlyLiters < 100
                                    ? () => setState(() => _monthlyLiters += 5)
                                    : null,
                                icon: const Icon(Icons.add),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Quick select buttons
                        Wrap(
                          spacing: 8,
                          children: [15, 30, 45, 60].map((liters) {
                            final isSelected = _monthlyLiters == liters;
                            return ChoiceChip(
                              label: Text('$liters L'),
                              selected: isSelected,
                              onSelected: (_) => setState(() => _monthlyLiters = liters),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),

                        // Skip weekends toggle
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.weekend, color: colorScheme.primary),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Skip Weekends', style: TextStyle(fontWeight: FontWeight.w600)),
                                    Text(
                                      'No delivery on Saturday & Sunday',
                                      style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _skipWeekends,
                                onChanged: (v) => setState(() => _skipWeekends = v),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Summary Card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Product', style: TextStyle(color: colorScheme.onPrimaryContainer)),
                                  Flexible(
                                    child: Text(
                                      _products.firstWhere((p) => p['id'] == _selectedProductId)['name'],
                                      style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onPrimaryContainer),
                                      textAlign: TextAlign.end,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Monthly Quota', style: TextStyle(color: colorScheme.onPrimaryContainer)),
                                  Text(
                                    '$_monthlyLiters Liters',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onPrimaryContainer),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Delivery', style: TextStyle(color: colorScheme.onPrimaryContainer)),
                                  Text(
                                    _skipWeekends ? 'Mon-Fri' : 'Daily',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onPrimaryContainer),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Submit button
              if (_selectedProductId != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: FilledButton(
                      onPressed: _isProcessing ? null : _handleSubmitRequest,
                      child: _isProcessing
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Request Subscription'),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product, bool isSelected) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: () => setState(() => _selectedProductId = product['id']),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primaryContainer : colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outline.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(product['emoji'], style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 2),
            Text(
              product['name'],
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 11,
                color: isSelected ? colorScheme.onPrimaryContainer : null,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              product['unit'],
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 9,
                color: isSelected
                    ? colorScheme.onPrimaryContainer.withValues(alpha: 0.7)
                    : colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            if (isSelected)
              Icon(Icons.check_circle, color: colorScheme.primary, size: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSubmitRequest() async {
    // Show address dialog
    final result = await _showAddressDialog();
    if (result == null) return;
    
    final address = result['address'] as String;
    final latitude = result['latitude'] as double?;
    final longitude = result['longitude'] as double?;

    setState(() => _isProcessing = true);

    try {
      final user = SupabaseService.currentUser;
      if (user == null) throw Exception('Not logged in');
      
      // Get selected product
      final product = _products.firstWhere((p) => p['id'] == _selectedProductId);
      
      // Create subscription request (status = pending)
      final startDate = DateTime.now().add(const Duration(days: 1));
      final endDate = startDate.add(const Duration(days: 30));
      
      await SupabaseService.client.from('subscriptions').insert({
        'user_id': user.id,
        'product_id': _selectedProductId,
        'quantity': 1, // Per delivery
        'monthly_liters': _monthlyLiters,
        'plan_type': 'monthly',
        'status': 'pending', // Admin will activate
        'skip_weekends': _skipWeekends,
        'delivery_address': address,
        'delivery_slot': 'morning',
        'start_date': startDate.toIso8601String().split('T')[0],
        'end_date': endDate.toIso8601String().split('T')[0],
      });

      // Update profile address and status (if not already active)
      final profileResponse = await SupabaseService.client
          .from('profiles')
          .select('subscription_status')
          .eq('id', user.id)
          .maybeSingle();
      
      final currentStatus = profileResponse?['subscription_status'] as String? ?? 'inactive';
      
      final updateData = <String, dynamic>{
        'address': address,
      };

      // Only set to pending if not currently active
      if (currentStatus != 'active') {
        updateData['subscription_status'] = 'pending';
      }

      await SupabaseService.client.from('profiles').update(updateData).eq('id', user.id);

      if (mounted) {
        setState(() => _isProcessing = false);
        _showSuccessDialog(product['name']);
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  void _showSuccessDialog(String productName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.hourglass_top, color: Colors.orange, size: 64),
        title: const Text('Request Submitted!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$productName - $_monthlyLiters Liters/Month',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                children: [
                  const Text('⏳ Pending Admin Approval', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    'Admin will call you to collect payment and activate your subscription.',
                    style: TextStyle(fontSize: 12, color: Colors.orange.shade700),
                    textAlign: TextAlign.center,
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
              context.go('/dashboard');
            },
            child: const Text('Go to Dashboard'),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>?> _showAddressDialog() async {
    final addressController = TextEditingController();
    double? latitude;
    double? longitude;
    bool isFetchingLocation = false;

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Delivery Address'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: addressController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Enter your full delivery address',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: isFetchingLocation
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.my_location),
                      onPressed: isFetchingLocation
                          ? null
                          : () async {
                              setDialogState(() => isFetchingLocation = true);
                              try {
                                final permission = await Geolocator.checkPermission();
                                if (permission == LocationPermission.denied) {
                                  await Geolocator.requestPermission();
                                }
                                final position = await Geolocator.getCurrentPosition();
                                latitude = position.latitude;
                                longitude = position.longitude;

                                final placemarks = await placemarkFromCoordinates(
                                  position.latitude,
                                  position.longitude,
                                );
                                if (placemarks.isNotEmpty) {
                                  final p = placemarks.first;
                                  addressController.text =
                                      '${p.street}, ${p.subLocality}, ${p.locality}, ${p.postalCode}';
                                }
                              } catch (e) {
                                debugPrint('Location error: $e');
                              }
                              setDialogState(() => isFetchingLocation = false);
                            },
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap the location icon to use current location',
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (addressController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter your address')),
                  );
                  return;
                }
                Navigator.pop(context, {
                  'address': addressController.text.trim(),
                  'latitude': latitude,
                  'longitude': longitude,
                });
              },
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }
}
