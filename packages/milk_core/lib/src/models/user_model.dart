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
    @Default(UserRole.customer) UserRole role,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
}
