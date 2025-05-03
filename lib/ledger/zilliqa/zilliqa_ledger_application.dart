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
      ZilliqaSignTransactionOperation(
        accountIndex: accountIndex,
        transaction: protoBuf,
      ),
      transformer: transformer,
    );

    return signatureBytes;
  }
}
