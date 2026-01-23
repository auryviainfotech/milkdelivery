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
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'subscription_id') String? subscriptionId,
    @JsonKey(name: 'delivery_date') required DateTime deliveryDate,
    @Default(OrderStatus.pending) OrderStatus status,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'payment_method') String? paymentMethod,
    @JsonKey(name: 'total_amount') double? totalAmount,
    @JsonKey(name: 'order_type') String? orderType,
  }) = _OrderModel;

  factory OrderModel.fromJson(Map<String, dynamic> json) =>
      _$OrderModelFromJson(json);
}

/// Order item model
@freezed
class OrderItem with _$OrderItem {
  const factory OrderItem({
    required String id,
    @JsonKey(name: 'order_id') required String orderId,
    @JsonKey(name: 'product_id') required String productId,
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
    @JsonKey(name: 'order_id') required String orderId,
    @JsonKey(name: 'delivery_person_id') required String deliveryPersonId,
    @JsonKey(name: 'scheduled_date') required DateTime scheduledDate,
    @JsonKey(name: 'delivered_at') DateTime? deliveredAt,
    @Default(false) @JsonKey(name: 'qr_scanned') bool qrScanned,
    @Default(DeliveryStatus.pending) DeliveryStatus status,
    @JsonKey(name: 'issue_notes') String? issueNotes,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _DeliveryModel;

  factory DeliveryModel.fromJson(Map<String, dynamic> json) =>
      _$DeliveryModelFromJson(json);
}
