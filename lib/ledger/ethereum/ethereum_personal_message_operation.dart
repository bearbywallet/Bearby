import 'dart:typed_data';

import 'package:ledger_flutter_plus/ledger_flutter_plus_dart.dart';
import 'package:zilpay/ledger/ethereum/utils.dart';

class EthereumPersonalMessageOperation extends LedgerRawOperation<Uint8List> {
  final int accountIndex;
  final Uint8List message;

  EthereumPersonalMessageOperation(
      {this.accountIndex = 0, required this.message});

  @override
  Future<List<Uint8List>> write(ByteDataWriter writer) async {
    final output = <Uint8List>[];
    final List<int> paths = splitPath(getWalletDerivationPath(accountIndex));
    int offset = 0;
    while (offset != message.length) {
      final writer = ByteDataWriter();
      writer.writeUint8(0xe0);
      writer.writeUint8(0x08);

      int maxChunkSize = offset == 0 ? 150 - 1 - paths.length * 4 - 4 : 150;
      int chunkSize = offset + maxChunkSize > message.length
          ? message.length - offset
          : maxChunkSize;
      ByteData buffer = ByteData(
          offset == 0 ? 1 + paths.length * 4 + 4 + chunkSize : chunkSize);
      if (offset == 0) {
        buffer.setUint8(0, paths.length);
        for (int i = 0; i < paths.length; i++) {
          buffer.setUint32(1 + 4 * i, paths[i], Endian.big);
        }
        buffer.setUint32(1 + 4 * paths.length, message.length, Endian.big);
        buffer.buffer.asUint8List().setAll(1 + 4 * paths.length + 4,
            message.sublist(offset, offset + chunkSize));
        writer.writeUint8(0x00);
      } else {
        buffer.buffer
            .asUint8List()
            .setAll(0, message.sublist(offset, offset + chunkSize));
        writer.writeUint8(0x80);
      }

      writer.writeUint8(0x00);

      final List<int> bufferBytes = buffer.buffer.asUint8List();
      writer.writeUint8(buffer.lengthInBytes);
      writer.write(bufferBytes);

      offset += chunkSize;

      output.add(writer.toBytes());
    }

    return output;
  }

  @override
  Future<Uint8List> read(ByteDataReader reader) async {
    final bytes = reader.read(reader.remainingLength);

    return bytes;
  }
}
