import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import 'supabase_service.dart';

/// Repository for user profile management
class UserRepository {
  static const String _tableName = 'profiles';

  /// Get user profile by ID
  static Future<UserModel?> getProfile(String userId) async {
    try {
      final response = await SupabaseService.client
          .from(_tableName)
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) return null;
      return UserModel.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Create or update user profile
  static Future<UserModel> saveProfile(UserModel user) async {
    final response = await SupabaseService.client
        .from(_tableName)
        .upsert(user.toJson())
        .select()
        .single();

    return UserModel.fromJson(response);
  }

  /// Check if profile exists for user
  static Future<bool> profileExists(String userId) async {
    final response = await SupabaseService.client
        .from(_tableName)
        .select('id')
        .eq('id', userId)
        .maybeSingle();
    
    return response != null;
  }
}
