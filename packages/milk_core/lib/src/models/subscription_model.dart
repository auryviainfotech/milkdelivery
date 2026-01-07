import 'package:freezed_annotation/freezed_annotation.dart';

part 'subscription_model.freezed.dart';
part 'subscription_model.g.dart';

/// Subscription status
enum SubscriptionStatus {
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
    required String userId,
    required String planId,
    @Default(1) int quantity,
    required DateTime startDate,
    required DateTime endDate,
    @Default(SubscriptionStatus.active) SubscriptionStatus status,
    @Default([]) List<DateTime> skipDates,
    @Default(true) bool createdBeforeCutoff,
    DateTime? createdAt,
  }) = _SubscriptionModel;

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionModelFromJson(json);
}
