// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tron.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TronContractValue {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is TronContractValue);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'TronContractValue()';
  }
}

/// @nodoc
class $TronContractValueCopyWith<$Res> {
  $TronContractValueCopyWith(
      TronContractValue _, $Res Function(TronContractValue) __);
}

/// Adds pattern-matching-related methods to [TronContractValue].
extension TronContractValuePatterns on TronContractValue {
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
    TResult Function(TronContractValue_TransferContract value)?
        transferContract,
    TResult Function(TronContractValue_TriggerSmartContract value)?
        triggerSmartContract,
    TResult Function(TronContractValue_FreezeBalanceV2Contract value)?
        freezeBalanceV2Contract,
    TResult Function(TronContractValue_UnfreezeBalanceV2Contract value)?
        unfreezeBalanceV2Contract,
    TResult Function(TronContractValue_WithdrawExpireUnfreezeContract value)?
        withdrawExpireUnfreezeContract,
    TResult Function(TronContractValue_DelegateResourceContract value)?
        delegateResourceContract,
    TResult Function(TronContractValue_UnDelegateResourceContract value)?
        unDelegateResourceContract,
    TResult Function(TronContractValue_CancelAllUnfreezeV2Contract value)?
        cancelAllUnfreezeV2Contract,
    TResult Function(TronContractValue_TransferAssetContract value)?
        transferAssetContract,
    TResult Function(TronContractValue_VoteWitnessContract value)?
        voteWitnessContract,
    TResult Function(TronContractValue_AccountCreateContract value)?
        accountCreateContract,
    TResult Function(TronContractValue_AccountUpdateContract value)?
        accountUpdateContract,
    TResult Function(TronContractValue_AccountPermissionUpdateContract value)?
        accountPermissionUpdateContract,
    TResult Function(TronContractValue_Unknown value)? unknown,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case TronContractValue_TransferContract() when transferContract != null:
        return transferContract(_that);
      case TronContractValue_TriggerSmartContract()
          when triggerSmartContract != null:
        return triggerSmartContract(_that);
      case TronContractValue_FreezeBalanceV2Contract()
          when freezeBalanceV2Contract != null:
        return freezeBalanceV2Contract(_that);
      case TronContractValue_UnfreezeBalanceV2Contract()
          when unfreezeBalanceV2Contract != null:
        return unfreezeBalanceV2Contract(_that);
      case TronContractValue_WithdrawExpireUnfreezeContract()
          when withdrawExpireUnfreezeContract != null:
        return withdrawExpireUnfreezeContract(_that);
      case TronContractValue_DelegateResourceContract()
          when delegateResourceContract != null:
        return delegateResourceContract(_that);
      case TronContractValue_UnDelegateResourceContract()
          when unDelegateResourceContract != null:
        return unDelegateResourceContract(_that);
      case TronContractValue_CancelAllUnfreezeV2Contract()
          when cancelAllUnfreezeV2Contract != null:
        return cancelAllUnfreezeV2Contract(_that);
      case TronContractValue_TransferAssetContract()
          when transferAssetContract != null:
        return transferAssetContract(_that);
      case TronContractValue_VoteWitnessContract()
          when voteWitnessContract != null:
        return voteWitnessContract(_that);
      case TronContractValue_AccountCreateContract()
          when accountCreateContract != null:
        return accountCreateContract(_that);
      case TronContractValue_AccountUpdateContract()
          when accountUpdateContract != null:
        return accountUpdateContract(_that);
      case TronContractValue_AccountPermissionUpdateContract()
          when accountPermissionUpdateContract != null:
        return accountPermissionUpdateContract(_that);
      case TronContractValue_Unknown() when unknown != null:
        return unknown(_that);
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
    required TResult Function(TronContractValue_TransferContract value)
        transferContract,
    required TResult Function(TronContractValue_TriggerSmartContract value)
        triggerSmartContract,
    required TResult Function(TronContractValue_FreezeBalanceV2Contract value)
        freezeBalanceV2Contract,
    required TResult Function(TronContractValue_UnfreezeBalanceV2Contract value)
        unfreezeBalanceV2Contract,
    required TResult Function(
            TronContractValue_WithdrawExpireUnfreezeContract value)
        withdrawExpireUnfreezeContract,
    required TResult Function(TronContractValue_DelegateResourceContract value)
        delegateResourceContract,
    required TResult Function(
            TronContractValue_UnDelegateResourceContract value)
        unDelegateResourceContract,
    required TResult Function(
            TronContractValue_CancelAllUnfreezeV2Contract value)
        cancelAllUnfreezeV2Contract,
    required TResult Function(TronContractValue_TransferAssetContract value)
        transferAssetContract,
    required TResult Function(TronContractValue_VoteWitnessContract value)
        voteWitnessContract,
    required TResult Function(TronContractValue_AccountCreateContract value)
        accountCreateContract,
    required TResult Function(TronContractValue_AccountUpdateContract value)
        accountUpdateContract,
    required TResult Function(
            TronContractValue_AccountPermissionUpdateContract value)
        accountPermissionUpdateContract,
    required TResult Function(TronContractValue_Unknown value) unknown,
  }) {
    final _that = this;
    switch (_that) {
      case TronContractValue_TransferContract():
        return transferContract(_that);
      case TronContractValue_TriggerSmartContract():
        return triggerSmartContract(_that);
      case TronContractValue_FreezeBalanceV2Contract():
        return freezeBalanceV2Contract(_that);
      case TronContractValue_UnfreezeBalanceV2Contract():
        return unfreezeBalanceV2Contract(_that);
      case TronContractValue_WithdrawExpireUnfreezeContract():
        return withdrawExpireUnfreezeContract(_that);
      case TronContractValue_DelegateResourceContract():
        return delegateResourceContract(_that);
      case TronContractValue_UnDelegateResourceContract():
        return unDelegateResourceContract(_that);
      case TronContractValue_CancelAllUnfreezeV2Contract():
        return cancelAllUnfreezeV2Contract(_that);
      case TronContractValue_TransferAssetContract():
        return transferAssetContract(_that);
      case TronContractValue_VoteWitnessContract():
        return voteWitnessContract(_that);
      case TronContractValue_AccountCreateContract():
        return accountCreateContract(_that);
      case TronContractValue_AccountUpdateContract():
        return accountUpdateContract(_that);
      case TronContractValue_AccountPermissionUpdateContract():
        return accountPermissionUpdateContract(_that);
      case TronContractValue_Unknown():
        return unknown(_that);
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
    TResult? Function(TronContractValue_TransferContract value)?
        transferContract,
    TResult? Function(TronContractValue_TriggerSmartContract value)?
        triggerSmartContract,
    TResult? Function(TronContractValue_FreezeBalanceV2Contract value)?
        freezeBalanceV2Contract,
    TResult? Function(TronContractValue_UnfreezeBalanceV2Contract value)?
        unfreezeBalanceV2Contract,
    TResult? Function(TronContractValue_WithdrawExpireUnfreezeContract value)?
        withdrawExpireUnfreezeContract,
    TResult? Function(TronContractValue_DelegateResourceContract value)?
        delegateResourceContract,
    TResult? Function(TronContractValue_UnDelegateResourceContract value)?
        unDelegateResourceContract,
    TResult? Function(TronContractValue_CancelAllUnfreezeV2Contract value)?
        cancelAllUnfreezeV2Contract,
    TResult? Function(TronContractValue_TransferAssetContract value)?
        transferAssetContract,
    TResult? Function(TronContractValue_VoteWitnessContract value)?
        voteWitnessContract,
    TResult? Function(TronContractValue_AccountCreateContract value)?
        accountCreateContract,
    TResult? Function(TronContractValue_AccountUpdateContract value)?
        accountUpdateContract,
    TResult? Function(TronContractValue_AccountPermissionUpdateContract value)?
        accountPermissionUpdateContract,
    TResult? Function(TronContractValue_Unknown value)? unknown,
  }) {
    final _that = this;
    switch (_that) {
      case TronContractValue_TransferContract() when transferContract != null:
        return transferContract(_that);
      case TronContractValue_TriggerSmartContract()
          when triggerSmartContract != null:
        return triggerSmartContract(_that);
      case TronContractValue_FreezeBalanceV2Contract()
          when freezeBalanceV2Contract != null:
        return freezeBalanceV2Contract(_that);
      case TronContractValue_UnfreezeBalanceV2Contract()
          when unfreezeBalanceV2Contract != null:
        return unfreezeBalanceV2Contract(_that);
      case TronContractValue_WithdrawExpireUnfreezeContract()
          when withdrawExpireUnfreezeContract != null:
        return withdrawExpireUnfreezeContract(_that);
      case TronContractValue_DelegateResourceContract()
          when delegateResourceContract != null:
        return delegateResourceContract(_that);
      case TronContractValue_UnDelegateResourceContract()
          when unDelegateResourceContract != null:
        return unDelegateResourceContract(_that);
      case TronContractValue_CancelAllUnfreezeV2Contract()
          when cancelAllUnfreezeV2Contract != null:
        return cancelAllUnfreezeV2Contract(_that);
      case TronContractValue_TransferAssetContract()
          when transferAssetContract != null:
        return transferAssetContract(_that);
      case TronContractValue_VoteWitnessContract()
          when voteWitnessContract != null:
        return voteWitnessContract(_that);
      case TronContractValue_AccountCreateContract()
          when accountCreateContract != null:
        return accountCreateContract(_that);
      case TronContractValue_AccountUpdateContract()
          when accountUpdateContract != null:
        return accountUpdateContract(_that);
      case TronContractValue_AccountPermissionUpdateContract()
          when accountPermissionUpdateContract != null:
        return accountPermissionUpdateContract(_that);
      case TronContractValue_Unknown() when unknown != null:
        return unknown(_that);
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
    TResult Function(
            String ownerAddress, String toAddress, PlatformInt64 amount)?
        transferContract,
    TResult Function(
            String? ownerAddress,
            String? contractAddress,
            PlatformInt64? callValue,
            String? data,
            PlatformInt64? callTokenValue,
            PlatformInt64? tokenId)?
        triggerSmartContract,
    TResult Function(
            String ownerAddress, PlatformInt64 frozenBalance, int resource)?
        freezeBalanceV2Contract,
    TResult Function(
            String ownerAddress, PlatformInt64 unfreezeBalance, int resource)?
        unfreezeBalanceV2Contract,
    TResult Function(String ownerAddress)? withdrawExpireUnfreezeContract,
    TResult Function(String ownerAddress, int resource, PlatformInt64 balance,
            String receiverAddress, bool lock, PlatformInt64 lockPeriod)?
        delegateResourceContract,
    TResult Function(String ownerAddress, int resource, PlatformInt64 balance,
            String receiverAddress)?
        unDelegateResourceContract,
    TResult Function(String ownerAddress)? cancelAllUnfreezeV2Contract,
    TResult Function(String assetName, String ownerAddress, String toAddress,
            PlatformInt64 amount)?
        transferAssetContract,
    TResult Function(
            String ownerAddress, List<TronVoteInfo> votes, bool support)?
        voteWitnessContract,
    TResult Function(String ownerAddress, String accountAddress)?
        accountCreateContract,
    TResult Function(String ownerAddress, String accountName)?
        accountUpdateContract,
    TResult Function(String ownerAddress)? accountPermissionUpdateContract,
    TResult Function(String typeUrl, String valueJson)? unknown,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case TronContractValue_TransferContract() when transferContract != null:
        return transferContract(
            _that.ownerAddress, _that.toAddress, _that.amount);
      case TronContractValue_TriggerSmartContract()
          when triggerSmartContract != null:
        return triggerSmartContract(_that.ownerAddress, _that.contractAddress,
            _that.callValue, _that.data, _that.callTokenValue, _that.tokenId);
      case TronContractValue_FreezeBalanceV2Contract()
          when freezeBalanceV2Contract != null:
        return freezeBalanceV2Contract(
            _that.ownerAddress, _that.frozenBalance, _that.resource);
      case TronContractValue_UnfreezeBalanceV2Contract()
          when unfreezeBalanceV2Contract != null:
        return unfreezeBalanceV2Contract(
            _that.ownerAddress, _that.unfreezeBalance, _that.resource);
      case TronContractValue_WithdrawExpireUnfreezeContract()
          when withdrawExpireUnfreezeContract != null:
        return withdrawExpireUnfreezeContract(_that.ownerAddress);
      case TronContractValue_DelegateResourceContract()
          when delegateResourceContract != null:
        return delegateResourceContract(_that.ownerAddress, _that.resource,
            _that.balance, _that.receiverAddress, _that.lock, _that.lockPeriod);
      case TronContractValue_UnDelegateResourceContract()
          when unDelegateResourceContract != null:
        return unDelegateResourceContract(_that.ownerAddress, _that.resource,
            _that.balance, _that.receiverAddress);
      case TronContractValue_CancelAllUnfreezeV2Contract()
          when cancelAllUnfreezeV2Contract != null:
        return cancelAllUnfreezeV2Contract(_that.ownerAddress);
      case TronContractValue_TransferAssetContract()
          when transferAssetContract != null:
        return transferAssetContract(
            _that.assetName, _that.ownerAddress, _that.toAddress, _that.amount);
      case TronContractValue_VoteWitnessContract()
          when voteWitnessContract != null:
        return voteWitnessContract(
            _that.ownerAddress, _that.votes, _that.support);
      case TronContractValue_AccountCreateContract()
          when accountCreateContract != null:
        return accountCreateContract(_that.ownerAddress, _that.accountAddress);
      case TronContractValue_AccountUpdateContract()
          when accountUpdateContract != null:
        return accountUpdateContract(_that.ownerAddress, _that.accountName);
      case TronContractValue_AccountPermissionUpdateContract()
          when accountPermissionUpdateContract != null:
        return accountPermissionUpdateContract(_that.ownerAddress);
      case TronContractValue_Unknown() when unknown != null:
        return unknown(_that.typeUrl, _that.valueJson);
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
    required TResult Function(
            String ownerAddress, String toAddress, PlatformInt64 amount)
        transferContract,
    required TResult Function(
            String? ownerAddress,
            String? contractAddress,
            PlatformInt64? callValue,
            String? data,
            PlatformInt64? callTokenValue,
            PlatformInt64? tokenId)
        triggerSmartContract,
    required TResult Function(
            String ownerAddress, PlatformInt64 frozenBalance, int resource)
        freezeBalanceV2Contract,
    required TResult Function(
            String ownerAddress, PlatformInt64 unfreezeBalance, int resource)
        unfreezeBalanceV2Contract,
    required TResult Function(String ownerAddress)
        withdrawExpireUnfreezeContract,
    required TResult Function(
            String ownerAddress,
            int resource,
            PlatformInt64 balance,
            String receiverAddress,
            bool lock,
            PlatformInt64 lockPeriod)
        delegateResourceContract,
    required TResult Function(String ownerAddress, int resource,
            PlatformInt64 balance, String receiverAddress)
        unDelegateResourceContract,
    required TResult Function(String ownerAddress) cancelAllUnfreezeV2Contract,
    required TResult Function(String assetName, String ownerAddress,
            String toAddress, PlatformInt64 amount)
        transferAssetContract,
    required TResult Function(
            String ownerAddress, List<TronVoteInfo> votes, bool support)
        voteWitnessContract,
    required TResult Function(String ownerAddress, String accountAddress)
        accountCreateContract,
    required TResult Function(String ownerAddress, String accountName)
        accountUpdateContract,
    required TResult Function(String ownerAddress)
        accountPermissionUpdateContract,
    required TResult Function(String typeUrl, String valueJson) unknown,
  }) {
    final _that = this;
    switch (_that) {
      case TronContractValue_TransferContract():
        return transferContract(
            _that.ownerAddress, _that.toAddress, _that.amount);
      case TronContractValue_TriggerSmartContract():
        return triggerSmartContract(_that.ownerAddress, _that.contractAddress,
            _that.callValue, _that.data, _that.callTokenValue, _that.tokenId);
      case TronContractValue_FreezeBalanceV2Contract():
        return freezeBalanceV2Contract(
            _that.ownerAddress, _that.frozenBalance, _that.resource);
      case TronContractValue_UnfreezeBalanceV2Contract():
        return unfreezeBalanceV2Contract(
            _that.ownerAddress, _that.unfreezeBalance, _that.resource);
      case TronContractValue_WithdrawExpireUnfreezeContract():
        return withdrawExpireUnfreezeContract(_that.ownerAddress);
      case TronContractValue_DelegateResourceContract():
        return delegateResourceContract(_that.ownerAddress, _that.resource,
            _that.balance, _that.receiverAddress, _that.lock, _that.lockPeriod);
      case TronContractValue_UnDelegateResourceContract():
        return unDelegateResourceContract(_that.ownerAddress, _that.resource,
            _that.balance, _that.receiverAddress);
      case TronContractValue_CancelAllUnfreezeV2Contract():
        return cancelAllUnfreezeV2Contract(_that.ownerAddress);
      case TronContractValue_TransferAssetContract():
        return transferAssetContract(
            _that.assetName, _that.ownerAddress, _that.toAddress, _that.amount);
      case TronContractValue_VoteWitnessContract():
        return voteWitnessContract(
            _that.ownerAddress, _that.votes, _that.support);
      case TronContractValue_AccountCreateContract():
        return accountCreateContract(_that.ownerAddress, _that.accountAddress);
      case TronContractValue_AccountUpdateContract():
        return accountUpdateContract(_that.ownerAddress, _that.accountName);
      case TronContractValue_AccountPermissionUpdateContract():
        return accountPermissionUpdateContract(_that.ownerAddress);
      case TronContractValue_Unknown():
        return unknown(_that.typeUrl, _that.valueJson);
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
    TResult? Function(
            String ownerAddress, String toAddress, PlatformInt64 amount)?
        transferContract,
    TResult? Function(
            String? ownerAddress,
            String? contractAddress,
            PlatformInt64? callValue,
            String? data,
            PlatformInt64? callTokenValue,
            PlatformInt64? tokenId)?
        triggerSmartContract,
    TResult? Function(
            String ownerAddress, PlatformInt64 frozenBalance, int resource)?
        freezeBalanceV2Contract,
    TResult? Function(
            String ownerAddress, PlatformInt64 unfreezeBalance, int resource)?
        unfreezeBalanceV2Contract,
    TResult? Function(String ownerAddress)? withdrawExpireUnfreezeContract,
    TResult? Function(String ownerAddress, int resource, PlatformInt64 balance,
            String receiverAddress, bool lock, PlatformInt64 lockPeriod)?
        delegateResourceContract,
    TResult? Function(String ownerAddress, int resource, PlatformInt64 balance,
            String receiverAddress)?
        unDelegateResourceContract,
    TResult? Function(String ownerAddress)? cancelAllUnfreezeV2Contract,
    TResult? Function(String assetName, String ownerAddress, String toAddress,
            PlatformInt64 amount)?
        transferAssetContract,
    TResult? Function(
            String ownerAddress, List<TronVoteInfo> votes, bool support)?
        voteWitnessContract,
    TResult? Function(String ownerAddress, String accountAddress)?
        accountCreateContract,
    TResult? Function(String ownerAddress, String accountName)?
        accountUpdateContract,
    TResult? Function(String ownerAddress)? accountPermissionUpdateContract,
    TResult? Function(String typeUrl, String valueJson)? unknown,
  }) {
    final _that = this;
    switch (_that) {
      case TronContractValue_TransferContract() when transferContract != null:
        return transferContract(
            _that.ownerAddress, _that.toAddress, _that.amount);
      case TronContractValue_TriggerSmartContract()
          when triggerSmartContract != null:
        return triggerSmartContract(_that.ownerAddress, _that.contractAddress,
            _that.callValue, _that.data, _that.callTokenValue, _that.tokenId);
      case TronContractValue_FreezeBalanceV2Contract()
          when freezeBalanceV2Contract != null:
        return freezeBalanceV2Contract(
            _that.ownerAddress, _that.frozenBalance, _that.resource);
      case TronContractValue_UnfreezeBalanceV2Contract()
          when unfreezeBalanceV2Contract != null:
        return unfreezeBalanceV2Contract(
            _that.ownerAddress, _that.unfreezeBalance, _that.resource);
      case TronContractValue_WithdrawExpireUnfreezeContract()
          when withdrawExpireUnfreezeContract != null:
        return withdrawExpireUnfreezeContract(_that.ownerAddress);
      case TronContractValue_DelegateResourceContract()
          when delegateResourceContract != null:
        return delegateResourceContract(_that.ownerAddress, _that.resource,
            _that.balance, _that.receiverAddress, _that.lock, _that.lockPeriod);
      case TronContractValue_UnDelegateResourceContract()
          when unDelegateResourceContract != null:
        return unDelegateResourceContract(_that.ownerAddress, _that.resource,
            _that.balance, _that.receiverAddress);
      case TronContractValue_CancelAllUnfreezeV2Contract()
          when cancelAllUnfreezeV2Contract != null:
        return cancelAllUnfreezeV2Contract(_that.ownerAddress);
      case TronContractValue_TransferAssetContract()
          when transferAssetContract != null:
        return transferAssetContract(
            _that.assetName, _that.ownerAddress, _that.toAddress, _that.amount);
      case TronContractValue_VoteWitnessContract()
          when voteWitnessContract != null:
        return voteWitnessContract(
            _that.ownerAddress, _that.votes, _that.support);
      case TronContractValue_AccountCreateContract()
          when accountCreateContract != null:
        return accountCreateContract(_that.ownerAddress, _that.accountAddress);
      case TronContractValue_AccountUpdateContract()
          when accountUpdateContract != null:
        return accountUpdateContract(_that.ownerAddress, _that.accountName);
      case TronContractValue_AccountPermissionUpdateContract()
          when accountPermissionUpdateContract != null:
        return accountPermissionUpdateContract(_that.ownerAddress);
      case TronContractValue_Unknown() when unknown != null:
        return unknown(_that.typeUrl, _that.valueJson);
      case _:
        return null;
    }
  }
}

