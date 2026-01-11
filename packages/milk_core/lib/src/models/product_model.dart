import 'package:freezed_annotation/freezed_annotation.dart';

part 'product_model.freezed.dart';
part 'product_model.g.dart';

/// Product category enum
enum ProductCategory {
  @JsonValue('subscription')
  subscription,
  @JsonValue('one_time')
  oneTime,
}

/// Product model for milk products
@freezed
class ProductModel with _$ProductModel {
  const factory ProductModel({
    required String id,
    required String name,
    String? description,
    required double price,
    @Default('500ml') String unit,
    String? imageUrl,
    @Default('🥛') String emoji,
    @Default(true) bool isActive,
    /// Category: 'subscription' for daily milk, 'one_time' for additional purchases (ghee, butter, etc.)
    @Default(ProductCategory.subscription) ProductCategory category,
    DateTime? createdAt,
  }) = _ProductModel;

  factory ProductModel.fromJson(Map<String, dynamic> json) =>
      _$ProductModelFromJson(json);
}
