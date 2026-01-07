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

/// Provider for available products
final productsProvider = FutureProvider<List<ProductModel>>((ref) async {
  final response = await SupabaseService.client
      .from('products')
      .select()
      .eq('is_active', true)
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