/// @nodoc

class TronContractValue_TransferContract extends TronContractValue {
  const TronContractValue_TransferContract(
      {required this.ownerAddress,
      required this.toAddress,
      required this.amount})
      : super._();

  final String ownerAddress;
  final String toAddress;
  final PlatformInt64 amount;

  /// Create a copy of TronContractValue
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $TronContractValue_TransferContractCopyWith<
          TronContractValue_TransferContract>
      get copyWith => _$TronContractValue_TransferContractCopyWithImpl<
          TronContractValue_TransferContract>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is TronContractValue_TransferContract &&
            (identical(other.ownerAddress, ownerAddress) ||
                other.ownerAddress == ownerAddress) &&
            (identical(other.toAddress, toAddress) ||
                other.toAddress == toAddress) &&
            (identical(other.amount, amount) || other.amount == amount));
  }

  @override
  int get hashCode => Object.hash(runtimeType, ownerAddress, toAddress, amount);

  @override
  String toString() {
    return 'TronContractValue.transferContract(ownerAddress: $ownerAddress, toAddress: $toAddress, amount: $amount)';
  }
}

/// @nodoc
abstract mixin class $TronContractValue_TransferContractCopyWith<$Res>
    implements $TronContractValueCopyWith<$Res> {
  factory $TronContractValue_TransferContractCopyWith(
          TronContractValue_TransferContract value,
          $Res Function(TronContractValue_TransferContract) _then) =
      _$TronContractValue_TransferContractCopyWithImpl;
  @useResult
  $Res call({String ownerAddress, String toAddress, PlatformInt64 amount});
}

