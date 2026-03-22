import 'package:flutter/foundation.dart';
import 'package:bearby/ledger/bitcoin/btc_constants.dart';
import 'package:bearby/ledger/common.dart';
import 'package:bearby/ledger/transport/exceptions.dart';
import 'package:bearby/ledger/transport/transport.dart';
import 'package:bearby/src/rust/api/btc_ledger.dart' as btc_ffi;

/// Bitcoin Ledger app implementation (new protocol v2.1.0+).
///
/// Uses CLA=0xE1 and an interactive merkle-based protocol where
/// the device requests data from the client via status 0xE000 interrupts.
///
/// CRITICAL: Uses [transport.exchange] directly (NOT [transport.send])
/// because the BTC protocol uses status 0xE000 as a valid "I need more data"
/// response, while [send] throws on non-0x9000 status codes.
class BtcLedgerApp {
  final Transport transport;

  /// Queue for GET_MORE_ELEMENTS continuation data
  final List<Uint8List> _pendingElements = [];
  int _pendingElementSize = 0;

  BtcLedgerApp(this.transport);

  // --- Simple Commands ---

  /// Get the master key fingerprint (4 bytes).
  /// This is the simplest command and can be used to detect the BTC app.
  Future<Uint8List> getMasterFingerprint() async {
    final response = await _sendApdu(
      ins: BtcLedgerConstants.insGetMasterFingerprint,
      data: Uint8List(0),
    );
    return response.sublist(0, 4);
  }

  /// Get the extended public key (xpub) at the given derivation path.
  Future<String> getExtendedPubkey({
    required String path,
    bool display = false,
  }) async {
    final pathBytes = await btc_ffi.btcLedgerEncodePath(path: path);

    // Display flag goes in the data payload (first byte), NOT in P1
    final response = await _sendApdu(
      ins: BtcLedgerConstants.insGetPubkey,
      data: Uint8List.fromList([display ? 0x01 : 0x00, ...pathBytes]),
    );

    // Response is a null-terminated or length-delimited xpub string
    return String.fromCharCodes(response).replaceAll('\x00', '');
  }

  /// Get a wallet address from the device using a wallet policy.
  Future<String> getWalletAddress({
    required btc_ffi.WalletPolicy walletPolicy,
    required int change,
    required int addressIndex,
    bool display = false,
  }) async {
    // Build the APDU data:
    // display(1) || walletId(32) || walletHMAC(32) || change(1) || addressIndex(4 BE)
    final dataBytes = <int>[
      display ? 0x01 : 0x00,
      ...walletPolicy.policyId,
      ...walletPolicy.policyHmac,
      change,
    ];
    // Address index (big-endian)
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

    // Address comes in the final 0x9000 response, not via YIELD
    return String.fromCharCodes(result.finalResponse);
  }

