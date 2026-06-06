// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'exchange.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ExchangeProvider {
  Object get field0;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ExchangeProvider &&
            const DeepCollectionEquality().equals(other.field0, field0));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(field0));

  @override
  String toString() {
    return 'ExchangeProvider(field0: $field0)';
  }
}

/// @nodoc
class $ExchangeProviderCopyWith<$Res> {
  $ExchangeProviderCopyWith(
      ExchangeProvider _, $Res Function(ExchangeProvider) __);
}

/// Adds pattern-matching-related methods to [ExchangeProvider].
extension ExchangeProviderPatterns on ExchangeProvider {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ExchangeProvider_Relay value)? relay,
    TResult Function(ExchangeProvider_Uniswap value)? uniswap,
    TResult Function(ExchangeProvider_PancakeSwap value)? pancakeSwap,
    TResult Function(ExchangeProvider_ZilSwap value)? zilSwap,
    TResult Function(ExchangeProvider_SunSwap value)? sunSwap,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case ExchangeProvider_Relay() when relay != null:
        return relay(_that);
      case ExchangeProvider_Uniswap() when uniswap != null:
        return uniswap(_that);
      case ExchangeProvider_PancakeSwap() when pancakeSwap != null:
        return pancakeSwap(_that);
      case ExchangeProvider_ZilSwap() when zilSwap != null:
        return zilSwap(_that);
      case ExchangeProvider_SunSwap() when sunSwap != null:
        return sunSwap(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ExchangeProvider_Relay value) relay,
    required TResult Function(ExchangeProvider_Uniswap value) uniswap,
    required TResult Function(ExchangeProvider_PancakeSwap value) pancakeSwap,
    required TResult Function(ExchangeProvider_ZilSwap value) zilSwap,
    required TResult Function(ExchangeProvider_SunSwap value) sunSwap,
  }) {
    final _that = this;
    switch (_that) {
      case ExchangeProvider_Relay():
        return relay(_that);
      case ExchangeProvider_Uniswap():
        return uniswap(_that);
      case ExchangeProvider_PancakeSwap():
        return pancakeSwap(_that);
      case ExchangeProvider_ZilSwap():
        return zilSwap(_that);
      case ExchangeProvider_SunSwap():
        return sunSwap(_that);
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ExchangeProvider_Relay value)? relay,
    TResult? Function(ExchangeProvider_Uniswap value)? uniswap,
    TResult? Function(ExchangeProvider_PancakeSwap value)? pancakeSwap,
    TResult? Function(ExchangeProvider_ZilSwap value)? zilSwap,
    TResult? Function(ExchangeProvider_SunSwap value)? sunSwap,
  }) {
    final _that = this;
    switch (_that) {
      case ExchangeProvider_Relay() when relay != null:
        return relay(_that);
      case ExchangeProvider_Uniswap() when uniswap != null:
        return uniswap(_that);
      case ExchangeProvider_PancakeSwap() when pancakeSwap != null:
        return pancakeSwap(_that);
      case ExchangeProvider_ZilSwap() when zilSwap != null:
        return zilSwap(_that);
      case ExchangeProvider_SunSwap() when sunSwap != null:
        return sunSwap(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(RelayMeta field0)? relay,
    TResult Function(UniswapMeta field0)? uniswap,
    TResult Function(PancakeMeta field0)? pancakeSwap,
    TResult Function(ZilSwapMeta field0)? zilSwap,
    TResult Function(SunSwapMeta field0)? sunSwap,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case ExchangeProvider_Relay() when relay != null:
        return relay(_that.field0);
      case ExchangeProvider_Uniswap() when uniswap != null:
        return uniswap(_that.field0);
      case ExchangeProvider_PancakeSwap() when pancakeSwap != null:
        return pancakeSwap(_that.field0);
      case ExchangeProvider_ZilSwap() when zilSwap != null:
        return zilSwap(_that.field0);
      case ExchangeProvider_SunSwap() when sunSwap != null:
        return sunSwap(_that.field0);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(RelayMeta field0) relay,
    required TResult Function(UniswapMeta field0) uniswap,
    required TResult Function(PancakeMeta field0) pancakeSwap,
    required TResult Function(ZilSwapMeta field0) zilSwap,
    required TResult Function(SunSwapMeta field0) sunSwap,
  }) {
    final _that = this;
    switch (_that) {
      case ExchangeProvider_Relay():
        return relay(_that.field0);
      case ExchangeProvider_Uniswap():
        return uniswap(_that.field0);
      case ExchangeProvider_PancakeSwap():
        return pancakeSwap(_that.field0);
      case ExchangeProvider_ZilSwap():
        return zilSwap(_that.field0);
      case ExchangeProvider_SunSwap():
        return sunSwap(_that.field0);
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(RelayMeta field0)? relay,
    TResult? Function(UniswapMeta field0)? uniswap,
    TResult? Function(PancakeMeta field0)? pancakeSwap,
    TResult? Function(ZilSwapMeta field0)? zilSwap,
    TResult? Function(SunSwapMeta field0)? sunSwap,
  }) {
    final _that = this;
    switch (_that) {
      case ExchangeProvider_Relay() when relay != null:
        return relay(_that.field0);
      case ExchangeProvider_Uniswap() when uniswap != null:
        return uniswap(_that.field0);
      case ExchangeProvider_PancakeSwap() when pancakeSwap != null:
        return pancakeSwap(_that.field0);
      case ExchangeProvider_ZilSwap() when zilSwap != null:
        return zilSwap(_that.field0);
      case ExchangeProvider_SunSwap() when sunSwap != null:
        return sunSwap(_that.field0);
      case _:
        return null;
    }
  }
}

