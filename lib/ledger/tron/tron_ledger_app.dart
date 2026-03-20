import 'dart:convert';
import 'dart:typed_data';

import 'package:bearby/config/bip_purposes.dart';
import 'package:bearby/config/web3_constants.dart';
import 'package:bearby/ledger/common.dart';
import 'package:bearby/ledger/ethereum/models.dart';
import 'package:bearby/ledger/ledger_operation.dart';
import 'package:bearby/ledger/tron/models.dart';
import 'package:bearby/ledger/transport/transport.dart';
import 'package:bearby/src/rust/api/ledger.dart';
import 'package:bearby/src/rust/api/transaction.dart';
import 'package:bearby/src/rust/models/transactions/request.dart';
import 'package:bearby/utils/utils.dart';

class _DecodeResult {
  final int value;
  final int position;

  _DecodeResult({required this.value, required this.position});
}

class TronLedgerApp {
  static const int _cla = 0xe0;
  static const int _chunkSize = 250;

  static const int _insGetAddress = 0x02;
  static const int _insSignTransaction = 0x04;
  static const int _insSignTransactionHash = 0x05;
  static const int _insGetAppConfiguration = 0x06;
  static const int _insSignPersonalMessage = 0x08;
  static const int _insGetECDHPairKey = 0x0a;
  static const int _insSignTIP712HashedMessage = 0x0c;

  final Transport transport;

  TronLedgerApp(this.transport);

  Future<List<int>> _getPaths(int index) async {
    final String path = "$kBip44Purpose'/195'/0'/0/$index";
    final paths = await ledgerSplitPath(path: path);
    return paths;
  }

  Uint8List _buildPathPayload(List<int> paths) {
    final writer = ByteDataWriter(endian: Endian.big);
    writer.writeUint8(paths.length);
    for (final element in paths) {
      writer.writeUint32(element);
    }
    return writer.toBytes();
  }

  Future<TronAppConfiguration> getAppConfiguration() async {
    final response = await transport.send(
      _cla,
      _insGetAppConfiguration,
      0x00,
      0x00,
      Uint8List(0),
    );

    if (response.length < 4) {
      throw FormatException(
          'Invalid app configuration response, got ${response.length} bytes');
    }

    final flags = response[0];
    final version = '${response[1]}.${response[2]}.${response[3]}';

    return TronAppConfiguration(
      allowData: (flags & 0x01) != 0,
      allowContract: (flags & 0x02) != 0,
      truncateAddress: (flags & 0x04) != 0,
      signByHash: (flags & 0x08) != 0,
      version: version,
    );
  }

  Future<LedgerAccount> getAddress({
    required int index,
    bool boolDisplay = false,
  }) async {
    final paths = await _getPaths(index);
    final buffer = _buildPathPayload(paths);

    final response = await transport.send(
      _cla,
      _insGetAddress,
      boolDisplay ? 0x01 : 0x00,
      0x00,
      buffer,
    );

    final publicKeyLength = response[0];
    final addressLength = response[1 + publicKeyLength];

    final publicKey = bytesToHex(
      response.sublist(1, 1 + publicKeyLength),
    );
    final address = ascii.decode(
      response.sublist(
        1 + publicKeyLength + 1,
        1 + publicKeyLength + 1 + addressLength,
      ),
    );

    return LedgerAccount(
      publicKey: publicKey,
      address: address,
      index: index,
    );
  }

  Future<List<LedgerAccount>> getAccounts({
    required List<int> indices,
  }) async {
    final List<LedgerAccount> accounts = [];
    for (final int index in indices) {
      final account = await getAddress(index: index);
      accounts.add(account);
    }
    return accounts;
  }

  _DecodeResult _decodeVarint(Uint8List bytes, int index) {
    int value = 0;
    int shift = 0;
    int pos = index;

    while (pos < bytes.length) {
      final byte = bytes[pos];
      value |= (byte & 0x7f) << shift;
      pos++;
      if ((byte & 0x80) == 0) break;
      shift += 7;
    }

    return _DecodeResult(value: value, position: pos);
  }