  /// Derive accounts for the given indices.
  Future<List<LedgerAccount>> getAccounts({
    required List<int> indices,
    required int bipPurpose,
    int accountIndex = 0,
  }) async {
    final fingerprint = await getMasterFingerprint();

    // Get the account-level xpub: m/purpose'/0'/account'
    final accountPath = "m/$bipPurpose'/0'/$accountIndex'";
    final xpub = await getExtendedPubkey(path: accountPath);

    // Build wallet policy
    final walletPolicy = await btc_ffi.btcLedgerBuildWalletPolicy(
      xpub: xpub,
      masterFingerprint: fingerprint,
      bipPurpose: bipPurpose,
      accountIndex: accountIndex,
    );

    final List<LedgerAccount> accounts = [];
    for (final index in indices) {
      // Get the address at change=0, index=index
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

  // --- Transaction Signing ---

  /// Sign a PSBT using the Ledger device.
  ///
  /// Returns the list of signatures (one per input) as yielded by the device.
  Future<List<Uint8List>> signPsbt({
    required Uint8List psbtBytes,
    required int bipPurpose,
    required int accountIndex,
  }) async {
    final fingerprint = await getMasterFingerprint();

    // Get account xpub
    final accountPath = "m/$bipPurpose'/0'/$accountIndex'";
    final xpub = await getExtendedPubkey(path: accountPath);

    // Build wallet policy
    final walletPolicy = await btc_ffi.btcLedgerBuildWalletPolicy(
      xpub: xpub,
      masterFingerprint: fingerprint,
      bipPurpose: bipPurpose,
      accountIndex: accountIndex,
    );

    // Populate BIP32 derivation info (tap_key_origins, tap_internal_key, etc.)
    final preparedPsbt = await btc_ffi.btcLedgerPreparePsbt(
      psbtBytes: psbtBytes,
      masterFingerprint: fingerprint,
      bipPurpose: bipPurpose,
      accountIndex: accountIndex,
      xpub: xpub,
    );

    // Merkelise the prepared PSBT (with derivation info)
    final merkelized = await btc_ffi.btcLedgerMerkelisePsbt(
      psbtBytes: preparedPsbt,
    );

    debugPrint('BTC PSBT merkelized: inputs=${merkelized.inputCount}, '
        'outputs=${merkelized.outputCount}, '
        'globalCommitLen=${merkelized.globalMapCommitment.length}, '
        'globalKeysLeaves=${merkelized.globalMapKeysLeaves.length}');

    // Build the SIGN_PSBT payload:
    // globalCommitment || varint(inputCount) || inputMapsRoot(32) ||
    // varint(outputCount) || outputMapsRoot(32) || walletId(32) || walletHMAC(32)
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

    // Build preimage store: merge merkelized preimages + wallet policy
    final preimageHashes = <Uint8List>[...merkelized.preimageHashes];
    final preimageData = <Uint8List>[...merkelized.preimageData];

    // Add wallet policy serialized as raw preimage
    preimageHashes
        .add(await btc_ffi.btcLedgerSha256(data: walletPolicy.serialized));
    preimageData.add(walletPolicy.serialized);

    // Add wallet policy keys as known-list preimages (0x00 || key)
    for (final keyInfo in walletPolicy.keysInfo) {
      final keyBytes = Uint8List.fromList(keyInfo.codeUnits);
      final keyPreimage = Uint8List.fromList([0x00, ...keyBytes]);
      preimageHashes.add(await btc_ffi.btcLedgerSha256(data: keyPreimage));
      preimageData.add(keyPreimage);
    }

    // Build leaf hash lookup for merkle proofs
    final allLeafHashes = <String, List<Uint8List>>{};

    // Global keys/values leaves
    final globalKeysRoot = await btc_ffi.btcLedgerComputeMerkleRoot(
        leafHashes: merkelized.globalMapKeysLeaves);
    final globalValuesRoot = await btc_ffi.btcLedgerComputeMerkleRoot(
        leafHashes: merkelized.globalMapValuesLeaves);
    allLeafHashes[_hexEncode(globalKeysRoot)] = merkelized.globalMapKeysLeaves;
    allLeafHashes[_hexEncode(globalValuesRoot)] =
        merkelized.globalMapValuesLeaves;

    // Input maps leaves
    for (int i = 0; i < merkelized.inputCount; i++) {
      final keysRoot = await btc_ffi.btcLedgerComputeMerkleRoot(
          leafHashes: merkelized.inputMapKeysLeaves[i]);
      final valuesRoot = await btc_ffi.btcLedgerComputeMerkleRoot(
          leafHashes: merkelized.inputMapValuesLeaves[i]);
      allLeafHashes[_hexEncode(keysRoot)] = merkelized.inputMapKeysLeaves[i];
      allLeafHashes[_hexEncode(valuesRoot)] =
          merkelized.inputMapValuesLeaves[i];
    }

    // Input commitment leaves (for the top-level input maps tree)
    final inputCommitmentLeaves = <Uint8List>[];
    for (final c in merkelized.inputMapCommitments) {
      inputCommitmentLeaves.add(await btc_ffi.btcLedgerHashLeaf(data: c));
    }
    allLeafHashes[_hexEncode(merkelized.inputMapsRoot)] = inputCommitmentLeaves;

    // Output maps leaves
    for (int i = 0; i < merkelized.outputCount; i++) {
      final keysRoot = await btc_ffi.btcLedgerComputeMerkleRoot(
          leafHashes: merkelized.outputMapKeysLeaves[i]);
      final valuesRoot = await btc_ffi.btcLedgerComputeMerkleRoot(
          leafHashes: merkelized.outputMapValuesLeaves[i]);
      allLeafHashes[_hexEncode(keysRoot)] = merkelized.outputMapKeysLeaves[i];
      allLeafHashes[_hexEncode(valuesRoot)] =
          merkelized.outputMapValuesLeaves[i];
    }

    // Output commitment leaves
    final outputCommitmentLeaves = <Uint8List>[];
    for (final c in merkelized.outputMapCommitments) {
      outputCommitmentLeaves.add(await btc_ffi.btcLedgerHashLeaf(data: c));
    }
    allLeafHashes[_hexEncode(merkelized.outputMapsRoot)] =
        outputCommitmentLeaves;

    // Wallet policy keys tree (single key)
    final keyLeaf = await btc_ffi.btcLedgerHashLeaf(
        data: Uint8List.fromList(walletPolicy.keysInfo.first.codeUnits));
    final keysRoot =
        await btc_ffi.btcLedgerComputeMerkleRoot(leafHashes: [keyLeaf]);
    allLeafHashes[_hexEncode(keysRoot)] = [keyLeaf];

    // Send SIGN_PSBT and run the client interaction loop
    final result = await _sendApduWithClientLoop(
      ins: BtcLedgerConstants.insSignPsbt,
      data: Uint8List.fromList(payload),
      preimageHashes: preimageHashes,
      preimageData: preimageData,
      allLeafHashes: allLeafHashes,
    );

    // Signatures come via YIELD
    return result.yielded;
  }

  // --- Message Signing ---

  /// Sign a message using the Ledger Bitcoin app.
  Future<Uint8List> signMessage({
    required String message,
    required int bipPurpose,
    required int index,
    int accountIndex = 0,
  }) async {
    final msgBytes = Uint8List.fromList(message.codeUnits);

    // Chunk message into 64-byte pieces and build merkle tree
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

    // Compute leaf hashes and merkle root
    final leafHashes = <Uint8List>[];
    for (final chunk in chunks) {
      leafHashes.add(await btc_ffi.btcLedgerHashLeaf(data: chunk));
    }
    final merkleRoot =
        await btc_ffi.btcLedgerComputeMerkleRoot(leafHashes: leafHashes);

    // Build the payload: path || varint(msgLen) || merkleRoot(32)
    final fullPath = "m/$bipPurpose'/0'/$accountIndex'/0/$index";
    final pathBytes = await btc_ffi.btcLedgerEncodePath(path: fullPath);
    final msgLenVarint = _encodeVarint(msgBytes.length);

    final payload = <int>[
      ...pathBytes,
      ...msgLenVarint,
      ...merkleRoot,
    ];

    // Build preimage store for chunks (0x00 || chunk, matching addKnownList)
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

    // Signature comes in the final 0x9000 response
    return result.finalResponse;
  }

  // --- Client Interaction Loop ---

  /// Send an APDU and handle the interactive client-server protocol.
  ///
  /// The device may respond with status 0xE000 multiple times, each time
  /// requesting data (preimages, merkle proofs, etc.) from the client.
  /// Signatures are collected via YIELD (0x10) commands.
  /// Returns (finalResponse, yieldedResults) — the final 0x9000 response
  /// body and any data yielded during the interaction loop.
  Future<({Uint8List finalResponse, List<Uint8List> yielded})> _sendApduWithClientLoop({
    required int ins,
    int p1 = 0x00,
    int p2 = 0x00,
    required Uint8List data,
    required List<Uint8List> preimageHashes,
    required List<Uint8List> preimageData,
    required Map<String, List<Uint8List>> allLeafHashes,
  }) async {
    _pendingElements.clear();

    // Send initial APDU
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
        // Return both the final response body and any yielded results
        final finalBody = response.sublist(0, response.length - 2);
        return (finalResponse: finalBody, yielded: yieldedResults);
      }

      if (sw != BtcLedgerConstants.swInterrupt) {
        throw TransportStatusError(
            sw, 'Unexpected status: 0x${sw.toRadixString(16)}');
      }

      // Extract client command from response payload
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

      // Send response back via framework continue
      response = await _exchangeApdu(
        cla: BtcLedgerConstants.frameworkCla,
        ins: BtcLedgerConstants.frameworkContinueIns,
        p1: 0x00,
        p2: 0x00,
        data: clientResponse,
      );
    }
  }

