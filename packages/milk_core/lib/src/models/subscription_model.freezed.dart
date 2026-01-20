// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'subscription_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

SubscriptionPlan _$SubscriptionPlanFromJson(Map<String, dynamic> json) {
  return _SubscriptionPlan.fromJson(json);
}

/// @nodoc
mixin _$SubscriptionPlan {
  String get id => throw _privateConstructorUsedError;
  String get productId => throw _privateConstructorUsedError;
  String? get name => throw _privateConstructorUsedError;
  int get durationDays => throw _privateConstructorUsedError;
  double get price => throw _privateConstructorUsedError;
  bool get isActive => throw _privateConstructorUsedError;

  /// Serializes this SubscriptionPlan to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SubscriptionPlan
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SubscriptionPlanCopyWith<SubscriptionPlan> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SubscriptionPlanCopyWith<$Res> {
  factory $SubscriptionPlanCopyWith(
          SubscriptionPlan value, $Res Function(SubscriptionPlan) then) =
      _$SubscriptionPlanCopyWithImpl<$Res, SubscriptionPlan>;
  @useResult
  $Res call(
      {String id,
      String productId,
      String? name,
      int durationDays,
      double price,
      bool isActive});
}

/// @nodoc
class _$SubscriptionPlanCopyWithImpl<$Res, $Val extends SubscriptionPlan>
    implements $SubscriptionPlanCopyWith<$Res> {
  _$SubscriptionPlanCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SubscriptionPlan
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? productId = null,
    Object? name = freezed,
    Object? durationDays = null,
    Object? price = null,
    Object? isActive = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      productId: null == productId
          ? _value.productId
          : productId // ignore: cast_nullable_to_non_nullable
              as String,
      name: freezed == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String?,
      durationDays: null == durationDays
          ? _value.durationDays
          : durationDays // ignore: cast_nullable_to_non_nullable
              as int,
      price: null == price
          ? _value.price
          : price // ignore: cast_nullable_to_non_nullable
              as double,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SubscriptionPlanImplCopyWith<$Res>
    implements $SubscriptionPlanCopyWith<$Res> {
  factory _$$SubscriptionPlanImplCopyWith(_$SubscriptionPlanImpl value,
          $Res Function(_$SubscriptionPlanImpl) then) =
      __$$SubscriptionPlanImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String productId,
      String? name,
      int durationDays,
      double price,
      bool isActive});
}

/// @nodoc
class __$$SubscriptionPlanImplCopyWithImpl<$Res>
    extends _$SubscriptionPlanCopyWithImpl<$Res, _$SubscriptionPlanImpl>
    implements _$$SubscriptionPlanImplCopyWith<$Res> {
  __$$SubscriptionPlanImplCopyWithImpl(_$SubscriptionPlanImpl _value,
      $Res Function(_$SubscriptionPlanImpl) _then)
      : super(_value, _then);

  /// Create a copy of SubscriptionPlan
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? productId = null,
    Object? name = freezed,
    Object? durationDays = null,
    Object? price = null,
    Object? isActive = null,
  }) {
    return _then(_$SubscriptionPlanImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      productId: null == productId
          ? _value.productId
          : productId // ignore: cast_nullable_to_non_nullable
              as String,
      name: freezed == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String?,
      durationDays: null == durationDays
          ? _value.durationDays
          : durationDays // ignore: cast_nullable_to_non_nullable
              as int,
      price: null == price
          ? _value.price
          : price // ignore: cast_nullable_to_non_nullable
              as double,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SubscriptionPlanImpl implements _SubscriptionPlan {
  const _$SubscriptionPlanImpl(
      {required this.id,
      required this.productId,
      this.name,
      required this.durationDays,
      required this.price,
      this.isActive = true});

  factory _$SubscriptionPlanImpl.fromJson(Map<String, dynamic> json) =>
      _$$SubscriptionPlanImplFromJson(json);

  @override
  final String id;
  @override
  final String productId;
  @override
  final String? name;
  @override
  final int durationDays;
  @override
  final double price;
  @override
  @JsonKey()
  final bool isActive;

  @override
  String toString() {
    return 'SubscriptionPlan(id: $id, productId: $productId, name: $name, durationDays: $durationDays, price: $price, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SubscriptionPlanImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.productId, productId) ||
                other.productId == productId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.durationDays, durationDays) ||
                other.durationDays == durationDays) &&
            (identical(other.price, price) || other.price == price) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, productId, name, durationDays, price, isActive);

  /// Create a copy of SubscriptionPlan
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SubscriptionPlanImplCopyWith<_$SubscriptionPlanImpl> get copyWith =>
      __$$SubscriptionPlanImplCopyWithImpl<_$SubscriptionPlanImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SubscriptionPlanImplToJson(
      this,
    );
  }
}

