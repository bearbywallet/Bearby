import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:zilpay/ledger/common.dart';
import 'package:zilpay/ledger/ethereum/ledger_resolver.dart';
import 'package:zilpay/ledger/ethereum/models.dart';
import 'package:zilpay/ledger/ethereum/resolution_types.dart';
import 'package:zilpay/ledger/ledger_operation.dart';
import 'package:zilpay/ledger/transport/exceptions.dart';
import 'package:zilpay/ledger/transport/transport.dart';
import 'package:zilpay/src/rust/api/ledger.dart';
import 'package:zilpay/src/rust/api/transaction.dart';
import 'package:zilpay/src/rust/models/transactions/request.dart';
import 'package:zilpay/utils/utils.dart';

class EthLedgerApp {
  final Transport transport;

  EthLedgerApp(this.transport);

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
    ResolutionConfig? resolutionConfig,
  }) async {
    final config = resolutionConfig ??
        const ResolutionConfig(
          erc20: true,
          externalPlugins: true,
          nft: false,
          uniswapV3: false,
        );

    LedgerEthTransactionResolution? resolution;
    try {
      resolution = await LedgerTransactionResolver.resolveTransaction(
        transaction,
        const LoadConfig(),
        config,
      );
    } catch (e) {
      debugPrint(
          '[LEDGER_ERROR] Resolution failed, falling back to blind signing: $e');
    }

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
      resolution: resolution,
    );
  }

  Future<EthLedgerSignature> signTransaction({
    required int index,
    required int slip44,
    required List<Uint8List> transactionChunks,
    LedgerEthTransactionResolution? resolution,
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

    if (resolution != null) {
      for (final plugin in resolution.plugin) {
        await _setPlugin(plugin);
      }
      for (final extPlugin in resolution.externalPlugin) {
        await _setExternalPlugin(extPlugin.payload, extPlugin.signature);
      }
      for (final nft in resolution.nfts) {
        await _provideNFTInformation(nft);
      }
      for (final token in resolution.erc20Tokens) {
        await _provideERC20TokenInformation(token);
      }
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

  Future<void> _provideERC20TokenInformation(String dataHex) async {
    try {
      final buffer = hexToBytes(dataHex);
      await transport.send(0xe0, 0x0a, 0x00, 0x00, buffer);
    } on TransportStatusError catch (e) {
      if (e.statusCode == 0x6d00) {
        return;
      }
      rethrow;
    }
  }

  Future<void> _provideNFTInformation(String dataHex) async {
    try {
      final buffer = hexToBytes(dataHex);
      await transport.send(0xe0, 0x14, 0x00, 0x00, buffer);
    } on TransportStatusError catch (e) {
      if (e.statusCode == 0x6d00) {
        throw TransportException(
          'NFT resolution not supported by the app version',
          'NftNotSupported',
        );
      }
      rethrow;
    }
  }

  Future<void> _setExternalPlugin(String payload, String signature) async {
    try {
      final payloadBuffer = hexToBytes(payload);
      final signatureBuffer = hexToBytes(signature);
      final buffer = Uint8List.fromList([...payloadBuffer, ...signatureBuffer]);
      await transport.send(0xe0, 0x12, 0x00, 0x00, buffer);
    } on TransportStatusError catch (e) {
      if (e.statusCode == 0x6a80 ||
          e.statusCode == 0x6984 ||
          e.statusCode == 0x6d00) {
        return;
      }
      rethrow;
    }
  }

  Future<void> _setPlugin(String data) async {
    try {
      final buffer = hexToBytes(data);
      await transport.send(0xe0, 0x16, 0x00, 0x00, buffer);
    } on TransportStatusError catch (e) {
      if (e.statusCode == 0x6a80 ||
          e.statusCode == 0x6984 ||
          e.statusCode == 0x6d00) {
        return;
      }
      rethrow;
    }
  }
}