/// @nodoc

class ExchangeProvider_Relay extends ExchangeProvider {
  const ExchangeProvider_Relay(this.field0) : super._();

  @override
  final RelayMeta field0;

  /// Create a copy of ExchangeProvider
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ExchangeProvider_RelayCopyWith<ExchangeProvider_Relay> get copyWith =>
      _$ExchangeProvider_RelayCopyWithImpl<ExchangeProvider_Relay>(
          this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ExchangeProvider_Relay &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  @override
  String toString() {
    return 'ExchangeProvider.relay(field0: $field0)';
  }
}

/// @nodoc
abstract mixin class $ExchangeProvider_RelayCopyWith<$Res>
    implements $ExchangeProviderCopyWith<$Res> {
  factory $ExchangeProvider_RelayCopyWith(ExchangeProvider_Relay value,
          $Res Function(ExchangeProvider_Relay) _then) =
      _$ExchangeProvider_RelayCopyWithImpl;
  @useResult
  $Res call({RelayMeta field0});
}

/// @nodoc
class _$ExchangeProvider_RelayCopyWithImpl<$Res>
    implements $ExchangeProvider_RelayCopyWith<$Res> {
  _$ExchangeProvider_RelayCopyWithImpl(this._self, this._then);

  final ExchangeProvider_Relay _self;
  final $Res Function(ExchangeProvider_Relay) _then;

  /// Create a copy of ExchangeProvider
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? field0 = null,
  }) {
    return _then(ExchangeProvider_Relay(
      null == field0
          ? _self.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as RelayMeta,
    ));
  }
}

/// @nodoc

class ExchangeProvider_Uniswap extends ExchangeProvider {
  const ExchangeProvider_Uniswap(this.field0) : super._();

  @override
  final UniswapMeta field0;

  /// Create a copy of ExchangeProvider
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ExchangeProvider_UniswapCopyWith<ExchangeProvider_Uniswap> get copyWith =>
      _$ExchangeProvider_UniswapCopyWithImpl<ExchangeProvider_Uniswap>(
          this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ExchangeProvider_Uniswap &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  @override
  String toString() {
    return 'ExchangeProvider.uniswap(field0: $field0)';
  }
}

/// @nodoc
abstract mixin class $ExchangeProvider_UniswapCopyWith<$Res>
    implements $ExchangeProviderCopyWith<$Res> {
  factory $ExchangeProvider_UniswapCopyWith(ExchangeProvider_Uniswap value,
          $Res Function(ExchangeProvider_Uniswap) _then) =
      _$ExchangeProvider_UniswapCopyWithImpl;
  @useResult
  $Res call({UniswapMeta field0});
}

/// @nodoc
class _$ExchangeProvider_UniswapCopyWithImpl<$Res>
    implements $ExchangeProvider_UniswapCopyWith<$Res> {
  _$ExchangeProvider_UniswapCopyWithImpl(this._self, this._then);

  final ExchangeProvider_Uniswap _self;
  final $Res Function(ExchangeProvider_Uniswap) _then;

  /// Create a copy of ExchangeProvider
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? field0 = null,
  }) {
    return _then(ExchangeProvider_Uniswap(
      null == field0
          ? _self.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as UniswapMeta,
    ));
  }
}

/// @nodoc

class ExchangeProvider_PancakeSwap extends ExchangeProvider {
  const ExchangeProvider_PancakeSwap(this.field0) : super._();

  @override
  final PancakeMeta field0;

  /// Create a copy of ExchangeProvider
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ExchangeProvider_PancakeSwapCopyWith<ExchangeProvider_PancakeSwap>
      get copyWith => _$ExchangeProvider_PancakeSwapCopyWithImpl<
          ExchangeProvider_PancakeSwap>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ExchangeProvider_PancakeSwap &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  @override
  String toString() {
    return 'ExchangeProvider.pancakeSwap(field0: $field0)';
  }
}