abstract class _SubscriptionPlan implements SubscriptionPlan {
  const factory _SubscriptionPlan(
      {required final String id,
      required final String productId,
      final String? name,
      required final int durationDays,
      required final double price,
      final bool isActive}) = _$SubscriptionPlanImpl;

  factory _SubscriptionPlan.fromJson(Map<String, dynamic> json) =
      _$SubscriptionPlanImpl.fromJson;

  @override
  String get id;
  @override
  String get productId;
  @override
  String? get name;
  @override
  int get durationDays;
  @override
  double get price;
  @override
  bool get isActive;

  /// Create a copy of SubscriptionPlan
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SubscriptionPlanImplCopyWith<_$SubscriptionPlanImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SubscriptionModel _$SubscriptionModelFromJson(Map<String, dynamic> json) {
  return _SubscriptionModel.fromJson(json);
}

/// @nodoc
mixin _$SubscriptionModel {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'user_id')
  String get userId => throw _privateConstructorUsedError;
  @JsonKey(name: 'plan_id')
  String? get planId => throw _privateConstructorUsedError;
  @JsonKey(name: 'product_id')
  String? get productId => throw _privateConstructorUsedError;
  int get quantity => throw _privateConstructorUsedError;
  @JsonKey(name: 'monthly_liters')
  int get monthlyLiters => throw _privateConstructorUsedError;
  @JsonKey(name: 'start_date')
  DateTime get startDate => throw _privateConstructorUsedError;
  @JsonKey(name: 'end_date')
  DateTime? get endDate => throw _privateConstructorUsedError;
  SubscriptionStatus get status => throw _privateConstructorUsedError;
  @JsonKey(name: 'skip_dates')
  List<DateTime> get skipDates => throw _privateConstructorUsedError;
  @JsonKey(name: 'skip_weekends')
  bool get skipWeekends => throw _privateConstructorUsedError;
  @JsonKey(name: 'delivery_address')
  String? get deliveryAddress => throw _privateConstructorUsedError;
  @JsonKey(name: 'time_slot')
  String get timeSlot => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_before_cutoff')
  bool get createdBeforeCutoff => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime? get createdAt => throw _privateConstructorUsedError;

  /// Serializes this SubscriptionModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SubscriptionModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SubscriptionModelCopyWith<SubscriptionModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SubscriptionModelCopyWith<$Res> {
  factory $SubscriptionModelCopyWith(
          SubscriptionModel value, $Res Function(SubscriptionModel) then) =
      _$SubscriptionModelCopyWithImpl<$Res, SubscriptionModel>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'user_id') String userId,
      @JsonKey(name: 'plan_id') String? planId,
      @JsonKey(name: 'product_id') String? productId,
      int quantity,
      @JsonKey(name: 'monthly_liters') int monthlyLiters,
      @JsonKey(name: 'start_date') DateTime startDate,
      @JsonKey(name: 'end_date') DateTime? endDate,
      SubscriptionStatus status,
      @JsonKey(name: 'skip_dates') List<DateTime> skipDates,
      @JsonKey(name: 'skip_weekends') bool skipWeekends,
      @JsonKey(name: 'delivery_address') String? deliveryAddress,
      @JsonKey(name: 'time_slot') String timeSlot,
      @JsonKey(name: 'created_before_cutoff') bool createdBeforeCutoff,
      @JsonKey(name: 'created_at') DateTime? createdAt});
}

