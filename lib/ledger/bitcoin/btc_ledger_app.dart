import 'package:flutter/foundation.dart';
import 'package:bearby/config/bip_purposes.dart';
import 'package:bearby/ledger/bitcoin/btc_constants.dart';
import 'package:bearby/ledger/common.dart';
import 'package:bearby/ledger/transport/exceptions.dart';
import 'package:bearby/ledger/transport/transport.dart';
import 'package:bearby/src/rust/api/btc_ledger.dart' as btc_ffi;
import 'package:bearby/src/rust/models/btc_chain.dart';

class BtcLedgerApp {
  final Transport transport;

  final List<Uint8List> _pendingElements = [];
  int _pendingElementSize = 0;

  BtcLedgerApp(this.transport);

  Future<Uint8List> getMasterFingerprint() async {
    final response = await _sendApdu(
      ins: BtcLedgerConstants.insGetMasterFingerprint,
      data: Uint8List(0),
    );
    return response.sublist(0, 4);
  }

  Future<String> getExtendedPubkey({
    required String path,
    bool display = false,
  }) async {
    final pathBytes = await btc_ffi.btcLedgerEncodePath(path: path);

    final response = await _sendApdu(
      ins: BtcLedgerConstants.insGetPubkey,
      data: Uint8List.fromList([display ? 0x01 : 0x00, ...pathBytes]),
    );

    return String.fromCharCodes(response).replaceAll('\x00', '');
  }

  Future<String> getWalletAddress({
    required btc_ffi.WalletPolicy walletPolicy,
    required int change,
    required int addressIndex,
    bool display = false,
  }) async {
    final dataBytes = <int>[
      display ? 0x01 : 0x00,
      ...walletPolicy.policyId,
      ...walletPolicy.policyHmac,
      change,
    ];
    final addrIdx = ByteData(4);
    addrIdx.setUint32(0, addressIndex, Endian.big);
    dataBytes.addAll(addrIdx.buffer.asUint8List());

    _pendingElements.clear();

    final preimageHashes = <Uint8List>[];
    final preimageData = <Uint8List>[];

    preimageHashes
        .add(await btc_ffi.btcLedgerSha256(data: walletPolicy.serialized));
    preimageData.add(walletPolicy.serialized);

    final allLeafHashes = <String, List<Uint8List>>{};
    final keyLeaves = <Uint8List>[];
    for (final keyInfo in walletPolicy.keysInfo) {
      final keyBytes = Uint8List.fromList(keyInfo.codeUnits);
      keyLeaves.add(await btc_ffi.btcLedgerHashLeaf(data: keyBytes));
      final keyPreimage = Uint8List.fromList([0x00, ...keyBytes]);
      preimageHashes.add(await btc_ffi.btcLedgerSha256(data: keyPreimage));
      preimageData.add(keyPreimage);
    }
    final keysRoot =
        await btc_ffi.btcLedgerComputeMerkleRoot(leafHashes: keyLeaves);
    allLeafHashes[_hexEncode(keysRoot)] = keyLeaves;

    final result = await _sendApduWithClientLoop(
      ins: BtcLedgerConstants.insGetWalletAddress,
      data: Uint8List.fromList(dataBytes),
      preimageHashes: preimageHashes,
      preimageData: preimageData,
      allLeafHashes: allLeafHashes,
    );

    if (result.finalResponse.isEmpty) {
      throw TransportException('Empty address response', 'EmptyAddress');
    }

    return String.fromCharCodes(result.finalResponse);
  }

  Future<BtcAccountXpubsInputInfo> getAccountXpubs({
    required int accountIndex,
  }) async {
    final bip44 =
        await getExtendedPubkey(path: "m/$kBip44Purpose'/0'/$accountIndex'");
    final bip49 =
        await getExtendedPubkey(path: "m/$kBip49Purpose'/0'/$accountIndex'");
    final bip84 =
        await getExtendedPubkey(path: "m/$kBip84Purpose'/0'/$accountIndex'");
    final bip86 =
        await getExtendedPubkey(path: "m/$kBip86Purpose'/0'/$accountIndex'");
    return BtcAccountXpubsInputInfo(
      bip44Xpub: bip44,
      bip49Xpub: bip49,
      bip84Xpub: bip84,
      bip86Xpub: bip86,
    );
  }

