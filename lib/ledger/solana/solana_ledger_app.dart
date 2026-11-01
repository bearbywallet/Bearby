import 'dart:convert';
import 'dart:typed_data';

import 'package:bearby/config/bip_purposes.dart';
import 'package:bearby/config/web3_constants.dart';
import 'package:bearby/ledger/common.dart';
import 'package:bearby/ledger/transport/exceptions.dart';
import 'package:bearby/ledger/transport/transport.dart';
import 'package:bearby/src/rust/api/ledger.dart';
import 'package:bearby/src/rust/api/transaction.dart';
import 'package:bearby/src/rust/models/transactions/request.dart';
import 'package:bearby/utils/utils.dart';

class SolanaAppConfiguration {
  final bool blindSigningEnabled;
  final String pubkeyDisplayMode;
  final String version;

  const SolanaAppConfiguration({
    required this.blindSigningEnabled,
    required this.pubkeyDisplayMode,
    required this.version,
  });
}

class SolanaLedgerApp {
  static const int _cla = 0xe0;

  static const int _insGetAppConfiguration = 0x04;
  static const int _insGetPubkey = 0x05;
  static const int _insSignMessage = 0x06;
  static const int _insSignOffchainMessage = 0x07;

  static const int _p1NonConfirm = 0x00;
  static const int _p1Confirm = 0x01;

  static const int _p2Extend = 0x01;
  static const int _p2More = 0x02;

  static const int _maxPayload = 255;
  static const int _pubKeyLength = 32;
  static const int _signatureLength = 64;

  final Transport transport;

  SolanaLedgerApp(this.transport);

  static String defaultDerivationPath(int index) {
    if (index < 0) {
      throw ArgumentError.value(
        index,
        'index',
        'Account index cannot be negative',
      );
    }
    return "$kBip44Purpose'/$kSolanaSlip44'/$index'/0'";
  }

  static String _normalizeHardenedPath(String originalPath) {
    var trimmed = originalPath.trim();
    if (trimmed.startsWith('m/') || trimmed.startsWith('M/')) {
      trimmed = trimmed.substring(2);
    }
    if (trimmed.isEmpty) {
      throw ArgumentError.value(
        originalPath,
        'originalPath',
        'Derivation path cannot be empty',
      );
    }

    final segments = trimmed
        .split('/')
        .where((segment) => segment.isNotEmpty)
        .map((segment) {
      if (segment.endsWith("'")) {
        return segment;
      }
      if (segment.endsWith('h') || segment.endsWith('H')) {
        return "${segment.substring(0, segment.length - 1)}'";
      }
      return "$segment'";
    }).toList();

    if (segments.isEmpty) {
      throw ArgumentError.value(
        originalPath,
        'originalPath',
        'Derivation path cannot be empty',
      );
    }

    return segments.join('/');
  }

  Future<Uint8List> pathToBuffer(String originalPath) async {
    final normalizedPath = _normalizeHardenedPath(originalPath);
    final paths = await ledgerSplitPath(path: normalizedPath);

    final buffer = Uint8List(1 + paths.length * 4);
    final view = ByteData.view(buffer.buffer);
    view.setUint8(0, paths.length);
    for (int i = 0; i < paths.length; i++) {
      view.setUint32(1 + i * 4, paths[i], Endian.big);
    }
    return buffer;
  }

  Future<Uint8List> _sendToDevice(
    int instruction,
    int p1,
    Uint8List payload,
  ) async {
    int p2 = 0;
    int payloadOffset = 0;

    if (payload.length > _maxPayload) {
      while (payload.length - payloadOffset > _maxPayload) {
        final chunk = payload.sublist(
          payloadOffset,
          payloadOffset + _maxPayload,
        );
        payloadOffset += _maxPayload;

        final reply = await transport.send(
          _cla,
          instruction,
          p1,
          p2 | _p2More,
          chunk,
        );

        if (reply.isNotEmpty) {
          throw TransportException(
            'solana.sendToDevice: received unexpected reply payload',
            'UnexpectedReplyPayload',
          );
        }

        p2 |= _p2Extend;
      }
    }

    final finalChunk = payload.sublist(payloadOffset);
    return await transport.send(
      _cla,
      instruction,
      p1,
      p2,
      finalChunk,
    );
  }

  Future<SolanaAppConfiguration?> getAppConfiguration() async {
    try {
      final response = await transport.send(
        _cla,
        _insGetAppConfiguration,
        _p1NonConfirm,
        0x00,
        Uint8List(0),
      );

      if (response.length < 5) {
        return null;
      }

      final blindSigningEnabled = response[0] != 0;
      final pubkeyDisplayMode = response[1] == 0 ? 'long' : 'short';
      final version = '${response[2]}.${response[3]}.${response[4]}';

      return SolanaAppConfiguration(
        blindSigningEnabled: blindSigningEnabled,
        pubkeyDisplayMode: pubkeyDisplayMode,
        version: version,
      );
    } catch (_) {
      return null;
    }
  }

  Future<LedgerAccount> getAddress({
    required int index,
    bool display = false,
    String? path,
  }) async {
    if (index < 0) {
      throw ArgumentError.value(
        index,
        'index',
        'Account index cannot be negative',
      );
    }

    final derivationPath = path ?? defaultDerivationPath(index);
    final pathBuffer = await pathToBuffer(derivationPath);

    final pubKeyBytes = await _sendToDevice(
      _insGetPubkey,
      display ? _p1Confirm : _p1NonConfirm,
      pathBuffer,
    );

    if (pubKeyBytes.length != _pubKeyLength) {
      throw TransportException(
        'Invalid Solana public key length: expected $_pubKeyLength bytes, got ${pubKeyBytes.length}',
        'InvalidPubKeyLength',
      );
    }

    final address = await ledgerSolanaPubkeyToAddress(pubkey: pubKeyBytes);
    final publicKey = bytesToHex(pubKeyBytes);

    return LedgerAccount(
      address: address,
      index: index,
      publicKey: publicKey,
    );
  }