  // --- Client Command Handlers ---

  /// Handle GET_PREIMAGE (0x40): device requests data by its SHA-256 hash.
  ///
  /// Request: [0x00 (hash_type) || hash(32)]
  /// Response: [varint(total_len) || payload_size(1) || data_chunk]
  Future<Uint8List> _handleGetPreimage(
    Uint8List commandData,
    List<Uint8List> preimageHashes,
    List<Uint8List> preimageData,
  ) async {
    // Skip hash type byte (always 0x00 for SHA-256)
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
    // Max payload in single response: 255 - varint_len - 1 (for payload_size byte)
    final maxPayload = 255 - totalLenVarint.length - 1;
    final firstChunkSize =
        preimage.length > maxPayload ? maxPayload : preimage.length;

    // Queue remaining data for GET_MORE_ELEMENTS
    if (preimage.length > firstChunkSize) {
      final remaining = preimage.sublist(firstChunkSize);
      _queueElements(remaining, 1); // 1 byte per element for raw data
    }

    final result = <int>[
      ...totalLenVarint,
      firstChunkSize,
      ...preimage.sublist(0, firstChunkSize),
    ];

    return Uint8List.fromList(result);
  }

  /// Handle GET_MERKLE_LEAF_PROOF (0x41): device requests merkle proof for a leaf.
  ///
  /// Request: [root_hash(32) || varint(tree_size) || varint(leaf_index)]
  /// Response: [leaf_hash(32) || proof_length(1) || n_response_elements(1) || proofs(32 each)]
  Future<Uint8List> _handleGetMerkleLeafProof(
    Uint8List commandData,
    Map<String, List<Uint8List>> allLeafHashes,
  ) async {
    final rootHash = commandData.sublist(0, 32);
    int offset = 32;
    final (treeSize, treeSizeLen) = _decodeVarint(commandData, offset);
    offset += treeSizeLen;
    final (leafIndex, _) = _decodeVarint(commandData, offset);

    // Find the leaf hashes for this root
    debugPrint('BTC GET_MERKLE_LEAF_PROOF: root=${_hexEncode(rootHash)}, '
        'treeSize=$treeSize, leafIndex=$leafIndex');

    final rootHex = _hexEncode(rootHash);
    final leafHashes = allLeafHashes[rootHex];
    if (leafHashes == null) {
      debugPrint('BTC GET_MERKLE_LEAF_PROOF: UNKNOWN ROOT! Known roots: ${allLeafHashes.keys.toList()}');
      throw TransportException(
        'Unknown merkle root: $rootHex',
        'UnknownMerkleRoot',
      );
    }

    final proof = await btc_ffi.btcLedgerGetMerkleProof(
      leafHashes: leafHashes,
      leafIndex: leafIndex,
    );

    // Max proof elements per response: floor((255 - 32 - 1 - 1) / 32) = 6
    const maxProofElements = 6;
    final proofLen = proof.proofHashes.length;
    final nResponse = proofLen > maxProofElements ? maxProofElements : proofLen;

    // Queue remaining proof elements for GET_MORE_ELEMENTS
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

  /// Handle GET_MERKLE_LEAF_INDEX (0x42): device asks for leaf index by hash.
  ///
  /// Request: [root_hash(32) || leaf_hash(32)]
  /// Response: [found(1) || varint(index)]
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
      debugPrint('BTC GET_MERKLE_LEAF_INDEX: ROOT NOT FOUND! Known roots: ${allLeafHashes.keys.toList()}');
      return Uint8List.fromList([0x00, 0x00]); // not found
    }