  Future<List<LedgerAccount>> getAccounts({
    required List<int> indices,
    required int bipPurpose,
    int accountIndex = 0,
  }) async {
    final fingerprint = await getMasterFingerprint();

    final accountPath = "m/$bipPurpose'/0'/$accountIndex'";
    final xpub = await getExtendedPubkey(path: accountPath);

    final walletPolicy = await btc_ffi.btcLedgerBuildWalletPolicy(
      xpub: xpub,
      masterFingerprint: fingerprint,
      bipPurpose: bipPurpose,
      accountIndex: accountIndex,
    );

    final List<LedgerAccount> accounts = [];
    for (final index in indices) {
      final address = await getWalletAddress(
        walletPolicy: walletPolicy,
        change: 0,
        addressIndex: index,
        display: false,
      );

      accounts.add(LedgerAccount(
        publicKey: null,
        address: address,
        index: index,
      ));
    }

    return accounts;
  }

  Future<List<Uint8List>> signPsbt({
    required Uint8List psbtBytes,
    required int bipPurpose,
    required int accountIndex,
  }) async {
    final fingerprint = await getMasterFingerprint();

    final accountPath = "m/$bipPurpose'/0'/$accountIndex'";
    final xpub = await getExtendedPubkey(path: accountPath);

    final walletPolicy = await btc_ffi.btcLedgerBuildWalletPolicy(
      xpub: xpub,
      masterFingerprint: fingerprint,
      bipPurpose: bipPurpose,
      accountIndex: accountIndex,
    );

    final preparedPsbt = await btc_ffi.btcLedgerPreparePsbt(
      psbtBytes: psbtBytes,
      masterFingerprint: fingerprint,
      bipPurpose: bipPurpose,
      accountIndex: accountIndex,
      xpub: xpub,
    );

    final merkelized = await btc_ffi.btcLedgerMerkelisePsbt(
      psbtBytes: preparedPsbt,
    );

    debugPrint('BTC PSBT merkelized: inputs=${merkelized.inputCount}, '
        'outputs=${merkelized.outputCount}, '
        'globalCommitLen=${merkelized.globalMapCommitment.length}, '
        'globalKeysLeaves=${merkelized.globalMapKeysLeaves.length}');

    final inputCountVarint = _encodeVarint(merkelized.inputCount);
    final outputCountVarint = _encodeVarint(merkelized.outputCount);

    final payload = <int>[
      ...merkelized.globalMapCommitment,
      ...inputCountVarint,
      ...merkelized.inputMapsRoot,
      ...outputCountVarint,
      ...merkelized.outputMapsRoot,
      ...walletPolicy.policyId,
      ...walletPolicy.policyHmac,
    ];

    final preimageHashes = <Uint8List>[...merkelized.preimageHashes];
    final preimageData = <Uint8List>[...merkelized.preimageData];

    preimageHashes
        .add(await btc_ffi.btcLedgerSha256(data: walletPolicy.serialized));
    preimageData.add(walletPolicy.serialized);

    for (final keyInfo in walletPolicy.keysInfo) {
      final keyBytes = Uint8List.fromList(keyInfo.codeUnits);
      final keyPreimage = Uint8List.fromList([0x00, ...keyBytes]);
      preimageHashes.add(await btc_ffi.btcLedgerSha256(data: keyPreimage));
      preimageData.add(keyPreimage);
    }

    final allLeafHashes = <String, List<Uint8List>>{};

    final globalKeysRoot = await btc_ffi.btcLedgerComputeMerkleRoot(
        leafHashes: merkelized.globalMapKeysLeaves);
    final globalValuesRoot = await btc_ffi.btcLedgerComputeMerkleRoot(
        leafHashes: merkelized.globalMapValuesLeaves);
    allLeafHashes[_hexEncode(globalKeysRoot)] = merkelized.globalMapKeysLeaves;
    allLeafHashes[_hexEncode(globalValuesRoot)] =
        merkelized.globalMapValuesLeaves;

    for (int i = 0; i < merkelized.inputCount; i++) {
      final keysRoot = await btc_ffi.btcLedgerComputeMerkleRoot(
          leafHashes: merkelized.inputMapKeysLeaves[i]);
      final valuesRoot = await btc_ffi.btcLedgerComputeMerkleRoot(
          leafHashes: merkelized.inputMapValuesLeaves[i]);
      allLeafHashes[_hexEncode(keysRoot)] = merkelized.inputMapKeysLeaves[i];
      allLeafHashes[_hexEncode(valuesRoot)] =
          merkelized.inputMapValuesLeaves[i];
    }

    final inputCommitmentLeaves = <Uint8List>[];
    for (final c in merkelized.inputMapCommitments) {
      inputCommitmentLeaves.add(await btc_ffi.btcLedgerHashLeaf(data: c));
    }
    allLeafHashes[_hexEncode(merkelized.inputMapsRoot)] = inputCommitmentLeaves;

    for (int i = 0; i < merkelized.outputCount; i++) {
      final keysRoot = await btc_ffi.btcLedgerComputeMerkleRoot(
          leafHashes: merkelized.outputMapKeysLeaves[i]);
      final valuesRoot = await btc_ffi.btcLedgerComputeMerkleRoot(
          leafHashes: merkelized.outputMapValuesLeaves[i]);
      allLeafHashes[_hexEncode(keysRoot)] = merkelized.outputMapKeysLeaves[i];
      allLeafHashes[_hexEncode(valuesRoot)] =
          merkelized.outputMapValuesLeaves[i];
    }

    final outputCommitmentLeaves = <Uint8List>[];
    for (final c in merkelized.outputMapCommitments) {
      outputCommitmentLeaves.add(await btc_ffi.btcLedgerHashLeaf(data: c));
    }
    allLeafHashes[_hexEncode(merkelized.outputMapsRoot)] =
        outputCommitmentLeaves;

    final keyLeaf = await btc_ffi.btcLedgerHashLeaf(
        data: Uint8List.fromList(walletPolicy.keysInfo.first.codeUnits));
    final keysRoot =
        await btc_ffi.btcLedgerComputeMerkleRoot(leafHashes: [keyLeaf]);
    allLeafHashes[_hexEncode(keysRoot)] = [keyLeaf];

    final result = await _sendApduWithClientLoop(
      ins: BtcLedgerConstants.insSignPsbt,
      data: Uint8List.fromList(payload),
      preimageHashes: preimageHashes,
      preimageData: preimageData,
      allLeafHashes: allLeafHashes,
    );

    final sigMap = <int, Uint8List>{};
    for (final yielded in result.yielded) {
      if (yielded.length < 2) continue;
      final inputIndex = yielded[0];
      final signature = yielded.sublist(1);
      debugPrint(
          'BTC YIELD: inputIndex=$inputIndex, sigLen=${signature.length}');
      sigMap[inputIndex] = signature;
    }

    final sortedSigs = <Uint8List>[];
    final keys = sigMap.keys.toList()..sort();
    for (final key in keys) {
      sortedSigs.add(sigMap[key]!);
    }
    return sortedSigs;
  }

