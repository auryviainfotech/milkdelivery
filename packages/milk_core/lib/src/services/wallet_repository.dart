import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/wallet_model.dart';
import 'supabase_service.dart';

/// Repository for wallet management
class WalletRepository {
  static const String _walletTable = 'wallets';
  static const String _transactionTable = 'wallet_transactions';

  /// Get wallet for user
  static Future<WalletModel> getWallet(String userId) async {
    final response = await SupabaseService.client
        .from(_walletTable)
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) {
      // Create wallet if it doesn't exist
      return await createWallet(userId);
    }
    return _mapToWalletModel(response);
  }

  /// Create a new wallet
  static Future<WalletModel> createWallet(String userId) async {
    final response = await SupabaseService.client
        .from(_walletTable)
        .insert({
          'user_id': userId,
          'balance': 0.0,
        })
        .select()
        .single();

    return _mapToWalletModel(response);
  }

  /// Map Supabase snake_case response to WalletModel (camelCase)
  static WalletModel _mapToWalletModel(Map<String, dynamic> json) {
    return WalletModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Get recent transactions
  static Future<List<WalletTransaction>> getTransactions(String walletId) async {
    final response = await SupabaseService.client
        .from(_transactionTable)
        .select()
        .eq('wallet_id', walletId)
        .order('created_at', ascending: false)
        .limit(10);

    return (response as List)
        .map((json) => WalletTransaction.fromJson(json))
        .toList();
  }
}
