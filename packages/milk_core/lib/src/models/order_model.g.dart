// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$OrderModelImpl _$$OrderModelImplFromJson(Map<String, dynamic> json) =>
    _$OrderModelImpl(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      subscriptionId: json['subscription_id'] as String?,
      deliveryDate: DateTime.parse(json['delivery_date'] as String),
      status: $enumDecodeNullable(_$OrderStatusEnumMap, json['status']) ??
          OrderStatus.pending,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      paymentMethod: json['payment_method'] as String?,
      totalAmount: (json['total_amount'] as num?)?.toDouble(),
      orderType: json['order_type'] as String?,
    );

Map<String, dynamic> _$$OrderModelImplToJson(_$OrderModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'subscription_id': instance.subscriptionId,
      'delivery_date': instance.deliveryDate.toIso8601String(),
      'status': _$OrderStatusEnumMap[instance.status]!,
      'created_at': instance.createdAt?.toIso8601String(),
      'payment_method': instance.paymentMethod,
      'total_amount': instance.totalAmount,
      'order_type': instance.orderType,
    };

const _$OrderStatusEnumMap = {
  OrderStatus.pending: 'pending',
  OrderStatus.paymentPending: 'payment_pending',
  OrderStatus.assigned: 'assigned',
  OrderStatus.delivered: 'delivered',
  OrderStatus.failed: 'failed',
};

_$OrderItemImpl _$$OrderItemImplFromJson(Map<String, dynamic> json) =>
    _$OrderItemImpl(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      productId: json['product_id'] as String,
      quantity: (json['quantity'] as num).toInt(),
      price: (json['price'] as num).toDouble(),
    );

Map<String, dynamic> _$$OrderItemImplToJson(_$OrderItemImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'order_id': instance.orderId,
      'product_id': instance.productId,
      'quantity': instance.quantity,
      'price': instance.price,
    };

_$DeliveryModelImpl _$$DeliveryModelImplFromJson(Map<String, dynamic> json) =>
    _$DeliveryModelImpl(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      deliveryPersonId: json['delivery_person_id'] as String,
      scheduledDate: DateTime.parse(json['scheduled_date'] as String),
      deliveredAt: json['delivered_at'] == null
          ? null
          : DateTime.parse(json['delivered_at'] as String),
      qrScanned: json['qr_scanned'] as bool? ?? false,
      status: $enumDecodeNullable(_$DeliveryStatusEnumMap, json['status']) ??
          DeliveryStatus.pending,
      issueNotes: json['issue_notes'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$$DeliveryModelImplToJson(_$DeliveryModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'order_id': instance.orderId,
      'delivery_person_id': instance.deliveryPersonId,
      'scheduled_date': instance.scheduledDate.toIso8601String(),
      'delivered_at': instance.deliveredAt?.toIso8601String(),
      'qr_scanned': instance.qrScanned,
      'status': _$DeliveryStatusEnumMap[instance.status]!,
      'issue_notes': instance.issueNotes,
      'created_at': instance.createdAt?.toIso8601String(),
    };

const _$DeliveryStatusEnumMap = {
  DeliveryStatus.pending: 'pending',
  DeliveryStatus.inTransit: 'inTransit',
  DeliveryStatus.delivered: 'delivered',
  DeliveryStatus.issue: 'issue',
};
