import 'dart:typed_data';

import 'package:ledger_flutter_plus/ledger_flutter_plus.dart';
import 'package:zilpay/ledger/common.dart';
import 'package:zilpay/ledger/ethereum/utils.dart';
import 'package:zilpay/ledger/zilliqa/zilliqa_public_key_operation.dart';
import 'package:zilpay/ledger/zilliqa/zilliqa_sign_hash_operation.dart';
import 'package:zilpay/ledger/zilliqa/zilliqa_sign_tx_operation.dart';
import 'package:zilpay/src/rust/api/transaction.dart';
import 'package:zilpay/src/rust/models/transactions/request.dart';

class ZilliqaLedgerApp {
  final LedgerConnection ledger;
  final LedgerTransformer? transformer;

  ZilliqaLedgerApp(
    this.ledger, {
    this.transformer,
  });

  Future<List<LedgerAccount>> getPublicAddress(
    List<int> accountIndices,
  ) async {
    final List<LedgerAccount> accounts = [];

    for (final index in accountIndices) {
      final account = await ledger.sendOperation<LedgerAccount>(
        ZilliqaPublicAddressOperation(index),
        transformer: transformer,
      );

      accounts.add(account);
    }

    return accounts;
  }

  Future<String> signHash(
    Uint8List hashBytes,
    int accountIndex,
  ) async {
    final signature = await ledger.sendOperation<Uint8List>(
      ZilliqaSignHashOperation(
        accountIndex,
        hashBytes,
      ),
      transformer: transformer,
    );

    _checkResult(signature);

    return bytesToHex(signature);
  }

  Future<Uint8List> signTransaction(
    TransactionRequestInfo transaction,
    int walletIndex,
    int accountIndex,
  ) async {
    final protoBuf = await encodeTxRlp(
      tx: transaction,
      walletIndex: BigInt.from(walletIndex),
      accountIndex: BigInt.from(accountIndex),
    );

    final signatureBytes = await ledger.sendOperation<Uint8List>(
      SignZilliqaTransactionOperation(
        keyIndex: accountIndex,
        transactionBytes: protoBuf.bytes,
        connectionType: ledger.connectionType,
      ),
      transformer: transformer,
    );

    _checkResult(signatureBytes);

    return signatureBytes;
  }

  static void _checkResult(Uint8List result) {
    if (result.length != 2) {
      return;
    }

    int status = (result[0] << 8) | result[1];

    switch (status) {
      case 0x9000:
        break;
      case 0x5515:
        throw Exception('Device is locked');
      case 0x6967:
        throw Exception('Operation rejected');
      case 0x6985:
        throw Exception('Condition not satisfied (possibly rejected by user)');
      case 0x6a80:
        throw Exception('Invalid data');
      case 0x6f00:
        throw Exception('Unknown error');
      default:
        throw Exception(
            'Unknown status code: 0x${status.toRadixString(16).padLeft(4, '0')}');
    }
  }
}
