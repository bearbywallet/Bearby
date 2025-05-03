import 'dart:typed_data';

import 'package:ledger_flutter_plus/ledger_flutter_plus_dart.dart';

class ZilliqaSignHashOperation extends LedgerRawOperation<Uint8List> {
  static const cla = 0xE0;
  static const ins = 0x08;
  static const sigByteLen = 64;

  final int accountIndex;
  final Uint8List hash;

  ZilliqaSignHashOperation(this.accountIndex, this.hash);

  @override
  Future<List<Uint8List>> write(ByteDataWriter writer) async {
    writer.writeUint8(cla); // CLA
    writer.writeUint8(ins); // INS: signHash
    writer.writeUint8(0x00); // P1
    writer.writeUint8(0x00); // P2

    writer.writeUint8(4 + hash.length);
    writer.writeInt32(accountIndex, Endian.little);
    writer.write(hash);

    return [writer.toBytes()];
  }

  @override
  Future<Uint8List> read(ByteDataReader reader) async {
    final signatureBytes = reader.read(sigByteLen);

    return signatureBytes;
  }
}
