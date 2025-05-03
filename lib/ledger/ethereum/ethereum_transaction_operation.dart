import 'package:flutter/foundation.dart';
import 'package:ledger_flutter_plus/ledger_flutter_plus_dart.dart';
import 'package:zilpay/ledger/ethereum/utils.dart';

class EthereumTransactionOperation extends LedgerRawOperation<Uint8List> {
  final int accountIndex;
  final Uint8List transaction;

  EthereumTransactionOperation({
    this.accountIndex = 0,
    required this.transaction,
  });

  @override
  Future<List<Uint8List>> write(ByteDataWriter writer) async {
    final output = <Uint8List>[];
    final List<int> paths = splitPath(getWalletDerivationPath(accountIndex));

    if (paths.isEmpty) {
      throw Exception('Derivation path is empty');
    }

    int offset = 0;

    while (offset < transaction.length) {
      writer = ByteDataWriter();

      writer.writeUint8(0xe0); // CLA
      writer.writeUint8(0x04); // ins (SIGN)

      final bool first = offset == 0;
      final int maxChunkSize = first ? 150 - 1 - paths.length * 4 : 150;
      final int chunkSize = offset + maxChunkSize > transaction.length
          ? transaction.length - offset
          : maxChunkSize;

      if (chunkSize <= 0) {
        throw Exception('Invalid chunk size: $chunkSize at offset $offset');
      }

      final buffer =
          Uint8List(first ? 1 + paths.length * 4 + chunkSize : chunkSize);

      if (first) {
        buffer[0] = paths.length;
        for (var i = 0; i < paths.length; i++) {
          buffer.buffer.asByteData().setUint32(1 + 4 * i, paths[i], Endian.big);
        }
        buffer.setAll(1 + 4 * paths.length,
            transaction.sublist(offset, offset + chunkSize));
        writer.writeUint8(0x00);
      } else {
        buffer.setAll(0, transaction.sublist(offset, offset + chunkSize));
        writer.writeUint8(0x80);
      }

      writer.writeUint8(0x00);
      writer.writeUint8(buffer.lengthInBytes);
      writer.write(buffer);

      final chunkData = writer.toBytes();
      output.add(chunkData);

      offset += chunkSize;
    }

    if (offset != transaction.length) {
      throw Exception(
          'Incomplete data sent: sent $offset of ${transaction.length} bytes');
    }

    return output;
  }

  @override
  Future<Uint8List> read(ByteDataReader reader) async {
    final bytes = reader.read(reader.remainingLength);
    return bytes;
  }
}
