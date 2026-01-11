// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$WalletModelImpl _$$WalletModelImplFromJson(Map<String, dynamic> json) =>
    _$WalletModelImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$WalletModelImplToJson(_$WalletModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'balance': instance.balance,
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

_$WalletTransactionImpl _$$WalletTransactionImplFromJson(
        Map<String, dynamic> json) =>
    _$WalletTransactionImpl(
      id: json['id'] as String,
      walletId: json['walletId'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: $enumDecode(_$TransactionTypeEnumMap, json['type']),
      reason: $enumDecodeNullable(_$TransactionReasonEnumMap, json['reason']),
      description: json['description'] as String?,
      paymentId: json['paymentId'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$WalletTransactionImplToJson(
        _$WalletTransactionImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'walletId': instance.walletId,
      'amount': instance.amount,
      'type': _$TransactionTypeEnumMap[instance.type]!,
      'reason': _$TransactionReasonEnumMap[instance.reason],
      'description': instance.description,
      'paymentId': instance.paymentId,
      'createdAt': instance.createdAt?.toIso8601String(),
    };

const _$TransactionTypeEnumMap = {
  TransactionType.credit: 'credit',
  TransactionType.debit: 'debit',
};

const _$TransactionReasonEnumMap = {
  TransactionReason.recharge: 'recharge',
  TransactionReason.subscription: 'subscription',
  TransactionReason.refund: 'refund',
  TransactionReason.delivery: 'delivery',
};
