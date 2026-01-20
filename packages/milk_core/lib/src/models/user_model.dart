import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

/// User roles in the system
enum UserRole {
  customer,
  delivery,
  admin,
}

/// User profile model
@freezed
class UserModel with _$UserModel {
  const factory UserModel({
    required String id,
    required String phone,
    @JsonKey(name: 'full_name') String? fullName,
    String? address,
    double? latitude,
    double? longitude,
    @JsonKey(name: 'qr_code') String? qrCode,
    @Default(UserRole.customer) UserRole role,
    @JsonKey(name: 'liters_remaining') @Default(0.0) double litersRemaining,
    @JsonKey(name: 'subscription_status') @Default('inactive') String subscriptionStatus,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
}

