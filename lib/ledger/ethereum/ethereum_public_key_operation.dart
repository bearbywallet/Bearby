import 'dart:convert';
import 'dart:typed_data';

import 'package:ledger_flutter_plus/ledger_flutter_plus_dart.dart';
import 'package:zilpay/ledger/ethereum/models.dart';
import 'package:zilpay/ledger/ethereum/utils.dart';

class EthereumPublicKeyOperation extends LedgerRawOperation<EthLedgerAccount> {
  final int accountIndex;

  EthereumPublicKeyOperation({
    this.accountIndex = 0,
  });

  @override
  Future<List<Uint8List>> write(ByteDataWriter writer) async {
    writer.writeUint8(0xe0); // CLA (class of instruction)
    writer.writeUint8(0x02); // INS (instruction code) - GET_PUBLIC_KEY
    writer.writeUint8(0x00); // P1 parameter
    writer.writeUint8(0x00); // P2 parameter

    final List<int> paths = splitPath(getWalletDerivationPath(accountIndex));
    final int bufferSize = 1 + paths.length * 4;
    final ByteData buffer = ByteData(bufferSize)..setUint8(0, paths.length);
    for (int i = 0; i < paths.length; i++) {
      buffer.setUint32(1 + 4 * i, paths[i], Endian.big);
    }

    final List<int> bufferBytes = buffer.buffer.asUint8List();
    writer.writeUint8(buffer.lengthInBytes); // CDATA length
    writer.write(bufferBytes); // CDATA

    return [writer.toBytes()];
  }

  @override
  Future<EthLedgerAccount> read(ByteDataReader reader) async {
    final bytes = reader.read(reader.remainingLength);
    int publicKeyLength = bytes[0];
    int addressLength = bytes[1 + publicKeyLength];
    final publicKey =
        bytesToHex(bytes.sublist(1, 1 + publicKeyLength), include0x: true);
    final address =
        '0x${utf8.decode(bytes.sublist(1 + publicKeyLength + 1, 1 + publicKeyLength + 1 + addressLength))}';
    return EthLedgerAccount(
      publicKey: publicKey,
      address: address,
      index: accountIndex,
    );
  }
}
