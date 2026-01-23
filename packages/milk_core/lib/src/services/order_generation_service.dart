import 'supabase_service.dart';
import 'wallet_repository.dart';

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
    int failed = 0;
    
    final targetDateStr = '${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}';
    
    // 1. Get active subscriptions with profile info
    final subscriptions = await client
        .from('subscriptions')
        .select('*, profiles:user_id(id, full_name, address, latitude, longitude, assigned_delivery_person_id)')
        .eq('status', 'active')
        .gte('end_date', targetDateStr);
    
    if (subscriptions.isEmpty) {
      return {'orders_created': 0, 'deliveries_assigned': 0, 'unassigned': 0, 'failed': 0};
    }
    
    // 2. Fetch all products to lookup prices and validate existence
    final productsResponse = await client
        .from('products')
        .select('id, price');
    
    // Create a map for quick product price lookup and validation
    final productPrices = <String, double>{};
    for (final product in productsResponse) {
      final productId = product['id']?.toString() ?? '';
      final price = (product['price'] as num?)?.toDouble() ?? 0.0;
      productPrices[productId] = price;
    }
    
    // 3. Get the weekday name for target date
    final weekdays = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    final targetWeekday = weekdays[targetDate.weekday - 1];
    
    // 4. Process each subscription
    for (final sub in subscriptions) {
      try {
        final userId = sub['user_id'] as String?;
        final profile = sub['profiles'] as Map<String, dynamic>?;
        final productId = sub['product_id'] as String?;
        final planType = sub['plan_type'] as String? ?? 'monthly';
        final isPaused = sub['is_paused'] as bool? ?? false;
        
        if (userId == null) continue;
        
        // Skip paused subscriptions
        if (isPaused) continue;

        // Skip if product doesn't exist anymore
        if (productId != null && !productPrices.containsKey(productId)) {
          print('Skipping subscription ${sub['id']}: Product $productId not found');
          failed++;
          continue;
        }
        
        // Check if this subscription should generate an order today
        if (!_shouldGenerateOrder(planType, targetWeekday, sub)) {
          continue;
        }
        
        // Check if order already exists
        final existingOrder = await client
            .from('orders')
            .select('id')
            .eq('user_id', userId)
            .eq('delivery_date', targetDateStr)
            .maybeSingle();
        
        if (existingOrder != null) continue;
        
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
        final quantity = sub['quantity'] as int? ?? 1;
        final dailyPrice = productId != null ? (productPrices[productId] ?? 0.0) : 0.0;
        final totalDailyAmount = dailyPrice * quantity;
        
        // Try to debit from wallet
        final debitSuccess = await WalletRepository.debitWallet(
          userId: userId,
          amount: totalDailyAmount,
          description: 'Daily milk delivery - $targetDateStr',
          orderId: orderId,
        );
        
        if (!debitSuccess) {
          await client.from('orders')
              .update({'status': 'payment_pending'})
              .eq('id', orderId);
        }
        
        if (productId != null) {
          await client.from('order_items').insert({
            'order_id': orderId,
            'product_id': productId,
            'quantity': quantity,
            'price': dailyPrice,
          });
        }
        
        // Assign delivery person
        String? assignedPersonId = profile?['assigned_delivery_person_id'] as String?;
        
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
      } catch (e) {
        print('Error processing subscription ${sub['id']}: $e');
        failed++;
      }
    }
    
    return {
      'orders_created': ordersCreated,
      'deliveries_assigned': deliveriesAssigned,
      'unassigned': unassigned,
      'failed': failed,
    };
  }
  
  /// Check if order should be generated based on plan type
  /// - Daily/Monthly plans: generate every day
  /// - Weekly plans: only generate on matching weekday(s)
  static bool _shouldGenerateOrder(String planType, String targetWeekday, Map<String, dynamic> subscription) {
    switch (planType.toLowerCase()) {
      case 'daily':
      case 'monthly':
        // Daily and Monthly plans generate orders every day
        return true;
        
      case 'weekly':
        // Weekly plans only generate on specific days
        // Check if subscription has delivery_days field (e.g., ['monday', 'thursday'])
        final deliveryDays = subscription['delivery_days'] as List<dynamic>?;
        
        if (deliveryDays == null || deliveryDays.isEmpty) {
          // If no delivery days specified, default to generating on Monday
          return targetWeekday == 'monday';
        }
        
        // Check if target weekday is in the list of delivery days
        return deliveryDays.any((day) => 
          day.toString().toLowerCase() == targetWeekday.toLowerCase()
        );
        
      default:
        // Unknown plan type - treat as daily
        return true;
    }
  }
  

}
