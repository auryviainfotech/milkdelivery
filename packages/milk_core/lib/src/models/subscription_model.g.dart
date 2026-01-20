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
      userId: json['user_id'] as String,
      planId: json['plan_id'] as String?,
      productId: json['product_id'] as String?,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      monthlyLiters: (json['monthly_liters'] as num?)?.toInt() ?? 30,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: json['end_date'] == null
          ? null
          : DateTime.parse(json['end_date'] as String),
      status:
          $enumDecodeNullable(_$SubscriptionStatusEnumMap, json['status']) ??
              SubscriptionStatus.pending,
      skipDates: (json['skip_dates'] as List<dynamic>?)
              ?.map((e) => DateTime.parse(e as String))
              .toList() ??
          const [],
      skipWeekends: json['skip_weekends'] as bool? ?? false,
      deliveryAddress: json['delivery_address'] as String?,
      timeSlot: json['time_slot'] as String? ?? 'morning',
      createdBeforeCutoff: json['created_before_cutoff'] as bool? ?? true,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$$SubscriptionModelImplToJson(
        _$SubscriptionModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'plan_id': instance.planId,
      'product_id': instance.productId,
      'quantity': instance.quantity,
      'monthly_liters': instance.monthlyLiters,
      'start_date': instance.startDate.toIso8601String(),
      'end_date': instance.endDate?.toIso8601String(),
      'status': _$SubscriptionStatusEnumMap[instance.status]!,
      'skip_dates': instance.skipDates.map((e) => e.toIso8601String()).toList(),
      'skip_weekends': instance.skipWeekends,
      'delivery_address': instance.deliveryAddress,
      'time_slot': instance.timeSlot,
      'created_before_cutoff': instance.createdBeforeCutoff,
      'created_at': instance.createdAt?.toIso8601String(),
    };

const _$SubscriptionStatusEnumMap = {
  SubscriptionStatus.pending: 'pending',
  SubscriptionStatus.active: 'active',
  SubscriptionStatus.paused: 'paused',
  SubscriptionStatus.expired: 'expired',
  SubscriptionStatus.cancelled: 'cancelled',
};
