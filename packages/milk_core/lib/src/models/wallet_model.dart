import 'package:freezed_annotation/freezed_annotation.dart';

part 'wallet_model.freezed.dart';
part 'wallet_model.g.dart';

/// Wallet transaction type
enum TransactionType {
  credit,
  debit,
}

/// Transaction reason
enum TransactionReason {
  recharge,
  subscription,
  refund,
  delivery,
}

/// Wallet model
@freezed
class WalletModel with _$WalletModel {
  const factory WalletModel({
    required String id,
    required String userId,
    @Default(0.0) double balance,
    DateTime? updatedAt,
  }) = _WalletModel;

  factory WalletModel.fromJson(Map<String, dynamic> json) =>
      _$WalletModelFromJson(json);
}

/// Wallet transaction model
@freezed
class WalletTransaction with _$WalletTransaction {
  const factory WalletTransaction({
    required String id,
    required String walletId,
    required double amount,
    required TransactionType type,
    TransactionReason? reason,
    String? paymentId,
    DateTime? createdAt,
  }) = _WalletTransaction;

  factory WalletTransaction.fromJson(Map<String, dynamic> json) =>
      _$WalletTransactionFromJson(json);
}
