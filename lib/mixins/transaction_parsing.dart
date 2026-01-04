import 'dart:convert';
import 'package:zilpay/config/web3_constants.dart';
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

class BtcInput {
  final String? txid;
  final int? vout;
  final Map<String, dynamic>? scriptSig;
  final int? sequence;
  final List<String>? txinwitness;

  BtcInput({
    this.txid,
    this.vout,
    this.scriptSig,
    this.sequence,
    this.txinwitness,
  });

  factory BtcInput.fromJson(Map<String, dynamic> json) {
    return BtcInput(
      txid: json['txid'] as String?,
      vout: json['vout'] as int?,
      scriptSig: json['scriptSig'] as Map<String, dynamic>?,
      sequence: json['sequence'] as int?,
      txinwitness: (json['txinwitness'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
    );
  }

  String? get scriptSigHex => scriptSig?['hex'] as String?;
  String? get scriptSigAsm => scriptSig?['asm'] as String?;
}

class BtcOutput {
  final int? n;
  final Map<String, dynamic>? scriptPubKey;
  final BigInt? value;

  BtcOutput({
    this.n,
    this.scriptPubKey,
    this.value,
  });

  factory BtcOutput.fromJson(Map<String, dynamic> json) {
    return BtcOutput(
      n: json['n'] as int?,
      scriptPubKey: json['scriptPubKey'] as Map<String, dynamic>?,
      value: _parseBtcValue(json['value']),
    );
  }

  static BigInt? _parseBtcValue(dynamic value) {
    if (value == null) return null;

    if (value is int) return BigInt.from(value);

    if (value is double) {
      return BigInt.from((value * 100000000).round());
    }

    if (value is String) {
      final intValue = BigInt.tryParse(value);
      if (intValue != null) return intValue;

      final doubleValue = double.tryParse(value);
      if (doubleValue != null) {
        return BigInt.from((doubleValue * 100000000).round());
      }
    }

    return null;
  }

  String? get address => scriptPubKey?['address'] as String?;
  String? get scriptPubKeyHex => scriptPubKey?['hex'] as String?;
  String? get scriptPubKeyAsm => scriptPubKey?['asm'] as String?;
  String? get scriptPubKeyType => scriptPubKey?['type'] as String?;
}

class ParsedBtcReceipt {
  final String? txid;
  final String? hash;
  final int? version;
  final int? locktime;
  final int? size;
  final int? vsize;
  final int? weight;
  final List<BtcInput>? inputs;
  final List<BtcOutput>? outputs;
  final int? confirmations;
  final BigInt? fee;

  ParsedBtcReceipt({
    this.txid,
    this.hash,
    this.version,
    this.locktime,
    this.size,
    this.vsize,
    this.weight,
    this.inputs,
    this.outputs,
    this.confirmations,
    this.fee,
  });

  factory ParsedBtcReceipt.fromJson(Map<String, dynamic> json) {
    final inputsList = (json['vin'] as List<dynamic>?)
        ?.map((e) => BtcInput.fromJson(e as Map<String, dynamic>))
        .toList();

    final outputsList = (json['vout'] as List<dynamic>?)
        ?.map((e) => BtcOutput.fromJson(e as Map<String, dynamic>))
        .toList();

    return ParsedBtcReceipt(
      txid: json['txid'] as String?,
      hash: json['hash'] as String?,
      version: json['version'] as int?,
      locktime: json['locktime'] as int?,
      size: json['size'] as int?,
      vsize: json['vsize'] as int?,
      weight: json['weight'] as int?,
      inputs: inputsList,
      outputs: outputsList,
      confirmations: json['confirmations'] as int?,
      fee: _parseBigInt(json['fee']),
    );
  }

  static BigInt? _parseBigInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return BigInt.from(value);
    if (value is String) return BigInt.tryParse(value);
    return null;
  }

  String? get transactionHash => txid ?? hash;
  int? get lockTime => locktime;
  int? get inputsCount => inputs?.length;
  int? get outputsCount => outputs?.length;

  BigInt get totalOutputValue {
    return outputs?.fold<BigInt>(
          BigInt.zero,
          (sum, output) => sum + (output.value ?? BigInt.zero),
        ) ??
        BigInt.zero;
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
  String? get domainContract => typedData?['domain']?['verifyingContract'] as String?;
  String? get primaryType => typedData?['primaryType'] as String?;
  Map<String, dynamic>? get typedMessage => typedData?['message'] as Map<String, dynamic>?;

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

  ParsedBtcReceipt? get btcReceipt {
    if (btc == null) return null;
    try {
      final json = jsonDecode(btc!) as Map<String, dynamic>;
      return ParsedBtcReceipt.fromJson(json);
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
  bool get isBtcTransaction => btc != null;

  String get chainType {
    if (evm != null) return 'EVM';
    if (scilla != null) return 'Scilla';
    if (btc != null) return 'BTC';
    return 'Unknown';
  }

  String get transactionHash {
    return metadata.hash ?? evmReceipt?.transactionHash ?? scillaReceipt?.transactionHash ?? btcReceipt?.transactionHash ?? '';
  }

  String? get icon => metadata.icon;
  String? get title => metadata.title;
  BaseTokenInfo? get tokenInfo => metadata.tokenInfo;
  BigInt get chainHash => metadata.chainHash;

  String get sender {
    if (btc != null) {
      return btcReceipt?.inputs?.firstOrNull?.txid ?? '';
    }
    return evmReceipt?.sender ?? scillaReceipt?.sender ?? '';
  }

  String get recipient {
    if (btc != null) {
      return btcReceipt?.outputs?.firstOrNull?.address ?? '';
    }
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
    if (btc != null && metadata.tokenInfo?.value == null) {
      return btcReceipt?.totalOutputValue.toString() ?? '0';
    }
    return metadata.tokenInfo?.value ?? evmReceipt?.amount ?? scillaReceipt?.amount ?? '0';
  }

  BigInt get fee {
    if (btc != null && btcReceipt != null && metadata.btcUtxoAmounts != null) {
      BigInt inputTotal = BigInt.zero;
      for (int i = 0; i < metadata.btcUtxoAmounts!.length; i++) {
        inputTotal += metadata.btcUtxoAmounts![i];
      }

      final outputTotal = btcReceipt!.totalOutputValue;

      return inputTotal - outputTotal;
    }
    return btcReceipt?.fee ?? evmReceipt?.fee ?? scillaReceipt?.fee ?? BigInt.zero;
  }

  String? get sig {
    return evmReceipt?.sig ?? scillaReceipt?.sig;
  }

  String? get error {
    return evmReceipt?.error ?? scillaReceipt?.error;
  }
}