/// @nodoc
class _$TronContractValue_TransferContractCopyWithImpl<$Res>
    implements $TronContractValue_TransferContractCopyWith<$Res> {
  _$TronContractValue_TransferContractCopyWithImpl(this._self, this._then);

  final TronContractValue_TransferContract _self;
  final $Res Function(TronContractValue_TransferContract) _then;

  /// Create a copy of TronContractValue
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? ownerAddress = null,
    Object? toAddress = null,
    Object? amount = null,
  }) {
    return _then(TronContractValue_TransferContract(
      ownerAddress: null == ownerAddress
          ? _self.ownerAddress
          : ownerAddress // ignore: cast_nullable_to_non_nullable
              as String,
      toAddress: null == toAddress
          ? _self.toAddress
          : toAddress // ignore: cast_nullable_to_non_nullable
              as String,
      amount: null == amount
          ? _self.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as PlatformInt64,
    ));
  }
}

/// @nodoc

class TronContractValue_TriggerSmartContract extends TronContractValue {
  const TronContractValue_TriggerSmartContract(
      {this.ownerAddress,
      this.contractAddress,
      this.callValue,
      this.data,
      this.callTokenValue,
      this.tokenId})
      : super._();

  final String? ownerAddress;
  final String? contractAddress;
  final PlatformInt64? callValue;
  final String? data;
  final PlatformInt64? callTokenValue;
  final PlatformInt64? tokenId;

