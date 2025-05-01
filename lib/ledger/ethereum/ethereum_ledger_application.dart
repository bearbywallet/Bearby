import 'dart:typed_data';

import 'package:ledger_flutter_plus/ledger_flutter_plus.dart';
import 'package:zilpay/ledger/ethereum/ethereum_personal_message_operation.dart';
import 'package:zilpay/ledger/ethereum/ethereum_public_key_operation.dart';
import 'package:zilpay/ledger/ethereum/models.dart';

class EthereumLedgerApp {
  final LedgerConnection ledger;
  final LedgerTransformer? transformer;

  EthereumLedgerApp(
    this.ledger, {
    this.transformer,
  });

  Future<List<EthLedgerAccount>> getAccounts(List<int> accountIndices) async {
    final List<EthLedgerAccount> accounts = [];

    for (final index in accountIndices) {
      final account = await ledger.sendOperation<EthLedgerAccount>(
        EthereumPublicKeyOperation(accountIndex: index),
        transformer: transformer,
      );
      accounts.add(account);
    }

    return accounts;
  }

  @override
  Future<Uint8List> signPersonalMessage(
      Uint8List message, int accountIndex) async {
    final signature = await ledger.sendOperation<Uint8List>(
      EthereumPersonalMessageOperation(
          accountIndex: accountIndex, message: message),
      transformer: transformer,
    );

    return signature;
  }
}
