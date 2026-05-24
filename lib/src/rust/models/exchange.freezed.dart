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
  MetadataThorchain get field0;

  /// Create a copy of ExchangeProvider
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ExchangeProviderCopyWith<ExchangeProvider> get copyWith =>
      _$ExchangeProviderCopyWithImpl<ExchangeProvider>(
          this as ExchangeProvider, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ExchangeProvider &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  @override
  String toString() {
    return 'ExchangeProvider(field0: $field0)';
  }
}

/// @nodoc
abstract mixin class $ExchangeProviderCopyWith<$Res> {
  factory $ExchangeProviderCopyWith(
          ExchangeProvider value, $Res Function(ExchangeProvider) _then) =
      _$ExchangeProviderCopyWithImpl;
  @useResult
  $Res call({MetadataThorchain field0});
}

/// @nodoc
class _$ExchangeProviderCopyWithImpl<$Res>
    implements $ExchangeProviderCopyWith<$Res> {
  _$ExchangeProviderCopyWithImpl(this._self, this._then);

  final ExchangeProvider _self;
  final $Res Function(ExchangeProvider) _then;

  /// Create a copy of ExchangeProvider
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? field0 = null,
  }) {
    return _then(_self.copyWith(
      field0: null == field0
          ? _self.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as MetadataThorchain,
    ));
  }
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
    TResult Function(ExchangeProvider_Thorchain value)? thorchain,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case ExchangeProvider_Thorchain() when thorchain != null:
        return thorchain(_that);
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
    required TResult Function(ExchangeProvider_Thorchain value) thorchain,
  }) {
    final _that = this;
    switch (_that) {
      case ExchangeProvider_Thorchain():
        return thorchain(_that);
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
    TResult? Function(ExchangeProvider_Thorchain value)? thorchain,
  }) {
    final _that = this;
    switch (_that) {
      case ExchangeProvider_Thorchain() when thorchain != null:
        return thorchain(_that);
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
    TResult Function(MetadataThorchain field0)? thorchain,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case ExchangeProvider_Thorchain() when thorchain != null:
        return thorchain(_that.field0);
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
    required TResult Function(MetadataThorchain field0) thorchain,
  }) {
    final _that = this;
    switch (_that) {
      case ExchangeProvider_Thorchain():
        return thorchain(_that.field0);
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
    TResult? Function(MetadataThorchain field0)? thorchain,
  }) {
    final _that = this;
    switch (_that) {
      case ExchangeProvider_Thorchain() when thorchain != null:
        return thorchain(_that.field0);
      case _:
        return null;
    }
  }
}

/// @nodoc

class ExchangeProvider_Thorchain extends ExchangeProvider {
  const ExchangeProvider_Thorchain(this.field0) : super._();

  @override
  final MetadataThorchain field0;

  /// Create a copy of ExchangeProvider
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ExchangeProvider_ThorchainCopyWith<ExchangeProvider_Thorchain>
      get copyWith =>
          _$ExchangeProvider_ThorchainCopyWithImpl<ExchangeProvider_Thorchain>(
              this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ExchangeProvider_Thorchain &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  @override
  String toString() {
    return 'ExchangeProvider.thorchain(field0: $field0)';
  }
}

/// @nodoc
abstract mixin class $ExchangeProvider_ThorchainCopyWith<$Res>
    implements $ExchangeProviderCopyWith<$Res> {
  factory $ExchangeProvider_ThorchainCopyWith(ExchangeProvider_Thorchain value,
          $Res Function(ExchangeProvider_Thorchain) _then) =
      _$ExchangeProvider_ThorchainCopyWithImpl;
  @override
  @useResult
  $Res call({MetadataThorchain field0});
}

/// @nodoc
class _$ExchangeProvider_ThorchainCopyWithImpl<$Res>
    implements $ExchangeProvider_ThorchainCopyWith<$Res> {
  _$ExchangeProvider_ThorchainCopyWithImpl(this._self, this._then);

  final ExchangeProvider_Thorchain _self;
  final $Res Function(ExchangeProvider_Thorchain) _then;

  /// Create a copy of ExchangeProvider
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? field0 = null,
  }) {
    return _then(ExchangeProvider_Thorchain(
      null == field0
          ? _self.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as MetadataThorchain,
    ));
  }
}

// dart format on