  int _getNextFieldEnd(Uint8List tx) {
    if (tx.isEmpty) return 0;

    final tagResult = _decodeVarint(tx, 0);
    final wireType = tagResult.value & 0x07;

    switch (wireType) {
      case 0: // Varint
        final valueResult = _decodeVarint(tx, tagResult.position);
        return valueResult.position;
      case 1: // 64-bit
        return tagResult.position + 8;
      case 2: // Length-delimited
        final lengthResult = _decodeVarint(tx, tagResult.position);
        return lengthResult.position + lengthResult.value;
      case 5: // 32-bit
        return tagResult.position + 4;
      default:
        return tx.length;
    }
  }

  Future<EthLedgerSignature> clearSignTransaction({
    required TransactionRequestInfo transaction,
    required int walletIndex,
    required int accountIndex,
  }) async {
    final txRLP = await encodeTxRlp(
      tx: transaction,
      walletIndex: BigInt.from(walletIndex),
      accountIndex: BigInt.from(accountIndex),
      slip44: kTronSlip44,
    );

    final sig = await signTransaction(
      index: accountIndex,
      rawTx: Uint8List.fromList(txRLP.bytes),
    );

    return sig;
  }

  Future<EthLedgerSignature> signTransaction({
    required int index,
    required Uint8List rawTx,
    List<Uint8List>? tokenSignatures,
  }) async {
    final paths = await _getPaths(index);
    final pathPayload = _buildPathPayload(paths);

    final List<Uint8List> chunks = [];
    List<int> currentBuffer = List<int>.from(pathPayload);
    int offset = 0;

    while (offset < rawTx.length) {
      final remaining = Uint8List.sublistView(rawTx, offset);
      final fieldEnd = _getNextFieldEnd(remaining);
      final fieldSize = fieldEnd > 0 ? fieldEnd : remaining.length;

      if (currentBuffer.length + fieldSize > _chunkSize) {
        if (currentBuffer.isNotEmpty) {
          chunks.add(Uint8List.fromList(currentBuffer));
          currentBuffer = [];
        }
        if (fieldSize > _chunkSize) {
          int fieldOffset = 0;
          final fieldData = rawTx.sublist(offset, offset + fieldSize);
          while (fieldOffset < fieldData.length) {
            final end = (fieldOffset + _chunkSize > fieldData.length)
                ? fieldData.length
                : fieldOffset + _chunkSize;
            chunks.add(Uint8List.fromList(fieldData.sublist(fieldOffset, end)));
            fieldOffset = end;
          }
          offset += fieldSize;
          continue;
        }
      }

      currentBuffer.addAll(rawTx.sublist(offset, offset + fieldSize));
      offset += fieldSize;
    }

    if (currentBuffer.isNotEmpty) {
      chunks.add(Uint8List.fromList(currentBuffer));
    }

    final List<int> p1Values = [];
    if (chunks.length == 1) {
      p1Values.add(0x10);
    } else {
      for (int i = 0; i < chunks.length; i++) {
        if (i == 0) {
          p1Values.add(0x00);
        } else if (i == chunks.length - 1) {
          p1Values.add(0x90);
        } else {
          p1Values.add(0x80);
        }
      }
    }

    late Uint8List response;
    for (int i = 0; i < chunks.length; i++) {
      response = await transport.send(
        _cla,
        _insSignTransaction,
        p1Values[i],
        0x00,
        chunks[i],
      );
    }

    if (tokenSignatures != null && tokenSignatures.isNotEmpty) {
      for (int i = 0; i < tokenSignatures.length; i++) {
        final isLast = i == tokenSignatures.length - 1;
        final p1 = isLast ? (0xA0 | 0x08 | i) : (0xA0 | i);

        response = await transport.send(
          _cla,
          _insSignTransaction,
          p1,
          0x00,
          tokenSignatures[i],
        );
      }
    }

    if (response.length != 65) {
      throw FormatException(
          'Response must be exactly 65 bytes, got ${response.length}');
    }
    int v = response[64];
    Uint8List r = Uint8List.fromList(response.sublist(0, 32));
    Uint8List s = Uint8List.fromList(response.sublist(32, 64));
    return EthLedgerSignature(v: v, r: r, s: s);
  }

