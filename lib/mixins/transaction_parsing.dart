import 'dart:convert';
import 'package:bearby/config/web3_constants.dart';
import 'package:bearby/src/rust/models/transactions/btc.dart';
import 'package:bearby/src/rust/models/transactions/history.dart';
import 'package:bearby/src/rust/models/transactions/base_token.dart';
import 'package:bearby/src/rust/models/transactions/tron.dart';

class ParsedEvmReceipt {
  final String? transactionHash;
  final BigInt? nonce;
  final String? sender;
  final String? recipient;
  final String? contractAddress;
  final BigInt? gasUsed;
  final BigInt? gasLimit;
  final BigInt? gasPrice;
  final BigInt? effectiveGasPrice;
  final BigInt? blobGasUsed;
  final BigInt? blobGasPrice;
  final BigInt? blockNumber;
  final int? statusCode;
  final String? amount;
  final BigInt? fee;
  final String? sig;
  final String? error;

  ParsedEvmReceipt({
    this.transactionHash,
    this.nonce,
    this.sender,
    this.recipient,
    this.contractAddress,
    this.gasUsed,
    this.gasLimit,
    this.gasPrice,
    this.effectiveGasPrice,
    this.blobGasUsed,
    this.blobGasPrice,
    this.blockNumber,
    this.statusCode,
    this.amount,
    this.fee,
    this.sig,
    this.error,
  });

  factory ParsedEvmReceipt.fromJson(Map<String, dynamic> json) {
    return ParsedEvmReceipt(
      transactionHash: json['transactionHash'] as String?,
      nonce: _parseBigInt(json['nonce']),
      sender: json['from'] as String?,
      recipient: json['to'] as String?,
      contractAddress: json['contractAddress'] as String?,
      gasUsed: _parseBigInt(json['gasUsed']),
      gasLimit: _parseBigInt(json['gasLimit']),
      gasPrice: _parseBigInt(json['gasPrice']),
      effectiveGasPrice: _parseBigInt(json['effectiveGasPrice']),
      blobGasUsed: _parseBigInt(json['blobGasUsed']),
      blobGasPrice: _parseBigInt(json['blobGasPrice']),
      blockNumber: _parseBigInt(json['blockNumber']),
      statusCode: _parseStatus(json['status']),
      amount: json['value'] as String?,
      fee: _parseBigInt(json['fee']),
      sig: json['signature'] as String?,
      error: json['error'] as String?,
    );
  }

  static int? _parseStatus(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      if (value == kHexOne) return 1;
      if (value == kHexZero) return 0;
      return int.tryParse(value);
    }
    return null;
  }

  static BigInt? _parseBigInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return BigInt.from(value);
    if (value is String) return BigInt.tryParse(value);
    return null;
  }
}

class ParsedScillaReceipt {
  final String? transactionHash;
  final BigInt? nonce;
  final String? sender;
  final String? recipient;
  final BigInt? gasLimit;
  final BigInt? gasPrice;
  final BigInt? blockNumber;
  final int? statusCode;
  final String? amount;
  final BigInt? fee;
  final String? sig;
  final String? error;

  ParsedScillaReceipt({
    this.transactionHash,
    this.nonce,
    this.sender,
    this.recipient,
    this.gasLimit,
    this.gasPrice,
    this.blockNumber,
    this.statusCode,
    this.amount,
    this.fee,
    this.sig,
    this.error,
  });

  factory ParsedScillaReceipt.fromJson(Map<String, dynamic> json) {
    return ParsedScillaReceipt(
      transactionHash: json['hash'] as String?,
      nonce: _parseBigInt(json['nonce']),
      sender: json['senderAddr'] as String?,
      recipient: json['toAddr'] as String?,
      gasLimit: _parseBigInt(json['gasLimit']),
      gasPrice: _parseBigInt(json['gasPrice']),
      blockNumber: _parseBigInt(json['blockNumber']),
      statusCode: json['status'] as int?,
      amount: json['amount'] as String?,
      fee: _parseBigInt(json['fee']),
      sig: json['signature'] as String?,
      error: json['error'] as String?,
    );
  }

  static BigInt? _parseBigInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return BigInt.from(value);
    if (value is String) return BigInt.tryParse(value);
    return null;
  }
}

class ParsedSignedMessage {
  final String? type;
  final String? message;
  final String? signature;
  final String? pubKey;
  final String? signer;
  final Map<String, dynamic>? typedData;

  ParsedSignedMessage({
    this.type,
    this.message,
    this.signature,
    this.pubKey,
    this.signer,
    this.typedData,
  });

  factory ParsedSignedMessage.fromJson(Map<String, dynamic> json) {
    return ParsedSignedMessage(
      type: json['type'] as String?,
      message: json['message'] as String?,
      signature: json['signature'] as String?,
      pubKey: json['pubKey'] as String?,
      signer: json['signer'] as String?,
      typedData: json['typedData'] as Map<String, dynamic>?,
    );
  }

