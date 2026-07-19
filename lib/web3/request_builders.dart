import 'dart:typed_data';

import 'package:bearby/config/web3_constants.dart';
import 'package:bearby/src/rust/models/ftoken.dart';
import 'package:bearby/src/rust/models/transactions/base_token.dart';
import 'package:bearby/src/rust/models/transactions/evm.dart';
import 'package:bearby/src/rust/models/transactions/request.dart';
import 'package:bearby/src/rust/models/transactions/transaction_metadata.dart';
import 'package:bearby/state/app_state.dart';
import 'package:bearby/web3/web3_utils.dart';

/// Parse a hex quantity (`0x…` or decimal string) into [BigInt].
BigInt? parseHexBigInt(dynamic v) {
  if (v == null) return null;
  final raw = v.toString();
  final hasHexPrefix = raw.startsWith('0x') || raw.startsWith('0X');
  final s = hasHexPrefix ? raw.substring(2) : raw;
  if (s.isEmpty) return BigInt.zero;
  // Only treat as hex when 0x-prefixed; bare decimals stay decimal (chainId 10 ≠ 0x10).
  return hasHexPrefix ? BigInt.tryParse(s, radix: 16) : BigInt.tryParse(s);
}

/// Build [TransactionRequestEVM] from a JSON-RPC tx object map.
TransactionRequestEVM buildEvmTransactionRequest(Map<String, dynamic> txParams) {
  final from = txParams[kParamFrom]?.toString();
  final to = txParams[kParamTo]?.toString();
  final value = txParams[kParamValue]?.toString();
  final gasLimit = parseHexBigInt(txParams[kParamGas] ?? txParams['gasLimit']);
  final maxFeePerGas = parseHexBigInt(txParams[kParamMaxFeePerGas]);
  final maxPriorityFeePerGas =
      parseHexBigInt(txParams[kParamMaxPriorityFeePerGas]);
  final gasPrice = parseHexBigInt(txParams[kParamGasPrice]);
  final chainId = parseHexBigInt(txParams[kParamChainId]);

  Uint8List? data;
  final dataHex = txParams[kParamData]?.toString();
  if (dataHex != null &&
      dataHex.isNotEmpty &&
      dataHex != '0x' &&
      dataHex != '0X') {
    try {
      data = Uint8List.fromList(
        hexToBytes(dataHex.replaceFirst(RegExp(r'^0[xX]'), '')),
      );
    } catch (_) {
      data = null;
    }
  }

  return TransactionRequestEVM(
    nonce: null,
    from: from,
    to: to,
    value: value,
    gasLimit: gasLimit,
    data: data,
    maxFeePerGas: maxFeePerGas,
    maxPriorityFeePerGas: maxPriorityFeePerGas,
    gasPrice: gasPrice,
    chainId: chainId,
    accessList: null,
    blobVersionedHashes: null,
    maxFeePerBlobGas: null,
  );
}

/// Native EVM token on the selected wallet, or null if missing.
FTokenInfo? nativeEvmToken(AppState appState) {
  try {
    return appState.wallet?.tokens
        .firstWhere((t) => t.addrType == kEvmAddressType && t.native);
  } catch (_) {
    return null;
  }
}

/// Wei amount from a hex/decimal `value` field.
BigInt evmValueAmount(String? value) {
  if (value == null ||
      value == '0x' ||
      value == '0X' ||
      value == '0x0' ||
      value == '0') {
    return BigInt.zero;
  }
  return parseHexBigInt(value) ?? BigInt.zero;
}

/// Full [TransactionRequestInfo] for confirm-transfer modal.
TransactionRequestInfo buildEvmTransactionRequestInfo({
  required Map<String, dynamic> txParams,
  required AppState appState,
  required bool broadcast,
  required FTokenInfo nativeToken,
  String? title,
  String? icon,
}) {
  final evmRequest = buildEvmTransactionRequest(txParams);
  final valueAmount = evmValueAmount(evmRequest.value);
  final tokenInfo = BaseTokenInfo(
    value: valueAmount.toString(),
    symbol: nativeToken.symbol,
    decimals: nativeToken.decimals,
  );
  final metadata = TransactionMetadataInfo(
    chainHash: appState.chain?.chainHash ?? BigInt.zero,
    hash: null,
    info: null,
    icon: icon,
    title: (title == null || title.isEmpty) ? kEvmTransactionTitle : title,
    signer: appState.account?.addr,
    tokenInfo: tokenInfo,
    broadcast: broadcast,
  );
  return TransactionRequestInfo(
    metadata: metadata,
    scilla: null,
    evm: evmRequest,
  );
}
