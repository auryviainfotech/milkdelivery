// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SubscriptionPlanImpl _$$SubscriptionPlanImplFromJson(
        Map<String, dynamic> json) =>
    _$SubscriptionPlanImpl(
      id: json['id'] as String,
      productId: json['productId'] as String,
      name: json['name'] as String?,
      durationDays: (json['durationDays'] as num).toInt(),
      price: (json['price'] as num).toDouble(),
      isActive: json['isActive'] as bool? ?? true,
    );

Map<String, dynamic> _$$SubscriptionPlanImplToJson(
        _$SubscriptionPlanImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'productId': instance.productId,
      'name': instance.name,
      'durationDays': instance.durationDays,
      'price': instance.price,
      'isActive': instance.isActive,
    };

_$SubscriptionModelImpl _$$SubscriptionModelImplFromJson(
        Map<String, dynamic> json) =>
    _$SubscriptionModelImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      planId: json['planId'] as String,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      status:
          $enumDecodeNullable(_$SubscriptionStatusEnumMap, json['status']) ??
              SubscriptionStatus.active,
      skipDates: (json['skipDates'] as List<dynamic>?)
              ?.map((e) => DateTime.parse(e as String))
              .toList() ??
          const [],
      createdBeforeCutoff: json['createdBeforeCutoff'] as bool? ?? true,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$SubscriptionModelImplToJson(
        _$SubscriptionModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'planId': instance.planId,
      'quantity': instance.quantity,
      'startDate': instance.startDate.toIso8601String(),
      'endDate': instance.endDate.toIso8601String(),
      'status': _$SubscriptionStatusEnumMap[instance.status]!,
      'skipDates': instance.skipDates.map((e) => e.toIso8601String()).toList(),
      'createdBeforeCutoff': instance.createdBeforeCutoff,
      'createdAt': instance.createdAt?.toIso8601String(),
    };

const _$SubscriptionStatusEnumMap = {
  SubscriptionStatus.active: 'active',
  SubscriptionStatus.paused: 'paused',
  SubscriptionStatus.expired: 'expired',
  SubscriptionStatus.cancelled: 'cancelled',
};
