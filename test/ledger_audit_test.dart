// Audit tests: runtime proof for bugs & DRY violations found in review.
//
// Convention:
//  - "PROOF" tests exercise the REAL production class via a fake Transport.
//  - "MIRROR" tests exercise a line-identical copy of a private production
//    algorithm (private members cannot be imported). The mirror is asserted
//    against the production source at runtime where possible.
// When a PROOF/MIRROR test goes green after a bugfix, update the test.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:bearby/ledger/common.dart';
import 'package:bearby/ledger/ethereum/eth_ledger_app.dart';
import 'package:bearby/ledger/models/device_model.dart';
import 'package:bearby/ledger/transport/exceptions.dart';
import 'package:bearby/ledger/transport/transport.dart';
import 'package:bearby/ledger/zilliqa/zilliqa_ledger_app.dart';

// Minimal GuardedTransport double for the shared-guard regression tests.
class _GuardedFakeTransport extends GuardedTransport {
  int inFlight = 0;
  int maxConcurrent = 0;

  @override
  DeviceModel? get deviceModel => null;

  @override
  void setScrambleKey(String key) {}

  @override
  Future<Uint8List> exchange(Uint8List apdu) {
    return guardedExchange(() async {
      inFlight += 1;
      maxConcurrent = inFlight > maxConcurrent ? inFlight : maxConcurrent;
      await Future<void>.delayed(const Duration(milliseconds: 5));
      inFlight -= 1;
      return Uint8List.fromList([0x90, 0x00]);
    });
  }

  @override
  Future<void> close() => guardedClose(() async {});
}

// ---------------------------------------------------------------------------
// Fake transport: records every APDU, replays a canned response.
// ---------------------------------------------------------------------------
class FakeTransport extends Transport {
  final List<Uint8List> sentApdus = [];
  Uint8List Function(Uint8List apdu) responder;

  FakeTransport({Uint8List Function(Uint8List apdu)? responder})
      : responder = responder ??
            ((apdu) => Uint8List.fromList([0x90, 0x00]));

  @override
  DeviceModel? get deviceModel => null;

  @override
  Stream<TransportEvent> get events => const Stream.empty();

  @override
  void setScrambleKey(String key) {}

  @override
  Future<void> close() async {}

  @override
  Future<Uint8List> exchange(Uint8List apdu) async {
    sentApdus.add(Uint8List.fromList(apdu));
    return responder(apdu);
  }
}

// MIRROR of the private _parseBigInt (transaction_parsing.dart, now a
// top-level helper with identical semantics).
BigInt? mirrorParseBigInt(Object? value) {
  if (value == null) return null;
  if (value is int) return BigInt.from(value);
  if (value is String) return BigInt.tryParse(value);
  return null;
}

Uint8List _withSw(List<int> payload) =>
    Uint8List.fromList([...payload, 0x90, 0x00]);