/// @nodoc
class _$SubscriptionModelCopyWithImpl<$Res, $Val extends SubscriptionModel>
    implements $SubscriptionModelCopyWith<$Res> {
  _$SubscriptionModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SubscriptionModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? planId = freezed,
    Object? productId = freezed,
    Object? quantity = null,
    Object? monthlyLiters = null,
    Object? startDate = null,
    Object? endDate = freezed,
    Object? status = null,
    Object? skipDates = null,
    Object? skipWeekends = null,
    Object? deliveryAddress = freezed,
    Object? timeSlot = null,
    Object? createdBeforeCutoff = null,
    Object? createdAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      planId: freezed == planId
          ? _value.planId
          : planId // ignore: cast_nullable_to_non_nullable
              as String?,
      productId: freezed == productId
          ? _value.productId
          : productId // ignore: cast_nullable_to_non_nullable
              as String?,
      quantity: null == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as int,
      monthlyLiters: null == monthlyLiters
          ? _value.monthlyLiters
          : monthlyLiters // ignore: cast_nullable_to_non_nullable
              as int,
      startDate: null == startDate
          ? _value.startDate
          : startDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      endDate: freezed == endDate
          ? _value.endDate
          : endDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as SubscriptionStatus,
      skipDates: null == skipDates
          ? _value.skipDates
          : skipDates // ignore: cast_nullable_to_non_nullable
              as List<DateTime>,
      skipWeekends: null == skipWeekends
          ? _value.skipWeekends
          : skipWeekends // ignore: cast_nullable_to_non_nullable
              as bool,
      deliveryAddress: freezed == deliveryAddress
          ? _value.deliveryAddress
          : deliveryAddress // ignore: cast_nullable_to_non_nullable
              as String?,
      timeSlot: null == timeSlot
          ? _value.timeSlot
          : timeSlot // ignore: cast_nullable_to_non_nullable
              as String,
      createdBeforeCutoff: null == createdBeforeCutoff
          ? _value.createdBeforeCutoff
          : createdBeforeCutoff // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SubscriptionModelImplCopyWith<$Res>
    implements $SubscriptionModelCopyWith<$Res> {
  factory _$$SubscriptionModelImplCopyWith(_$SubscriptionModelImpl value,
          $Res Function(_$SubscriptionModelImpl) then) =
      __$$SubscriptionModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'user_id') String userId,
      @JsonKey(name: 'plan_id') String? planId,
      @JsonKey(name: 'product_id') String? productId,
      int quantity,
      @JsonKey(name: 'monthly_liters') int monthlyLiters,
      @JsonKey(name: 'start_date') DateTime startDate,
      @JsonKey(name: 'end_date') DateTime? endDate,
      SubscriptionStatus status,
      @JsonKey(name: 'skip_dates') List<DateTime> skipDates,
      @JsonKey(name: 'skip_weekends') bool skipWeekends,
      @JsonKey(name: 'delivery_address') String? deliveryAddress,
      @JsonKey(name: 'time_slot') String timeSlot,
      @JsonKey(name: 'created_before_cutoff') bool createdBeforeCutoff,
      @JsonKey(name: 'created_at') DateTime? createdAt});
}

