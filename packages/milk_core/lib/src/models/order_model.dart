import 'package:freezed_annotation/freezed_annotation.dart';

part 'order_model.freezed.dart';
part 'order_model.g.dart';

/// Order status
enum OrderStatus {
  pending,
  assigned,
  delivered,
  failed,
}

/// Delivery status
enum DeliveryStatus {
  pending,
  inTransit,
  delivered,
  issue,
}

/// Order model
@freezed
class OrderModel with _$OrderModel {
  const factory OrderModel({
    required String id,
    required String userId,
    String? subscriptionId,
    required DateTime deliveryDate,
    @Default(OrderStatus.pending) OrderStatus status,
    DateTime? createdAt,
  }) = _OrderModel;

  factory OrderModel.fromJson(Map<String, dynamic> json) =>
      _$OrderModelFromJson(json);
}

/// Order item model
@freezed
class OrderItem with _$OrderItem {
  const factory OrderItem({
    required String id,
    required String orderId,
    required String productId,
    required int quantity,
    required double price,
  }) = _OrderItem;

  factory OrderItem.fromJson(Map<String, dynamic> json) =>
      _$OrderItemFromJson(json);
}

/// Delivery model for delivery personnel
@freezed
class DeliveryModel with _$DeliveryModel {
  const factory DeliveryModel({
    required String id,
    required String orderId,
    required String deliveryPersonId,
    required DateTime scheduledDate,
    DateTime? deliveredAt,
    @Default(false) bool qrScanned,
    @Default(DeliveryStatus.pending) DeliveryStatus status,
    String? issueNotes,
    DateTime? createdAt,
  }) = _DeliveryModel;

  factory DeliveryModel.fromJson(Map<String, dynamic> json) =>
      _$DeliveryModelFromJson(json);
}
