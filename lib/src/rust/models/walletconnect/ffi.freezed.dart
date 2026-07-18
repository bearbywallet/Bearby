// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ffi.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WcEventInfo {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is WcEventInfo);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'WcEventInfo()';
  }
}

/// @nodoc
class $WcEventInfoCopyWith<$Res> {
  $WcEventInfoCopyWith(WcEventInfo _, $Res Function(WcEventInfo) __);
}

/// Adds pattern-matching-related methods to [WcEventInfo].
extension WcEventInfoPatterns on WcEventInfo {
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
    TResult Function(WcEventInfo_Proposal value)? proposal,
    TResult Function(WcEventInfo_Request value)? request,
    TResult Function(WcEventInfo_SessionSettled value)? sessionSettled,
    TResult Function(WcEventInfo_SessionDeleted value)? sessionDeleted,
    TResult Function(WcEventInfo_SessionEvent value)? sessionEvent,
    TResult Function(WcEventInfo_RelayConnected value)? relayConnected,
    TResult Function(WcEventInfo_RelayDisconnected value)? relayDisconnected,
    TResult Function(WcEventInfo_Error value)? error,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case WcEventInfo_Proposal() when proposal != null:
        return proposal(_that);
      case WcEventInfo_Request() when request != null:
        return request(_that);
      case WcEventInfo_SessionSettled() when sessionSettled != null:
        return sessionSettled(_that);
      case WcEventInfo_SessionDeleted() when sessionDeleted != null:
        return sessionDeleted(_that);
      case WcEventInfo_SessionEvent() when sessionEvent != null:
        return sessionEvent(_that);
      case WcEventInfo_RelayConnected() when relayConnected != null:
        return relayConnected(_that);
      case WcEventInfo_RelayDisconnected() when relayDisconnected != null:
        return relayDisconnected(_that);
      case WcEventInfo_Error() when error != null:
        return error(_that);
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
    required TResult Function(WcEventInfo_Proposal value) proposal,
    required TResult Function(WcEventInfo_Request value) request,
    required TResult Function(WcEventInfo_SessionSettled value) sessionSettled,
    required TResult Function(WcEventInfo_SessionDeleted value) sessionDeleted,
    required TResult Function(WcEventInfo_SessionEvent value) sessionEvent,
    required TResult Function(WcEventInfo_RelayConnected value) relayConnected,
    required TResult Function(WcEventInfo_RelayDisconnected value)
        relayDisconnected,
    required TResult Function(WcEventInfo_Error value) error,
  }) {
    final _that = this;
    switch (_that) {
      case WcEventInfo_Proposal():
        return proposal(_that);
      case WcEventInfo_Request():
        return request(_that);
      case WcEventInfo_SessionSettled():
        return sessionSettled(_that);
      case WcEventInfo_SessionDeleted():
        return sessionDeleted(_that);
      case WcEventInfo_SessionEvent():
        return sessionEvent(_that);
      case WcEventInfo_RelayConnected():
        return relayConnected(_that);
      case WcEventInfo_RelayDisconnected():
        return relayDisconnected(_that);
      case WcEventInfo_Error():
        return error(_that);
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
    TResult? Function(WcEventInfo_Proposal value)? proposal,
    TResult? Function(WcEventInfo_Request value)? request,
    TResult? Function(WcEventInfo_SessionSettled value)? sessionSettled,
    TResult? Function(WcEventInfo_SessionDeleted value)? sessionDeleted,
    TResult? Function(WcEventInfo_SessionEvent value)? sessionEvent,
    TResult? Function(WcEventInfo_RelayConnected value)? relayConnected,
    TResult? Function(WcEventInfo_RelayDisconnected value)? relayDisconnected,
    TResult? Function(WcEventInfo_Error value)? error,
  }) {
    final _that = this;
    switch (_that) {
      case WcEventInfo_Proposal() when proposal != null:
        return proposal(_that);
      case WcEventInfo_Request() when request != null:
        return request(_that);
      case WcEventInfo_SessionSettled() when sessionSettled != null:
        return sessionSettled(_that);
      case WcEventInfo_SessionDeleted() when sessionDeleted != null:
        return sessionDeleted(_that);
      case WcEventInfo_SessionEvent() when sessionEvent != null:
        return sessionEvent(_that);
      case WcEventInfo_RelayConnected() when relayConnected != null:
        return relayConnected(_that);
      case WcEventInfo_RelayDisconnected() when relayDisconnected != null:
        return relayDisconnected(_that);
      case WcEventInfo_Error() when error != null:
        return error(_that);
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
    TResult Function(WcProposalInfo field0)? proposal,
    TResult Function(WcRequestInfo field0)? request,
    TResult Function(String topic)? sessionSettled,
    TResult Function(String topic, String message)? sessionDeleted,
    TResult Function(String topic, String chainId, String name, String data)?
        sessionEvent,
    TResult Function()? relayConnected,
    TResult Function()? relayDisconnected,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case WcEventInfo_Proposal() when proposal != null:
        return proposal(_that.field0);
      case WcEventInfo_Request() when request != null:
        return request(_that.field0);
      case WcEventInfo_SessionSettled() when sessionSettled != null:
        return sessionSettled(_that.topic);
      case WcEventInfo_SessionDeleted() when sessionDeleted != null:
        return sessionDeleted(_that.topic, _that.message);
      case WcEventInfo_SessionEvent() when sessionEvent != null:
        return sessionEvent(_that.topic, _that.chainId, _that.name, _that.data);
      case WcEventInfo_RelayConnected() when relayConnected != null:
        return relayConnected();
      case WcEventInfo_RelayDisconnected() when relayDisconnected != null:
        return relayDisconnected();
      case WcEventInfo_Error() when error != null:
        return error(_that.message);
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
    required TResult Function(WcProposalInfo field0) proposal,
    required TResult Function(WcRequestInfo field0) request,
    required TResult Function(String topic) sessionSettled,
    required TResult Function(String topic, String message) sessionDeleted,
    required TResult Function(
            String topic, String chainId, String name, String data)
        sessionEvent,
    required TResult Function() relayConnected,
    required TResult Function() relayDisconnected,
    required TResult Function(String message) error,
  }) {
    final _that = this;
    switch (_that) {
      case WcEventInfo_Proposal():
        return proposal(_that.field0);
      case WcEventInfo_Request():
        return request(_that.field0);
      case WcEventInfo_SessionSettled():
        return sessionSettled(_that.topic);
      case WcEventInfo_SessionDeleted():
        return sessionDeleted(_that.topic, _that.message);
      case WcEventInfo_SessionEvent():
        return sessionEvent(_that.topic, _that.chainId, _that.name, _that.data);
      case WcEventInfo_RelayConnected():
        return relayConnected();
      case WcEventInfo_RelayDisconnected():
        return relayDisconnected();
      case WcEventInfo_Error():
        return error(_that.message);
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
    TResult? Function(WcProposalInfo field0)? proposal,
    TResult? Function(WcRequestInfo field0)? request,
    TResult? Function(String topic)? sessionSettled,
    TResult? Function(String topic, String message)? sessionDeleted,
    TResult? Function(String topic, String chainId, String name, String data)?
        sessionEvent,
    TResult? Function()? relayConnected,
    TResult? Function()? relayDisconnected,
    TResult? Function(String message)? error,
  }) {
    final _that = this;
    switch (_that) {
      case WcEventInfo_Proposal() when proposal != null:
        return proposal(_that.field0);
      case WcEventInfo_Request() when request != null:
        return request(_that.field0);
      case WcEventInfo_SessionSettled() when sessionSettled != null:
        return sessionSettled(_that.topic);
      case WcEventInfo_SessionDeleted() when sessionDeleted != null:
        return sessionDeleted(_that.topic, _that.message);
      case WcEventInfo_SessionEvent() when sessionEvent != null:
        return sessionEvent(_that.topic, _that.chainId, _that.name, _that.data);
      case WcEventInfo_RelayConnected() when relayConnected != null:
        return relayConnected();
      case WcEventInfo_RelayDisconnected() when relayDisconnected != null:
        return relayDisconnected();
      case WcEventInfo_Error() when error != null:
        return error(_that.message);
      case _:
        return null;
    }
  }
}

