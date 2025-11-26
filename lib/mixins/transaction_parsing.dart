import 'dart:convert';
import 'package:zilpay/src/rust/models/transactions/history.dart';
import 'package:zilpay/src/rust/models/transactions/base_token.dart';

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
      if (value == '0x1') return 1;
      if (value == '0x0') return 0;
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
  final dynamic typedData;

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
      typedData: json['typedData'],
    );
  }

  bool get isPersonalSign => type == 'personal_sign';
  bool get isTypedData => type == 'eth_signTypedData_v4';
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
  bool get isEvmTransaction => evm != null;
  bool get isScillaTransaction => scilla != null;

  String get chainType {
    if (evm != null) return 'EVM';
    if (scilla != null) return 'Scilla';
    return 'Unknown';
  }

  String get transactionHash {
    return metadata.hash ?? evmReceipt?.transactionHash ?? scillaReceipt?.transactionHash ?? '';
  }

  String? get icon => metadata.icon;
  String? get title => metadata.title;
  BaseTokenInfo? get tokenInfo => metadata.tokenInfo;
  BigInt get chainHash => metadata.chainHash;

  String get sender {
    return evmReceipt?.sender ?? scillaReceipt?.sender ?? '';
  }

  String get recipient {
    return evmReceipt?.recipient ?? scillaReceipt?.recipient ?? '';
  }

  String? get contractAddress {
    return evmReceipt?.contractAddress;
  }

  BigInt? get nonce {
    return evmReceipt?.nonce ?? scillaReceipt?.nonce;
  }

  BigInt? get gasUsed => evmReceipt?.gasUsed;
  BigInt? get gasLimit => evmReceipt?.gasLimit ?? scillaReceipt?.gasLimit;
  BigInt? get gasPrice => evmReceipt?.gasPrice ?? scillaReceipt?.gasPrice;
  BigInt? get effectiveGasPrice => evmReceipt?.effectiveGasPrice;
  BigInt? get blobGasUsed => evmReceipt?.blobGasUsed;
  BigInt? get blobGasPrice => evmReceipt?.blobGasPrice;
  BigInt? get blockNumber => evmReceipt?.blockNumber ?? scillaReceipt?.blockNumber;
  int? get statusCode => evmReceipt?.statusCode ?? scillaReceipt?.statusCode;

  String get amount {
    return metadata.tokenInfo?.value ?? evmReceipt?.amount ?? scillaReceipt?.amount ?? '0';
  }

  BigInt get fee {
    return evmReceipt?.fee ?? scillaReceipt?.fee ?? BigInt.zero;
  }

  String? get sig {
    return evmReceipt?.sig ?? scillaReceipt?.sig;
  }

  String? get error {
    return evmReceipt?.error ?? scillaReceipt?.error;
  }
}
