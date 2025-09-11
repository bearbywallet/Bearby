// ignore_for_file: constant_identifier_names

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:ledger_flutter_plus/ledger_flutter_plus_dart.dart';
import 'package:zilpay/ledger/ethereum/utils.dart';

const int ETH_CLA = 0xe0;
const int ETH_INS_SIGN = 0x04;
const int P1_FIRST_CHUNK = 0x00;
const int P1_MORE_CHUNKS = 0x80;
const int P2_UNUSED = 0x00;
const int ETH_SIGNATURE_LENGTH = 65;

class EthereumTransactionOperation extends LedgerComplexOperation<Uint8List> {
  final int accountIndex;
  final Uint8List transactionRlp;
  final List<Uint8List> transactionChunks;
  final ConnectionType connectionType;

  const EthereumTransactionOperation({
    required this.accountIndex,
    required this.transactionRlp,
    required this.transactionChunks,
    required this.connectionType,
  });

  @override
  Future<Uint8List> invoke(LedgerSendFct send) async {
    debugPrint('[LEDGER_DEBUG] Starting transaction signing...');

    final List<int> paths = splitPath(getWalletDerivationPath(accountIndex));
    final derivationPathBuff = Uint8List(1 + paths.length * 4);
    derivationPathBuff[0] = paths.length;
    for (int i = 0; i < paths.length; i++) {
      derivationPathBuff.buffer
          .asByteData()
          .setUint32(1 + 4 * i, paths[i], Endian.big);
    }

    debugPrint(
        '[LEDGER_DEBUG] Derivation path (${derivationPathBuff.length} bytes): ${bytesToHex(derivationPathBuff)}');
    debugPrint(
        '[LEDGER_DEBUG] Transaction RLP (${transactionRlp.length} bytes): ${bytesToHex(transactionRlp)}');

    List<Uint8List> chunks;

    final totalSimpleSize = derivationPathBuff.length + transactionRlp.length;
    const maxChunkSize = 255;

    if (totalSimpleSize <= maxChunkSize) {
      debugPrint(
          '[LEDGER_DEBUG] Simple transaction - using single chunk approach');

      final singleChunk = Uint8List(totalSimpleSize);
      singleChunk.setRange(0, derivationPathBuff.length, derivationPathBuff);
      singleChunk.setRange(
          derivationPathBuff.length, totalSimpleSize, transactionRlp);

      chunks = [singleChunk];
      debugPrint(
          '[LEDGER_DEBUG] Created single chunk (${singleChunk.length} bytes): ${bytesToHex(singleChunk)}');
    } else {
      debugPrint(
          '[LEDGER_DEBUG] Complex transaction - using pre-prepared chunks from Rust');

      if (transactionChunks.isEmpty) {
        throw LedgerDeviceException(
          message: 'Complex transaction requires chunks but none provided',
          connectionType: connectionType,
        );
      }

      chunks = transactionChunks;
      debugPrint('[LEDGER_DEBUG] Using ${chunks.length} pre-prepared chunks');
    }

    ByteDataReader? responseReader;

    for (int i = 0; i < chunks.length; i++) {
      final chunk = chunks[i];
      final bool isFirstChunk = (i == 0);
      final p1 = isFirstChunk ? P1_FIRST_CHUNK : P1_MORE_CHUNKS;

      debugPrint(
          '[LEDGER_DEBUG] Sending chunk ${i + 1}/${chunks.length}: P1=0x${p1.toRadixString(16)}, size=${chunk.length}');
      debugPrint('[LEDGER_DEBUG] Chunk data: ${bytesToHex(chunk)}');

      try {
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
      } catch (e) {
        debugPrint('[LEDGER_ERROR] Failed to send chunk ${i + 1}: $e');
        rethrow;
      }
    }

    if (responseReader == null) {
      throw LedgerDeviceException(
        message: 'No response received from device',
        connectionType: connectionType,
      );
    }

    final rawResponseBytes =
        responseReader.read(responseReader.remainingLength);
    debugPrint('[LEDGER_DEBUG] Raw response: ${bytesToHex(rawResponseBytes)}');

    if (rawResponseBytes.length < 2) {
      throw LedgerDeviceException(
        message: 'Response too short',
        connectionType: connectionType,
      );
    }

    int status = (rawResponseBytes[rawResponseBytes.length - 2] << 8) |
        rawResponseBytes[rawResponseBytes.length - 1];

    if (status != 0x9000) {
      final hexStatus = status.toRadixString(16).padLeft(4, '0').toUpperCase();
      debugPrint('[LEDGER_ERROR] Device returned error status: 0x$hexStatus');

      switch (status) {
        case 0x6a80:
          throw Exception(
              'Invalid data received. Please enable "Contract data" or "Blind signing" in Ethereum app settings');
        case 0x6985:
          throw Exception(
              'Transaction rejected by user or requires plugin/clear signing setup');
        case 0x6982:
          throw Exception('Security conditions not satisfied');
        case 0x6983:
          throw Exception('Incorrect data length');
        case 0x6984:
          throw Exception('Required plugin not installed');
        case 0x6967:
          throw Exception('Transaction rejected by user');
        default:
          throw LedgerDeviceException(
            message: 'Device error: 0x$hexStatus',
            connectionType: connectionType,
          );
      }
    }

    final signatureBytes =
        rawResponseBytes.sublist(0, rawResponseBytes.length - 2);
    debugPrint('[LEDGER_DEBUG] Signature length: ${signatureBytes.length}');

    if (signatureBytes.length != ETH_SIGNATURE_LENGTH) {
      throw LedgerDeviceException(
        message:
            'Invalid signature length: ${signatureBytes.length}, expected: $ETH_SIGNATURE_LENGTH',
        connectionType: connectionType,
      );
    }

    debugPrint('[LEDGER_DEBUG] Transaction signed successfully');
    return signatureBytes;
  }
}
