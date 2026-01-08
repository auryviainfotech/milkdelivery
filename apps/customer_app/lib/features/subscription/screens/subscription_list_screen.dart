import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:milk_core/milk_core.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../../services/razorpay_service.dart';

/// 4 Hardcoded milk products
final List<Map<String, dynamic>> _products = [
  {
    'id': '1',
    'name': 'Full Cream Milk',
    'price': 35.0,
    'unit': '500ml',
    'emoji': '🥛',
    'description': 'Rich & creamy, 6% fat content',
  },
  {
    'id': '2',
    'name': 'Toned Milk',
    'price': 30.0,
    'unit': '500ml',
    'emoji': '🥛',
    'description': 'Balanced nutrition, 3% fat content',
  },
  {
    'id': '3',
    'name': 'Double Toned Milk',
    'price': 28.0,
    'unit': '500ml',
    'emoji': '🥛',
    'description': 'Light & healthy, 1.5% fat content',
  },
  {
    'id': '4',
    'name': 'Buffalo Milk',
    'price': 45.0,
    'unit': '500ml',
    'emoji': '🦬',
    'description': 'Premium quality, high protein',
  },
];

/// Subscription list and new subscription screen
class SubscriptionListScreen extends ConsumerStatefulWidget {
  const SubscriptionListScreen({super.key});

  @override
  ConsumerState<SubscriptionListScreen> createState() => _SubscriptionListScreenState();
}

class _SubscriptionListScreenState extends ConsumerState<SubscriptionListScreen> {
  String? _selectedProductId;
  String _selectedPlan = 'daily';
  int _quantity = 1;
  bool _isProcessing = false;
  
  // Razorpay payment tracking
  Map<String, dynamic>? _pendingPaymentData;
  
  @override
  void initState() {
    super.initState();
    _initRazorpay();
  }
  
  void _initRazorpay() {
    RazorpayService.init(
      onSuccess: _handlePaymentSuccess,
      onError: _handlePaymentError,
    );
  }
  
  @override
  void dispose() {
    RazorpayService.dispose();
    super.dispose();
  }
  
  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    if (_pendingPaymentData == null) return;
    
    // Save subscription to database
    await _saveSubscription(
      _pendingPaymentData!['product'],
      _pendingPaymentData!['address'],
      _pendingPaymentData!['latitude'],
      _pendingPaymentData!['longitude'],
    );
    
    if (mounted) {
      setState(() => _isProcessing = false);
      
      // Show success dialog
      _showPaymentSuccessDialog(response.paymentId ?? 'N/A');
    }
    