  /// Create a copy of TronContractValue
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $TronContractValue_TriggerSmartContractCopyWith<
          TronContractValue_TriggerSmartContract>
      get copyWith => _$TronContractValue_TriggerSmartContractCopyWithImpl<
          TronContractValue_TriggerSmartContract>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is TronContractValue_TriggerSmartContract &&
            (identical(other.ownerAddress, ownerAddress) ||
                other.ownerAddress == ownerAddress) &&
            (identical(other.contractAddress, contractAddress) ||
                other.contractAddress == contractAddress) &&
            (identical(other.callValue, callValue) ||
                other.callValue == callValue) &&
            (identical(other.data, data) || other.data == data) &&
            (identical(other.callTokenValue, callTokenValue) ||
                other.callTokenValue == callTokenValue) &&
            (identical(other.tokenId, tokenId) || other.tokenId == tokenId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, ownerAddress, contractAddress,
      callValue, data, callTokenValue, tokenId);

  @override
  String toString() {
    return 'TronContractValue.triggerSmartContract(ownerAddress: $ownerAddress, contractAddress: $contractAddress, callValue: $callValue, data: $data, callTokenValue: $callTokenValue, tokenId: $tokenId)';
  }
}

/// @nodoc
abstract mixin class $TronContractValue_TriggerSmartContractCopyWith<$Res>
    implements $TronContractValueCopyWith<$Res> {
  factory $TronContractValue_TriggerSmartContractCopyWith(
          TronContractValue_TriggerSmartContract value,
          $Res Function(TronContractValue_TriggerSmartContract) _then) =
      _$TronContractValue_TriggerSmartContractCopyWithImpl;
  @useResult
  $Res call(
      {String? ownerAddress,
      String? contractAddress,
      PlatformInt64? callValue,
      String? data,
      PlatformInt64? callTokenValue,
      PlatformInt64? tokenId});
}

/// @nodoc
class _$TronContractValue_TriggerSmartContractCopyWithImpl<$Res>
    implements $TronContractValue_TriggerSmartContractCopyWith<$Res> {
  _$TronContractValue_TriggerSmartContractCopyWithImpl(this._self, this._then);

  final TronContractValue_TriggerSmartContract _self;
  final $Res Function(TronContractValue_TriggerSmartContract) _then;

  /// Create a copy of TronContractValue
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? ownerAddress = freezed,
    Object? contractAddress = freezed,
    Object? callValue = freezed,
    Object? data = freezed,
    Object? callTokenValue = freezed,
    Object? tokenId = freezed,
  }) {
    return _then(TronContractValue_TriggerSmartContract(
      ownerAddress: freezed == ownerAddress
          ? _self.ownerAddress
          : ownerAddress // ignore: cast_nullable_to_non_nullable
              as String?,
      contractAddress: freezed == contractAddress
          ? _self.contractAddress
          : contractAddress // ignore: cast_nullable_to_non_nullable
              as String?,
      callValue: freezed == callValue
          ? _self.callValue
          : callValue // ignore: cast_nullable_to_non_nullable
              as PlatformInt64?,
      data: freezed == data
          ? _self.data
          : data // ignore: cast_nullable_to_non_nullable
              as String?,
      callTokenValue: freezed == callTokenValue
          ? _self.callTokenValue
          : callTokenValue // ignore: cast_nullable_to_non_nullable
              as PlatformInt64?,
      tokenId: freezed == tokenId
          ? _self.tokenId
          : tokenId // ignore: cast_nullable_to_non_nullable
              as PlatformInt64?,
    ));
  }
}

/// @nodoc

class TronContractValue_FreezeBalanceV2Contract extends TronContractValue {
  const TronContractValue_FreezeBalanceV2Contract(
      {required this.ownerAddress,
      required this.frozenBalance,
      required this.resource})
      : super._();

  final String ownerAddress;
  final PlatformInt64 frozenBalance;
  final int resource;

  /// Create a copy of TronContractValue
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $TronContractValue_FreezeBalanceV2ContractCopyWith<
          TronContractValue_FreezeBalanceV2Contract>
      get copyWith => _$TronContractValue_FreezeBalanceV2ContractCopyWithImpl<
          TronContractValue_FreezeBalanceV2Contract>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is TronContractValue_FreezeBalanceV2Contract &&
            (identical(other.ownerAddress, ownerAddress) ||
                other.ownerAddress == ownerAddress) &&
            (identical(other.frozenBalance, frozenBalance) ||
                other.frozenBalance == frozenBalance) &&
            (identical(other.resource, resource) ||
                other.resource == resource));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, ownerAddress, frozenBalance, resource);

  @override
  String toString() {
    return 'TronContractValue.freezeBalanceV2Contract(ownerAddress: $ownerAddress, frozenBalance: $frozenBalance, resource: $resource)';
  }
}

/// @nodoc
abstract mixin class $TronContractValue_FreezeBalanceV2ContractCopyWith<$Res>
    implements $TronContractValueCopyWith<$Res> {
  factory $TronContractValue_FreezeBalanceV2ContractCopyWith(
          TronContractValue_FreezeBalanceV2Contract value,
          $Res Function(TronContractValue_FreezeBalanceV2Contract) _then) =
      _$TronContractValue_FreezeBalanceV2ContractCopyWithImpl;
  @useResult
  $Res call({String ownerAddress, PlatformInt64 frozenBalance, int resource});
}