  Future<Uint8List> signMessage({
    required String message,
    required int bipPurpose,
    required int index,
    int accountIndex = 0,
  }) async {
    final msgBytes = Uint8List.fromList(message.codeUnits);

    final chunks = <Uint8List>[];
    const chunkSize = 64;
    for (int i = 0; i < msgBytes.length; i += chunkSize) {
      final end =
          (i + chunkSize > msgBytes.length) ? msgBytes.length : i + chunkSize;
      chunks.add(msgBytes.sublist(i, end));
    }
    if (chunks.isEmpty) {
      chunks.add(Uint8List(0));
    }

    final leafHashes = <Uint8List>[];
    for (final chunk in chunks) {
      leafHashes.add(await btc_ffi.btcLedgerHashLeaf(data: chunk));
    }
    final merkleRoot =
        await btc_ffi.btcLedgerComputeMerkleRoot(leafHashes: leafHashes);

    final fullPath = "m/$bipPurpose'/0'/$accountIndex'/0/$index";
    final pathBytes = await btc_ffi.btcLedgerEncodePath(path: fullPath);
    final msgLenVarint = _encodeVarint(msgBytes.length);

    final payload = <int>[
      ...pathBytes,
      ...msgLenVarint,
      ...merkleRoot,
    ];

    final preimageHashes = <Uint8List>[];
    final preimageData = <Uint8List>[];
    for (final chunk in chunks) {
      final chunkPreimage = Uint8List.fromList([0x00, ...chunk]);
      preimageHashes.add(await btc_ffi.btcLedgerSha256(data: chunkPreimage));
      preimageData.add(chunkPreimage);
    }

    final allLeafHashes = <String, List<Uint8List>>{};
    allLeafHashes[_hexEncode(merkleRoot)] = leafHashes;

    final result = await _sendApduWithClientLoop(
      ins: BtcLedgerConstants.insSignMessage,
      data: Uint8List.fromList(payload),
      preimageHashes: preimageHashes,
      preimageData: preimageData,
      allLeafHashes: allLeafHashes,
    );

    if (result.finalResponse.isEmpty) {
      throw TransportException('No signature received', 'NoSignature');
    }

    return result.finalResponse;
  }

