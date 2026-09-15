import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:bearby/mixins/history_amount.dart';
import 'package:bearby/src/rust/models/transactions/btc.dart';
import 'package:bearby/src/rust/models/transactions/history.dart';
import 'package:bearby/src/rust/models/transactions/transaction_metadata.dart';

HistoricalTransactionInfo _tx({
  TransactionStatusInfo status = TransactionStatusInfo.success,
  String? hash,
  String? title,
  bool broadcast = false,
  String? evm,
  String? scilla,
  TransactionBitcoin? btc,
  String? signedMessage,
  BigInt? timestamp,
}) {
  return HistoricalTransactionInfo(
    status: status,
    metadata: TransactionMetadataInfo(
      chainHash: BigInt.one,
      hash: hash,
      title: title,
      broadcast: broadcast,
    ),
    evm: evm,
    scilla: scilla,
    btc: btc,
    signedMessage: signedMessage,
    timestamp: timestamp ?? BigInt.from(1700000000),
  );
}

String _evmJson({required String from, required String to}) {
  return '{"from":"$from","to":"$to","value":"1000","fee":"10"}';
}

TxInInfo _input({String? address}) {
  return TxInInfo(
    previousOutput: OutPointInfo(txid: 'a' * 64, vout: 0),
    scriptSig: Uint8List(0),
    sequence: 0,
    witness: const [],
    address: address,
  );
}

void main() {
  group('addressesEqual', () {
    test('matches case-insensitively', () {
      expect(
        addressesEqual(
          '0xAbCDEF0000000000000000000000000000000001',
          '0xabcdef0000000000000000000000000000000001',
        ),
        isTrue,
      );
    });

    test('rejects empty or null', () {
      expect(addressesEqual(null, '0x1'), isFalse);
      expect(addressesEqual('', '0x1'), isFalse);
      expect(addressesEqual('0x1', null), isFalse);
    });
  });

  group('resolveTxFlow', () {
    const account = '0xabcdef0000000000000000000000000000000001';

    test('signed message is neutral', () {
      final tx = _tx(signedMessage: '{"type":"personal_sign","message":"hi"}');
      expect(
        resolveTxFlow(transaction: tx, accountAddress: account),
        TxFlow.neutral,
      );
    });

    test('EVM send when sender is account', () {
      final tx = _tx(
        evm: _evmJson(
          from: account,
          to: '0x00000000000000000000000000000000000000aa',
        ),
      );
      expect(
        resolveTxFlow(transaction: tx, accountAddress: account),
        TxFlow.outgoing,
      );
    });

    test('EVM receive when recipient is account', () {
      final tx = _tx(
        evm: _evmJson(
          from: '0x00000000000000000000000000000000000000bb',
          to: account,
        ),
      );
      expect(
        resolveTxFlow(transaction: tx, accountAddress: account),
        TxFlow.incoming,
      );
    });

    test('self-transfer is neutral', () {
      final tx = _tx(evm: _evmJson(from: account, to: account));
      expect(
        resolveTxFlow(transaction: tx, accountAddress: account),
        TxFlow.neutral,
      );
    });

    test('BTC with fee is outgoing', () {
      final tx = _tx(
        btc: TransactionBitcoin(
          version: 2,
          lockTime: 0,
          input: const [],
          output: const [],
          fee: BigInt.from(250),
        ),
      );
      expect(
        resolveTxFlow(transaction: tx, accountAddress: null),
        TxFlow.outgoing,
      );
    });

    test('BTC without fee is incoming', () {
      final tx = _tx(
        btc: const TransactionBitcoin(
          version: 2,
          lockTime: 0,
          input: [],
          output: [],
        ),
      );
      expect(
        resolveTxFlow(transaction: tx, accountAddress: null),
        TxFlow.incoming,
      );
    });

    test('backfilled BTC receive (broadcast=true, no fee, foreign inputs) is incoming',
        () {
      final tx = _tx(
        broadcast: true,
        btc: TransactionBitcoin(
          version: 2,
          lockTime: 0,
          input: [_input(address: null)],
          output: const [],
        ),
      );
      expect(
        resolveTxFlow(transaction: tx, accountAddress: null),
        TxFlow.incoming,
      );
    });

    test('BTC without fee but with owned input address is outgoing', () {
      final tx = _tx(
        broadcast: true,
        btc: TransactionBitcoin(
          version: 2,
          lockTime: 0,
          input: [_input(address: 'bc1qownaddress')],
          output: const [],
        ),
      );
      expect(
        resolveTxFlow(transaction: tx, accountAddress: null),
        TxFlow.outgoing,
      );
    });

    test('broadcast fallback without addresses is outgoing', () {
      final tx = _tx(broadcast: true, scilla: '{"amount":"1"}');
      expect(
        resolveTxFlow(transaction: tx, accountAddress: null),
        TxFlow.outgoing,
      );
    });
  });
}