/// @nodoc
class _$TronContractValue_FreezeBalanceV2ContractCopyWithImpl<$Res>
    implements $TronContractValue_FreezeBalanceV2ContractCopyWith<$Res> {
  _$TronContractValue_FreezeBalanceV2ContractCopyWithImpl(
      this._self, this._then);

  final TronContractValue_FreezeBalanceV2Contract _self;
  final $Res Function(TronContractValue_FreezeBalanceV2Contract) _then;

  /// Create a copy of TronContractValue
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? ownerAddress = null,
    Object? frozenBalance = null,
    Object? resource = null,
  }) {
    return _then(TronContractValue_FreezeBalanceV2Contract(
      ownerAddress: null == ownerAddress
          ? _self.ownerAddress
          : ownerAddress // ignore: cast_nullable_to_non_nullable
              as String,
      frozenBalance: null == frozenBalance
          ? _self.frozenBalance
          : frozenBalance // ignore: cast_nullable_to_non_nullable
              as PlatformInt64,
      resource: null == resource
          ? _self.resource
          : resource // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

class TronContractValue_UnfreezeBalanceV2Contract extends TronContractValue {
  const TronContractValue_UnfreezeBalanceV2Contract(
      {required this.ownerAddress,
      required this.unfreezeBalance,
      required this.resource})
      : super._();

  final String ownerAddress;
  final PlatformInt64 unfreezeBalance;
  final int resource;

  /// Create a copy of TronContractValue
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $TronContractValue_UnfreezeBalanceV2ContractCopyWith<
          TronContractValue_UnfreezeBalanceV2Contract>
      get copyWith => _$TronContractValue_UnfreezeBalanceV2ContractCopyWithImpl<
          TronContractValue_UnfreezeBalanceV2Contract>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is TronContractValue_UnfreezeBalanceV2Contract &&
            (identical(other.ownerAddress, ownerAddress) ||
                other.ownerAddress == ownerAddress) &&
            (identical(other.unfreezeBalance, unfreezeBalance) ||
                other.unfreezeBalance == unfreezeBalance) &&
            (identical(other.resource, resource) ||
                other.resource == resource));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, ownerAddress, unfreezeBalance, resource);

  @override
  String toString() {
    return 'TronContractValue.unfreezeBalanceV2Contract(ownerAddress: $ownerAddress, unfreezeBalance: $unfreezeBalance, resource: $resource)';
  }
}

/// @nodoc
abstract mixin class $TronContractValue_UnfreezeBalanceV2ContractCopyWith<$Res>
    implements $TronContractValueCopyWith<$Res> {
  factory $TronContractValue_UnfreezeBalanceV2ContractCopyWith(
          TronContractValue_UnfreezeBalanceV2Contract value,
          $Res Function(TronContractValue_UnfreezeBalanceV2Contract) _then) =
      _$TronContractValue_UnfreezeBalanceV2ContractCopyWithImpl;
  @useResult
  $Res call({String ownerAddress, PlatformInt64 unfreezeBalance, int resource});
}

/// @nodoc
class _$TronContractValue_UnfreezeBalanceV2ContractCopyWithImpl<$Res>
    implements $TronContractValue_UnfreezeBalanceV2ContractCopyWith<$Res> {
  _$TronContractValue_UnfreezeBalanceV2ContractCopyWithImpl(
      this._self, this._then);

  final TronContractValue_UnfreezeBalanceV2Contract _self;
  final $Res Function(TronContractValue_UnfreezeBalanceV2Contract) _then;

  /// Create a copy of TronContractValue
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? ownerAddress = null,
    Object? unfreezeBalance = null,
    Object? resource = null,
  }) {
    return _then(TronContractValue_UnfreezeBalanceV2Contract(
      ownerAddress: null == ownerAddress
          ? _self.ownerAddress
          : ownerAddress // ignore: cast_nullable_to_non_nullable
              as String,
      unfreezeBalance: null == unfreezeBalance
          ? _self.unfreezeBalance
          : unfreezeBalance // ignore: cast_nullable_to_non_nullable
              as PlatformInt64,
      resource: null == resource
          ? _self.resource
          : resource // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

class TronContractValue_WithdrawExpireUnfreezeContract
    extends TronContractValue {
  const TronContractValue_WithdrawExpireUnfreezeContract(
      {required this.ownerAddress})
      : super._();

  final String ownerAddress;

  /// Create a copy of TronContractValue
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $TronContractValue_WithdrawExpireUnfreezeContractCopyWith<
          TronContractValue_WithdrawExpireUnfreezeContract>
      get copyWith =>
          _$TronContractValue_WithdrawExpireUnfreezeContractCopyWithImpl<
                  TronContractValue_WithdrawExpireUnfreezeContract>(
              this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is TronContractValue_WithdrawExpireUnfreezeContract &&
            (identical(other.ownerAddress, ownerAddress) ||
                other.ownerAddress == ownerAddress));
  }

  @override
  int get hashCode => Object.hash(runtimeType, ownerAddress);

  @override
  String toString() {
    return 'TronContractValue.withdrawExpireUnfreezeContract(ownerAddress: $ownerAddress)';
  }
}

/// @nodoc
abstract mixin class $TronContractValue_WithdrawExpireUnfreezeContractCopyWith<
    $Res> implements $TronContractValueCopyWith<$Res> {
  factory $TronContractValue_WithdrawExpireUnfreezeContractCopyWith(
          TronContractValue_WithdrawExpireUnfreezeContract value,
          $Res Function(TronContractValue_WithdrawExpireUnfreezeContract)
              _then) =
      _$TronContractValue_WithdrawExpireUnfreezeContractCopyWithImpl;
  @useResult
  $Res call({String ownerAddress});
}

/// @nodoc
class _$TronContractValue_WithdrawExpireUnfreezeContractCopyWithImpl<$Res>
    implements $TronContractValue_WithdrawExpireUnfreezeContractCopyWith<$Res> {
  _$TronContractValue_WithdrawExpireUnfreezeContractCopyWithImpl(
      this._self, this._then);

  final TronContractValue_WithdrawExpireUnfreezeContract _self;
  final $Res Function(TronContractValue_WithdrawExpireUnfreezeContract) _then;

  /// Create a copy of TronContractValue
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? ownerAddress = null,
  }) {
    return _then(TronContractValue_WithdrawExpireUnfreezeContract(
      ownerAddress: null == ownerAddress
          ? _self.ownerAddress
          : ownerAddress // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class TronContractValue_DelegateResourceContract extends TronContractValue {
  const TronContractValue_DelegateResourceContract(
      {required this.ownerAddress,
      required this.resource,
      required this.balance,
      required this.receiverAddress,
      required this.lock,
      required this.lockPeriod})
      : super._();

  final String ownerAddress;
  final int resource;
  final PlatformInt64 balance;
  final String receiverAddress;
  final bool lock;
  final PlatformInt64 lockPeriod;

  /// Create a copy of TronContractValue
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $TronContractValue_DelegateResourceContractCopyWith<
          TronContractValue_DelegateResourceContract>
      get copyWith => _$TronContractValue_DelegateResourceContractCopyWithImpl<
          TronContractValue_DelegateResourceContract>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is TronContractValue_DelegateResourceContract &&
            (identical(other.ownerAddress, ownerAddress) ||
                other.ownerAddress == ownerAddress) &&
            (identical(other.resource, resource) ||
                other.resource == resource) &&
            (identical(other.balance, balance) || other.balance == balance) &&
            (identical(other.receiverAddress, receiverAddress) ||
                other.receiverAddress == receiverAddress) &&
            (identical(other.lock, lock) || other.lock == lock) &&
            (identical(other.lockPeriod, lockPeriod) ||
                other.lockPeriod == lockPeriod));
  }

  @override
  int get hashCode => Object.hash(runtimeType, ownerAddress, resource, balance,
      receiverAddress, lock, lockPeriod);

  @override
  String toString() {
    return 'TronContractValue.delegateResourceContract(ownerAddress: $ownerAddress, resource: $resource, balance: $balance, receiverAddress: $receiverAddress, lock: $lock, lockPeriod: $lockPeriod)';
  }
}

/// @nodoc
abstract mixin class $TronContractValue_DelegateResourceContractCopyWith<$Res>
    implements $TronContractValueCopyWith<$Res> {
  factory $TronContractValue_DelegateResourceContractCopyWith(
          TronContractValue_DelegateResourceContract value,
          $Res Function(TronContractValue_DelegateResourceContract) _then) =
      _$TronContractValue_DelegateResourceContractCopyWithImpl;
  @useResult
  $Res call(
      {String ownerAddress,
      int resource,
      PlatformInt64 balance,
      String receiverAddress,
      bool lock,
      PlatformInt64 lockPeriod});
}

/// @nodoc
class _$TronContractValue_DelegateResourceContractCopyWithImpl<$Res>
    implements $TronContractValue_DelegateResourceContractCopyWith<$Res> {
  _$TronContractValue_DelegateResourceContractCopyWithImpl(
      this._self, this._then);

  final TronContractValue_DelegateResourceContract _self;
  final $Res Function(TronContractValue_DelegateResourceContract) _then;

  /// Create a copy of TronContractValue
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? ownerAddress = null,
    Object? resource = null,
    Object? balance = null,
    Object? receiverAddress = null,
    Object? lock = null,
    Object? lockPeriod = null,
  }) {
    return _then(TronContractValue_DelegateResourceContract(
      ownerAddress: null == ownerAddress
          ? _self.ownerAddress
          : ownerAddress // ignore: cast_nullable_to_non_nullable
              as String,
      resource: null == resource
          ? _self.resource
          : resource // ignore: cast_nullable_to_non_nullable
              as int,
      balance: null == balance
          ? _self.balance
          : balance // ignore: cast_nullable_to_non_nullable
              as PlatformInt64,
      receiverAddress: null == receiverAddress
          ? _self.receiverAddress
          : receiverAddress // ignore: cast_nullable_to_non_nullable
              as String,
      lock: null == lock
          ? _self.lock
          : lock // ignore: cast_nullable_to_non_nullable
              as bool,
      lockPeriod: null == lockPeriod
          ? _self.lockPeriod
          : lockPeriod // ignore: cast_nullable_to_non_nullable
              as PlatformInt64,
    ));
  }
}