/// @nodoc
class __$$SubscriptionModelImplCopyWithImpl<$Res>
    extends _$SubscriptionModelCopyWithImpl<$Res, _$SubscriptionModelImpl>
    implements _$$SubscriptionModelImplCopyWith<$Res> {
  __$$SubscriptionModelImplCopyWithImpl(_$SubscriptionModelImpl _value,
      $Res Function(_$SubscriptionModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of SubscriptionModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? planId = freezed,
    Object? productId = freezed,
    Object? quantity = null,
    Object? monthlyLiters = null,
    Object? startDate = null,
    Object? endDate = freezed,
    Object? status = null,
    Object? skipDates = null,
    Object? skipWeekends = null,
    Object? deliveryAddress = freezed,
    Object? timeSlot = null,
    Object? createdBeforeCutoff = null,
    Object? createdAt = freezed,
  }) {
    return _then(_$SubscriptionModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      planId: freezed == planId
          ? _value.planId
          : planId // ignore: cast_nullable_to_non_nullable
              as String?,
      productId: freezed == productId
          ? _value.productId
          : productId // ignore: cast_nullable_to_non_nullable
              as String?,
      quantity: null == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as int,
      monthlyLiters: null == monthlyLiters
          ? _value.monthlyLiters
          : monthlyLiters // ignore: cast_nullable_to_non_nullable
              as int,
      startDate: null == startDate
          ? _value.startDate
          : startDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      endDate: freezed == endDate
          ? _value.endDate
          : endDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as SubscriptionStatus,
      skipDates: null == skipDates
          ? _value._skipDates
          : skipDates // ignore: cast_nullable_to_non_nullable
              as List<DateTime>,
      skipWeekends: null == skipWeekends
          ? _value.skipWeekends
          : skipWeekends // ignore: cast_nullable_to_non_nullable
              as bool,
      deliveryAddress: freezed == deliveryAddress
          ? _value.deliveryAddress
          : deliveryAddress // ignore: cast_nullable_to_non_nullable
              as String?,
      timeSlot: null == timeSlot
          ? _value.timeSlot
          : timeSlot // ignore: cast_nullable_to_non_nullable
              as String,
      createdBeforeCutoff: null == createdBeforeCutoff
          ? _value.createdBeforeCutoff
          : createdBeforeCutoff // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SubscriptionModelImpl implements _SubscriptionModel {
  const _$SubscriptionModelImpl(
      {required this.id,
      @JsonKey(name: 'user_id') required this.userId,
      @JsonKey(name: 'plan_id') this.planId,
      @JsonKey(name: 'product_id') this.productId,
      this.quantity = 1,
      @JsonKey(name: 'monthly_liters') this.monthlyLiters = 30,
      @JsonKey(name: 'start_date') required this.startDate,
      @JsonKey(name: 'end_date') this.endDate,
      this.status = SubscriptionStatus.pending,
      @JsonKey(name: 'skip_dates') final List<DateTime> skipDates = const [],
      @JsonKey(name: 'skip_weekends') this.skipWeekends = false,
      @JsonKey(name: 'delivery_address') this.deliveryAddress,
      @JsonKey(name: 'time_slot') this.timeSlot = 'morning',
      @JsonKey(name: 'created_before_cutoff') this.createdBeforeCutoff = true,
      @JsonKey(name: 'created_at') this.createdAt})
      : _skipDates = skipDates;

  factory _$SubscriptionModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$SubscriptionModelImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'user_id')
  final String userId;
  @override
  @JsonKey(name: 'plan_id')
  final String? planId;
  @override
  @JsonKey(name: 'product_id')
  final String? productId;
  @override
  @JsonKey()
  final int quantity;
  @override
  @JsonKey(name: 'monthly_liters')
  final int monthlyLiters;
  @override
  @JsonKey(name: 'start_date')
  final DateTime startDate;
  @override
  @JsonKey(name: 'end_date')
  final DateTime? endDate;
  @override
  @JsonKey()
  final SubscriptionStatus status;
  final List<DateTime> _skipDates;
  @override
  @JsonKey(name: 'skip_dates')
  List<DateTime> get skipDates {
    if (_skipDates is EqualUnmodifiableListView) return _skipDates;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_skipDates);
  }

  @override
  @JsonKey(name: 'skip_weekends')
  final bool skipWeekends;
  @override
  @JsonKey(name: 'delivery_address')
  final String? deliveryAddress;
  @override
  @JsonKey(name: 'time_slot')
  final String timeSlot;
  @override
  @JsonKey(name: 'created_before_cutoff')
  final bool createdBeforeCutoff;
  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  @override
  String toString() {
    return 'SubscriptionModel(id: $id, userId: $userId, planId: $planId, productId: $productId, quantity: $quantity, monthlyLiters: $monthlyLiters, startDate: $startDate, endDate: $endDate, status: $status, skipDates: $skipDates, skipWeekends: $skipWeekends, deliveryAddress: $deliveryAddress, timeSlot: $timeSlot, createdBeforeCutoff: $createdBeforeCutoff, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SubscriptionModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.planId, planId) || other.planId == planId) &&
            (identical(other.productId, productId) ||
                other.productId == productId) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity) &&
            (identical(other.monthlyLiters, monthlyLiters) ||
                other.monthlyLiters == monthlyLiters) &&
            (identical(other.startDate, startDate) ||
                other.startDate == startDate) &&
            (identical(other.endDate, endDate) || other.endDate == endDate) &&
            (identical(other.status, status) || other.status == status) &&
            const DeepCollectionEquality()
                .equals(other._skipDates, _skipDates) &&
            (identical(other.skipWeekends, skipWeekends) ||
                other.skipWeekends == skipWeekends) &&
            (identical(other.deliveryAddress, deliveryAddress) ||
                other.deliveryAddress == deliveryAddress) &&
            (identical(other.timeSlot, timeSlot) ||
                other.timeSlot == timeSlot) &&
            (identical(other.createdBeforeCutoff, createdBeforeCutoff) ||
                other.createdBeforeCutoff == createdBeforeCutoff) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      userId,
      planId,
      productId,
      quantity,
      monthlyLiters,
      startDate,
      endDate,
      status,
      const DeepCollectionEquality().hash(_skipDates),
      skipWeekends,
      deliveryAddress,
      timeSlot,
      createdBeforeCutoff,
      createdAt);

  /// Create a copy of SubscriptionModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SubscriptionModelImplCopyWith<_$SubscriptionModelImpl> get copyWith =>
      __$$SubscriptionModelImplCopyWithImpl<_$SubscriptionModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SubscriptionModelImplToJson(
      this,
    );
  }
}

