import 'dart:typed_data';

import 'package:ledger_flutter_plus/ledger_flutter_plus.dart';
import 'package:zilpay/ledger/ethereum/ethereum_eip712_hashed_message_operation.dart';
import 'package:zilpay/ledger/ethereum/ethereum_personal_message_operation.dart';
import 'package:zilpay/ledger/ethereum/ethereum_public_key_operation.dart';
import 'package:zilpay/ledger/ethereum/models.dart';
import 'package:zilpay/src/rust/api/transaction.dart';

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

  Future<Uint8List> signPersonalMessage(
      Uint8List message, int accountIndex) async {
    final signature = await ledger.sendOperation<Uint8List>(
      EthereumPersonalMessageOperation(
          accountIndex: accountIndex, message: message),
      transformer: transformer,
    );

    _checkResult(signature);

    return signature;
  }

  Future<Uint8List> signEIP712HashedMessage(
    Eip712Hashes hashes,
    int accountIndex,
  ) async {
    final signature = await ledger.sendOperation<Uint8List>(
      EthereumEIP712HashedMessageOperation(
        accountIndex: accountIndex,
        domainSeparator: hashes.domainSeparator,
        hashStructMessage: hashes.hashStructMessage,
      ),
      transformer: transformer,
    );

    _checkResult(signature);

    return signature;
  }

  void _checkResult(Uint8List result) {
    if (result.length != 2) {
      return;
    }

    if (result.first == 105 && result.last == 103) {
      throw "Rejected";
    } else if (result.first == 85 && result.last == 21) {
      throw "device is lock";
    }
  }
}
