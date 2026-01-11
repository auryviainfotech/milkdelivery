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
      .eq('is_active', true)
      .eq('category', 'one_time')  // Only one-time products
      .order('name');
  
  return (response as List)
      .map((json) => ProductModel.fromJson(json))
      .toList();
});

/// Provider for user's orders
final ordersProvider = FutureProvider<List<OrderModel>>((ref) async {
  final user = SupabaseService.currentUser;
  if (user == null) return [];
  
  final response = await SupabaseService.client
      .from('orders')
      .select()
      .eq('user_id', user.id)
      .order('delivery_date', ascending: false);
  
  return (response as List)
      .map((json) => OrderModel.fromJson(json))
      .toList();
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
