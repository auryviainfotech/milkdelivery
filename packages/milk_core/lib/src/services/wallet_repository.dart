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

  /// Debit (deduct) amount from wallet
  /// Returns true if successful, false if insufficient balance
  static Future<bool> debitWallet({
    required String userId,
    required double amount,
    required String description,
    String? orderId,
  }) async {
    // Get current wallet
    final wallet = await getWallet(userId);
    
    // Check if sufficient balance
    if (wallet.balance < amount) {
      return false; // Insufficient balance
    }
    
    // Calculate new balance
    final newBalance = wallet.balance - amount;
    
    // Update wallet balance
    await SupabaseService.client
        .from(_walletTable)
        .update({'balance': newBalance})
        .eq('id', wallet.id);
    
    // Log transaction
    await SupabaseService.client.from(_transactionTable).insert({
      'wallet_id': wallet.id,
      'type': 'debit',
      'amount': amount,
      'reason': description,
      'payment_id': orderId,
    });
    
    return true;
  }

  /// Credit (add) amount to wallet
  static Future<void> creditWallet({
    required String userId,
    required double amount,
    required String description,
    String? paymentId,
  }) async {
    // Get current wallet
    final wallet = await getWallet(userId);
    
    // Calculate new balance
    final newBalance = wallet.balance + amount;
    
    // Update wallet balance
    await SupabaseService.client
        .from(_walletTable)
        .update({'balance': newBalance})
        .eq('id', wallet.id);
    
    // Log transaction
    await SupabaseService.client.from(_transactionTable).insert({
      'wallet_id': wallet.id,
      'type': 'credit',
      'amount': amount,
      'reason': description,
      'payment_id': paymentId,
    });
  }

  /// Get wallet balance for a user (quick check)
  static Future<double> getBalance(String userId) async {
    final wallet = await getWallet(userId);
    return wallet.balance;
  }
}

