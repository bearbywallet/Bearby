import 'dart:typed_data';

import 'package:ledger_flutter_plus/ledger_flutter_plus_dart.dart';
import 'package:zilpay/ledger/zilliqa/models.dart';

class ZilliqaPublicAddressOperation
    extends LedgerRawOperation<ZilLedgerAccount> {
  static const cla = 0xE0;
  static const ins = 0x02;
  static const pubKeyByteLen = 33;
  static const bech32AddrLen = 39;

  final int accountIndex;

  ZilliqaPublicAddressOperation(this.accountIndex);

  @override
  Future<List<Uint8List>> write(ByteDataWriter writer) async {
    writer.writeUint8(cla); // CLA
    writer.writeUint8(ins); // INS: getPublicAddress
    writer.writeUint8(0x00); // P1
    writer.writeUint8(0x01); // P2: request public address
    writer.writeUint8(0x04); // Data length (4 bytes for index)
    writer.writeInt32(accountIndex, Endian.little); // Account index

    return [writer.toBytes()];
  }

  @override
  Future<ZilLedgerAccount> read(ByteDataReader reader) async {
    final publicKeyBytes = reader.read(pubKeyByteLen);
    final publicKey = publicKeyBytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();

    final addressBytes = reader.read(bech32AddrLen);
    final address = String.fromCharCodes(addressBytes);

    return ZilLedgerAccount(
      publicKey: publicKey,
      address: address,
      index: accountIndex,
    );
  }
}
