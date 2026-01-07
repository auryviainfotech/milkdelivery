// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$OrderModelImpl _$$OrderModelImplFromJson(Map<String, dynamic> json) =>
    _$OrderModelImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      subscriptionId: json['subscriptionId'] as String?,
      deliveryDate: DateTime.parse(json['deliveryDate'] as String),
      status: $enumDecodeNullable(_$OrderStatusEnumMap, json['status']) ??
          OrderStatus.pending,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$OrderModelImplToJson(_$OrderModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'subscriptionId': instance.subscriptionId,
      'deliveryDate': instance.deliveryDate.toIso8601String(),
      'status': _$OrderStatusEnumMap[instance.status]!,
      'createdAt': instance.createdAt?.toIso8601String(),
    };

const _$OrderStatusEnumMap = {
  OrderStatus.pending: 'pending',
  OrderStatus.assigned: 'assigned',
  OrderStatus.delivered: 'delivered',
  OrderStatus.failed: 'failed',
};

_$OrderItemImpl _$$OrderItemImplFromJson(Map<String, dynamic> json) =>
    _$OrderItemImpl(
      id: json['id'] as String,
      orderId: json['orderId'] as String,
      productId: json['productId'] as String,
      quantity: (json['quantity'] as num).toInt(),
      price: (json['price'] as num).toDouble(),
    );

Map<String, dynamic> _$$OrderItemImplToJson(_$OrderItemImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'orderId': instance.orderId,
      'productId': instance.productId,
      'quantity': instance.quantity,
      'price': instance.price,
    };

_$DeliveryModelImpl _$$DeliveryModelImplFromJson(Map<String, dynamic> json) =>
    _$DeliveryModelImpl(
      id: json['id'] as String,
      orderId: json['orderId'] as String,
      deliveryPersonId: json['deliveryPersonId'] as String,
      scheduledDate: DateTime.parse(json['scheduledDate'] as String),
      deliveredAt: json['deliveredAt'] == null
          ? null
          : DateTime.parse(json['deliveredAt'] as String),
      qrScanned: json['qrScanned'] as bool? ?? false,
      status: $enumDecodeNullable(_$DeliveryStatusEnumMap, json['status']) ??
          DeliveryStatus.pending,
      issueNotes: json['issueNotes'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$DeliveryModelImplToJson(_$DeliveryModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'orderId': instance.orderId,
      'deliveryPersonId': instance.deliveryPersonId,
      'scheduledDate': instance.scheduledDate.toIso8601String(),
      'deliveredAt': instance.deliveredAt?.toIso8601String(),
      'qrScanned': instance.qrScanned,
      'status': _$DeliveryStatusEnumMap[instance.status]!,
      'issueNotes': instance.issueNotes,
      'createdAt': instance.createdAt?.toIso8601String(),
    };

const _$DeliveryStatusEnumMap = {
  DeliveryStatus.pending: 'pending',
  DeliveryStatus.inTransit: 'inTransit',
  DeliveryStatus.delivered: 'delivered',
  DeliveryStatus.issue: 'issue',
};
