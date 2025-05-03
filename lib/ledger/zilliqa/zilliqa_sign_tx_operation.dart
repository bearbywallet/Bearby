import 'dart:typed_data';
import 'package:ledger_flutter_plus/ledger_flutter_plus_dart.dart';

class ZilliqaSignTransactionOperation extends LedgerRawOperation<Uint8List> {
  static const cla = 0xE0; // Corrected from 0xC7 to match JS code
  static const ins = 0x04; // INS: signTxn
  static const sigByteLen = 64; // Signature length
  static const streamLen = 128; // Stream in batches of 128 bytes

  final int accountIndex;
  final Uint8List transaction;

  ZilliqaSignTransactionOperation({
    required this.accountIndex,
    required this.transaction,
  });

  @override
  Future<List<Uint8List>> write(ByteDataWriter writer) async {
    final List<Uint8List> apduList = [];

    int remainingBytes = transaction.length;
    int offset = 0;

    // First APDU: includes accountIndex, hostBytesLeft, txn1Size, and first chunk
    final firstWriter = ByteDataWriter();
    firstWriter.writeUint8(cla);
    firstWriter.writeUint8(ins);
    firstWriter.writeUint8(0x00); // P1
    firstWriter.writeUint8(0x00); // P2

    final indexBytes = ByteData(4)..setInt32(0, accountIndex, Endian.little);
    final firstChunkSize =
        remainingBytes > streamLen ? streamLen : remainingBytes;
    final hostBytesLeft = remainingBytes - firstChunkSize;
    final hostBytesLeftBytes = ByteData(4)
      ..setInt32(0, hostBytesLeft, Endian.little);
    final txn1SizeBytes = ByteData(4)
      ..setInt32(0, firstChunkSize, Endian.little);
    final txn1Bytes = transaction.sublist(0, firstChunkSize);

    final firstData = Uint8List.fromList([
      ...indexBytes.buffer.asUint8List(),
      ...hostBytesLeftBytes.buffer.asUint8List(),
      ...txn1SizeBytes.buffer.asUint8List(),
      ...txn1Bytes,
    ]);

    firstWriter.writeUint8(firstData.length); // Lc
    firstWriter.write(firstData);
    apduList.add(firstWriter.toBytes());

    // Update offset and remaining bytes
    offset += firstChunkSize;
    remainingBytes -= firstChunkSize;

    // Subsequent APDUs: hostBytesLeft, txnNSize, txnNBytes
    while (remainingBytes > 0) {
      final subsequentWriter = ByteDataWriter();
      subsequentWriter.writeUint8(cla);
      subsequentWriter.writeUint8(ins);
      subsequentWriter.writeUint8(0x00); // P1
      subsequentWriter.writeUint8(0x00); // P2

      final chunkSize = remainingBytes > streamLen ? streamLen : remainingBytes;
      final hostBytesLeftN = remainingBytes - chunkSize;
      final hostBytesLeftBytesN = ByteData(4)
        ..setInt32(0, hostBytesLeftN, Endian.little);
      final txnNSizeBytes = ByteData(4)..setInt32(0, chunkSize, Endian.little);
      final txnNBytes = transaction.sublist(offset, offset + chunkSize);

      final subsequentData = Uint8List.fromList([
        ...hostBytesLeftBytesN.buffer.asUint8List(),
        ...txnNSizeBytes.buffer.asUint8List(),
        ...txnNBytes,
      ]);

      subsequentWriter.writeUint8(subsequentData.length); // Lc
      subsequentWriter.write(subsequentData);
      apduList.add(subsequentWriter.toBytes());

      offset += chunkSize;
      remainingBytes -= chunkSize;
    }

    return apduList;
  }

  @override
  Future<Uint8List> read(ByteDataReader reader) async {
    final response = reader.read(reader.remainingLength);
    if (response.length < sigByteLen) {
      throw Exception('Invalid signature length');
    }
    return response.sublist(0, sigByteLen);
  }
}