    _pendingPaymentData = null;
  }
  
  void _handlePaymentError(PaymentFailureResponse response) {
    if (mounted) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: ${response.message ?? "Unknown error"}'),
          backgroundColor: Colors.red,
        ),
      );
    }
    _pendingPaymentData = null;
  }
  
  void _showPaymentSuccessDialog(String paymentId) {
    final product = _pendingPaymentData?['product'];
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 64),
        title: const Text('Payment Successful!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${product?['name'] ?? 'Subscription'} - $_planLabel',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '₹${_totalPrice.toStringAsFixed(0)}',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  const Text('✅ Order Confirmed', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Payment ID: $paymentId', style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Your milk delivery will start from tomorrow!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
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

  double get _pricePerDay {
    if (_selectedProductId == null) return 0;
    final product = _products.firstWhere((p) => p['id'] == _selectedProductId);
    return (product['price'] as double) * _quantity;
  }

  double get _totalPrice {
    switch (_selectedPlan) {
      case 'weekly':
        return _pricePerDay * 7;
      case 'monthly':
        return _pricePerDay * 30;
      default:
        return _pricePerDay * 30; // Show monthly for daily plan
    }
  }

  String get _planLabel {
    switch (_selectedPlan) {
      case 'weekly':
        return 'Weekly (7 days)';
      case 'monthly':
        return 'Monthly (30 days)';
      default:
        return 'Daily (per month)';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscribe to Milk'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: _products.length,
                    itemBuilder: (context, index) {
                      final product = _products[index];
                      final isSelected = _selectedProductId == product['id'];
                      return _buildProductCard(product, isSelected);
                    },
                  ),
                  const SizedBox(height: 24),

                  // Quantity selector
                  if (_selectedProductId != null) ...[
                    Text(
                      'Quantity (per delivery)',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
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
                            onPressed: _quantity > 1
                                ? () => setState(() => _quantity--)
                                : null,
                            icon: const Icon(Icons.remove),
                          ),
                          Container(
                            width: 60,
                            alignment: Alignment.center,
                            child: Text(
                              '$_quantity',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton.filledTonal(
                            onPressed: _quantity < 5
                                ? () => setState(() => _quantity++)
                                : null,
                            icon: const Icon(Icons.add),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Plan selection
                    Text(
                      'Select Plan',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildPlanChip('daily', 'Daily'),
                        const SizedBox(width: 8),
                        _buildPlanChip('weekly', 'Weekly'),
                        const SizedBox(width: 8),
                        _buildPlanChip('monthly', 'Monthly'),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Price display
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _planLabel,
                            style: TextStyle(color: colorScheme.onPrimaryContainer),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '₹${_totalPrice.toStringAsFixed(0)}',
                            style: theme.textTheme.headlineLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                          if (_selectedPlan == 'daily')
                            Text(
                              '₹${_pricePerDay.toStringAsFixed(0)}/day',
                              style: TextStyle(color: colorScheme.onPrimaryContainer),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Subscribe button
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
                  onPressed: _isProcessing ? null : _handleSubscribe,
                  child: _isProcessing
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Subscribe Now'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product, bool isSelected) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: () => setState(() => _selectedProductId = product['id']),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primaryContainer : colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outline.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              children: [
                Text(product['emoji'], style: const TextStyle(fontSize: 32)),
                const SizedBox(height: 4),
                Text(
                  product['name'],
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isSelected ? colorScheme.onPrimaryContainer : null,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  product['unit'],
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isSelected
                        ? colorScheme.onPrimaryContainer.withOpacity(0.7)
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            Text(
              '₹${(product['price'] as double).toStringAsFixed(0)}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanChip(String value, String label) {
    final isSelected = _selectedPlan == value;
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => setState(() => _selectedPlan = value),
        selectedColor: colorScheme.primary,
        labelStyle: TextStyle(
          color: isSelected ? colorScheme.onPrimary : null,
        ),
        showCheckmark: false,
      ),
    );
  }

  Future<void> _handleSubscribe() async {
    // Show address dialog - now returns a Map with address and GPS
    final result = await _showAddressDialog();
    if (result == null) return;
    
    final address = result['address'] as String;
    final latitude = result['latitude'] as double?;
    final longitude = result['longitude'] as double?;

    setState(() => _isProcessing = true);

    try {
      // Get selected product
      final product = _products.firstWhere((p) => p['id'] == _selectedProductId);
      
      // Get user info
      final user = SupabaseService.currentUser;
      if (user == null) throw Exception('Not logged in');
      
      final profile = await SupabaseService.client
          .from('profiles')
          .select('full_name, phone')
          .eq('id', user.id)
          .maybeSingle();
      
      // Check wallet balance
      final walletResponse = await SupabaseService.client
          .from('wallets')
          .select('id, balance')
          .eq('user_id', user.id)
          .maybeSingle();
      
      final walletBalance = (walletResponse?['balance'] as num?)?.toDouble() ?? 0;
      
      // Store pending payment data for callback
      _pendingPaymentData = {
        'product': product,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
      };
      
      setState(() => _isProcessing = false);
      
      // Show payment options
      if (!mounted) return;
      
      final paymentMethod = await showModalBottomSheet<String>(
        context: context,
        builder: (context) => _buildPaymentOptionsSheet(walletBalance),
      );
      
      if (paymentMethod == null) return;
      
      if (paymentMethod == 'wallet') {
        // Pay from wallet
        await _payFromWallet(product, address, latitude, longitude, walletResponse?['id']);
      } else {
        // Pay via Razorpay
        RazorpayService.openCheckout(
          amount: _totalPrice,
          orderId: 'ORD${DateTime.now().millisecondsSinceEpoch}',
          description: '${product['name']} - $_planLabel subscription',
          email: user.email ?? 'customer@milkdelivery.com',
          phone: profile?['phone']?.toString().replaceAll('+91', '') ?? '',
          name: profile?['full_name'] ?? '',
        );
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

  Widget _buildPaymentOptionsSheet(double walletBalance) {
    final hasEnoughBalance = walletBalance >= _totalPrice;
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose Payment Method',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Amount: ₹${_totalPrice.toStringAsFixed(2)}',
            style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 24),
          
          // Wallet option
          Card(
            elevation: hasEnoughBalance ? 2 : 0,
            color: hasEnoughBalance ? Colors.green.shade50 : Colors.grey.shade100,
            child: ListTile(
              leading: Icon(
                Icons.account_balance_wallet,
                color: hasEnoughBalance ? Colors.green : Colors.grey,
              ),
              title: Text('Pay from Wallet'),
              subtitle: Text(
                hasEnoughBalance 
                    ? 'Balance: ₹${walletBalance.toStringAsFixed(2)}'
                    : 'Insufficient balance (₹${walletBalance.toStringAsFixed(2)})',
              ),
              trailing: hasEnoughBalance 
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        context.push('/wallet');
                      },
                      child: const Text('Recharge'),
                    ),
              onTap: hasEnoughBalance ? () => Navigator.pop(context, 'wallet') : null,
            ),
          ),
          const SizedBox(height: 12),
          
          // Razorpay option
          Card(
            elevation: 2,
            child: ListTile(
              leading: const Icon(Icons.payment, color: Colors.blue),
              title: const Text('Pay with Razorpay'),
              subtitle: const Text('UPI, Cards, Net Banking'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => Navigator.pop(context, 'razorpay'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _payFromWallet(
    Map<String, dynamic> product, 
    String address, 
    double? latitude, 
    double? longitude,
    String? walletId,
  ) async {
    if (walletId == null) return;
    
    final user = SupabaseService.currentUser;
    if (user == null) return;
    
    setState(() => _isProcessing = true);
    
    try {
      // Deduct from wallet
      final walletResponse = await SupabaseService.client
          .from('wallets')
          .select('balance')
          .eq('id', walletId)
          .single();
      
      final currentBalance = (walletResponse['balance'] as num).toDouble();
      final newBalance = currentBalance - _totalPrice;
      
      await SupabaseService.client
          .from('wallets')
          .update({
            'balance': newBalance,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', walletId);
      
      // Record transaction
      await SupabaseService.client
          .from('wallet_transactions')
          .insert({
            'wallet_id': walletId,
            'amount': _totalPrice,
            'type': 'debit',
            'reason': 'Subscription: ${product['name']} - $_planLabel',
          });
      
      // Save subscription
      await _saveSubscription(product, address, latitude, longitude);
      
      setState(() => _isProcessing = false);
      
      if (mounted) {
        context.push('/order-success');
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment failed: $e')),
        );
      }
    }
  }


  Future<Map<String, dynamic>?> _showAddressDialog() async {
    final houseController = TextEditingController();
    final streetController = TextEditingController();
    final landmarkController = TextEditingController();
    final cityController = TextEditingController();
    final pinController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    double? latitude;
    double? longitude;
    bool isGettingLocation = false;
    String locationStatus = '';
    
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final theme = Theme.of(context);
            final colorScheme = theme.colorScheme;
            
            Future<void> getLocation() async {
              setState(() {
                isGettingLocation = true;
                locationStatus = 'Checking permissions...';
              });
              
              try {
                // Check if location services are enabled
                bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
                if (!serviceEnabled) {
                  setState(() {
                    isGettingLocation = false;
                    locationStatus = '❌ Location services disabled';
                  });
                  return;
                }
                
                // Check permissions
                LocationPermission permission = await Geolocator.checkPermission();
                if (permission == LocationPermission.denied) {
                  permission = await Geolocator.requestPermission();
                  if (permission == LocationPermission.denied) {
                    setState(() {
                      isGettingLocation = false;
                      locationStatus = '❌ Location permission denied';
                    });
                    return;
                  }
                }
                
                if (permission == LocationPermission.deniedForever) {
                  setState(() {
                    isGettingLocation = false;
                    locationStatus = '❌ Location permanently denied. Enable in settings.';
                  });
                  return;
                }
                
                setState(() => locationStatus = 'Getting location...');
                
                // Get current position
                Position position = await Geolocator.getCurrentPosition(
                  desiredAccuracy: LocationAccuracy.high,
                );
                
                setState(() => locationStatus = 'Identifying address...');
                
                // Reverse geocoding to get address text
                List<Placemark> placemarks = await placemarkFromCoordinates(
                  position.latitude,
                  position.longitude,
                );
                
                if (placemarks.isNotEmpty) {
                  final place = placemarks.first;
                  
                  // Auto-fill form fields
                  streetController.text = [
                    if (place.subLocality != null && place.subLocality!.isNotEmpty) place.subLocality,
                    if (place.locality != null && place.locality!.isNotEmpty && place.locality != place.subLocality) place.locality,
                  ].join(', ');
                  
                  cityController.text = place.subAdministrativeArea ?? place.administrativeArea ?? '';
                  pinController.text = place.postalCode ?? '';
                }

                setState(() {
                  latitude = position.latitude;
                  longitude = position.longitude;
                  isGettingLocation = false;
                  locationStatus = '✅ Location & Address captured!';
                });
              } catch (e) {
                setState(() {
                  isGettingLocation = false;
                  locationStatus = '❌ Error: $e';
                });
              }
            }
            
            return AlertDialog(
              title: const Text('Delivery Address'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // GPS Location Button
                      Card(
                        color: latitude != null 
                            ? Colors.green.shade50 
                            : colorScheme.primaryContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    latitude != null ? Icons.check_circle : Icons.my_location,
                                    color: latitude != null ? Colors.green : colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      latitude != null 
                                          ? 'Location captured!'
                                          : 'Get exact delivery location',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: latitude != null ? Colors.green.shade700 : null,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (latitude != null)
                                Text(
                                  '📍 ${latitude!.toStringAsFixed(6)}, ${longitude!.toStringAsFixed(6)}',
                                  style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                                )
                              else
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: isGettingLocation ? null : getLocation,
                                    icon: isGettingLocation 
                                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                        : const Icon(Icons.gps_fixed),
                                    label: Text(isGettingLocation ? locationStatus : 'Get My Location'),
                                  ),
                                ),
                              if (locationStatus.isNotEmpty && latitude == null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(locationStatus, style: const TextStyle(fontSize: 12)),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      Text(
                        'Enter address for delivery person:',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: houseController,
                        decoration: const InputDecoration(
                          labelText: 'House/Flat No. *',
                          hintText: 'e.g., 12-A, Flat 302',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.home_outlined),
                        ),
                        validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: streetController,
                        decoration: const InputDecoration(
                          labelText: 'Street/Colony *',
                          hintText: 'e.g., Gandhi Nagar, MG Road',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.signpost_outlined),
                        ),
                        validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: landmarkController,
                        decoration: const InputDecoration(
                          labelText: 'Landmark',
                          hintText: 'e.g., Near School, Opposite Mall',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_on_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: cityController,
                              decoration: const InputDecoration(
                                labelText: 'City *',
                                hintText: 'City',
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: pinController,
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              decoration: const InputDecoration(
                                labelText: 'PIN *',
                                hintText: '500001',
                                border: OutlineInputBorder(),
                                counterText: '',
                              ),
                              validator: (v) {
                                if (v?.isEmpty ?? true) return 'Required';
                                if (v!.length != 6) return '6 digits';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      final fullAddress = [
                        houseController.text.trim(),
                        streetController.text.trim(),
                        if (landmarkController.text.trim().isNotEmpty)
                          landmarkController.text.trim(),
                        cityController.text.trim(),
                        'PIN: ${pinController.text.trim()}',
                      ].join(', ');
                      Navigator.pop(context, {
                        'address': fullAddress,
                        'latitude': latitude,
                        'longitude': longitude,
                      });
                    }
                  },
                  child: const Text('Proceed to Pay'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _saveSubscription(Map<String, dynamic> product, String address, double? latitude, double? longitude) async {
    final user = SupabaseService.currentUser;
    if (user == null) return;

    // Update user's address and GPS coordinates
    final profileData = <String, dynamic>{
      'id': user.id,
      'address': address,
    };
    
    // Add GPS coordinates if available
    if (latitude != null && longitude != null) {
      profileData['latitude'] = latitude;
      profileData['longitude'] = longitude;
    }
    
    await SupabaseService.client.from('profiles').upsert(profileData);

    // Create subscription
    final startDate = DateTime.now();
    final endDate = _selectedPlan == 'weekly'
        ? startDate.add(const Duration(days: 7))
        : startDate.add(const Duration(days: 30));

    await SupabaseService.client.from('subscriptions').insert({
      'user_id': user.id,
      'product_id': product['id'],
      'plan_type': _selectedPlan,
      'quantity': _quantity,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'status': 'active',
      'total_amount': _totalPrice,
    });
  }
}
