import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:zilpay/ledger/common.dart';
import 'package:zilpay/ledger/ethereum/models.dart';
import 'package:zilpay/ledger/ledger_operation.dart';
import 'package:zilpay/ledger/transport/exceptions.dart';
import 'package:zilpay/ledger/transport/transport.dart';
import 'package:zilpay/src/rust/api/ledger.dart';
import 'package:zilpay/src/rust/api/transaction.dart';
import 'package:zilpay/src/rust/models/transactions/request.dart';
import 'package:zilpay/utils/utils.dart';

class EthAppConfiguration {
  final String version;

  EthAppConfiguration({required this.version});
}

class EthLedgerApp {
  static const int _cla = 0xe0;
  static const int _insGetAppConfiguration = 0x06;

  final Transport transport;

  EthLedgerApp(this.transport);

  Future<EthAppConfiguration?> getAppConfiguration() async {
    try {
      final response = await transport.send(
        _cla,
        _insGetAppConfiguration,
        0x00,
        0x00,
        Uint8List(0),
      );

      if (response.isEmpty || response.length < 4) {
        return null;
      }

      final version = 'v${response[1]}.${response[2]}.${response[3]}';
      return EthAppConfiguration(version: version);
    } catch (e) {
      return null;
    }
  }

  Future<List<int>> _getPaths({required int slip44, required int index}) async {
    final String path = "44'/$slip44'/0'/0/$index";
    final paths = await ledgerSplitPath(path: path);
    return paths;
  }

  Future<List<LedgerAccount>> getAccounts({
    required List<int> indices,
    int slip44 = 60,
    bool boolChaincode = false,
    int? chainId,
  }) async {
    final List<LedgerAccount> accounts = [];
    for (final int index in indices) {
      final account = await getAddress(
        index: index,
        slip44: slip44,
        boolDisplay: false,
        boolChaincode: boolChaincode,
        chainId: chainId,
      );
      accounts.add(account);
    }
    return accounts;
  }

  Future<LedgerAccount> getAddress({
    required int index,
    int slip44 = 60,
    bool boolDisplay = false,
    bool boolChaincode = false,
    int? chainId,
  }) async {
    final paths = await _getPaths(slip44: slip44, index: index);

    final writer = ByteDataWriter(endian: Endian.big);
    writer.writeUint8(paths.length);
    for (final element in paths) {
      writer.writeUint32(element);
    }
    var buffer = writer.toBytes();

    if (chainId != null) {
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

  Future<EthLedgerSignature> signPersonalMessage({
    required int index,
    required Uint8List message,
    int slip44 = 60,
  }) async {
    final paths = await _getPaths(slip44: slip44, index: index);

    int offset = 0;
    late Uint8List response;

    while (offset < message.length) {
      final bool isFirstChunk = offset == 0;
      final int maxChunkSize =
          isFirstChunk ? 150 - 1 - (paths.length * 4) - 4 : 150;

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
        0xe0,
        0x08,
        isFirstChunk ? 0x00 : 0x80,
        0x00,
        buffer,
      );

      offset += chunkSize;
    }

    return EthLedgerSignature.fromLedgerResponse(response);
  }

  Future<EthLedgerSignature> signEIP712HashedMessage({
    required int index,
    required Uint8List domainSeparator,
    required Uint8List hashStructMessage,
    int slip44 = 60,
  }) async {
    final paths = await _getPaths(slip44: slip44, index: index);

    if (domainSeparator.length != 32 || hashStructMessage.length != 32) {
      throw ArgumentError(
          'domainSeparator and hashStructMessage must be 32 bytes long');
    }

    final writer = ByteDataWriter(endian: Endian.big);

    writer.writeUint8(paths.length);
    for (final element in paths) {
      writer.writeUint32(element);
    }

    writer.write(domainSeparator);
    writer.write(hashStructMessage);

    final buffer = writer.toBytes();

    final response = await transport.send(
      0xe0,
      0x0c,
      0x00,
      0x00,
      buffer,
    );

    return EthLedgerSignature.fromLedgerResponse(response);
  }

  Future<EthLedgerSignature> clearSignTransaction({
    required TransactionRequestInfo transaction,
    required int walletIndex,
    required int accountIndex,
    required int slip44,
  }) async {
    final EncodedRLPTx txRLP = await encodeTxRlp(
      tx: transaction,
      walletIndex: BigInt.from(walletIndex),
      accountIndex: BigInt.from(accountIndex),
      slip44: slip44,
    );

    return await signTransaction(
      index: accountIndex,
      slip44: slip44,
      transactionChunks: txRLP.chunksBytes,
    );
  }

  Future<EthLedgerSignature> signTransaction({
    required int index,
    required int slip44,
    required List<Uint8List> transactionChunks,
  }) async {
    if (transactionChunks.isEmpty) {
      throw ArgumentError('Transaction chunks cannot be empty.');
    }

    debugPrint('Total chunks: ${transactionChunks.length}');
    for (int i = 0; i < transactionChunks.length; i++) {
      final chunk = transactionChunks[i];
      debugPrint('Chunk $i length: ${chunk.length}');
      debugPrint('Chunk $i hex: ${bytesToHex(chunk)}...');
    }

    late Uint8List response;

    try {
      for (int i = 0; i < transactionChunks.length; i++) {
        await Future.delayed(const Duration(milliseconds: 50));
        final isFirstChunk = i == 0;

        response = await transport.send(
          0xe0, // CLA
          0x04, // INS
          isFirstChunk ? 0x00 : 0x80, // P1: 0x00
          0x00, // P2
          transactionChunks[i],
        );
      }
    } on TransportStatusError catch (e) {
      if (e.statusCode == 0x6a80) {
        throw TransportException(
          'Please enable Blind signing or Contract data in the Ethereum app Settings',
          'ContractDataNotEnabled',
        );
      }
      rethrow;
    }

    return EthLedgerSignature.fromLedgerResponse(response);
  }
}