/// @nodoc

class TronContractValue_UnDelegateResourceContract extends TronContractValue {
  const TronContractValue_UnDelegateResourceContract(
      {required this.ownerAddress,
      required this.resource,
      required this.balance,
      required this.receiverAddress})
      : super._();

  final String ownerAddress;
  final int resource;
  final PlatformInt64 balance;
  final String receiverAddress;

  /// Create a copy of TronContractValue
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $TronContractValue_UnDelegateResourceContractCopyWith<
          TronContractValue_UnDelegateResourceContract>
      get copyWith =>
          _$TronContractValue_UnDelegateResourceContractCopyWithImpl<
              TronContractValue_UnDelegateResourceContract>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is TronContractValue_UnDelegateResourceContract &&
            (identical(other.ownerAddress, ownerAddress) ||
                other.ownerAddress == ownerAddress) &&
            (identical(other.resource, resource) ||
                other.resource == resource) &&
            (identical(other.balance, balance) || other.balance == balance) &&
            (identical(other.receiverAddress, receiverAddress) ||
                other.receiverAddress == receiverAddress));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, ownerAddress, resource, balance, receiverAddress);

  @override
  String toString() {
    return 'TronContractValue.unDelegateResourceContract(ownerAddress: $ownerAddress, resource: $resource, balance: $balance, receiverAddress: $receiverAddress)';
  }
}

/// @nodoc
abstract mixin class $TronContractValue_UnDelegateResourceContractCopyWith<$Res>
    implements $TronContractValueCopyWith<$Res> {
  factory $TronContractValue_UnDelegateResourceContractCopyWith(
          TronContractValue_UnDelegateResourceContract value,
          $Res Function(TronContractValue_UnDelegateResourceContract) _then) =
      _$TronContractValue_UnDelegateResourceContractCopyWithImpl;
  @useResult
  $Res call(
      {String ownerAddress,
      int resource,
      PlatformInt64 balance,
      String receiverAddress});
}

/// @nodoc
class _$TronContractValue_UnDelegateResourceContractCopyWithImpl<$Res>
    implements $TronContractValue_UnDelegateResourceContractCopyWith<$Res> {
  _$TronContractValue_UnDelegateResourceContractCopyWithImpl(
      this._self, this._then);

  final TronContractValue_UnDelegateResourceContract _self;
  final $Res Function(TronContractValue_UnDelegateResourceContract) _then;

  /// Create a copy of TronContractValue
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? ownerAddress = null,
    Object? resource = null,
    Object? balance = null,
    Object? receiverAddress = null,
  }) {
    return _then(TronContractValue_UnDelegateResourceContract(
      ownerAddress: null == ownerAddress
          ? _self.ownerAddress
          : ownerAddress // ignore: cast_nullable_to_non_nullable
              as String,
      resource: null == resource
          ? _self.resource
          : resource // ignore: cast_nullable_to_non_nullable
              as int,
      balance: null == balance
          ? _self.balance
          : balance // ignore: cast_nullable_to_non_nullable
              as PlatformInt64,
      receiverAddress: null == receiverAddress
          ? _self.receiverAddress
          : receiverAddress // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class TronContractValue_CancelAllUnfreezeV2Contract extends TronContractValue {
  const TronContractValue_CancelAllUnfreezeV2Contract(
      {required this.ownerAddress})
      : super._();

  final String ownerAddress;

  /// Create a copy of TronContractValue
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $TronContractValue_CancelAllUnfreezeV2ContractCopyWith<
          TronContractValue_CancelAllUnfreezeV2Contract>
      get copyWith =>
          _$TronContractValue_CancelAllUnfreezeV2ContractCopyWithImpl<
              TronContractValue_CancelAllUnfreezeV2Contract>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is TronContractValue_CancelAllUnfreezeV2Contract &&
            (identical(other.ownerAddress, ownerAddress) ||
                other.ownerAddress == ownerAddress));
  }

  @override
  int get hashCode => Object.hash(runtimeType, ownerAddress);

  @override
  String toString() {
    return 'TronContractValue.cancelAllUnfreezeV2Contract(ownerAddress: $ownerAddress)';
  }
}

/// @nodoc
abstract mixin class $TronContractValue_CancelAllUnfreezeV2ContractCopyWith<
    $Res> implements $TronContractValueCopyWith<$Res> {
  factory $TronContractValue_CancelAllUnfreezeV2ContractCopyWith(
          TronContractValue_CancelAllUnfreezeV2Contract value,
          $Res Function(TronContractValue_CancelAllUnfreezeV2Contract) _then) =
      _$TronContractValue_CancelAllUnfreezeV2ContractCopyWithImpl;
  @useResult
  $Res call({String ownerAddress});
}