  Future<EthLedgerSignature> signTransactionHash({
    required int index,
    required Uint8List hash,
  }) async {
    if (hash.length != 32) {
      throw ArgumentError('Hash must be 32 bytes long');
    }

    final paths = await _getPaths(index);
    final pathPayload = _buildPathPayload(paths);

    final writer = ByteDataWriter(endian: Endian.big);
    writer.write(pathPayload);
    writer.write(hash);

    final response = await transport.send(
      _cla,
      _insSignTransactionHash,
      0x00,
      0x00,
      writer.toBytes(),
    );

    return EthLedgerSignature.fromLedgerResponse(response);
  }

  Future<EthLedgerSignature> signPersonalMessage({
    required int index,
    required Uint8List message,
  }) async {
    final paths = await _getPaths(index);

    int offset = 0;
    late Uint8List response;

    while (offset < message.length) {
      final bool isFirstChunk = offset == 0;
      final int maxChunkSize =
          isFirstChunk ? _chunkSize - 1 - (paths.length * 4) - 4 : _chunkSize;

      final int chunkSize = (offset + maxChunkSize > message.length)
          ? message.length - offset
          : maxChunkSize;

      final Uint8List chunkData = message.sublist(offset, offset + chunkSize);
      late Uint8List buffer;

      if (isFirstChunk) {
        final writer = ByteDataWriter(endian: Endian.big);
        writer.writeUint8(paths.length);
        for (final element in paths) {
          writer.writeUint32(element);
        }
        writer.writeUint32(message.length);
        writer.write(chunkData);
        buffer = writer.toBytes();
      } else {
        buffer = chunkData;
      }

      response = await transport.send(
        _cla,
        _insSignPersonalMessage,
        isFirstChunk ? 0x00 : 0x80,
        0x00,
        buffer,
      );

      offset += chunkSize;
    }

    return EthLedgerSignature.fromLedgerResponse(response);
  }

  Future<EthLedgerSignature> signTIP712HashedMessage({
    required int index,
    required Uint8List domainSeparator,
    required Uint8List hashStructMessage,
  }) async {
    if (domainSeparator.length != 32 || hashStructMessage.length != 32) {
      throw ArgumentError(
          'domainSeparator and hashStructMessage must be 32 bytes long');
    }

    final paths = await _getPaths(index);

    final writer = ByteDataWriter(endian: Endian.big);
    writer.writeUint8(paths.length);
    for (final element in paths) {
      writer.writeUint32(element);
    }
    writer.write(domainSeparator);
    writer.write(hashStructMessage);

    final response = await transport.send(
      _cla,
      _insSignTIP712HashedMessage,
      0x00,
      0x00,
      writer.toBytes(),
    );

    return EthLedgerSignature.fromLedgerResponse(response);
  }

  Future<Uint8List> getECDHPairKey({
    required int index,
    required Uint8List publicKey,
  }) async {
    if (publicKey.length != 65) {
      throw ArgumentError('Public key must be 65 bytes long');
    }

    final paths = await _getPaths(index);

    final writer = ByteDataWriter(endian: Endian.big);
    writer.writeUint8(paths.length);
    for (final element in paths) {
      writer.writeUint32(element);
    }
    writer.write(publicKey);

    final response = await transport.send(
      _cla,
      _insGetECDHPairKey,
      0x01,
      0x00,
      writer.toBytes(),
    );

    return Uint8List.fromList(response.sublist(1, 66));
  }
}
