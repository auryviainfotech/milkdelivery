import 'supabase_service.dart';

/// Service for generating daily orders from active subscriptions
class OrderGenerationService {
  /// Generate orders for a specific date from active subscriptions
  /// 
  /// Returns a map with:
  /// - 'orders_created': number of orders created
  /// - 'deliveries_assigned': number of deliveries assigned to a person
  /// - 'unassigned': number of deliveries without matching delivery person
  static Future<Map<String, int>> generateOrdersForDate(DateTime targetDate) async {
    final client = SupabaseService.client;
    int ordersCreated = 0;
    int deliveriesAssigned = 0;
    int unassigned = 0;
    
    final targetDateStr = '${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}';
    
    // 1. Get active subscriptions where end_date >= targetDate
    final subscriptions = await client
        .from('subscriptions')
        .select('*, profiles!subscriptions_user_id_fkey(id, full_name, address, latitude, longitude)')
        .eq('status', 'active')
        .gte('end_date', targetDateStr);
    
    if (subscriptions.isEmpty) {
      return {'orders_created': 0, 'deliveries_assigned': 0, 'unassigned': 0};
    }
    
    // 2. Get all delivery persons with their service areas
    final deliveryPersons = await client
        .from('profiles')
        .select('id, full_name, service_pin_codes, qr_code')
        .eq('role', 'delivery');
    
    // 3. Process each subscription
    for (final sub in subscriptions) {
      final userId = sub['user_id'] as String?;
      final profile = sub['profiles'] as Map<String, dynamic>?;
      
      if (userId == null) continue;
      
      // Check if order already exists for this user and date
      final existingOrder = await client
          .from('orders')
          .select('id')
          .eq('user_id', userId)
          .eq('delivery_date', targetDateStr)
          .maybeSingle();
      
      if (existingOrder != null) continue; // Skip if order already exists
      
      // Extract PIN code from address
      final address = profile?['address'] as String? ?? '';
      final customerPinCode = _extractPinCode(address);
      
      // Create order
      final orderResponse = await client
          .from('orders')
          .insert({
            'user_id': userId,
            'subscription_id': sub['id'],
            'delivery_date': targetDateStr,
            'status': 'pending',
          })
          .select()
          .single();
      
      final orderId = orderResponse['id'] as String;
      ordersCreated++;
      
      // Create order items
      final productId = sub['product_id'] as String?;
      final quantity = sub['quantity'] as int? ?? 1;
      final price = (sub['total_amount'] as num?)?.toDouble() ?? 0.0;
      
      if (productId != null) {
        await client.from('order_items').insert({
          'order_id': orderId,
          'product_id': productId,
          'quantity': quantity,
          'price': price / 30, // Daily price from monthly total
        });
      }
      
      // Find matching delivery person
      String? assignedPersonId = _findDeliveryPerson(
        deliveryPersons, 
        customerPinCode,
      );
      
      // Create delivery record
      await client.from('deliveries').insert({
        'order_id': orderId,
        'delivery_person_id': assignedPersonId,
        'scheduled_date': targetDateStr,
        'status': 'pending',
      });
      
      if (assignedPersonId != null) {
        deliveriesAssigned++;
      } else {
        unassigned++;
      }
    }
    
    return {
      'orders_created': ordersCreated,
      'deliveries_assigned': deliveriesAssigned,
      'unassigned': unassigned,
    };
  }
  
  /// Extract PIN code from address string
  /// Looks for 6-digit number patterns (Indian PIN codes)
  static String? _extractPinCode(String address) {
    final pinRegex = RegExp(r'\b\d{6}\b');
    final match = pinRegex.firstMatch(address);
    return match?.group(0);
  }
  
  /// Find a delivery person who serves the given PIN code
  static String? _findDeliveryPerson(
    List<dynamic> deliveryPersons, 
    String? customerPinCode,
  ) {
    if (customerPinCode == null || customerPinCode.isEmpty) {
      return null;
    }
    
    for (final person in deliveryPersons) {
      // Check service_pin_codes array (PostgreSQL text[])
      final servicePinCodes = person['service_pin_codes'] as List<dynamic>?;
      if (servicePinCodes != null) {
        for (final pin in servicePinCodes) {
          if (pin.toString().trim() == customerPinCode) {
            return person['id'] as String?;
          }
        }
      }
      
      // Also check qr_code field (legacy area storage)
      final legacyArea = person['qr_code'] as String?;
      if (legacyArea != null && legacyArea.contains(customerPinCode)) {
        return person['id'] as String?;
      }
    }
    
    return null;
  }
}
