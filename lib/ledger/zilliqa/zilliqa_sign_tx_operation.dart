// ignore_for_file: constant_identifier_names

import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:ledger_flutter_plus/ledger_flutter_plus_dart.dart';

const int CLA = 0xe0;
const int INS_SIGN_TXN = 0x04;
const int P1_FIRST = 0x00;
const int P2_FIRST = 0x00;
const int STREAM_LEN = 128;
const int SIG_BYTE_LEN = 64;

class SignZilliqaTransactionOperation
    extends LedgerComplexOperation<Uint8List> {
  final int keyIndex;
  final Uint8List transactionBytes;
  final ConnectionType connectionType;

  const SignZilliqaTransactionOperation({
    required this.keyIndex,
    required this.transactionBytes,
    required this.connectionType,
  });

  @override
  Future<Uint8List> invoke(LedgerSendFct send) async {
    Uint8List txnBytes = transactionBytes;
    int txnOffset = 0;

    final indexBytesWriter = ByteDataWriter(endian: Endian.little);
    indexBytesWriter.writeInt32(keyIndex);
    final indexBytes = indexBytesWriter.toBytes();

    final firstChunkSize = min(txnBytes.length, STREAM_LEN);
    final txn1Bytes = txnBytes.sublist(txnOffset, txnOffset + firstChunkSize);
    txnOffset += firstChunkSize;
    final hostBytesLeft = txnBytes.length - txnOffset;

    final hostBytesLeftWriter = ByteDataWriter(endian: Endian.little);
    hostBytesLeftWriter.writeInt32(hostBytesLeft);
    final hostBytesLeftBytes = hostBytesLeftWriter.toBytes();

    final txn1SizeWriter = ByteDataWriter(endian: Endian.little);
    txn1SizeWriter.writeInt32(txn1Bytes.length);
    final txn1SizeBytes = txn1SizeWriter.toBytes();

    final firstPayloadWriter = ByteDataWriter();
    firstPayloadWriter.write(indexBytes);
    firstPayloadWriter.write(hostBytesLeftBytes);
    firstPayloadWriter.write(txn1SizeBytes);
    firstPayloadWriter.write(txn1Bytes);
    final firstPayload = firstPayloadWriter.toBytes();

    ByteDataReader responseReader = await send(
      LedgerSimpleOperation(
        cla: CLA,
        ins: INS_SIGN_TXN,
        p1: P1_FIRST,
        p2: P2_FIRST,
        data: firstPayload,
        prependDataLength: true,
        debugName: 'Sign Zilliqa Txn Chunk 1',
      ),
    );

    while (txnOffset < txnBytes.length) {
      final currentChunkSize = min(txnBytes.length - txnOffset, STREAM_LEN);
      final txnNBytes =
          txnBytes.sublist(txnOffset, txnOffset + currentChunkSize);
      txnOffset += currentChunkSize;
      final remainingBytes = txnBytes.length - txnOffset;

      final hostBytesLeftWriterNext = ByteDataWriter(endian: Endian.little);
      hostBytesLeftWriterNext.writeInt32(remainingBytes);
      final hostBytesLeftBytesNext = hostBytesLeftWriterNext.toBytes();

      final txnNSizeWriter = ByteDataWriter(endian: Endian.little);
      txnNSizeWriter.writeInt32(txnNBytes.length);
      final txnNSizeBytes = txnNSizeWriter.toBytes();

      final nextPayloadWriter = ByteDataWriter();
      nextPayloadWriter.write(hostBytesLeftBytesNext);
      nextPayloadWriter.write(txnNSizeBytes);
      nextPayloadWriter.write(txnNBytes);
      final nextPayload = nextPayloadWriter.toBytes();

      responseReader = await send(
        LedgerSimpleOperation(
          cla: CLA,
          ins: INS_SIGN_TXN,
          p1: P1_FIRST,
          p2: P2_FIRST,
          data: nextPayload,
          prependDataLength: true,
          debugName: 'Sign Zilliqa Txn Chunk N',
        ),
      );
    }

    if (responseReader.remainingLength < SIG_BYTE_LEN) {
      throw LedgerDeviceException(
        message:
            'Signature response too short. Expected $SIG_BYTE_LEN bytes, got ${responseReader.remainingLength}',
        connectionType: connectionType,
      );
    }

    final signatureBytes = responseReader.read(SIG_BYTE_LEN);
    return signatureBytes;
  }
}
