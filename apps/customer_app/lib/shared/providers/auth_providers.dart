import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milk_core/milk_core.dart';

/// Provider for the current user profile
final userProfileProvider = FutureProvider<UserModel?>((ref) async {
  final user = SupabaseService.currentUser;
  if (user == null) return null;
  return await UserRepository.getProfile(user.id);
});

/// Provider for the current user's wallet
final walletProvider = FutureProvider<WalletModel?>((ref) async {
  final user = SupabaseService.currentUser;
  if (user == null) return null;
  return await WalletRepository.getWallet(user.id);
});

/// Provider for SUBSCRIPTION products only (daily milk delivery)
/// These are the products available for subscription plans
final productsProvider = FutureProvider<List<ProductModel>>((ref) async {
  final response = await SupabaseService.client
      .from('products')
      .select()
      .eq('is_active', true)
      .eq('category', 'subscription')  // Only subscription products
      .order('name');
  
  return (response as List)
      .map((json) => ProductModel.fromJson(json))
      .toList();
});

/// Provider for ONE-TIME purchase products (butter, ghee, paneer, etc.)
/// These are available in the Shop screen for individual purchases
final oneTimeProductsProvider = FutureProvider<List<ProductModel>>((ref) async {
  final response = await SupabaseService.client
      .from('products')
      .select()
      .order('name'); // Fetch ALL products to allow buying Milk in Shop
  
  return (response as List)
      .map((json) => ProductModel.fromJson(json))
      .toList();
});

/// Provider for user's orders
final ordersProvider = FutureProvider<List<OrderModel>>((ref) async {
  final user = SupabaseService.currentUser;
  debugPrint('🔍 [ORDERS] Current user: ${user?.id}');
  if (user == null) {
    debugPrint('🔍 [ORDERS] No user logged in, returning empty');
    return [];
  }
  
  try {
    // Filter to show last 3 days of orders
    final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
    final dateStr = threeDaysAgo.toIso8601String().split('T')[0];
    
    final response = await SupabaseService.client
        .from('orders')
        .select('*, order_items(*, products(*))')
        .eq('user_id', user.id)
        .gte('delivery_date', dateStr)
        .order('delivery_date', ascending: false);
    
    debugPrint('🔍 [ORDERS] Raw response count: ${(response as List).length}');
    debugPrint('🔍 [ORDERS] Raw response: $response');
    
    final orders = <OrderModel>[];
    for (final json in (response as List)) {
      try {
        orders.add(OrderModel.fromJson(json));
      } catch (e) {
        debugPrint('🔍 [ORDERS] Failed to parse order: $e');
        debugPrint('🔍 [ORDERS] Problematic JSON: $json');
      }
    }
    
    debugPrint('🔍 [ORDERS] Successfully parsed ${orders.length} orders');
    return orders;
  } catch (e) {
    debugPrint('🔍 [ORDERS] Error fetching orders: $e');
    return [];
  }
});

/// Provider for user's active subscriptions
final activeSubscriptionsProvider = FutureProvider<List<SubscriptionModel>>((ref) async {
  final user = SupabaseService.currentUser;
  if (user == null) return [];
  
  final response = await SupabaseService.client
      .from('subscriptions')
      .select()
      .eq('user_id', user.id)
      .eq('status', 'active')
      .order('created_at', ascending: false);
  
  return (response as List)
      .map((json) => SubscriptionModel.fromJson(json))
      .toList();
});

/// Provider for user's ALL subscriptions (active + pending)
/// Used in Orders screen to show subscription status
final allSubscriptionsProvider = FutureProvider<List<SubscriptionModel>>((ref) async {
  final user = SupabaseService.currentUser;
  debugPrint('[allSubscriptionsProvider] Current user: ${user?.id}');
  if (user == null) {
    debugPrint('[allSubscriptionsProvider] No user logged in!');
    return [];
  }
  
  try {
    // Fetch all subscriptions for user, then filter in Dart
    // This avoids complex Supabase filter syntax issues
    final response = await SupabaseService.client
        .from('subscriptions')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);
    
    debugPrint('[allSubscriptionsProvider] Raw response: $response');
    
    final allSubs = (response as List)
        .map((json) => SubscriptionModel.fromJson(json))
        .toList();
    
    debugPrint('[allSubscriptionsProvider] All subs for user: ${allSubs.length}');
    
    // Filter to only active and pending
    final filtered = allSubs.where((s) => 
        s.status == SubscriptionStatus.active || 
        s.status == SubscriptionStatus.pending
    ).toList();
    
    debugPrint('[allSubscriptionsProvider] After filtering (active/pending): ${filtered.length}');
    
    return filtered;
  } catch (e, stack) {
    debugPrint('[allSubscriptionsProvider] ERROR: $e');
    debugPrint('[allSubscriptionsProvider] Stack: $stack');
    rethrow;
  }
});

