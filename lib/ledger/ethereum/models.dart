import 'dart:typed_data';

import 'package:zilpay/ledger/ethereum/utils.dart';

class EthLedgerAccount {
  final String publicKey;
  final String address;
  final int index;

  EthLedgerAccount({
    required this.publicKey,
    required this.address,
    required this.index,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EthLedgerAccount &&
          runtimeType == other.runtimeType &&
          publicKey == other.publicKey &&
          index == other.index);

  @override
  int get hashCode => Object.hash(publicKey, index);
}

class EthLedgerSignature {
  final int v;
  final Uint8List r;
  final Uint8List s;

  EthLedgerSignature({required this.v, required this.r, required this.s});

  String toHexString() {
    if (r.length != 32 || s.length != 32) {
      throw ArgumentError('r and s must be 32 bytes long');
    }

    final buffer = Uint8List(65);
    buffer.setRange(0, 32, r);
    buffer.setRange(32, 64, s);
    buffer[64] = v;

    return bytesToHex(buffer, include0x: true);
  }

  Uint8List toBytes() {
    if (r.length != 32 || s.length != 32) {
      throw ArgumentError('r and s must be 32 bytes long');
    }

    final buffer = Uint8List(65);
    buffer.setRange(0, 32, r);
    buffer.setRange(32, 64, s);
    buffer[64] = v;

    return buffer;
  }

  static EthLedgerSignature fromBytes(Uint8List bytes) {
    if (bytes.length != 65) {
      throw ArgumentError(
          'Bytes must be 65 bytes long to form a valid signature');
    }

    final v = bytes[64];
    final r = Uint8List.sublistView(bytes, 0, 32);
    final s = Uint8List.sublistView(bytes, 32, 64);

    return EthLedgerSignature(v: v, r: r, s: s);
  }

  static EthLedgerSignature fromLedgerResponse(Uint8List bytes) {
    if (bytes.length < 65) {
      throw FormatException('Response too short to contain valid signature');
    }

    int v = bytes[0];
    Uint8List r = Uint8List.sublistView(bytes, 1, 1 + 32);
    Uint8List s = Uint8List.sublistView(bytes, 1 + 32, 1 + 32 + 32);

    return EthLedgerSignature(v: v, r: r, s: s);
  }
}
