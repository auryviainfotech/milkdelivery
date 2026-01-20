// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserModelImpl _$$UserModelImplFromJson(Map<String, dynamic> json) =>
    _$UserModelImpl(
      id: json['id'] as String,
      phone: json['phone'] as String,
      fullName: json['full_name'] as String?,
      address: json['address'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      qrCode: json['qr_code'] as String?,
      role: $enumDecodeNullable(_$UserRoleEnumMap, json['role']) ??
          UserRole.customer,
      litersRemaining: (json['liters_remaining'] as num?)?.toDouble() ?? 0.0,
      subscriptionStatus: json['subscription_status'] as String? ?? 'inactive',
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$$UserModelImplToJson(_$UserModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'phone': instance.phone,
      'full_name': instance.fullName,
      'address': instance.address,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'qr_code': instance.qrCode,
      'role': _$UserRoleEnumMap[instance.role]!,
      'liters_remaining': instance.litersRemaining,
      'subscription_status': instance.subscriptionStatus,
      'created_at': instance.createdAt?.toIso8601String(),
    };

const _$UserRoleEnumMap = {
  UserRole.customer: 'customer',
  UserRole.delivery: 'delivery',
  UserRole.admin: 'admin',
};
