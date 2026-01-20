import 'package:freezed_annotation/freezed_annotation.dart';

part 'subscription_model.freezed.dart';
part 'subscription_model.g.dart';

/// Subscription status
enum SubscriptionStatus {
  pending,  // Waiting for admin approval
  active,
  paused,
  expired,
  cancelled,
}

/// Subscription plan model
@freezed
class SubscriptionPlan with _$SubscriptionPlan {
  const factory SubscriptionPlan({
    required String id,
    required String productId,
    String? name,
    required int durationDays,
    required double price,
    @Default(true) bool isActive,
  }) = _SubscriptionPlan;

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionPlanFromJson(json);
}

/// User subscription model
@freezed
class SubscriptionModel with _$SubscriptionModel {
  const factory SubscriptionModel({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'plan_id') String? planId,
    @JsonKey(name: 'product_id') String? productId,
    @Default(1) int quantity,
    @JsonKey(name: 'monthly_liters') @Default(30) int monthlyLiters,
    @JsonKey(name: 'start_date') required DateTime startDate,
    @JsonKey(name: 'end_date') DateTime? endDate,
    @Default(SubscriptionStatus.pending) SubscriptionStatus status,
    @JsonKey(name: 'skip_dates') @Default([]) List<DateTime> skipDates,
    @JsonKey(name: 'skip_weekends') @Default(false) bool skipWeekends,
    @JsonKey(name: 'delivery_address') String? deliveryAddress,
    @JsonKey(name: 'time_slot') @Default('morning') String timeSlot,
    @JsonKey(name: 'created_before_cutoff') @Default(true) bool createdBeforeCutoff,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _SubscriptionModel;

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionModelFromJson(json);
}