  Future<List<LedgerAccount>> getAccounts({
    required List<int> indices,
    bool display = false,
  }) async {
    final accounts = <LedgerAccount>[];
    for (final index in indices) {
      final account = await getAddress(index: index, display: display);
      accounts.add(account);
    }
    return accounts;
  }

  Future<Uint8List> signTransaction({
    required int index,
    required Uint8List txBytes,
    String? path,
  }) async {
    if (index < 0) {
      throw ArgumentError.value(
        index,
        'index',
        'Account index cannot be negative',
      );
    }
    if (txBytes.isEmpty) {
      throw ArgumentError.value(
        txBytes,
        'txBytes',
        'Transaction bytes cannot be empty',
      );
    }

    final derivationPath = path ?? defaultDerivationPath(index);
    final pathBuffer = await pathToBuffer(derivationPath);

    final payload = Uint8List(1 + pathBuffer.length + txBytes.length);
    payload[0] = 1;
    payload.setRange(1, 1 + pathBuffer.length, pathBuffer);
    payload.setRange(1 + pathBuffer.length, payload.length, txBytes);

    final signatureBuffer = await _sendToDevice(
      _insSignMessage,
      _p1Confirm,
      payload,
    );

    if (signatureBuffer.length != _signatureLength) {
      throw TransportException(
        'Invalid Solana signature length: expected $_signatureLength bytes, got ${signatureBuffer.length}',
        'InvalidSignatureLength',
      );
    }

    return signatureBuffer;
  }

  Future<Uint8List> signTransactionRequest({
    required TransactionRequestInfo transaction,
    required int walletIndex,
    required int accountIndex,
    required int ledgerIndex,
    String? path,
  }) async {
    final encodedTx = await encodeTxRlp(
      tx: transaction,
      walletIndex: BigInt.from(walletIndex),
      accountIndex: BigInt.from(accountIndex),
      slip44: kSolanaSlip44,
    );

    return signTransaction(
      index: ledgerIndex,
      txBytes: encodedTx.bytes,
      path: path,
    );
  }

  Future<Uint8List> signOffchainMessage({
    required int index,
    required Uint8List message,
    String? path,
    Uint8List? signerPubkey,
    String? signerAddress,
  }) async {
    if (index < 0) {
      throw ArgumentError.value(
        index,
        'index',
        'Account index cannot be negative',
      );
    }
    if (message.isEmpty) {
      throw ArgumentError.value(
        message,
        'message',
        'Message bytes cannot be empty',
      );
    }

    final derivationPath = path ?? defaultDerivationPath(index);
    final pathBuffer = await pathToBuffer(derivationPath);

    Uint8List? resolvedPubkey = signerPubkey;
    if (resolvedPubkey == null &&
        (signerAddress == null || signerAddress.isEmpty)) {
      final pubKeyBytes = await _sendToDevice(
        _insGetPubkey,
        _p1NonConfirm,
        pathBuffer,
      );
      if (pubKeyBytes.length != _pubKeyLength) {
        throw TransportException(
          'Invalid Solana public key length: expected $_pubKeyLength bytes, got ${pubKeyBytes.length}',
          'InvalidPubKeyLength',
        );
      }
      resolvedPubkey = pubKeyBytes;
    }

    final formattedMessage = await ledgerSolanaPrepareOffchainMessage(
      message: message,
      signerPubkey: resolvedPubkey,
      signerAddress: signerAddress,
    );

    final payload = Uint8List(1 + pathBuffer.length + formattedMessage.length);
    payload[0] = 1;
    payload.setRange(1, 1 + pathBuffer.length, pathBuffer);
    payload.setRange(1 + pathBuffer.length, payload.length, formattedMessage);

    final signatureBuffer = await _sendToDevice(
      _insSignOffchainMessage,
      _p1Confirm,
      payload,
    );

    if (signatureBuffer.length != _signatureLength) {
      throw TransportException(
        'Invalid Solana signature length: expected $_signatureLength bytes, got ${signatureBuffer.length}',
        'InvalidSignatureLength',
      );
    }

    return signatureBuffer;
  }

  Future<String> signPersonalMessage({
    required int index,
    required String message,
    String? path,
    Uint8List? signerPubkey,
    String? signerAddress,
  }) async {
    if (message.isEmpty) {
      throw ArgumentError.value(
        message,
        'message',
        'Message cannot be empty',
      );
    }

    final Uint8List messageBytes = _decodeMessagePayload(message);
    final sigBytes = await signOffchainMessage(
      index: index,
      message: messageBytes,
      path: path,
      signerPubkey: signerPubkey,
      signerAddress: signerAddress,
    );
    return bytesToHex(sigBytes);
  }

  static Uint8List _decodeMessagePayload(String message) {
    if (message.startsWith('0x') || message.startsWith('0X')) {
      final hexPart = message.substring(2);
      if (hexPart.isNotEmpty && hexPart.length.isEven) {
        try {
          return hexToBytes(hexPart);
        } catch (_) {}
      }
    }
    return Uint8List.fromList(utf8.encode(message));
  }
}