/// @nodoc
abstract mixin class $ExchangeProvider_PancakeSwapCopyWith<$Res>
    implements $ExchangeProviderCopyWith<$Res> {
  factory $ExchangeProvider_PancakeSwapCopyWith(
          ExchangeProvider_PancakeSwap value,
          $Res Function(ExchangeProvider_PancakeSwap) _then) =
      _$ExchangeProvider_PancakeSwapCopyWithImpl;
  @useResult
  $Res call({PancakeMeta field0});
}

/// @nodoc
class _$ExchangeProvider_PancakeSwapCopyWithImpl<$Res>
    implements $ExchangeProvider_PancakeSwapCopyWith<$Res> {
  _$ExchangeProvider_PancakeSwapCopyWithImpl(this._self, this._then);

  final ExchangeProvider_PancakeSwap _self;
  final $Res Function(ExchangeProvider_PancakeSwap) _then;

  /// Create a copy of ExchangeProvider
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? field0 = null,
  }) {
    return _then(ExchangeProvider_PancakeSwap(
      null == field0
          ? _self.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as PancakeMeta,
    ));
  }
}

/// @nodoc

class ExchangeProvider_ZilSwap extends ExchangeProvider {
  const ExchangeProvider_ZilSwap(this.field0) : super._();

  @override
  final ZilSwapMeta field0;

  /// Create a copy of ExchangeProvider
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ExchangeProvider_ZilSwapCopyWith<ExchangeProvider_ZilSwap> get copyWith =>
      _$ExchangeProvider_ZilSwapCopyWithImpl<ExchangeProvider_ZilSwap>(
          this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ExchangeProvider_ZilSwap &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  @override
  String toString() {
    return 'ExchangeProvider.zilSwap(field0: $field0)';
  }
}

/// @nodoc
abstract mixin class $ExchangeProvider_ZilSwapCopyWith<$Res>
    implements $ExchangeProviderCopyWith<$Res> {
  factory $ExchangeProvider_ZilSwapCopyWith(ExchangeProvider_ZilSwap value,
          $Res Function(ExchangeProvider_ZilSwap) _then) =
      _$ExchangeProvider_ZilSwapCopyWithImpl;
  @useResult
  $Res call({ZilSwapMeta field0});
}

/// @nodoc
class _$ExchangeProvider_ZilSwapCopyWithImpl<$Res>
    implements $ExchangeProvider_ZilSwapCopyWith<$Res> {
  _$ExchangeProvider_ZilSwapCopyWithImpl(this._self, this._then);

  final ExchangeProvider_ZilSwap _self;
  final $Res Function(ExchangeProvider_ZilSwap) _then;

  /// Create a copy of ExchangeProvider
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? field0 = null,
  }) {
    return _then(ExchangeProvider_ZilSwap(
      null == field0
          ? _self.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as ZilSwapMeta,
    ));
  }
}

/// @nodoc

class ExchangeProvider_SunSwap extends ExchangeProvider {
  const ExchangeProvider_SunSwap(this.field0) : super._();

  @override
  final SunSwapMeta field0;

  /// Create a copy of ExchangeProvider
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ExchangeProvider_SunSwapCopyWith<ExchangeProvider_SunSwap> get copyWith =>
      _$ExchangeProvider_SunSwapCopyWithImpl<ExchangeProvider_SunSwap>(
          this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ExchangeProvider_SunSwap &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  @override
  String toString() {
    return 'ExchangeProvider.sunSwap(field0: $field0)';
  }
}

/// @nodoc
abstract mixin class $ExchangeProvider_SunSwapCopyWith<$Res>
    implements $ExchangeProviderCopyWith<$Res> {
  factory $ExchangeProvider_SunSwapCopyWith(ExchangeProvider_SunSwap value,
          $Res Function(ExchangeProvider_SunSwap) _then) =
      _$ExchangeProvider_SunSwapCopyWithImpl;
  @useResult
  $Res call({SunSwapMeta field0});
}

/// @nodoc
class _$ExchangeProvider_SunSwapCopyWithImpl<$Res>
    implements $ExchangeProvider_SunSwapCopyWith<$Res> {
  _$ExchangeProvider_SunSwapCopyWithImpl(this._self, this._then);

  final ExchangeProvider_SunSwap _self;
  final $Res Function(ExchangeProvider_SunSwap) _then;

  /// Create a copy of ExchangeProvider
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? field0 = null,
  }) {
    return _then(ExchangeProvider_SunSwap(
      null == field0
          ? _self.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as SunSwapMeta,
    ));
  }
}

// dart format on
