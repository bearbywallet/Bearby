import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:bearby/config/web3_constants.dart';
import 'package:bearby/src/rust/api/transaction.dart' as rust_api;
import 'package:bearby/src/rust/models/ftoken.dart';
import 'package:bearby/src/rust/models/transactions/base_token.dart';
import 'package:bearby/src/rust/models/transactions/evm.dart';
import 'package:bearby/src/rust/models/transactions/request.dart';
import 'package:bearby/src/rust/models/transactions/transaction_metadata.dart';
import 'package:bearby/web3/web3_utils.dart';

/// Parse a hex (optional `0x`) integer. Null input → null.
/// Non-null malformed input throws [FormatException] (matches pre-WC browser
/// behavior where `BigInt.parse` failed and the dapp received an error).
BigInt? hexToBigInt(Object? raw) {
  if (raw == null) return null;
  final s = raw.toString().replaceFirst(kHexPrefix, '');
  if (s.isEmpty) return BigInt.zero;
  final parsed = BigInt.tryParse(s, radix: kHexRadix);
  if (parsed == null) {
    throw FormatException('Invalid hex BigInt: $raw');
  }
  return parsed;
}

/// dApp eth_sendTransaction params → signable request.
/// Shared by in-app browser (EIP-1193) and WalletConnect handlers.
TransactionRequestInfo buildEvmTransactionRequest({
  required Map<String, Object?> txParams,
  required FTokenInfo nativeToken,
  required BigInt chainHash,
  required String? signerAddr,
  required String title,
  String? icon,
}) {
  final from = txParams[kParamFrom]?.toString() ?? '';
  final to = txParams[kParamTo]?.toString();
  final value = txParams[kParamValue]?.toString();
  final rawData = txParams[kParamData]?.toString();
  final data = rawData == null
      ? null
      : Uint8List.fromList(hexToBytes(rawData.replaceFirst(kHexPrefix, '')));

  final valueAmount = hexToBigInt(value) ?? BigInt.zero;

  final evmRequest = TransactionRequestEVM(
    nonce: null,
    from: from,
    to: to,
    value: value,
    gasLimit: hexToBigInt(txParams[kParamGas]),
    data: data,
    maxFeePerGas: hexToBigInt(txParams[kParamMaxFeePerGas]),
    maxPriorityFeePerGas: hexToBigInt(txParams[kParamMaxPriorityFeePerGas]),
    gasPrice: hexToBigInt(txParams[kParamGasPrice]),
    chainId: hexToBigInt(txParams[kParamChainId]),
    accessList: null,
    blobVersionedHashes: null,
    maxFeePerBlobGas: null,
  );

  return TransactionRequestInfo(
    metadata: TransactionMetadataInfo(
      chainHash: chainHash,
      hash: null,
      info: null,
      icon: icon,
      title: title,
      signer: signerAddr,
      tokenInfo: BaseTokenInfo(
        value: valueAmount.toString(),
        symbol: nativeToken.symbol,
        decimals: nativeToken.decimals,
      ),
      broadcast: true,
    ),
    scilla: null,
    evm: evmRequest,
  );
}

/// Hex wei amount from eth_sendTransaction params (for modal display).
BigInt evmValueAmount(Map<String, Object?> txParams) {
  return hexToBigInt(txParams[kParamValue]) ?? BigInt.zero;
}

/// Tron raw_data envelope → signable request.
/// Shared by in-app browser (TronWeb3) and WalletConnect handlers.
/// [broadcast] false → sign-only (WC tron_signTransaction / browser multi-sign).
TransactionRequestInfo buildTronTransactionRequest({
  required Map<String, Object?> transaction,
  required FTokenInfo nativeToken,
  required BigInt chainHash,
  required String? signerAddr,
  required String title,
  required bool broadcast,
  String? icon,
  String? tokenValue,
}) {
  final valueStr = tokenValue ?? tronTransferAmount(transaction);
  final tronTx = rust_api.parseTronTransaction(json: jsonEncode(transaction));
  return TransactionRequestInfo(
    metadata: TransactionMetadataInfo(
      chainHash: chainHash,
      hash: null,
      info: null,
      icon: icon,
      title: title,
      signer: signerAddr,
      tokenInfo: BaseTokenInfo(
        value: valueStr,
        symbol: nativeToken.symbol,
        decimals: nativeToken.decimals,
      ),
      broadcast: broadcast,
    ),
    scilla: null,
    evm: null,
    tron: tronTx,
  );
}

/// Amount (sun) from the first TransferContract in a TronWeb transaction map.
String tronTransferAmount(Map<String, Object?> transaction) {
  final amount = _tronFirstContractValue(transaction)?['amount'];
  if (amount == null) return '0';
  return amount.toString();
}

/// Recipient from the first TransferContract, or empty when not a transfer.
String tronTransferTo(Map<String, Object?> transaction) {
  final to = _tronFirstContractValue(transaction)?['to_address'];
  if (to == null) return '';
  return to.toString();
}

Map<String, Object?>? _tronFirstContractValue(
  Map<String, Object?> transaction,
) {
  final rawData = transaction['raw_data'];
  if (rawData is! Map) return null;
  final contracts = rawData['contract'];
  if (contracts is! List || contracts.isEmpty) return null;
  final first = contracts.first;
  if (first is! Map) return null;
  final parameter = first['parameter'];
  if (parameter is! Map) return null;
  final value = parameter['value'];
  if (value is! Map) return null;
  return Map<String, Object?>.from(value);
}
