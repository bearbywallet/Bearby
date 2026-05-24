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
mixin _$ExchangeProviderMetadata {
  List<ThorchainInbound> get field0;

  /// Create a copy of ExchangeProviderMetadata
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ExchangeProviderMetadataCopyWith<ExchangeProviderMetadata> get copyWith =>
      _$ExchangeProviderMetadataCopyWithImpl<ExchangeProviderMetadata>(
          this as ExchangeProviderMetadata, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ExchangeProviderMetadata &&
            const DeepCollectionEquality().equals(other.field0, field0));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(field0));

  @override
  String toString() {
    return 'ExchangeProviderMetadata(field0: $field0)';
  }
}

/// @nodoc
abstract mixin class $ExchangeProviderMetadataCopyWith<$Res> {
  factory $ExchangeProviderMetadataCopyWith(ExchangeProviderMetadata value,
          $Res Function(ExchangeProviderMetadata) _then) =
      _$ExchangeProviderMetadataCopyWithImpl;
  @useResult
  $Res call({List<ThorchainInbound> field0});
}

/// @nodoc
class _$ExchangeProviderMetadataCopyWithImpl<$Res>
    implements $ExchangeProviderMetadataCopyWith<$Res> {
  _$ExchangeProviderMetadataCopyWithImpl(this._self, this._then);

  final ExchangeProviderMetadata _self;
  final $Res Function(ExchangeProviderMetadata) _then;

  /// Create a copy of ExchangeProviderMetadata
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
              as List<ThorchainInbound>,
    ));
  }
}

/// Adds pattern-matching-related methods to [ExchangeProviderMetadata].
extension ExchangeProviderMetadataPatterns on ExchangeProviderMetadata {
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
    TResult Function(ExchangeProviderMetadata_Thorchain value)? thorchain,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case ExchangeProviderMetadata_Thorchain() when thorchain != null:
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
    required TResult Function(ExchangeProviderMetadata_Thorchain value)
        thorchain,
  }) {
    final _that = this;
    switch (_that) {
      case ExchangeProviderMetadata_Thorchain():
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
    TResult? Function(ExchangeProviderMetadata_Thorchain value)? thorchain,
  }) {
    final _that = this;
    switch (_that) {
      case ExchangeProviderMetadata_Thorchain() when thorchain != null:
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
    TResult Function(List<ThorchainInbound> field0)? thorchain,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case ExchangeProviderMetadata_Thorchain() when thorchain != null:
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
    required TResult Function(List<ThorchainInbound> field0) thorchain,
  }) {
    final _that = this;
    switch (_that) {
      case ExchangeProviderMetadata_Thorchain():
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
    TResult? Function(List<ThorchainInbound> field0)? thorchain,
  }) {
    final _that = this;
    switch (_that) {
      case ExchangeProviderMetadata_Thorchain() when thorchain != null:
        return thorchain(_that.field0);
      case _:
        return null;
    }
  }
}

/// @nodoc

class ExchangeProviderMetadata_Thorchain extends ExchangeProviderMetadata {
  const ExchangeProviderMetadata_Thorchain(final List<ThorchainInbound> field0)
      : _field0 = field0,
        super._();

  final List<ThorchainInbound> _field0;
  @override
  List<ThorchainInbound> get field0 {
    if (_field0 is EqualUnmodifiableListView) return _field0;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_field0);
  }

  /// Create a copy of ExchangeProviderMetadata
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ExchangeProviderMetadata_ThorchainCopyWith<
          ExchangeProviderMetadata_Thorchain>
      get copyWith => _$ExchangeProviderMetadata_ThorchainCopyWithImpl<
          ExchangeProviderMetadata_Thorchain>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ExchangeProviderMetadata_Thorchain &&
            const DeepCollectionEquality().equals(other._field0, _field0));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_field0));

  @override
  String toString() {
    return 'ExchangeProviderMetadata.thorchain(field0: $field0)';
  }
}

/// @nodoc
abstract mixin class $ExchangeProviderMetadata_ThorchainCopyWith<$Res>
    implements $ExchangeProviderMetadataCopyWith<$Res> {
  factory $ExchangeProviderMetadata_ThorchainCopyWith(
          ExchangeProviderMetadata_Thorchain value,
          $Res Function(ExchangeProviderMetadata_Thorchain) _then) =
      _$ExchangeProviderMetadata_ThorchainCopyWithImpl;
  @override
  @useResult
  $Res call({List<ThorchainInbound> field0});
}

/// @nodoc
class _$ExchangeProviderMetadata_ThorchainCopyWithImpl<$Res>
    implements $ExchangeProviderMetadata_ThorchainCopyWith<$Res> {
  _$ExchangeProviderMetadata_ThorchainCopyWithImpl(this._self, this._then);

  final ExchangeProviderMetadata_Thorchain _self;
  final $Res Function(ExchangeProviderMetadata_Thorchain) _then;

  /// Create a copy of ExchangeProviderMetadata
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? field0 = null,
  }) {
    return _then(ExchangeProviderMetadata_Thorchain(
      null == field0
          ? _self._field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as List<ThorchainInbound>,
    ));
  }
}