abstract class _SubscriptionModel implements SubscriptionModel {
  const factory _SubscriptionModel(
      {required final String id,
      @JsonKey(name: 'user_id') required final String userId,
      @JsonKey(name: 'plan_id') final String? planId,
      @JsonKey(name: 'product_id') final String? productId,
      final int quantity,
      @JsonKey(name: 'monthly_liters') final int monthlyLiters,
      @JsonKey(name: 'start_date') required final DateTime startDate,
      @JsonKey(name: 'end_date') final DateTime? endDate,
      final SubscriptionStatus status,
      @JsonKey(name: 'skip_dates') final List<DateTime> skipDates,
      @JsonKey(name: 'skip_weekends') final bool skipWeekends,
      @JsonKey(name: 'delivery_address') final String? deliveryAddress,
      @JsonKey(name: 'time_slot') final String timeSlot,
      @JsonKey(name: 'created_before_cutoff') final bool createdBeforeCutoff,
      @JsonKey(name: 'created_at')
      final DateTime? createdAt}) = _$SubscriptionModelImpl;

  factory _SubscriptionModel.fromJson(Map<String, dynamic> json) =
      _$SubscriptionModelImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'user_id')
  String get userId;
  @override
  @JsonKey(name: 'plan_id')
  String? get planId;
  @override
  @JsonKey(name: 'product_id')
  String? get productId;
  @override
  int get quantity;
  @override
  @JsonKey(name: 'monthly_liters')
  int get monthlyLiters;
  @override
  @JsonKey(name: 'start_date')
  DateTime get startDate;
  @override
  @JsonKey(name: 'end_date')
  DateTime? get endDate;
  @override
  SubscriptionStatus get status;
  @override
  @JsonKey(name: 'skip_dates')
  List<DateTime> get skipDates;
  @override
  @JsonKey(name: 'skip_weekends')
  bool get skipWeekends;
  @override
  @JsonKey(name: 'delivery_address')
  String? get deliveryAddress;
  @override
  @JsonKey(name: 'time_slot')
  String get timeSlot;
  @override
  @JsonKey(name: 'created_before_cutoff')
  bool get createdBeforeCutoff;
  @override
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;

  /// Create a copy of SubscriptionModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SubscriptionModelImplCopyWith<_$SubscriptionModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
