import 'dart:convert';
import 'dart:typed_data';

import 'package:zilpay/ledger/common.dart';
import 'package:zilpay/ledger/ledger_operation.dart';
import 'package:zilpay/ledger/transport/transport.dart';
import 'package:zilpay/src/rust/api/ledger.dart';
import 'package:zilpay/utils/utils.dart';

class EthLedgerApp {
  final Transport transport;

  EthLedgerApp(this.transport);

  Future<LedgerAccount> getAddress({
    required int index,
    int slip44 = 60,
    bool boolDisplay = false,
    bool boolChaincode = false,
    int? chainId, // Изменен тип на int?
  }) async {
    final String path = "44'/$slip44'/0'/0/$index";
    final paths = await ledgerSplitPath(path: path);

    final writer = ByteDataWriter(endian: Endian.big);
    writer.writeUint8(paths.length);
    for (final element in paths) {
      writer.writeUint32(element);
    }
    var buffer = writer.toBytes();

    if (chainId != null) {
      // Прямое преобразование 64-битного числа в 8-байтовый буфер
      final byteData = ByteData(8);
      byteData.setUint64(0, chainId, Endian.big);
      final chainIdBuffer = byteData.buffer.asUint8List();

      buffer = Uint8List.fromList([...buffer, ...chainIdBuffer]);
    }

    final response = await transport.send(
      0xe0,
      0x02,
      boolDisplay ? 0x01 : 0x00,
      boolChaincode ? 0x01 : 0x00,
      buffer,
    );

    final publicKeyLength = response[0];
    final addressLength = response[1 + publicKeyLength];

    final publicKey = bytesToHex(
      response.sublist(1, 1 + publicKeyLength),
    );
    final address = '0x${ascii.decode(
      response.sublist(
        1 + publicKeyLength + 1,
        1 + publicKeyLength + 1 + addressLength,
      ),
    )}';

    String? chainCode;
    if (boolChaincode) {
      chainCode = bytesToHex(
        response.sublist(
          1 + publicKeyLength + 1 + addressLength,
          1 + publicKeyLength + 1 + addressLength + 32,
        ),
      );
    }

    return LedgerAccount(
      publicKey: publicKey,
      address: address,
      chainCode: chainCode,
      index: index,
    );
  }
}
