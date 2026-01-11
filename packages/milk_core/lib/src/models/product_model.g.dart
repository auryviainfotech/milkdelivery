// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ProductModelImpl _$$ProductModelImplFromJson(Map<String, dynamic> json) =>
    _$ProductModelImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      price: (json['price'] as num).toDouble(),
      unit: json['unit'] as String? ?? '500ml',
      imageUrl: json['imageUrl'] as String?,
      emoji: json['emoji'] as String? ?? '🥛',
      isActive: json['isActive'] as bool? ?? true,
      category:
          $enumDecodeNullable(_$ProductCategoryEnumMap, json['category']) ??
              ProductCategory.subscription,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$ProductModelImplToJson(_$ProductModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'price': instance.price,
      'unit': instance.unit,
      'imageUrl': instance.imageUrl,
      'emoji': instance.emoji,
      'isActive': instance.isActive,
      'category': _$ProductCategoryEnumMap[instance.category]!,
      'createdAt': instance.createdAt?.toIso8601String(),
    };

const _$ProductCategoryEnumMap = {
  ProductCategory.subscription: 'subscription',
  ProductCategory.oneTime: 'one_time',
};
