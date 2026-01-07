import 'package:milk_core/milk_core.dart';
import 'supabase_service.dart';

class SubscriptionRepository {
  static const String _table = 'subscriptions';

  static Future<SubscriptionModel> createSubscription({
    required String userId,
    required String planId,
    required int quantity,
    required DateTime startDate,
  }) async {
    // For now, plans are just product IDs or we assume a default duration
    // In a real app, you'd fetch the plan to get duration
    final endDate = startDate.add(const Duration(days: 30)); // Default 1 month

    final data = {
      'user_id': userId,
      'plan_id': planId,
      'quantity': quantity,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'status': 'active',
      'created_at': DateTime.now().toIso8601String(),
    };

    final response = await SupabaseService.client
        .from(_table)
        .insert(data)
        .select()
        .single();

    return SubscriptionModel.fromJson(response);
  }

  static Future<List<SubscriptionModel>> getActiveSubscriptions(String userId) async {
    final response = await SupabaseService.client
        .from(_table)
        .select()
        .eq('user_id', userId)
        .eq('status', 'active');
    
    return (response as List)
        .map((json) => SubscriptionModel.fromJson(json))
        .toList();
  }
}
