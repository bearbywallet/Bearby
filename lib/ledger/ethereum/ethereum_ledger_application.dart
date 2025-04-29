import 'package:ledger_flutter_plus/ledger_flutter_plus.dart';
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
}
