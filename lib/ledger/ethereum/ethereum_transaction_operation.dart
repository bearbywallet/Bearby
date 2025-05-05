import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:ledger_flutter_plus/ledger_flutter_plus_dart.dart';
import 'package:zilpay/ledger/ethereum/utils.dart';

const int ETH_CLA = 0xe0;
const int ETH_INS_SIGN = 0x04;
const int P1_FIRST_CHUNK = 0x00;
const int P1_MORE_CHUNKS = 0x80;
const int P2_UNUSED = 0x00;
const int MAX_APDU_PAYLOAD_SIZE = 250;
const int ETH_SIGNATURE_LENGTH = 65;

class EthereumTransactionOperation extends LedgerComplexOperation<Uint8List> {
  final int accountIndex;
  final Uint8List transaction;
  final ConnectionType connectionType;

  const EthereumTransactionOperation({
    required this.accountIndex,
    required this.transaction,
    required this.connectionType,
  });

  @override
  Future<Uint8List> invoke(LedgerSendFct send) async {
    final List<int> paths = splitPath(getWalletDerivationPath(accountIndex));
    if (paths.isEmpty) {
      throw Exception('Derivation path is empty');
    }

    final pathWriter = ByteDataWriter();
    pathWriter.writeUint8(paths.length);
    for (var pathElement in paths) {
      pathWriter.writeUint32(pathElement, Endian.big);
    }
    final pathBytes = pathWriter.toBytes();

    int offset = 0;
    ByteDataReader? responseReader;

    final firstChunkSize = min(
      transaction.length,
      MAX_APDU_PAYLOAD_SIZE - pathBytes.length,
    );

    if (firstChunkSize < 0) {
      throw Exception(
          'Transaction data is too small to fit with derivation path in the first chunk.');
    }

    final firstPayloadWriter = ByteDataWriter();
    firstPayloadWriter.write(pathBytes);
    firstPayloadWriter
        .write(transaction.sublist(offset, offset + firstChunkSize));
    final firstPayload = firstPayloadWriter.toBytes();

    responseReader = await send(
      LedgerSimpleOperation(
        cla: ETH_CLA,
        ins: ETH_INS_SIGN,
        p1: P1_FIRST_CHUNK,
        p2: P2_UNUSED,
        data: firstPayload,
        prependDataLength: true,
        debugName: 'Sign Ethereum Txn Chunk 1',
      ),
    );

    offset += firstChunkSize;
    while (offset < transaction.length) {
      final remainingBytes = transaction.length - offset;
      final currentChunkSize = min(remainingBytes, MAX_APDU_PAYLOAD_SIZE);

      final nextPayload =
          transaction.sublist(offset, offset + currentChunkSize);

      responseReader = await send(
        LedgerSimpleOperation(
          cla: ETH_CLA,
          ins: ETH_INS_SIGN,
          p1: P1_MORE_CHUNKS,
          p2: P2_UNUSED,
          data: nextPayload,
          prependDataLength: true,
          debugName: 'Sign Ethereum Txn Chunk N',
        ),
      );

      offset += currentChunkSize;
    }

    if (responseReader == null) {
      throw LedgerDeviceException(
        message:
            'No response received from Ledger device after sending transaction data.',
        connectionType: connectionType,
      );
    }

    if (responseReader.remainingLength < ETH_SIGNATURE_LENGTH) {
      throw LedgerDeviceException(
        message:
            'Signature response too short. Expected $ETH_SIGNATURE_LENGTH bytes, got ${responseReader.remainingLength}',
        connectionType: connectionType,
      );
    }

    final signatureBytes = responseReader.read(ETH_SIGNATURE_LENGTH);

    return signatureBytes;
  }
}