/// @nodoc
mixin _$ExchangeProviderQuote {
  ThorchainSwapQuote get field0;

  /// Create a copy of ExchangeProviderQuote
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ExchangeProviderQuoteCopyWith<ExchangeProviderQuote> get copyWith =>
      _$ExchangeProviderQuoteCopyWithImpl<ExchangeProviderQuote>(
          this as ExchangeProviderQuote, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ExchangeProviderQuote &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  @override
  String toString() {
    return 'ExchangeProviderQuote(field0: $field0)';
  }
}

/// @nodoc
abstract mixin class $ExchangeProviderQuoteCopyWith<$Res> {
  factory $ExchangeProviderQuoteCopyWith(ExchangeProviderQuote value,
          $Res Function(ExchangeProviderQuote) _then) =
      _$ExchangeProviderQuoteCopyWithImpl;
  @useResult
  $Res call({ThorchainSwapQuote field0});
}

/// @nodoc
class _$ExchangeProviderQuoteCopyWithImpl<$Res>
    implements $ExchangeProviderQuoteCopyWith<$Res> {
  _$ExchangeProviderQuoteCopyWithImpl(this._self, this._then);

  final ExchangeProviderQuote _self;
  final $Res Function(ExchangeProviderQuote) _then;

  /// Create a copy of ExchangeProviderQuote
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
              as ThorchainSwapQuote,
    ));
  }
}

/// Adds pattern-matching-related methods to [ExchangeProviderQuote].
extension ExchangeProviderQuotePatterns on ExchangeProviderQuote {
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
    TResult Function(ExchangeProviderQuote_Thorchain value)? thorchain,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case ExchangeProviderQuote_Thorchain() when thorchain != null:
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
    required TResult Function(ExchangeProviderQuote_Thorchain value) thorchain,
  }) {
    final _that = this;
    switch (_that) {
      case ExchangeProviderQuote_Thorchain():
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
    TResult? Function(ExchangeProviderQuote_Thorchain value)? thorchain,
  }) {
    final _that = this;
    switch (_that) {
      case ExchangeProviderQuote_Thorchain() when thorchain != null:
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
    TResult Function(ThorchainSwapQuote field0)? thorchain,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case ExchangeProviderQuote_Thorchain() when thorchain != null:
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
    required TResult Function(ThorchainSwapQuote field0) thorchain,
  }) {
    final _that = this;
    switch (_that) {
      case ExchangeProviderQuote_Thorchain():
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
    TResult? Function(ThorchainSwapQuote field0)? thorchain,
  }) {
    final _that = this;
    switch (_that) {
      case ExchangeProviderQuote_Thorchain() when thorchain != null:
        return thorchain(_that.field0);
      case _:
        return null;
    }
  }
}

/// @nodoc

class ExchangeProviderQuote_Thorchain extends ExchangeProviderQuote {
  const ExchangeProviderQuote_Thorchain(this.field0) : super._();

  @override
  final ThorchainSwapQuote field0;

  /// Create a copy of ExchangeProviderQuote
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ExchangeProviderQuote_ThorchainCopyWith<ExchangeProviderQuote_Thorchain>
      get copyWith => _$ExchangeProviderQuote_ThorchainCopyWithImpl<
          ExchangeProviderQuote_Thorchain>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ExchangeProviderQuote_Thorchain &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  @override
  String toString() {
    return 'ExchangeProviderQuote.thorchain(field0: $field0)';
  }
}

/// @nodoc
abstract mixin class $ExchangeProviderQuote_ThorchainCopyWith<$Res>
    implements $ExchangeProviderQuoteCopyWith<$Res> {
  factory $ExchangeProviderQuote_ThorchainCopyWith(
          ExchangeProviderQuote_Thorchain value,
          $Res Function(ExchangeProviderQuote_Thorchain) _then) =
      _$ExchangeProviderQuote_ThorchainCopyWithImpl;
  @override
  @useResult
  $Res call({ThorchainSwapQuote field0});
}

/// @nodoc
class _$ExchangeProviderQuote_ThorchainCopyWithImpl<$Res>
    implements $ExchangeProviderQuote_ThorchainCopyWith<$Res> {
  _$ExchangeProviderQuote_ThorchainCopyWithImpl(this._self, this._then);

  final ExchangeProviderQuote_Thorchain _self;
  final $Res Function(ExchangeProviderQuote_Thorchain) _then;

  /// Create a copy of ExchangeProviderQuote
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? field0 = null,
  }) {
    return _then(ExchangeProviderQuote_Thorchain(
      null == field0
          ? _self.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as ThorchainSwapQuote,
    ));
  }
}

// dart format on
