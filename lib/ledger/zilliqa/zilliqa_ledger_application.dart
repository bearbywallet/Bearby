import 'dart:typed_data';

import 'package:ledger_flutter_plus/ledger_flutter_plus.dart';
import 'package:zilpay/ledger/common.dart';
import 'package:zilpay/ledger/ethereum/utils.dart';
import 'package:zilpay/ledger/zilliqa/zilliqa_public_key_operation.dart';
import 'package:zilpay/ledger/zilliqa/zilliqa_sign_hash_operation.dart';

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
}