  Future<({Uint8List finalResponse, List<Uint8List> yielded})>
      _sendApduWithClientLoop({
    required int ins,
    int p1 = 0x00,
    int p2 = 0x00,
    required Uint8List data,
    required List<Uint8List> preimageHashes,
    required List<Uint8List> preimageData,
    required Map<String, List<Uint8List>> allLeafHashes,
  }) async {
    _pendingElements.clear();

    Uint8List response = await _exchangeApdu(
      cla: BtcLedgerConstants.cla,
      ins: ins,
      p1: p1,
      p2: p2,
      data: data,
    );

    final List<Uint8List> yieldedResults = [];

    while (true) {
      final sw = _getStatusWord(response);

      if (sw == BtcLedgerConstants.swOk) {
        final finalBody = response.sublist(0, response.length - 2);
        return (finalResponse: finalBody, yielded: yieldedResults);
      }

      if (sw != BtcLedgerConstants.swInterrupt) {
        throw TransportStatusError(
            sw, 'Unexpected status: 0x${sw.toRadixString(16)}');
      }

      final payload = response.sublist(0, response.length - 2);
      if (payload.isEmpty) {
        throw TransportException(
            'Empty client command payload', 'EmptyPayload');
      }

      final commandCode = payload[0];
      final commandData = payload.sublist(1);

      Uint8List clientResponse;

      switch (commandCode) {
        case BtcLedgerConstants.ccYield:
          yieldedResults.add(Uint8List.fromList(commandData));
          clientResponse = Uint8List(0);
          break;

        case BtcLedgerConstants.ccGetPreimage:
          clientResponse = await _handleGetPreimage(
            commandData,
            preimageHashes,
            preimageData,
          );
          break;

        case BtcLedgerConstants.ccGetMerkleLeafProof:
          clientResponse = await _handleGetMerkleLeafProof(
            commandData,
            allLeafHashes,
          );
          break;

        case BtcLedgerConstants.ccGetMerkleLeafIndex:
          clientResponse = await _handleGetMerkleLeafIndex(
            commandData,
            allLeafHashes,
          );
          break;

        case BtcLedgerConstants.ccGetMoreElements:
          clientResponse = _handleGetMoreElements();
          break;

        default:
          throw TransportException(
            'Unknown client command: 0x${commandCode.toRadixString(16)}',
            'UnknownClientCommand',
          );
      }

      response = await _exchangeApdu(
        cla: BtcLedgerConstants.frameworkCla,
        ins: BtcLedgerConstants.frameworkContinueIns,
        p1: 0x00,
        p2: 0x00,
        data: clientResponse,
      );
    }
  }