/// @nodoc

class WcEventInfo_Proposal extends WcEventInfo {
  const WcEventInfo_Proposal(this.field0) : super._();

  final WcProposalInfo field0;

  /// Create a copy of WcEventInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $WcEventInfo_ProposalCopyWith<WcEventInfo_Proposal> get copyWith =>
      _$WcEventInfo_ProposalCopyWithImpl<WcEventInfo_Proposal>(
          this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is WcEventInfo_Proposal &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  @override
  String toString() {
    return 'WcEventInfo.proposal(field0: $field0)';
  }
}

/// @nodoc
abstract mixin class $WcEventInfo_ProposalCopyWith<$Res>
    implements $WcEventInfoCopyWith<$Res> {
  factory $WcEventInfo_ProposalCopyWith(WcEventInfo_Proposal value,
          $Res Function(WcEventInfo_Proposal) _then) =
      _$WcEventInfo_ProposalCopyWithImpl;
  @useResult
  $Res call({WcProposalInfo field0});
}

/// @nodoc
class _$WcEventInfo_ProposalCopyWithImpl<$Res>
    implements $WcEventInfo_ProposalCopyWith<$Res> {
  _$WcEventInfo_ProposalCopyWithImpl(this._self, this._then);

  final WcEventInfo_Proposal _self;
  final $Res Function(WcEventInfo_Proposal) _then;

  /// Create a copy of WcEventInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? field0 = null,
  }) {
    return _then(WcEventInfo_Proposal(
      null == field0
          ? _self.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as WcProposalInfo,
    ));
  }
}

