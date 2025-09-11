import 'dart:async';
import 'package:zilpay/ledger/ledger_operation.dart';
import 'package:zilpay/ledger/transport/transport.dart';

abstract class LedgerApp {
  final Transport transport;

  LedgerApp(this.transport);

  Future<T> sendOperation<T>(LedgerOperation<T> operation) async {
    return operation.execute(transport);
  }
}