  Future<Uint8List> _handleGetPreimage(
    Uint8List commandData,
    List<Uint8List> preimageHashes,
    List<Uint8List> preimageData,
  ) async {
    final requestedHash = commandData.sublist(1, 33);

    debugPrint('BTC GET_PREIMAGE: hash=${_hexEncode(requestedHash)}');

    final preimage = await btc_ffi.btcLedgerGetPreimage(
      preimageHashes: preimageHashes,
      preimageData: preimageData,
      requestedHash: requestedHash,
    );

    debugPrint('BTC GET_PREIMAGE: found preimage len=${preimage.length}, '
        'first bytes=${_hexEncode(preimage.sublist(0, preimage.length > 8 ? 8 : preimage.length))}');

    final totalLenVarint = _encodeVarint(preimage.length);
    final maxPayload = 255 - totalLenVarint.length - 1;
    final firstChunkSize =
        preimage.length > maxPayload ? maxPayload : preimage.length;

    if (preimage.length > firstChunkSize) {
      final remaining = preimage.sublist(firstChunkSize);
      _queueElements(remaining, 1);
    }

    final result = <int>[
      ...totalLenVarint,
      firstChunkSize,
      ...preimage.sublist(0, firstChunkSize),
    ];

    return Uint8List.fromList(result);
  }

  Future<Uint8List> _handleGetMerkleLeafProof(
    Uint8List commandData,
    Map<String, List<Uint8List>> allLeafHashes,
  ) async {
    final rootHash = commandData.sublist(0, 32);
    int offset = 32;
    final (treeSize, treeSizeLen) = _decodeVarint(commandData, offset);
    offset += treeSizeLen;
    final (leafIndex, _) = _decodeVarint(commandData, offset);

    debugPrint('BTC GET_MERKLE_LEAF_PROOF: root=${_hexEncode(rootHash)}, '
        'treeSize=$treeSize, leafIndex=$leafIndex');

    final rootHex = _hexEncode(rootHash);
    final leafHashes = allLeafHashes[rootHex];
    if (leafHashes == null) {
      debugPrint(
          'BTC GET_MERKLE_LEAF_PROOF: UNKNOWN ROOT! Known roots: ${allLeafHashes.keys.toList()}');
      throw TransportException(
        'Unknown merkle root: $rootHex',
        'UnknownMerkleRoot',
      );
    }

    final proof = await btc_ffi.btcLedgerGetMerkleProof(
      leafHashes: leafHashes,
      leafIndex: leafIndex,
    );

    const maxProofElements = 6;
    final proofLen = proof.proofHashes.length;
    final nResponse = proofLen > maxProofElements ? maxProofElements : proofLen;

    if (proofLen > maxProofElements) {
      final remaining = proof.proofHashes.sublist(maxProofElements);
      _queueElementsList(remaining);
    }

    final result = <int>[
      ...proof.leafHash,
      proofLen,
      nResponse,
    ];
    for (int i = 0; i < nResponse; i++) {
      result.addAll(proof.proofHashes[i]);
    }

    return Uint8List.fromList(result);
  }

  Future<Uint8List> _handleGetMerkleLeafIndex(
    Uint8List commandData,
    Map<String, List<Uint8List>> allLeafHashes,
  ) async {
    final rootHash = commandData.sublist(0, 32);
    final targetLeafHash = commandData.sublist(32, 64);

    final rootHex = _hexEncode(rootHash);
    final targetHex = _hexEncode(targetLeafHash);
    debugPrint('BTC GET_MERKLE_LEAF_INDEX: root=$rootHex, target=$targetHex');

    final leafHashes = allLeafHashes[rootHex];
    if (leafHashes == null) {
      debugPrint(
          'BTC GET_MERKLE_LEAF_INDEX: ROOT NOT FOUND! Known roots: ${allLeafHashes.keys.toList()}');
      return Uint8List.fromList([0x00, 0x00]);
    }

    debugPrint(
        'BTC GET_MERKLE_LEAF_INDEX: tree has ${leafHashes.length} leaves');
    for (int j = 0; j < leafHashes.length; j++) {
      debugPrint('  leaf[$j]=${_hexEncode(leafHashes[j])}');
    }

    final index = await btc_ffi.btcLedgerGetMerkleLeafIndex(
      leafHashes: leafHashes,
      targetHash: targetLeafHash,
    );

    if (index < 0) {
      debugPrint('BTC GET_MERKLE_LEAF_INDEX: NOT FOUND');
      return Uint8List.fromList([0x00, 0x00]);
    }

    debugPrint('BTC GET_MERKLE_LEAF_INDEX: found at index=$index');
    final indexVarint = _encodeVarint(index);
    return Uint8List.fromList([0x01, ...indexVarint]);
  }

