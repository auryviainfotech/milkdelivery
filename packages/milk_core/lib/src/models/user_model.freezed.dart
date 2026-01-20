// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

UserModel _$UserModelFromJson(Map<String, dynamic> json) {
  return _UserModel.fromJson(json);
}

/// @nodoc
mixin _$UserModel {
  String get id => throw _privateConstructorUsedError;
  String get phone => throw _privateConstructorUsedError;
  @JsonKey(name: 'full_name')
  String? get fullName => throw _privateConstructorUsedError;
  String? get address => throw _privateConstructorUsedError;
  double? get latitude => throw _privateConstructorUsedError;
  double? get longitude => throw _privateConstructorUsedError;
  @JsonKey(name: 'qr_code')
  String? get qrCode => throw _privateConstructorUsedError;
  UserRole get role => throw _privateConstructorUsedError;
  @JsonKey(name: 'liters_remaining')
  double get litersRemaining => throw _privateConstructorUsedError;
  @JsonKey(name: 'subscription_status')
  String get subscriptionStatus => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime? get createdAt => throw _privateConstructorUsedError;

  /// Serializes this UserModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UserModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserModelCopyWith<UserModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserModelCopyWith<$Res> {
  factory $UserModelCopyWith(UserModel value, $Res Function(UserModel) then) =
      _$UserModelCopyWithImpl<$Res, UserModel>;
  @useResult
  $Res call(
      {String id,
      String phone,
      @JsonKey(name: 'full_name') String? fullName,
      String? address,
      double? latitude,
      double? longitude,
      @JsonKey(name: 'qr_code') String? qrCode,
      UserRole role,
      @JsonKey(name: 'liters_remaining') double litersRemaining,
      @JsonKey(name: 'subscription_status') String subscriptionStatus,
      @JsonKey(name: 'created_at') DateTime? createdAt});
}

/// @nodoc
class _$UserModelCopyWithImpl<$Res, $Val extends UserModel>
    implements $UserModelCopyWith<$Res> {
  _$UserModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UserModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? phone = null,
    Object? fullName = freezed,
    Object? address = freezed,
    Object? latitude = freezed,
    Object? longitude = freezed,
    Object? qrCode = freezed,
    Object? role = null,
    Object? litersRemaining = null,
    Object? subscriptionStatus = null,
    Object? createdAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      phone: null == phone
          ? _value.phone
          : phone // ignore: cast_nullable_to_non_nullable
              as String,
      fullName: freezed == fullName
          ? _value.fullName
          : fullName // ignore: cast_nullable_to_non_nullable
              as String?,
      address: freezed == address
          ? _value.address
          : address // ignore: cast_nullable_to_non_nullable
              as String?,
      latitude: freezed == latitude
          ? _value.latitude
          : latitude // ignore: cast_nullable_to_non_nullable
              as double?,
      longitude: freezed == longitude
          ? _value.longitude
          : longitude // ignore: cast_nullable_to_non_nullable
              as double?,
      qrCode: freezed == qrCode
          ? _value.qrCode
          : qrCode // ignore: cast_nullable_to_non_nullable
              as String?,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as UserRole,
      litersRemaining: null == litersRemaining
          ? _value.litersRemaining
          : litersRemaining // ignore: cast_nullable_to_non_nullable
              as double,
      subscriptionStatus: null == subscriptionStatus
          ? _value.subscriptionStatus
          : subscriptionStatus // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UserModelImplCopyWith<$Res>
    implements $UserModelCopyWith<$Res> {
  factory _$$UserModelImplCopyWith(
          _$UserModelImpl value, $Res Function(_$UserModelImpl) then) =
      __$$UserModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String phone,
      @JsonKey(name: 'full_name') String? fullName,
      String? address,
      double? latitude,
      double? longitude,
      @JsonKey(name: 'qr_code') String? qrCode,
      UserRole role,
      @JsonKey(name: 'liters_remaining') double litersRemaining,
      @JsonKey(name: 'subscription_status') String subscriptionStatus,
      @JsonKey(name: 'created_at') DateTime? createdAt});
}