/// Provider for a specific order's details
final orderDetailProvider = FutureProvider.family<OrderModel?, String>((ref, id) async {
  final response = await SupabaseService.client
      .from('orders')
      .select()
      .eq('id', id)
      .single();
  
  return OrderModel.fromJson(response);
});

/// Provider for a specific subscription's details
final subscriptionDetailProvider = FutureProvider.family<SubscriptionModel?, String>((ref, id) async {
  final response = await SupabaseService.client
      .from('subscriptions')
      .select()
      .eq('id', id)
      .single();
  
  return SubscriptionModel.fromJson(response);
});

/// Provider for user's wallet transactions
final walletTransactionsProvider = FutureProvider<List<WalletTransaction>>((ref) async {
  final wallet = await ref.watch(walletProvider.future);
  if (wallet == null) return [];
  return await WalletRepository.getTransactions(wallet.id);
});

/// Provider for user's notifications
final notificationsProvider = FutureProvider<List<NotificationModel>>((ref) async {
  final user = SupabaseService.currentUser;
  if (user == null) return [];
  
  final response = await SupabaseService.client
      .from('notifications')
      .select()
      .eq('user_id', user.id)
      .order('created_at', ascending: false)
      .limit(50);
  
  return (response as List)
      .map((json) => NotificationModel.fromJson(json))
      .toList();
});

/// Provider for unread notification count
final unreadNotificationCountProvider = FutureProvider<int>((ref) async {
  final user = SupabaseService.currentUser;
  if (user == null) return 0;
  
  final response = await SupabaseService.client
      .from('notifications')
      .select()
      .eq('user_id', user.id)
      .eq('is_read', false);
  
  return (response as List).length;
});

/// Provider for user profile stats (deliveries count, months, savings)
final userProfileStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final user = SupabaseService.currentUser;
  if (user == null) {
    return {'deliveries': 0, 'months': 0, 'savings': 0.0};
  }

  try {
    // Count delivered orders (delivered OR payment_pending)
    // We fetch all orders for the user and filter in Dart to handle OR condition easily
    final ordersResponse = await SupabaseService.client
        .from('orders')
        .select('status, total_amount')
        .eq('user_id', user.id);
    
    final allOrders = (ordersResponse as List);
    final deliveredOrders = allOrders.where((o) => 
        o['status'] == 'delivered' || o['status'] == 'payment_pending'
    ).toList();
    
    final deliveriesCount = deliveredOrders.length;

    // Calculate months subscribed (based on oldest active subscription)
    final subsResponse = await SupabaseService.client
        .from('subscriptions')
        .select('created_at')
        .eq('user_id', user.id)
        .order('created_at', ascending: true)
        .limit(1);
    
    int monthsSubscribed = 0;
    if ((subsResponse as List).isNotEmpty) {
      final createdAt = DateTime.parse(subsResponse.first['created_at']);
      final now = DateTime.now();
      monthsSubscribed = ((now.year - createdAt.year) * 12) + (now.month - createdAt.month);
      if (monthsSubscribed < 1 && now.isAfter(createdAt)) {
        monthsSubscribed = 1; // At least 1 month if they have a subscription
      }
    }

    return {
      'deliveries': deliveriesCount,
      'months': monthsSubscribed,
      'savings': 0.0, // Deprecated, but keeping structure for safety
    };
  } catch (e) {
    debugPrint('Error fetching profile stats: $e');
    return {'deliveries': 0, 'months': 0, 'savings': 0.0};
  }
});

/// Provider for user quota data (liters remaining + status)
final userQuotaProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final user = SupabaseService.currentUser;
  if (user == null) return null;
  
  final response = await SupabaseService.client
      .from('profiles')
      .select('liters_remaining, subscription_status, full_name, phone, qr_code')
      .eq('id', user.id)
      .maybeSingle();
  return response;
});