  Uint8List _handleGetMoreElements() {
    if (_pendingElements.isEmpty) {
      throw TransportException('No more elements queued', 'NoMoreElements');
    }

    final elementSize = _pendingElementSize;

    final maxElements = elementSize > 0 ? (253 ~/ elementSize) : 1;
    final nElements = _pendingElements.length > maxElements
        ? maxElements
        : _pendingElements.length;

    final result = <int>[nElements, elementSize];
    for (int i = 0; i < nElements; i++) {
      result.addAll(_pendingElements.removeAt(0));
    }

    return Uint8List.fromList(result);
  }

  Future<Uint8List> _sendApdu({
    required int ins,
    int p1 = 0x00,
    int p2 = 0x00,
    required Uint8List data,
  }) async {
    final response = await _exchangeApdu(
      cla: BtcLedgerConstants.cla,
      ins: ins,
      p1: p1,
      p2: p2,
      data: data,
    );

    final sw = _getStatusWord(response);
    if (sw != BtcLedgerConstants.swOk) {
      throw TransportStatusError(sw, 'Status code: 0x${sw.toRadixString(16)}');
    }

    return response.sublist(0, response.length - 2);
  }

  Future<Uint8List> _exchangeApdu({
    required int cla,
    required int ins,
    int p1 = 0x00,
    int p2 = 0x00,
    required Uint8List data,
  }) async {
    final apdu = Uint8List.fromList([
      cla,
      ins,
      p1,
      p2,
      data.length,
      ...data,
    ]);

    debugPrint(
        'BTC APDU → CLA=0x${cla.toRadixString(16)} INS=0x${ins.toRadixString(16)} '
        'P1=0x${p1.toRadixString(16)} P2=0x${p2.toRadixString(16)} '
        'len=${data.length}');

    final response = await transport.exchange(apdu);

    if (response.length < 2) {
      throw TransportException(
          'Response too short: ${response.length}', 'InvalidResponseLength');
    }

    final sw = _getStatusWord(response);
    debugPrint(
        'BTC APDU ← SW=0x${sw.toRadixString(16)} len=${response.length}');

    return response;
  }

  int _getStatusWord(Uint8List response) {
    return (response[response.length - 2] << 8) | response[response.length - 1];
  }

  void _queueElements(Uint8List data, int elementSize) {
    _pendingElementSize = elementSize;
    if (elementSize == 1) {
      for (int i = 0; i < data.length; i++) {
        _pendingElements.add(Uint8List.fromList([data[i]]));
      }
    } else {
      for (int i = 0; i < data.length; i += elementSize) {
        final end =
            (i + elementSize > data.length) ? data.length : i + elementSize;
        _pendingElements.add(data.sublist(i, end));
      }
    }
  }

  void _queueElementsList(List<Uint8List> elements) {
    if (elements.isEmpty) return;
    _pendingElementSize = elements.first.length;
    _pendingElements.addAll(elements);
  }

  List<int> _encodeVarint(int value) {
    if (value < 0xFD) {
      return [value];
    } else if (value <= 0xFFFF) {
      return [0xFD, value & 0xFF, (value >> 8) & 0xFF];
    } else {
      return [
        0xFE,
        value & 0xFF,
        (value >> 8) & 0xFF,
        (value >> 16) & 0xFF,
        (value >> 24) & 0xFF,
      ];
    }
  }

  (int, int) _decodeVarint(Uint8List data, int offset) {
    final first = data[offset];
    if (first < 0xFD) {
      return (first, 1);
    } else if (first == 0xFD) {
      final val = data[offset + 1] | (data[offset + 2] << 8);
      return (val, 3);
    } else {
      final val = data[offset + 1] |
          (data[offset + 2] << 8) |
          (data[offset + 3] << 16) |
          (data[offset + 4] << 24);
      return (val, 5);
    }
  }

  String _hexEncode(Uint8List bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