/// @nodoc
class _$TronContractValue_CancelAllUnfreezeV2ContractCopyWithImpl<$Res>
    implements $TronContractValue_CancelAllUnfreezeV2ContractCopyWith<$Res> {
  _$TronContractValue_CancelAllUnfreezeV2ContractCopyWithImpl(
      this._self, this._then);

  final TronContractValue_CancelAllUnfreezeV2Contract _self;
  final $Res Function(TronContractValue_CancelAllUnfreezeV2Contract) _then;

  /// Create a copy of TronContractValue
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? ownerAddress = null,
  }) {
    return _then(TronContractValue_CancelAllUnfreezeV2Contract(
      ownerAddress: null == ownerAddress
          ? _self.ownerAddress
          : ownerAddress // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class TronContractValue_TransferAssetContract extends TronContractValue {
  const TronContractValue_TransferAssetContract(
      {required this.assetName,
      required this.ownerAddress,
      required this.toAddress,
      required this.amount})
      : super._();

  final String assetName;
  final String ownerAddress;
  final String toAddress;
  final PlatformInt64 amount;

  /// Create a copy of TronContractValue
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $TronContractValue_TransferAssetContractCopyWith<
          TronContractValue_TransferAssetContract>
      get copyWith => _$TronContractValue_TransferAssetContractCopyWithImpl<
          TronContractValue_TransferAssetContract>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is TronContractValue_TransferAssetContract &&
            (identical(other.assetName, assetName) ||
                other.assetName == assetName) &&
            (identical(other.ownerAddress, ownerAddress) ||
                other.ownerAddress == ownerAddress) &&
            (identical(other.toAddress, toAddress) ||
                other.toAddress == toAddress) &&
            (identical(other.amount, amount) || other.amount == amount));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, assetName, ownerAddress, toAddress, amount);

  @override
  String toString() {
    return 'TronContractValue.transferAssetContract(assetName: $assetName, ownerAddress: $ownerAddress, toAddress: $toAddress, amount: $amount)';
  }
}

/// @nodoc
abstract mixin class $TronContractValue_TransferAssetContractCopyWith<$Res>
    implements $TronContractValueCopyWith<$Res> {
  factory $TronContractValue_TransferAssetContractCopyWith(
          TronContractValue_TransferAssetContract value,
          $Res Function(TronContractValue_TransferAssetContract) _then) =
      _$TronContractValue_TransferAssetContractCopyWithImpl;
  @useResult
  $Res call(
      {String assetName,
      String ownerAddress,
      String toAddress,
      PlatformInt64 amount});
}

/// @nodoc
class _$TronContractValue_TransferAssetContractCopyWithImpl<$Res>
    implements $TronContractValue_TransferAssetContractCopyWith<$Res> {
  _$TronContractValue_TransferAssetContractCopyWithImpl(this._self, this._then);

  final TronContractValue_TransferAssetContract _self;
  final $Res Function(TronContractValue_TransferAssetContract) _then;

  /// Create a copy of TronContractValue
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? assetName = null,
    Object? ownerAddress = null,
    Object? toAddress = null,
    Object? amount = null,
  }) {
    return _then(TronContractValue_TransferAssetContract(
      assetName: null == assetName
          ? _self.assetName
          : assetName // ignore: cast_nullable_to_non_nullable
              as String,
      ownerAddress: null == ownerAddress
          ? _self.ownerAddress
          : ownerAddress // ignore: cast_nullable_to_non_nullable
              as String,
      toAddress: null == toAddress
          ? _self.toAddress
          : toAddress // ignore: cast_nullable_to_non_nullable
              as String,
      amount: null == amount
          ? _self.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as PlatformInt64,
    ));
  }
}

/// @nodoc

class TronContractValue_VoteWitnessContract extends TronContractValue {
  const TronContractValue_VoteWitnessContract(
      {required this.ownerAddress,
      required final List<TronVoteInfo> votes,
      required this.support})
      : _votes = votes,
        super._();

  final String ownerAddress;
  final List<TronVoteInfo> _votes;
  List<TronVoteInfo> get votes {
    if (_votes is EqualUnmodifiableListView) return _votes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_votes);
  }

  final bool support;

  /// Create a copy of TronContractValue
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $TronContractValue_VoteWitnessContractCopyWith<
          TronContractValue_VoteWitnessContract>
      get copyWith => _$TronContractValue_VoteWitnessContractCopyWithImpl<
          TronContractValue_VoteWitnessContract>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is TronContractValue_VoteWitnessContract &&
            (identical(other.ownerAddress, ownerAddress) ||
                other.ownerAddress == ownerAddress) &&
            const DeepCollectionEquality().equals(other._votes, _votes) &&
            (identical(other.support, support) || other.support == support));
  }

  @override
  int get hashCode => Object.hash(runtimeType, ownerAddress,
      const DeepCollectionEquality().hash(_votes), support);

  @override
  String toString() {
    return 'TronContractValue.voteWitnessContract(ownerAddress: $ownerAddress, votes: $votes, support: $support)';
  }
}

/// @nodoc
abstract mixin class $TronContractValue_VoteWitnessContractCopyWith<$Res>
    implements $TronContractValueCopyWith<$Res> {
  factory $TronContractValue_VoteWitnessContractCopyWith(
          TronContractValue_VoteWitnessContract value,
          $Res Function(TronContractValue_VoteWitnessContract) _then) =
      _$TronContractValue_VoteWitnessContractCopyWithImpl;
  @useResult
  $Res call({String ownerAddress, List<TronVoteInfo> votes, bool support});
}

/// @nodoc
class _$TronContractValue_VoteWitnessContractCopyWithImpl<$Res>
    implements $TronContractValue_VoteWitnessContractCopyWith<$Res> {
  _$TronContractValue_VoteWitnessContractCopyWithImpl(this._self, this._then);

  final TronContractValue_VoteWitnessContract _self;
  final $Res Function(TronContractValue_VoteWitnessContract) _then;

  /// Create a copy of TronContractValue
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? ownerAddress = null,
    Object? votes = null,
    Object? support = null,
  }) {
    return _then(TronContractValue_VoteWitnessContract(
      ownerAddress: null == ownerAddress
          ? _self.ownerAddress
          : ownerAddress // ignore: cast_nullable_to_non_nullable
              as String,
      votes: null == votes
          ? _self._votes
          : votes // ignore: cast_nullable_to_non_nullable
              as List<TronVoteInfo>,
      support: null == support
          ? _self.support
          : support // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class TronContractValue_AccountCreateContract extends TronContractValue {
  const TronContractValue_AccountCreateContract(
      {required this.ownerAddress, required this.accountAddress})
      : super._();

  final String ownerAddress;
  final String accountAddress;

  /// Create a copy of TronContractValue
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $TronContractValue_AccountCreateContractCopyWith<
          TronContractValue_AccountCreateContract>
      get copyWith => _$TronContractValue_AccountCreateContractCopyWithImpl<
          TronContractValue_AccountCreateContract>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is TronContractValue_AccountCreateContract &&
            (identical(other.ownerAddress, ownerAddress) ||
                other.ownerAddress == ownerAddress) &&
            (identical(other.accountAddress, accountAddress) ||
                other.accountAddress == accountAddress));
  }

  @override
  int get hashCode => Object.hash(runtimeType, ownerAddress, accountAddress);

  @override
  String toString() {
    return 'TronContractValue.accountCreateContract(ownerAddress: $ownerAddress, accountAddress: $accountAddress)';
  }
}

