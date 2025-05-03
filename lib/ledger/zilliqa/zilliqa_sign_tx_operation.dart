import 'package:flutter/foundation.dart';
import 'package:ledger_flutter_plus/ledger_flutter_plus_dart.dart';

class ZilliqaSignTransactionOperation extends LedgerRawOperation<Uint8List> {
  static const cla = 0xE0;
  static const ins = 0x04;
  static const sigByteLen = 64;
  static const streamLen = 128;

  final int accountIndex;
  final Uint8List transaction;

  ZilliqaSignTransactionOperation({
    required this.accountIndex,
    required this.transaction,
  });

  @override
  Future<List<Uint8List>> write(ByteDataWriter writer) async {
    final List<Uint8List> apduList = [];
    int offset = 0;
    int remainingBytes = transaction.length;

    final firstWriter = ByteDataWriter();
    firstWriter.writeUint8(cla);
    firstWriter.writeUint8(ins);
    firstWriter.writeUint8(0x00);
    firstWriter.writeUint8(0x00);

    final chunkSize = remainingBytes > streamLen ? streamLen : remainingBytes;
    final hostBytesLeft = remainingBytes - chunkSize;

    final indexBytes = ByteData(4)..setInt32(0, accountIndex, Endian.little);
    final hostBytesLeftBytes = ByteData(4)
      ..setInt32(0, hostBytesLeft, Endian.little);
    final txn1SizeBytes = ByteData(4)..setInt32(0, chunkSize, Endian.little);
    final txn1Bytes = transaction.sublist(offset, offset + chunkSize);

    final firstData = Uint8List.fromList([
      ...indexBytes.buffer.asUint8List(),
      ...hostBytesLeftBytes.buffer.asUint8List(),
      ...txn1SizeBytes.buffer.asUint8List(),
      ...txn1Bytes,
    ]);

    firstWriter.writeUint8(firstData.length);
    firstWriter.write(firstData);
    apduList.add(firstWriter.toBytes());

    offset += chunkSize;
    remainingBytes -= chunkSize;

    while (remainingBytes > 0) {
      final subsequentWriter = ByteDataWriter();
      subsequentWriter.writeUint8(cla);
      subsequentWriter.writeUint8(ins);
      subsequentWriter.writeUint8(0x00);
      subsequentWriter.writeUint8(0x00);

      final chunkSizeN =
          remainingBytes > streamLen ? streamLen : remainingBytes;
      final hostBytesLeftN = remainingBytes - chunkSizeN;

      final hostBytesLeftBytesN = ByteData(4)
        ..setInt32(0, hostBytesLeftN, Endian.little);
      final txnNSizeBytes = ByteData(4)..setInt32(0, chunkSizeN, Endian.little);
      final txnNBytes = transaction.sublist(offset, offset + chunkSizeN);

      final subsequentData = Uint8List.fromList([
        ...hostBytesLeftBytesN.buffer.asUint8List(),
        ...txnNSizeBytes.buffer.asUint8List(),
        ...txnNBytes,
      ]);

      subsequentWriter.writeUint8(subsequentData.length);
      subsequentWriter.write(subsequentData);
      apduList.add(subsequentWriter.toBytes());

      offset += chunkSizeN;
      remainingBytes -= chunkSizeN;
    }

    return apduList;
  }

  @override
  Future<Uint8List> read(ByteDataReader reader) async {
    final response = reader.read(reader.remainingLength);

    return response;
  }
}
