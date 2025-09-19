import 'dart:convert';
import 'dart:typed_data';

import 'package:zilpay/ledger/common.dart';
import 'package:zilpay/ledger/ledger_operation.dart';
import 'package:zilpay/ledger/transport/transport.dart';
import 'package:zilpay/ledger/zilliqa/zilliqa_exception.dart';
import 'package:zilpay/src/rust/api/transaction.dart';
import 'package:zilpay/src/rust/models/transactions/request.dart';
import 'package:zilpay/utils/utils.dart';

class _ZilliqaIns {
  static const int getVersion = 0x01;
  static const int getPublicKey = 0x02;
  static const int getPublicAddress = 0x02;
  static const int signTxn = 0x04;
  static const int signHash = 0x08;
}

class ZilliqaLedgerApp {
  static const int _cla = 0xe0;
  static const int _pubKeyByteLen = 33;
  static const int _sigByteLen = 64;
  static const int _hashByteLen = 32;

  final Transport transport;

  ZilliqaLedgerApp(this.transport);

  Future<String?> getVersion() async {
    const p1 = 0x00;
    const p2 = 0x00;

    final response = await transport.send(
      _cla,
      _ZilliqaIns.getVersion,
      p1,
      p2,
      Uint8List(0),
      checkZilliqaSW,
    );

    if (response.isEmpty || (response[0] != 0 && response[0] != 1)) {
      return null;
    }

    return 'v${response[0]}.${response[1]}.${response[2]}';
  }

  Future<Uint8List> getPublicKey(int index) async {
    const p1 = 0x00;
    const p2 = 0x00;

    final payload = _buildIndexPayload(index);
    final response = await transport.send(
      _cla,
      _ZilliqaIns.getPublicKey,
      p1,
      p2,
      payload,
      checkZilliqaSW,
    );

    return response.sublist(0, _pubKeyByteLen);
  }

  Future<List<LedgerAccount>> getPublicAddress(
    List<int> accountIndices,
  ) async {
    final List<LedgerAccount> accounts = [];

    for (final index in accountIndices) {
      final account = await getPublicAddres(index);

      accounts.add(account);
    }

    return accounts;
  }

  Future<LedgerAccount> getPublicAddres(int index) async {
    const p1 = 0x00;
    const p2 = 0x01;
    const bech32AddrLen = 42;

    final payload = _buildIndexPayload(index);
    final response = await transport.send(
      _cla,
      _ZilliqaIns.getPublicAddress,
      p1,
      p2,
      payload,
      checkZilliqaSW,
    );

    final publicKey = bytesToHex(response.sublist(0, _pubKeyByteLen));
    final pubAddr = utf8.decode(
      response.sublist(_pubKeyByteLen, _pubKeyByteLen + bech32AddrLen),
    );

    return LedgerAccount(
      publicKey: publicKey,
      address: pubAddr,
      index: index,
    );
  }

  Future<String> signHash(int keyIndex, Uint8List hashBytes) async {
    const p1 = 0x00;
    const p2 = 0x00;

    final indexBytes = _buildIndexPayload(keyIndex);

    if (hashBytes.isEmpty) {
      throw ArgumentError('Hash length is invalid');
    }

    if (hashBytes.length > _hashByteLen) {
      hashBytes = hashBytes.sublist(0, _hashByteLen);
    }

    final payload = Uint8List.fromList([...indexBytes, ...hashBytes]);
    final response = await transport.send(
      _cla,
      _ZilliqaIns.signHash,
      p1,
      p2,
      payload,
    );

    return bytesToHex(response.sublist(0, _sigByteLen));
  }

  Future<Uint8List> signTxn({
    required int keyIndex,
    required TransactionRequestInfo transaction,
    required int walletIndex,
    required int accountIndex,
  }) async {
    const p1 = 0x00;
    const p2 = 0x00;
    const streamLen = 128;

    final txProto = await encodeTxRlp(
      tx: transaction,
      walletIndex: BigInt.from(walletIndex),
      accountIndex: BigInt.from(accountIndex),
      slip44: 313,
    );
    final txnBytes = txProto.bytes;

    final indexBytes = _buildIndexPayload(keyIndex);
    int offset = 0;
    Uint8List response;

    final firstChunkLen =
        (txnBytes.length > streamLen) ? streamLen : txnBytes.length;
    final firstChunk = txnBytes.sublist(0, firstChunkLen);
    offset += firstChunkLen;

    final initialWriter = ByteDataWriter(endian: Endian.little)
      ..write(indexBytes)
      ..writeInt32(txnBytes.length - offset)
      ..writeInt32(firstChunk.length)
      ..write(firstChunk);

    response = await transport.send(
      _cla,
      _ZilliqaIns.signTxn,
      p1,
      p2,
      initialWriter.toBytes(),
    );

    while (offset < txnBytes.length) {
      final chunkLen = (txnBytes.length - offset > streamLen)
          ? streamLen
          : txnBytes.length - offset;
      final chunk = txnBytes.sublist(offset, offset + chunkLen);
      offset += chunkLen;

      final subsequentWriter = ByteDataWriter(endian: Endian.little)
        ..writeInt32(txnBytes.length - offset)
        ..writeInt32(chunk.length)
        ..write(chunk);

      response = await transport.send(
        _cla,
        _ZilliqaIns.signTxn,
        p1,
        p2,
        subsequentWriter.toBytes(),
      );
    }

    return response.sublist(0, _sigByteLen);
  }

  Uint8List _buildIndexPayload(int index) {
    final writer = ByteDataWriter(endian: Endian.little);
    writer.writeInt32(index);
    return writer.toBytes();
  }
}