    debugPrint('BTC GET_MERKLE_LEAF_INDEX: tree has ${leafHashes.length} leaves');
    for (int j = 0; j < leafHashes.length; j++) {
      debugPrint('  leaf[$j]=${_hexEncode(leafHashes[j])}');
    }

    final index = await btc_ffi.btcLedgerGetMerkleLeafIndex(
      leafHashes: leafHashes,
      targetHash: targetLeafHash,
    );

    if (index < 0) {
      debugPrint('BTC GET_MERKLE_LEAF_INDEX: NOT FOUND');
      return Uint8List.fromList([0x00, 0x00]); // not found
    }

    debugPrint('BTC GET_MERKLE_LEAF_INDEX: found at index=$index');
    final indexVarint = _encodeVarint(index);
    return Uint8List.fromList([0x01, ...indexVarint]);
  }

  /// Handle GET_MORE_ELEMENTS (0xA0): send next queued chunk.
  ///
  /// Response: [n_elements(1) || element_length(1) || elements...]
  Uint8List _handleGetMoreElements() {
    if (_pendingElements.isEmpty) {
      throw TransportException('No more elements queued', 'NoMoreElements');
    }

    final elementSize = _pendingElementSize;
    // Max elements per response: floor(253 / elementSize)
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

  // --- APDU Helpers ---

  /// Send a simple (non-interactive) APDU command.
  /// Throws on non-0x9000 status.
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

  /// Raw APDU exchange - constructs the APDU bytes and sends via transport.
  /// Returns the full response including status word (last 2 bytes).
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

  // --- Utility Methods ---

  int _getStatusWord(Uint8List response) {
    return (response[response.length - 2] << 8) | response[response.length - 1];
  }

  /// Queue raw data as single-byte elements for GET_MORE_ELEMENTS.
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

  /// Queue a list of fixed-size elements (e.g., 32-byte proof hashes).
  void _queueElementsList(List<Uint8List> elements) {
    if (elements.isEmpty) return;
    _pendingElementSize = elements.first.length;
    _pendingElements.addAll(elements);
  }

  /// Bitcoin-style varint encoding.
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

  /// Bitcoin-style varint decoding. Returns (value, bytesConsumed).
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