/// @nodoc
abstract mixin class $TronContractValue_AccountCreateContractCopyWith<$Res>
    implements $TronContractValueCopyWith<$Res> {
  factory $TronContractValue_AccountCreateContractCopyWith(
          TronContractValue_AccountCreateContract value,
          $Res Function(TronContractValue_AccountCreateContract) _then) =
      _$TronContractValue_AccountCreateContractCopyWithImpl;
  @useResult
  $Res call({String ownerAddress, String accountAddress});
}

/// @nodoc
class _$TronContractValue_AccountCreateContractCopyWithImpl<$Res>
    implements $TronContractValue_AccountCreateContractCopyWith<$Res> {
  _$TronContractValue_AccountCreateContractCopyWithImpl(this._self, this._then);

  final TronContractValue_AccountCreateContract _self;
  final $Res Function(TronContractValue_AccountCreateContract) _then;

  /// Create a copy of TronContractValue
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? ownerAddress = null,
    Object? accountAddress = null,
  }) {
    return _then(TronContractValue_AccountCreateContract(
      ownerAddress: null == ownerAddress
          ? _self.ownerAddress
          : ownerAddress // ignore: cast_nullable_to_non_nullable
              as String,
      accountAddress: null == accountAddress
          ? _self.accountAddress
          : accountAddress // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class TronContractValue_AccountUpdateContract extends TronContractValue {
  const TronContractValue_AccountUpdateContract(
      {required this.ownerAddress, required this.accountName})
      : super._();

  final String ownerAddress;
  final String accountName;

  /// Create a copy of TronContractValue
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $TronContractValue_AccountUpdateContractCopyWith<
          TronContractValue_AccountUpdateContract>
      get copyWith => _$TronContractValue_AccountUpdateContractCopyWithImpl<
          TronContractValue_AccountUpdateContract>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is TronContractValue_AccountUpdateContract &&
            (identical(other.ownerAddress, ownerAddress) ||
                other.ownerAddress == ownerAddress) &&
            (identical(other.accountName, accountName) ||
                other.accountName == accountName));
  }

  @override
  int get hashCode => Object.hash(runtimeType, ownerAddress, accountName);

  @override
  String toString() {
    return 'TronContractValue.accountUpdateContract(ownerAddress: $ownerAddress, accountName: $accountName)';
  }
}

/// @nodoc
abstract mixin class $TronContractValue_AccountUpdateContractCopyWith<$Res>
    implements $TronContractValueCopyWith<$Res> {
  factory $TronContractValue_AccountUpdateContractCopyWith(
          TronContractValue_AccountUpdateContract value,
          $Res Function(TronContractValue_AccountUpdateContract) _then) =
      _$TronContractValue_AccountUpdateContractCopyWithImpl;
  @useResult
  $Res call({String ownerAddress, String accountName});
}

/// @nodoc
class _$TronContractValue_AccountUpdateContractCopyWithImpl<$Res>
    implements $TronContractValue_AccountUpdateContractCopyWith<$Res> {
  _$TronContractValue_AccountUpdateContractCopyWithImpl(this._self, this._then);

  final TronContractValue_AccountUpdateContract _self;
  final $Res Function(TronContractValue_AccountUpdateContract) _then;

  /// Create a copy of TronContractValue
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? ownerAddress = null,
    Object? accountName = null,
  }) {
    return _then(TronContractValue_AccountUpdateContract(
      ownerAddress: null == ownerAddress
          ? _self.ownerAddress
          : ownerAddress // ignore: cast_nullable_to_non_nullable
              as String,
      accountName: null == accountName
          ? _self.accountName
          : accountName // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class TronContractValue_AccountPermissionUpdateContract
    extends TronContractValue {
  const TronContractValue_AccountPermissionUpdateContract(
      {required this.ownerAddress})
      : super._();

  final String ownerAddress;

  /// Create a copy of TronContractValue
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $TronContractValue_AccountPermissionUpdateContractCopyWith<
          TronContractValue_AccountPermissionUpdateContract>
      get copyWith =>
          _$TronContractValue_AccountPermissionUpdateContractCopyWithImpl<
                  TronContractValue_AccountPermissionUpdateContract>(
              this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is TronContractValue_AccountPermissionUpdateContract &&
            (identical(other.ownerAddress, ownerAddress) ||
                other.ownerAddress == ownerAddress));
  }

  @override
  int get hashCode => Object.hash(runtimeType, ownerAddress);

  @override
  String toString() {
    return 'TronContractValue.accountPermissionUpdateContract(ownerAddress: $ownerAddress)';
  }
}

/// @nodoc
abstract mixin class $TronContractValue_AccountPermissionUpdateContractCopyWith<
    $Res> implements $TronContractValueCopyWith<$Res> {
  factory $TronContractValue_AccountPermissionUpdateContractCopyWith(
          TronContractValue_AccountPermissionUpdateContract value,
          $Res Function(TronContractValue_AccountPermissionUpdateContract)
              _then) =
      _$TronContractValue_AccountPermissionUpdateContractCopyWithImpl;
  @useResult
  $Res call({String ownerAddress});
}

/// @nodoc
class _$TronContractValue_AccountPermissionUpdateContractCopyWithImpl<$Res>
    implements
        $TronContractValue_AccountPermissionUpdateContractCopyWith<$Res> {
  _$TronContractValue_AccountPermissionUpdateContractCopyWithImpl(
      this._self, this._then);

  final TronContractValue_AccountPermissionUpdateContract _self;
  final $Res Function(TronContractValue_AccountPermissionUpdateContract) _then;

  /// Create a copy of TronContractValue
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? ownerAddress = null,
  }) {
    return _then(TronContractValue_AccountPermissionUpdateContract(
      ownerAddress: null == ownerAddress
          ? _self.ownerAddress
          : ownerAddress // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class TronContractValue_Unknown extends TronContractValue {
  const TronContractValue_Unknown(
      {required this.typeUrl, required this.valueJson})
      : super._();

  final String typeUrl;
  final String valueJson;

  /// Create a copy of TronContractValue
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $TronContractValue_UnknownCopyWith<TronContractValue_Unknown> get copyWith =>
      _$TronContractValue_UnknownCopyWithImpl<TronContractValue_Unknown>(
          this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is TronContractValue_Unknown &&
            (identical(other.typeUrl, typeUrl) || other.typeUrl == typeUrl) &&
            (identical(other.valueJson, valueJson) ||
                other.valueJson == valueJson));
  }

  @override
  int get hashCode => Object.hash(runtimeType, typeUrl, valueJson);

  @override
  String toString() {
    return 'TronContractValue.unknown(typeUrl: $typeUrl, valueJson: $valueJson)';
  }
}

/// @nodoc
abstract mixin class $TronContractValue_UnknownCopyWith<$Res>
    implements $TronContractValueCopyWith<$Res> {
  factory $TronContractValue_UnknownCopyWith(TronContractValue_Unknown value,
          $Res Function(TronContractValue_Unknown) _then) =
      _$TronContractValue_UnknownCopyWithImpl;
  @useResult
  $Res call({String typeUrl, String valueJson});
}

/// @nodoc
class _$TronContractValue_UnknownCopyWithImpl<$Res>
    implements $TronContractValue_UnknownCopyWith<$Res> {
  _$TronContractValue_UnknownCopyWithImpl(this._self, this._then);

  final TronContractValue_Unknown _self;
  final $Res Function(TronContractValue_Unknown) _then;

  /// Create a copy of TronContractValue
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? typeUrl = null,
    Object? valueJson = null,
  }) {
    return _then(TronContractValue_Unknown(
      typeUrl: null == typeUrl
          ? _self.typeUrl
          : typeUrl // ignore: cast_nullable_to_non_nullable
              as String,
      valueJson: null == valueJson
          ? _self.valueJson
          : valueJson // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

// dart format on
