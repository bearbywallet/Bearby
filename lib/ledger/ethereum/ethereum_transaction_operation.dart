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
const int MAX_CHUNK_SIZE = 255;
const int ETH_SIGNATURE_LENGTH = 65;

class EthereumTransactionOperation extends LedgerComplexOperation<Uint8List> {
  final int accountIndex;
  final Uint8List transactionRlp;
  final ConnectionType connectionType;

  const EthereumTransactionOperation({
    required this.accountIndex,
    required this.transactionRlp,
    required this.connectionType,
  });

  @override
  Future<Uint8List> invoke(LedgerSendFct send) async {
    final List<int> paths = splitPath(getWalletDerivationPath(accountIndex));
    final derivationPathBuffer = ByteData(1 + paths.length * 4);
    derivationPathBuffer.setUint8(0, paths.length);
    for (int i = 0; i < paths.length; i++) {
      derivationPathBuffer.setUint32(1 + 4 * i, paths[i], Endian.big);
    }

    final payload = Uint8List.fromList(
      derivationPathBuffer.buffer.asUint8List() + transactionRlp,
    );

    debugPrint(
        '[LEDGER_DEBUG] Full payload (path + rlp) length: ${payload.length}');
    debugPrint('[LEDGER_DEBUG] Full payload (hex): ${bytesToHex(payload)}');

    ByteDataReader? responseReader;
    int offset = 0;

    for (int i = 0; offset < payload.length; i++) {
      final int chunkSize = min(MAX_CHUNK_SIZE, payload.length - offset);
      final Uint8List chunk = payload.sublist(offset, offset + chunkSize);
      offset += chunkSize;

      final bool isFirstChunk = (i == 0);
      final p1 = isFirstChunk ? P1_FIRST_CHUNK : P1_MORE_CHUNKS;

      debugPrint(
          '[LEDGER_DEBUG] Sending chunk ${i + 1}: P1=0x${p1.toRadixString(16)}, size=${chunk.length}, data=${bytesToHex(chunk)}');

      responseReader = await send(
        LedgerSimpleOperation(
          cla: ETH_CLA,
          ins: ETH_INS_SIGN,
          p1: p1,
          p2: P2_UNUSED,
          data: chunk,
          prependDataLength: true,
          debugName: 'Sign Ethereum Txn Chunk ${i + 1}',
        ),
      );
    }

    if (responseReader == null) {
      throw LedgerDeviceException(
        message:
            'No response received from Ledger device after sending transaction data.',
        connectionType: connectionType,
      );
    }

    final rawResponseBytes =
        responseReader.read(responseReader.remainingLength);
    debugPrint(
        '[LEDGER_DEBUG] Raw response from device: ${bytesToHex(rawResponseBytes)}');
    debugPrint(
        '[LEDGER_DEBUG] Length of rawResponseBytes array: ${rawResponseBytes.length}');

    if (rawResponseBytes.length == 2) {
      int status = (rawResponseBytes[0] << 8) | rawResponseBytes[1];
      if (status == 0x6985 || status == 0x6a80) {
        throw Exception(
            'Transaction rejected by device. Please enable "Blind Signing" in the Ethereum application settings on your Ledger and try again.');
      }
    }

    if (rawResponseBytes.length < ETH_SIGNATURE_LENGTH) {
      throw LedgerDeviceException(
        message:
            'Signature response too short. Expected $ETH_SIGNATURE_LENGTH bytes, got ${rawResponseBytes.length}',
        connectionType: connectionType,
      );
    }

    final signatureBytes = rawResponseBytes.sublist(0, ETH_SIGNATURE_LENGTH);
    debugPrint(
        '[LEDGER_DEBUG] Parsed signature from device: ${bytesToHex(signatureBytes)}');

    return signatureBytes;
  }
}