/// @nodoc

class WcEventInfo_Request extends WcEventInfo {
  const WcEventInfo_Request(this.field0) : super._();

  final WcRequestInfo field0;

  /// Create a copy of WcEventInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $WcEventInfo_RequestCopyWith<WcEventInfo_Request> get copyWith =>
      _$WcEventInfo_RequestCopyWithImpl<WcEventInfo_Request>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is WcEventInfo_Request &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  @override
  String toString() {
    return 'WcEventInfo.request(field0: $field0)';
  }
}

/// @nodoc
abstract mixin class $WcEventInfo_RequestCopyWith<$Res>
    implements $WcEventInfoCopyWith<$Res> {
  factory $WcEventInfo_RequestCopyWith(
          WcEventInfo_Request value, $Res Function(WcEventInfo_Request) _then) =
      _$WcEventInfo_RequestCopyWithImpl;
  @useResult
  $Res call({WcRequestInfo field0});
}

/// @nodoc
class _$WcEventInfo_RequestCopyWithImpl<$Res>
    implements $WcEventInfo_RequestCopyWith<$Res> {
  _$WcEventInfo_RequestCopyWithImpl(this._self, this._then);

  final WcEventInfo_Request _self;
  final $Res Function(WcEventInfo_Request) _then;

  /// Create a copy of WcEventInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? field0 = null,
  }) {
    return _then(WcEventInfo_Request(
      null == field0
          ? _self.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as WcRequestInfo,
    ));
  }
}

/// @nodoc

class WcEventInfo_SessionSettled extends WcEventInfo {
  const WcEventInfo_SessionSettled({required this.topic}) : super._();

  final String topic;

  /// Create a copy of WcEventInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $WcEventInfo_SessionSettledCopyWith<WcEventInfo_SessionSettled>
      get copyWith =>
          _$WcEventInfo_SessionSettledCopyWithImpl<WcEventInfo_SessionSettled>(
              this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is WcEventInfo_SessionSettled &&
            (identical(other.topic, topic) || other.topic == topic));
  }

  @override
  int get hashCode => Object.hash(runtimeType, topic);

  @override
  String toString() {
    return 'WcEventInfo.sessionSettled(topic: $topic)';
  }
}

/// @nodoc
abstract mixin class $WcEventInfo_SessionSettledCopyWith<$Res>
    implements $WcEventInfoCopyWith<$Res> {
  factory $WcEventInfo_SessionSettledCopyWith(WcEventInfo_SessionSettled value,
          $Res Function(WcEventInfo_SessionSettled) _then) =
      _$WcEventInfo_SessionSettledCopyWithImpl;
  @useResult
  $Res call({String topic});
}

