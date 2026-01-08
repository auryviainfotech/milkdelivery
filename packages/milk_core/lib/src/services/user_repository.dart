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
  static Future<void> saveProfile(UserModel user) async {
    // Manually map to snake_case for Supabase
    await SupabaseService.client.from(_tableName).upsert({
      'id': user.id,
      'phone': user.phone,
      'full_name': user.fullName,
      'address': user.address,
      'latitude': user.latitude,
      'longitude': user.longitude,
      'role': user.role.name,
      'created_at': user.createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
    });
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