/// @nodoc
class __$$UserModelImplCopyWithImpl<$Res>
    extends _$UserModelCopyWithImpl<$Res, _$UserModelImpl>
    implements _$$UserModelImplCopyWith<$Res> {
  __$$UserModelImplCopyWithImpl(
      _$UserModelImpl _value, $Res Function(_$UserModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of UserModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? phone = null,
    Object? fullName = freezed,
    Object? address = freezed,
    Object? latitude = freezed,
    Object? longitude = freezed,
    Object? qrCode = freezed,
    Object? role = null,
    Object? litersRemaining = null,
    Object? subscriptionStatus = null,
    Object? createdAt = freezed,
  }) {
    return _then(_$UserModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      phone: null == phone
          ? _value.phone
          : phone // ignore: cast_nullable_to_non_nullable
              as String,
      fullName: freezed == fullName
          ? _value.fullName
          : fullName // ignore: cast_nullable_to_non_nullable
              as String?,
      address: freezed == address
          ? _value.address
          : address // ignore: cast_nullable_to_non_nullable
              as String?,
      latitude: freezed == latitude
          ? _value.latitude
          : latitude // ignore: cast_nullable_to_non_nullable
              as double?,
      longitude: freezed == longitude
          ? _value.longitude
          : longitude // ignore: cast_nullable_to_non_nullable
              as double?,
      qrCode: freezed == qrCode
          ? _value.qrCode
          : qrCode // ignore: cast_nullable_to_non_nullable
              as String?,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as UserRole,
      litersRemaining: null == litersRemaining
          ? _value.litersRemaining
          : litersRemaining // ignore: cast_nullable_to_non_nullable
              as double,
      subscriptionStatus: null == subscriptionStatus
          ? _value.subscriptionStatus
          : subscriptionStatus // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UserModelImpl implements _UserModel {
  const _$UserModelImpl(
      {required this.id,
      required this.phone,
      @JsonKey(name: 'full_name') this.fullName,
      this.address,
      this.latitude,
      this.longitude,
      @JsonKey(name: 'qr_code') this.qrCode,
      this.role = UserRole.customer,
      @JsonKey(name: 'liters_remaining') this.litersRemaining = 0.0,
      @JsonKey(name: 'subscription_status')
      this.subscriptionStatus = 'inactive',
      @JsonKey(name: 'created_at') this.createdAt});

  factory _$UserModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserModelImplFromJson(json);

  @override
  final String id;
  @override
  final String phone;
  @override
  @JsonKey(name: 'full_name')
  final String? fullName;
  @override
  final String? address;
  @override
  final double? latitude;
  @override
  final double? longitude;
  @override
  @JsonKey(name: 'qr_code')
  final String? qrCode;
  @override
  @JsonKey()
  final UserRole role;
  @override
  @JsonKey(name: 'liters_remaining')
  final double litersRemaining;
  @override
  @JsonKey(name: 'subscription_status')
  final String subscriptionStatus;
  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  @override
  String toString() {
    return 'UserModel(id: $id, phone: $phone, fullName: $fullName, address: $address, latitude: $latitude, longitude: $longitude, qrCode: $qrCode, role: $role, litersRemaining: $litersRemaining, subscriptionStatus: $subscriptionStatus, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.phone, phone) || other.phone == phone) &&
            (identical(other.fullName, fullName) ||
                other.fullName == fullName) &&
            (identical(other.address, address) || other.address == address) &&
            (identical(other.latitude, latitude) ||
                other.latitude == latitude) &&
            (identical(other.longitude, longitude) ||
                other.longitude == longitude) &&
            (identical(other.qrCode, qrCode) || other.qrCode == qrCode) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.litersRemaining, litersRemaining) ||
                other.litersRemaining == litersRemaining) &&
            (identical(other.subscriptionStatus, subscriptionStatus) ||
                other.subscriptionStatus == subscriptionStatus) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      phone,
      fullName,
      address,
      latitude,
      longitude,
      qrCode,
      role,
      litersRemaining,
      subscriptionStatus,
      createdAt);

  /// Create a copy of UserModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserModelImplCopyWith<_$UserModelImpl> get copyWith =>
      __$$UserModelImplCopyWithImpl<_$UserModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserModelImplToJson(
      this,
    );
  }
}

abstract class _UserModel implements UserModel {
  const factory _UserModel(
          {required final String id,
          required final String phone,
          @JsonKey(name: 'full_name') final String? fullName,
          final String? address,
          final double? latitude,
          final double? longitude,
          @JsonKey(name: 'qr_code') final String? qrCode,
          final UserRole role,
          @JsonKey(name: 'liters_remaining') final double litersRemaining,
          @JsonKey(name: 'subscription_status') final String subscriptionStatus,
          @JsonKey(name: 'created_at') final DateTime? createdAt}) =
      _$UserModelImpl;

  factory _UserModel.fromJson(Map<String, dynamic> json) =
      _$UserModelImpl.fromJson;

  @override
  String get id;
  @override
  String get phone;
  @override
  @JsonKey(name: 'full_name')
  String? get fullName;
  @override
  String? get address;
  @override
  double? get latitude;
  @override
  double? get longitude;
  @override
  @JsonKey(name: 'qr_code')
  String? get qrCode;
  @override
  UserRole get role;
  @override
  @JsonKey(name: 'liters_remaining')
  double get litersRemaining;
  @override
  @JsonKey(name: 'subscription_status')
  String get subscriptionStatus;
  @override
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;

  /// Create a copy of UserModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserModelImplCopyWith<_$UserModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