void main() {
  // -------------------------------------------------------------------------
  // 1) DRY regression guard: _parseBigInt must stay EXACTLY ONCE.
  //    It used to be copy-pasted verbatim into two classes of
  //    lib/mixins/transaction_parsing.dart (lines 84-89 and 138-143); fixed
  //    by extracting a single top-level helper.
  // -------------------------------------------------------------------------
  test('AUDIT: _parseBigInt defined exactly once, top-level, no dynamic', () {
    final src = File('lib/mixins/transaction_parsing.dart').readAsStringSync();
    final occurrences = 'BigInt? _parseBigInt('.allMatches(src).length;

    expect(occurrences, 1,
        reason: 'DRY regression: _parseBigInt must not be re-copied');
    expect(src.contains('static BigInt? _parseBigInt'), isFalse,
        reason: 'the helper must stay top-level');
    expect(src.contains('_parseBigInt(dynamic'), isFalse,
        reason: 'strict typing rule: Object?, never dynamic');
  });

  // -------------------------------------------------------------------------
  // 2) MIRROR of _parseBigInt: hex strings are silently dropped.
  //    EVM/Zilliqa payloads often carry amounts as "0x64" strings;
  //    BigInt.tryParse cannot parse them -> null -> silent data loss
  //    (the same file has _parseInt with a kHexZero special case, so the
  //    hex handling is inconsistent between the two parsers).
  // -------------------------------------------------------------------------
  test('MIRROR: _parseBigInt handles decimal AND hex strings', () {
    expect(mirrorParseBigInt('123'), BigInt.from(123)); // decimal ok
    expect(mirrorParseBigInt(64), BigInt.from(64)); // int ok
    // BigInt.tryParse auto-detects the 0x prefix -> hex amounts survive.
    // (Suspicion of silent hex loss DISPROVEN by this test.)
    expect(mirrorParseBigInt('0x64'), BigInt.from(100));
    // Only garbage strings are dropped to null (documented contract).
    expect(mirrorParseBigInt('not-a-number'), isNull);
  });

  // -------------------------------------------------------------------------
  // 3) MIRROR of the signPersonalMessage chunk loop (fixed form) + REAL-class
  //    regression: EthLedgerApp must throw ArgumentError for an empty message
  //    BEFORE contacting the device. Before the fix, `late response`
  //    (eth_ledger_app.dart:147) was never assigned -> LateInitializationError.
  // -------------------------------------------------------------------------
  test('REAL: EthLedgerApp.signPersonalMessage rejects empty message early',
      () async {
    final fake = FakeTransport();
    final app = EthLedgerApp(fake);

    await expectLater(
      app.signPersonalMessage(index: 0, message: Uint8List(0)),
      throwsA(isA<ArgumentError>()),
      reason: 'empty message must fail fast, not crash on `late response`',
    );
    expect(fake.sentApdus, isEmpty, reason: 'device never contacted');
  });

  // -------------------------------------------------------------------------
  // 4) PROOF (real ZilliqaLedgerApp): signHash must REJECT any hash that is
  //    not exactly 32 bytes. It used to silently truncate >32B (signature
  //    over the WRONG hash); now it throws like it always did for empty.
  // -------------------------------------------------------------------------
  test('REAL: Zilliqa signHash rejects 33-byte hash instead of truncating',
      () async {
    final fake = FakeTransport(
      responder: (apdu) => _withSw(List<int>.filled(64, 0xAB)),
    );
    final app = ZilliqaLedgerApp(fake);

    final badHash = Uint8List.fromList(List<int>.generate(33, (i) => i + 1));

    await expectLater(
      app.signHash(7, badHash),
      throwsA(isA<ArgumentError>()),
      reason: 'oversized hash must hard-fail; silent truncation '
          'signed the WRONG hash before the fix',
    );
    expect(fake.sentApdus, isEmpty, reason: 'device never contacted');
  });

  test(
      'REAL: Zilliqa signHash throws for EMPTY hash - consistent validation',
      () async {
    final fake = FakeTransport();
    final app = ZilliqaLedgerApp(fake);

    await expectLater(
      app.signHash(0, Uint8List(0)),
      throwsA(isA<ArgumentError>()),
      reason: 'empty -> hard error, oversized -> silent truncation. '
          'One consistent validation contract is required.',
    );
    expect(fake.sentApdus, isEmpty);
  });

  // -------------------------------------------------------------------------
  // 5) PROOF: getPublicAddres happy path + typed error for rejected SW.
  // -------------------------------------------------------------------------
  test('PROOF: Zilliqa getPublicAddres parses 33-byte pk + 42-byte bech32',
      () async {
    final pk = List<int>.filled(33, 0x02);
    final addr =
        utf8.encode('zils1${'q' * 38}');
    expect(addr.length, 43, reason: 'zils1 + 38 = 43-byte bech32 address');
    final fake = FakeTransport(responder: (apdu) => _withSw([...pk, ...addr]));
    final app = ZilliqaLedgerApp(fake);

    final account = await app.getPublicAddres(3);

    expect(fake.sentApdus.single[5], 3, reason: 'little-endian index');
    expect(account.publicKey, isNotEmpty);
    expect(account.address, startsWith('zils1'));
    expect(account.index, 3);
  });

  test('PROOF: Zilliqa getPublicAddres surfaces device errors via SW checker',
      () async {
    // Wire convention: transport returns payload + SW; SW 0x6985 alone.
    final fake = FakeTransport(
      responder: (apdu) => Uint8List.fromList([0x69, 0x85]),
    );
    final app = ZilliqaLedgerApp(fake);

    await expectLater(
      app.getPublicAddres(0),
      throwsA(isA<TransportStatusError>()),
      reason: '0x6985 user-rejected must surface as typed error, not vanish',
    );
  });

  // -------------------------------------------------------------------------
  // 6) REAL: LedgerAccount.== now covers `address` (before the fix, two
  //    accounts with the same index but different addresses collided in
  //    Sets/Maps; toString() was missing entirely).
  // -------------------------------------------------------------------------
  test('REAL: LedgerAccount distinguishes accounts by address', () {
    final a = LedgerAccount(publicKey: 'pk', address: 'zils1aaaa', index: 1);
    final b = LedgerAccount(publicKey: 'pk', address: 'zils1bbbb', index: 1);

    expect(a.address != b.address, isTrue);
    expect(a, isNot(equals(b)),
        reason: '== must include address (regression: it used to ignore it)');
    expect(<LedgerAccount>{a, b}, hasLength(2),
        reason: 'two distinct accounts must not collapse in a Set');
    expect(a.toString(), contains('LedgerAccount'),
        reason: 'default-trait rule: toString() must exist');
    expect(a.toString(), contains('zils1aaaa'));
  });

  // -------------------------------------------------------------------------
  // 7) REAL: GuardedTransport shared guard (was copy-pasted 4x).
  //    Concurrent exchanges must fail with TransportRaceCondition, and any
  //    exchange started after guardedClose() must fail with
  //    DisconnectedDeviceDuringOperationException (the pre-refactor race).
  // -------------------------------------------------------------------------
  test('REAL: GuardedTransport resets after a rejected concurrent exchange',
      () async {
    final t = _GuardedFakeTransport();

    // 1) a normal exchange passes and never overlaps anything
    await t.exchange(Uint8List.fromList([0x01]));
    expect(t.maxConcurrent, 1);

    // 2) concurrent one is rejected...
    final first = t.exchange(Uint8List.fromList([0x02]));
    await expectLater(
      t.exchange(Uint8List.fromList([0x03])),
      throwsA(isA<TransportRaceCondition>()),
    );
    await first;

    // 3) ...but the guard state resets: the next exchange succeeds.
    await t.exchange(Uint8List.fromList([0x04]));
    expect(t.maxConcurrent, 1,
        reason: 'no two exchanges ever ran at the same time');
  });

  test('REAL: GuardedTransport rejects concurrent second exchange', () async {
    final t = _GuardedFakeTransport();

    // Start one exchange and hold it via a slow responder.
    final first = t.exchange(Uint8List.fromList([0x01]));

    await expectLater(
      t.exchange(Uint8List.fromList([0x02])),
      throwsA(isA<TransportRaceCondition>()),
      reason: 'a second exchange while one is in flight must throw '
              'instead of silently queueing/corrupting the APDU stream',
    );
    await first;
  });

  test('REAL: GuardedTransport rejects exchange after close (race fix)',
      () async {
    final t = _GuardedFakeTransport();
    await t.exchange(Uint8List.fromList([0x01]));
    await t.close();

    await expectLater(
      t.exchange(Uint8List.fromList([0x02])),
      throwsA(isA<DisconnectedDeviceDuringOperationException>()),
      reason: 'before the refactor, close() vs new exchange raced: the '
              'closed flag did not exist. Now late callers fail fast.',
    );
  });
}