/// @nodoc
class _$WcEventInfo_SessionSettledCopyWithImpl<$Res>
    implements $WcEventInfo_SessionSettledCopyWith<$Res> {
  _$WcEventInfo_SessionSettledCopyWithImpl(this._self, this._then);

  final WcEventInfo_SessionSettled _self;
  final $Res Function(WcEventInfo_SessionSettled) _then;

  /// Create a copy of WcEventInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? topic = null,
  }) {
    return _then(WcEventInfo_SessionSettled(
      topic: null == topic
          ? _self.topic
          : topic // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class WcEventInfo_SessionDeleted extends WcEventInfo {
  const WcEventInfo_SessionDeleted({required this.topic, required this.message})
      : super._();

  final String topic;
  final String message;

  /// Create a copy of WcEventInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $WcEventInfo_SessionDeletedCopyWith<WcEventInfo_SessionDeleted>
      get copyWith =>
          _$WcEventInfo_SessionDeletedCopyWithImpl<WcEventInfo_SessionDeleted>(
              this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is WcEventInfo_SessionDeleted &&
            (identical(other.topic, topic) || other.topic == topic) &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, topic, message);

  @override
  String toString() {
    return 'WcEventInfo.sessionDeleted(topic: $topic, message: $message)';
  }
}

/// @nodoc
abstract mixin class $WcEventInfo_SessionDeletedCopyWith<$Res>
    implements $WcEventInfoCopyWith<$Res> {
  factory $WcEventInfo_SessionDeletedCopyWith(WcEventInfo_SessionDeleted value,
          $Res Function(WcEventInfo_SessionDeleted) _then) =
      _$WcEventInfo_SessionDeletedCopyWithImpl;
  @useResult
  $Res call({String topic, String message});
}

/// @nodoc
class _$WcEventInfo_SessionDeletedCopyWithImpl<$Res>
    implements $WcEventInfo_SessionDeletedCopyWith<$Res> {
  _$WcEventInfo_SessionDeletedCopyWithImpl(this._self, this._then);

  final WcEventInfo_SessionDeleted _self;
  final $Res Function(WcEventInfo_SessionDeleted) _then;

  /// Create a copy of WcEventInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? topic = null,
    Object? message = null,
  }) {
    return _then(WcEventInfo_SessionDeleted(
      topic: null == topic
          ? _self.topic
          : topic // ignore: cast_nullable_to_non_nullable
              as String,
      message: null == message
          ? _self.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class WcEventInfo_SessionEvent extends WcEventInfo {
  const WcEventInfo_SessionEvent(
      {required this.topic,
      required this.chainId,
      required this.name,
      required this.data})
      : super._();

  final String topic;
  final String chainId;
  final String name;
  final String data;

  /// Create a copy of WcEventInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $WcEventInfo_SessionEventCopyWith<WcEventInfo_SessionEvent> get copyWith =>
      _$WcEventInfo_SessionEventCopyWithImpl<WcEventInfo_SessionEvent>(
          this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is WcEventInfo_SessionEvent &&
            (identical(other.topic, topic) || other.topic == topic) &&
            (identical(other.chainId, chainId) || other.chainId == chainId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.data, data) || other.data == data));
  }

  @override
  int get hashCode => Object.hash(runtimeType, topic, chainId, name, data);

  @override
  String toString() {
    return 'WcEventInfo.sessionEvent(topic: $topic, chainId: $chainId, name: $name, data: $data)';
  }
}

/// @nodoc
abstract mixin class $WcEventInfo_SessionEventCopyWith<$Res>
    implements $WcEventInfoCopyWith<$Res> {
  factory $WcEventInfo_SessionEventCopyWith(WcEventInfo_SessionEvent value,
          $Res Function(WcEventInfo_SessionEvent) _then) =
      _$WcEventInfo_SessionEventCopyWithImpl;
  @useResult
  $Res call({String topic, String chainId, String name, String data});
}

/// @nodoc
class _$WcEventInfo_SessionEventCopyWithImpl<$Res>
    implements $WcEventInfo_SessionEventCopyWith<$Res> {
  _$WcEventInfo_SessionEventCopyWithImpl(this._self, this._then);

  final WcEventInfo_SessionEvent _self;
  final $Res Function(WcEventInfo_SessionEvent) _then;

  /// Create a copy of WcEventInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? topic = null,
    Object? chainId = null,
    Object? name = null,
    Object? data = null,
  }) {
    return _then(WcEventInfo_SessionEvent(
      topic: null == topic
          ? _self.topic
          : topic // ignore: cast_nullable_to_non_nullable
              as String,
      chainId: null == chainId
          ? _self.chainId
          : chainId // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      data: null == data
          ? _self.data
          : data // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class WcEventInfo_RelayConnected extends WcEventInfo {
  const WcEventInfo_RelayConnected() : super._();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is WcEventInfo_RelayConnected);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'WcEventInfo.relayConnected()';
  }
}

/// @nodoc

class WcEventInfo_RelayDisconnected extends WcEventInfo {
  const WcEventInfo_RelayDisconnected() : super._();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is WcEventInfo_RelayDisconnected);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'WcEventInfo.relayDisconnected()';
  }
}

/// @nodoc

class WcEventInfo_Error extends WcEventInfo {
  const WcEventInfo_Error({required this.message}) : super._();

  final String message;

  /// Create a copy of WcEventInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $WcEventInfo_ErrorCopyWith<WcEventInfo_Error> get copyWith =>
      _$WcEventInfo_ErrorCopyWithImpl<WcEventInfo_Error>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is WcEventInfo_Error &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  @override
  String toString() {
    return 'WcEventInfo.error(message: $message)';
  }
}

/// @nodoc
abstract mixin class $WcEventInfo_ErrorCopyWith<$Res>
    implements $WcEventInfoCopyWith<$Res> {
  factory $WcEventInfo_ErrorCopyWith(
          WcEventInfo_Error value, $Res Function(WcEventInfo_Error) _then) =
      _$WcEventInfo_ErrorCopyWithImpl;
  @useResult
  $Res call({String message});
}

/// @nodoc
class _$WcEventInfo_ErrorCopyWithImpl<$Res>
    implements $WcEventInfo_ErrorCopyWith<$Res> {
  _$WcEventInfo_ErrorCopyWithImpl(this._self, this._then);

  final WcEventInfo_Error _self;
  final $Res Function(WcEventInfo_Error) _then;

  /// Create a copy of WcEventInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? message = null,
  }) {
    return _then(WcEventInfo_Error(
      message: null == message
          ? _self.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

// dart format on