  bool get isPersonalSign => type == 'personal_sign';
  bool get isTypedData => type == 'eth_signTypedData_v4';

  String get decodedMessage {
    if (message == null) return '';
    if (message!.startsWith('0x')) {
      try {
        final hex = message!.substring(2);
        final bytes = <int>[];
        for (var i = 0; i < hex.length; i += 2) {
          bytes.add(int.parse(hex.substring(i, i + 2), radix: 16));
        }
        return utf8.decode(bytes);
      } catch (_) {
        return message!;
      }
    }
    return message!;
  }

  String? get domainName => typedData?['domain']?['name'] as String?;
  int? get domainChainId => typedData?['domain']?['chainId'] as int?;
  String? get domainContract =>
      typedData?['domain']?['verifyingContract'] as String?;
  String? get primaryType => typedData?['primaryType'] as String?;
  Map<String, dynamic>? get typedMessage =>
      typedData?['message'] as Map<String, dynamic>?;

  String get displayType {
    if (isPersonalSign) return 'Personal Sign';
    if (isTypedData) return 'EIP-712';
    return 'Unknown';
  }
}

extension HistoricalTransactionInfoExt on HistoricalTransactionInfo {
  ParsedEvmReceipt? get evmReceipt {
    if (evm == null) return null;
    try {
      final json = jsonDecode(evm!) as Map<String, dynamic>;
      return ParsedEvmReceipt.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  ParsedScillaReceipt? get scillaReceipt {
    if (scilla == null) return null;
    try {
      final json = jsonDecode(scilla!) as Map<String, dynamic>;
      return ParsedScillaReceipt.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  TransactionBitcoin? get btcReceipt => btc;

  TransactionRequestTron? get tronReceipt => tron;

  TronContractValue? get _tronFirstContractValue {
    final contracts = tron?.rawData.contract;
    if (contracts == null || contracts.isEmpty) return null;
    return contracts.first.value;
  }

  ParsedSignedMessage? get parsedSignedMessage {
    if (signedMessage == null) return null;
    try {
      final json = jsonDecode(signedMessage!) as Map<String, dynamic>;
      return ParsedSignedMessage.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  bool get isSignedMessage => signedMessage != null;
  bool get isEvmTransaction => evm != null && tron == null;
  bool get isScillaTransaction => scilla != null;
  bool get isBtcTransaction => btc != null;
  bool get isTronTransaction => tron != null;

  String get chainType {
    // Prefer chain-native blob: tron may still carry a polluted `evm` from older
    // receipt-update paths.
    if (tron != null) return 'Tron';
    if (evm != null) return 'EVM';
    if (scilla != null) return 'Scilla';
    if (btc != null) return 'BTC';
    return 'Unknown';
  }

  String get transactionHash {
    return metadata.hash ??
        tron?.txId ??
        evmReceipt?.transactionHash ??
        scillaReceipt?.transactionHash ??
        '';
  }

  String? get icon => metadata.icon;
  String? get title => metadata.title;
  BaseTokenInfo? get tokenInfo => metadata.tokenInfo;
  BigInt get chainHash => metadata.chainHash;

  String get sender {
    if (btc != null) {
      return btc?.input.firstOrNull?.previousOutput.txid ?? '';
    }
    final tronSender = _tronSender;
    if (tronSender != null && tronSender.isNotEmpty) return tronSender;
    return evmReceipt?.sender ?? scillaReceipt?.sender ?? '';
  }

  String get recipient {
    if (btc != null) {
      return '';
    }
    final tronTo = _tronRecipient;
    if (tronTo != null && tronTo.isNotEmpty) return tronTo;
    return evmReceipt?.recipient ?? scillaReceipt?.recipient ?? '';
  }

  String? get contractAddress {
    final value = _tronFirstContractValue;
    if (value is TronContractValue_TriggerSmartContract) {
      return value.contractAddress;
    }
    return evmReceipt?.contractAddress;
  }

  BigInt? get nonce {
    return evmReceipt?.nonce ?? scillaReceipt?.nonce;
  }

  BigInt? get gasUsed => evmReceipt?.gasUsed;
  BigInt? get gasLimit {
    final feeLimit = tron?.rawData.feeLimit;
    if (feeLimit != null) return BigInt.from(feeLimit.toInt());
    return evmReceipt?.gasLimit ?? scillaReceipt?.gasLimit;
  }

  BigInt? get gasPrice => evmReceipt?.gasPrice ?? scillaReceipt?.gasPrice;
  BigInt? get effectiveGasPrice => evmReceipt?.effectiveGasPrice;
  BigInt? get blobGasUsed => evmReceipt?.blobGasUsed;
  BigInt? get blobGasPrice => evmReceipt?.blobGasPrice;
  BigInt? get blockNumber =>
      evmReceipt?.blockNumber ?? scillaReceipt?.blockNumber;
  int? get statusCode => evmReceipt?.statusCode ?? scillaReceipt?.statusCode;

  String get amount {
    if (btc != null && metadata.tokenInfo?.value == null) {
      final total = btc!.output.fold<BigInt>(
        BigInt.zero,
        (sum, out) => sum + out.value,
      );
      return total.toString();
    }
    final tokenValue = metadata.tokenInfo?.value;
    if (tokenValue != null && tokenValue.isNotEmpty) {
      return tokenValue;
    }
    final tronAmount = _tronAmount;
    if (tronAmount != null && tronAmount.isNotEmpty) {
      return tronAmount;
    }
    return evmReceipt?.amount ?? scillaReceipt?.amount ?? '0';
  }

  BigInt get fee {
    if (btc != null) {
      return btc?.fee ?? BigInt.zero;
    }

    if (tron != null) {
      // fee_limit is a max budget, not actual fee.
      return BigInt.zero;
    }

    if (evm != null) {
      final receipt = evmReceipt;
      if (receipt?.fee != null) return receipt!.fee!;

      final gasUsed = receipt?.gasUsed;
      final effectivePrice = receipt?.effectiveGasPrice ?? receipt?.gasPrice;

      if (gasUsed != null && effectivePrice != null) {
        return gasUsed * effectivePrice;
      }
    }

    if (scilla != null) {
      final receipt = scillaReceipt;
      if (receipt?.fee != null) return receipt!.fee!;

      final gasLimit = receipt?.gasLimit;
      final gasPrice = receipt?.gasPrice;

      if (gasLimit != null && gasPrice != null) {
        return gasLimit * gasPrice;
      }
    }

    return btc?.fee ?? BigInt.zero;
  }

  String? get sig {
    return evmReceipt?.sig ?? scillaReceipt?.sig;
  }

  String? get error {
    return evmReceipt?.error ?? scillaReceipt?.error;
  }

  String? get _tronSender {
    final value = _tronFirstContractValue;
    if (value == null) return null;
    return switch (value) {
      TronContractValue_TransferContract(:final ownerAddress) => ownerAddress,
      TronContractValue_TriggerSmartContract(:final ownerAddress) =>
        ownerAddress,
      TronContractValue_FreezeBalanceV2Contract(:final ownerAddress) =>
        ownerAddress,
      TronContractValue_WithdrawBalanceContract(:final ownerAddress) =>
        ownerAddress,
      TronContractValue_UnfreezeBalanceV2Contract(:final ownerAddress) =>
        ownerAddress,
      TronContractValue_WithdrawExpireUnfreezeContract(:final ownerAddress) =>
        ownerAddress,
      TronContractValue_DelegateResourceContract(:final ownerAddress) =>
        ownerAddress,
      TronContractValue_UnDelegateResourceContract(:final ownerAddress) =>
        ownerAddress,
      TronContractValue_CancelAllUnfreezeV2Contract(:final ownerAddress) =>
        ownerAddress,
      TronContractValue_TransferAssetContract(:final ownerAddress) =>
        ownerAddress,
      TronContractValue_VoteWitnessContract(:final ownerAddress) =>
        ownerAddress,
      TronContractValue_AccountCreateContract(:final ownerAddress) =>
        ownerAddress,
      TronContractValue_AccountUpdateContract(:final ownerAddress) =>
        ownerAddress,
      TronContractValue_AccountPermissionUpdateContract(
        :final ownerAddress
      ) =>
        ownerAddress,
      TronContractValue_Unknown() => null,
    };
  }

  String? get _tronRecipient {
    final value = _tronFirstContractValue;
    if (value == null) return null;
    return switch (value) {
      TronContractValue_TransferContract(:final toAddress) => toAddress,
      TronContractValue_TriggerSmartContract(:final contractAddress) =>
        contractAddress,
      TronContractValue_DelegateResourceContract(:final receiverAddress) =>
        receiverAddress,
      TronContractValue_UnDelegateResourceContract(:final receiverAddress) =>
        receiverAddress,
      TronContractValue_TransferAssetContract(:final toAddress) => toAddress,
      TronContractValue_AccountCreateContract(:final accountAddress) =>
        accountAddress,
      _ => null,
    };
  }

  String? get _tronAmount {
    final value = _tronFirstContractValue;
    if (value == null) return null;
    return switch (value) {
      TronContractValue_TransferContract(:final amount) => amount.toString(),
      TronContractValue_TriggerSmartContract(:final callValue) =>
        callValue?.toString(),
      TronContractValue_TransferAssetContract(:final amount) =>
        amount.toString(),
      TronContractValue_FreezeBalanceV2Contract(:final frozenBalance) =>
        frozenBalance.toString(),
      TronContractValue_UnfreezeBalanceV2Contract(:final unfreezeBalance) =>
        unfreezeBalance.toString(),
      TronContractValue_DelegateResourceContract(:final balance) =>
        balance.toString(),
      TronContractValue_UnDelegateResourceContract(:final balance) =>
        balance.toString(),
      _ => null,
    };
  }
}
