import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:typed_data';

import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart'
    show PlatformInt64Util;
import 'package:provider/provider.dart';

import 'package:bearby/config/walletconnect.dart';
import 'package:bearby/config/web3_constants.dart';
import 'package:bearby/mixins/eip712.dart';
import 'package:bearby/mixins/transaction_parsing.dart';
import 'package:bearby/modals/app_connect.dart';
import 'package:bearby/modals/sign_message.dart';
import 'package:bearby/modals/transfer.dart';
import 'package:bearby/src/rust/api/utils.dart';
import 'package:bearby/src/rust/api/walletconnect.dart';
import 'package:bearby/src/rust/models/ftoken.dart';
import 'package:bearby/src/rust/models/provider.dart';
import 'package:bearby/src/rust/models/transactions/base_token.dart';
import 'package:bearby/src/rust/models/transactions/evm.dart';
import 'package:bearby/src/rust/models/transactions/request.dart';
import 'package:bearby/src/rust/models/transactions/transaction_metadata.dart';
import 'package:bearby/src/rust/models/walletconnect/ffi.dart';
import 'package:bearby/state/app_state.dart';
import 'package:bearby/utils/utils.dart';

/// Thin Flutter facade over the Rust WalletConnect engine.
///
/// Signing/tx confirmation stay in Dart (existing modals + FFI); the SDK only
/// transports requests/responses.
class WalletConnectService {
  WalletConnectService._();
  static final WalletConnectService instance = WalletConnectService._();

  StreamSubscription<WcEventInfo>? _sub;
  bool _started = false;
  bool _approving = false;
  GlobalKey<NavigatorState>? navigatorKey;

  void _log(String msg) => debugPrint('[wc] $msg');

  /// Call after wallet unlock. Safe to call multiple times.
  Future<void> start({GlobalKey<NavigatorState>? navKey}) async {
    if (navKey != null) navigatorKey = navKey;
    if (_started) return;

    final platform = _platformName();
    final packageName = _packageName();

    await wcInit(
      projectId: kWcProjectId,
      appName: kWcAppName,
      appDescription: kWcAppDescription,
      appUrl: kWcAppUrl,
      appIcon: kWcAppIcon,
      packageName: packageName,
      platform: platform,
    );

    _log('init ok platform=$platform');
    _sub = wcEvents().listen(
      _onEvent,
      onError: (Object e) {
        _log('events error: $e');
      },
      onDone: () {
        // Stream closed (e.g. after sink re-attach path); allow restart.
        _log('events stream done');
        _sub = null;
        _started = false;
      },
    );
    _started = true;
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    if (_started) {
      await wcShutdown();
      _started = false;
    }
  }

  /// Pair from a scanned/opened WalletConnect URI.
  Future<void> pair(String uri) async {
    if (!_started) await start();
    final normalized = _normalizeUri(uri);
    final short = normalized.length > 48
        ? '${normalized.substring(0, 48)}…'
        : normalized;
    _log('pair $short');
    await wcPair(uri: normalized);
    _log('pair subscribed');
  }

  /// Notify all WC sessions that the active account changed (reown
  /// `emitSessionEvent` / `accountsChanged`).
  ///
  /// [address] is the chain-native address (0x… for EVM, base58 for Solana, …).
  /// [caip2] is the active chain, e.g. `eip155:1` or `solana:5eykt…`.
  Future<void> onAccountsChanged({
    required String address,
    required String caip2,
  }) async {
    if (!_started) return;
    final parts = caip2.split(':');
    if (parts.length < 2) {
      _log('onAccountsChanged bad caip2=$caip2');
      return;
    }
    final nsKey = parts[0];
    // bip122 uses a dedicated event name in AppKit; also send accountsChanged.
    final eventNames = nsKey == 'bip122'
        ? <String>[kWcBip122AddressesChanged, 'accountsChanged']
        : <String>['accountsChanged'];
    final dataJson = jsonEncode([address]);

    List<WcSessionInfo> sessions;
    try {
      sessions = await wcSessions();
    } catch (e) {
      _log('onAccountsChanged sessions: $e');
      return;
    }

    for (final s in sessions) {
      final touchesNs = s.accounts.any((a) => a.startsWith('$nsKey:')) ||
          s.events.contains('accountsChanged') ||
          s.events.contains(kWcBip122AddressesChanged);
      if (!touchesNs) continue;

      // Prefer a chainId already present in the session for this namespace.
      String chainId = caip2;
      for (final acc in s.accounts) {
        if (acc.startsWith('$nsKey:')) {
          final segs = acc.split(':');
          if (segs.length >= 2) {
            chainId = '${segs[0]}:${segs[1]}';
            break;
          }
        }
      }

      final caip10 = '$chainId:$address';
      try {
        await wcUpdateSessionAccounts(
          topic: s.topic,
          nsKey: nsKey,
          accounts: [caip10],
        );
      } catch (e) {
        _log('update accounts ${s.topic}: $e');
      }

      for (final name in eventNames) {
        try {
          await wcEmitSessionEvent(
            topic: s.topic,
            chainId: chainId,
            name: name,
            dataJson: dataJson,
          );
          _log(
            '$name topic=${s.topic.substring(0, 12)}… '
            'chain=$chainId addr=$address',
          );
        } catch (e) {
          _log('emit $name ${s.topic}: $e');
        }
      }
    }
  }

  /// Notify sessions of an EIP-155 / CAIP chain switch (`chainChanged`).
  Future<void> onChainChanged({required String caip2}) async {
    if (!_started) return;
    final parts = caip2.split(':');
    if (parts.length < 2) return;
    final nsKey = parts[0];
    final chainRef = parts[1];
    // EIP-1193 chainChanged data is typically a hex chain id or number.
    final dynamic data = nsKey == 'eip155'
        ? (int.tryParse(chainRef) ?? chainRef)
        : caip2;
    final dataJson = jsonEncode(data);

    List<WcSessionInfo> sessions;
    try {
      sessions = await wcSessions();
    } catch (_) {
      return;
    }

    for (final s in sessions) {
      if (!s.accounts.any((a) => a.startsWith('$nsKey:')) &&
          !s.events.contains('chainChanged')) {
        continue;
      }
      try {
        await wcEmitSessionEvent(
          topic: s.topic,
          chainId: caip2,
          name: 'chainChanged',
          dataJson: dataJson,
        );
        _log('chainChanged topic=${s.topic.substring(0, 12)}… chain=$caip2');
      } catch (e) {
        _log('emit chainChanged: $e');
      }
    }
  }

  static bool isWalletConnectUri(String raw) {
    final t = raw.trim();
    return t.startsWith('wc:') || t.startsWith('wc://');
  }

  static String _normalizeUri(String uri) {
    final t = uri.trim();
    if (t.startsWith('wc://')) {
      return 'wc:${t.substring(5)}';
    }
    return t;
  }

  void _onEvent(WcEventInfo e) {
    switch (e) {
      case WcEventInfo_Proposal(:final field0):
        _log(
          'event Proposal id=${field0.id} pairing=${field0.pairingTopic} '
          'peer=${field0.peerName}',
        );
        _showApprovalModal(field0);
      case WcEventInfo_Request(:final field0):
        _log(
          'event Request id=${field0.id} topic=${field0.topic} '
          'method=${field0.method} chain=${field0.chainId}',
        );
        _routeRequest(field0);
      case WcEventInfo_SessionDeleted(:final topic, :final message):
        _log('event SessionDeleted topic=$topic msg=$message');
      case WcEventInfo_SessionSettled(:final topic):
        _log('event SessionSettled topic=$topic');
      case WcEventInfo_SessionEvent(:final topic, :final name):
        _log('event SessionEvent topic=$topic name=$name');
      case WcEventInfo_RelayConnected():
        _log('event RelayConnected');
      case WcEventInfo_RelayDisconnected():
        _log('event RelayDisconnected');
      case WcEventInfo_Error(:final message):
        _log('event Error: $message');
    }
  }

  BuildContext? get _ctx => navigatorKey?.currentContext;

  Future<void> _showApprovalModal(WcProposalInfo proposal) async {
    final context = _ctx;
    if (context == null || !context.mounted) {
      _log('approval UI unavailable; rejecting ${proposal.id}');
      try {
        await wcRejectSession(proposalId: proposal.id);
      } catch (e) {
        _log('reject (no UI) ignored: $e');
      }
      return;
    }

    final appState = Provider.of<AppState>(context, listen: false);
    final icon = proposal.peerIcon ?? '';
    _log(
      'show approval id=${proposal.id} pairing=${proposal.pairingTopic} '
      'peer=${proposal.peerName}',
    );

    showAppConnectModal(
      context: context,
      title: proposal.peerName,
      uuid: proposal.pairingTopic,
      iconUrl: icon,
      onConfirm: (selectedIndexes) async {
        if (_approving) {
          _log('approve ignored (already in flight)');
          return;
        }
        _approving = true;
        try {
          final namespaces =
              _buildApprovals(appState, proposal, selectedIndexes);
          _log(
            'approve namespaces=${namespaces.map((n) => '${n.key}:${n.methods.length}m').join(',')}',
          );
          if (namespaces.isEmpty) {
            _log('approve empty namespaces → reject');
            try {
              await wcRejectSession(proposalId: proposal.id);
            } catch (e) {
              _log('reject after empty ns ignored: $e');
            }
            return;
          }
          final topic = await wcApproveSession(
            proposalId: proposal.id,
            namespaces: namespaces,
          );
          _log('approve ok session=$topic');
        } catch (e) {
          _log('approve failed: $e');
          // Proposal is already consumed on the Rust side after take();
          // reject is best-effort and must not crash the UI.
          try {
            await wcRejectSession(proposalId: proposal.id);
          } catch (re) {
            _log('reject after approve failure (ignored): $re');
          }
        } finally {
          _approving = false;
        }
      },
      onReject: () async {
        _log('user reject proposal=${proposal.id}');
        try {
          await wcRejectSession(proposalId: proposal.id);
        } catch (e) {
          _log('reject ignored: $e');
        }
      },
    );
  }

  List<WcNamespaceApproval> _buildApprovals(
    AppState appState,
    WcProposalInfo proposal,
    List<int> selectedIndexes,
  ) {
    _log(
      'proposal required=${proposal.required_.map((n) => '${n.key}[${n.chains.join(",")}] m=${n.methods}').join('; ')} '
      'optional=${proposal.optional.map((n) => '${n.key}[${n.chains.join(",")}] m=${n.methods}').join('; ')}',
    );

    final out = <WcNamespaceApproval>[];
    final seen = <String>{};

    void addNs(WcNamespaceInfo ns, {required bool required}) {
      if (!seen.add(ns.key)) return;

      final slip44 = _slip44ForNamespace(ns.key);
      if (slip44 == null) {
        _log('skip ns=${ns.key}: unsupported namespace');
        return;
      }

      // Addresses from *any* wallet that holds this slip44 — not only the
      // currently selected chain (multi-network WC sessions).
      final addrs = _addressesForSlip44(appState, slip44, selectedIndexes);
      if (addrs.isEmpty) {
        _log('skip ns=${ns.key}: no wallet accounts for slip44=$slip44');
        return;
      }

      final chains = _resolveChains(ns, appState, slip44);
      if (chains.isEmpty) {
        _log('skip ns=${ns.key}: no resolvable chains');
        return;
      }

      final methods = _methodsFor(ns.key, ns.methods);
      final events = _eventsFor(ns.key, ns.events);
      if (methods.isEmpty) {
        _log('skip ns=${ns.key}: no supported methods (req=${ns.methods})');
        return;
      }

      final caip10 = <String>[];
      for (final chain in chains) {
        for (final addr in addrs) {
          caip10.add('$chain:${_formatAccountAddr(addr, ns.key)}');
        }
      }
      if (caip10.isEmpty) return;

      _log(
        'approve ns=${ns.key} chains=${chains.length} accounts=${caip10.length} '
        'methods=$methods events=$events required=$required',
      );
      out.add(WcNamespaceApproval(
        key: ns.key,
        accounts: caip10,
        methods: methods,
        events: events,
      ));
    }

    for (final ns in proposal.required_) {
      addNs(ns, required: true);
    }
    for (final ns in proposal.optional) {
      addNs(ns, required: false);
    }
    return out;
  }

  int? _slip44ForNamespace(String ns) {
    switch (ns) {
      case 'eip155':
        return kEthereumSlip44;
      case 'solana':
        return kSolanaSlip44;
      case 'tron':
        return kTronSlip44;
      case 'bip122':
        return kBitcoinlip44;
      default:
        return null;
    }
  }

  /// Collect addresses for [slip44] across all wallets.
  ///
  /// [selectedIndexes] only applies when the active wallet matches [slip44]
  /// (approval UI selects accounts for the current wallet).
  List<String> _addressesForSlip44(
    AppState appState,
    int slip44,
    List<int> selectedIndexes,
  ) {
    final out = <String>[];
    final seen = <String>{};

    void addAddr(String addr) {
      if (addr.isEmpty) return;
      if (seen.add(addr)) out.add(addr);
    }

    final active = appState.wallet;
    if (active != null && active.slip44 == slip44) {
      final accounts = appState.accounts;
      if (selectedIndexes.isNotEmpty) {
        for (final i in selectedIndexes) {
          if (i >= 0 && i < accounts.length) addAddr(accounts[i].addr);
        }
      }
      if (out.isEmpty && appState.account != null) {
        addAddr(appState.account!.addr);
      }
      if (out.isEmpty) {
        for (final a in accounts) {
          addAddr(a.addr);
        }
      }
    }

    // Other wallets (e.g. BTC while UI is on Solana).
    for (final w in appState.wallets) {
      if (w.slip44 != slip44) continue;
      final byBip = w.accounts[slip44];
      if (byBip == null) continue;
      final list = byBip[w.bip] ??
          byBip.values.expand((e) => e).toList();
      if (list.isEmpty) continue;
      final idx = w.selectedAccount.toInt();
      if (idx >= 0 && idx < list.length) {
        addAddr(list[idx].addr);
      } else {
        addAddr(list.first.addr);
      }
    }
    return out;
  }

  List<String> _resolveChains(
    WcNamespaceInfo ns,
    AppState appState,
    int slip44,
  ) {
    if (ns.chains.isNotEmpty) {
      // Keep dApp-requested CAIP-2 chains as-is (filter only obviously wrong).
      return List<String>.from(ns.chains);
    }
    // No chains in proposal → use every provider we know for this slip44,
    // mapped to CAIP-2.
    final caip = <String>{};
    for (final p in appState.state.providers) {
      if (p.slip44 != slip44) continue;
      final id = _caip2ForProvider(ns.key, p);
      if (id != null) caip.add(id);
    }
    if (caip.isEmpty) {
      final fallback = _defaultCaip2(ns.key, appState);
      if (fallback != null) caip.add(fallback);
    }
    return caip.toList();
  }

  String? _caip2ForProvider(String nsKey, NetworkConfigInfo p) {
    final id = p.chainId.toInt();
    switch (nsKey) {
      case 'eip155':
        return 'eip155:$id';
      case 'solana':
        return kSolanaCaip2ByChainId[id] ?? 'solana:${p.chainId}';
      case 'tron':
        return 'tron:${p.chainId}';
      case 'bip122':
        return kBtcCaip2ByChainId[id] ??
            kBtcCaip2ByChainId[0]; // default mainnet genesis
      default:
        return null;
    }
  }

  String? _defaultCaip2(String nsKey, AppState appState) {
    final ch = appState.chain;
    if (ch != null && _slip44ForNamespace(nsKey) == ch.slip44) {
      return _caip2ForProvider(nsKey, ch);
    }
    switch (nsKey) {
      case 'bip122':
        return kBtcCaip2ByChainId[0];
      case 'solana':
        return kSolanaCaip2ByChainId[101];
      case 'eip155':
        return 'eip155:1';
      default:
        return null;
    }
  }

  List<String> _methodsFor(String nsKey, List<String> requested) {
    final supported = switch (nsKey) {
      'eip155' => kWcEip155Methods,
      'solana' => kWcSolanaMethods,
      'tron' => kWcTronMethods,
      'bip122' => kWcBip122Methods,
      _ => const <String>[],
    };
    if (supported.isEmpty) return const [];
    if (requested.isEmpty) return List<String>.from(supported);
    final hit = requested.where(supported.contains).toList();
    // If the dApp names methods we don't implement, still settle with our
    // supported set so multi-chain AppKit proposals can connect (optional ns).
    return hit.isEmpty ? List<String>.from(supported) : hit;
  }

  List<String> _eventsFor(String nsKey, List<String> requested) {
    final supported = switch (nsKey) {
      'bip122' => kWcBip122Events,
      _ => kWcStandardEvents,
    };
    final out = <String>[];
    if (requested.isEmpty) {
      out.addAll(supported);
    } else {
      out.addAll(requested.where(supported.contains));
    }
    for (final e in supported) {
      if (!out.contains(e)) out.add(e);
    }
    return out;
  }

  String _formatAccountAddr(String addr, String ns) {
    if (ns == 'eip155') return addr;
    // bip122 / solana / tron: no 0x prefix
    return addr.startsWith('0x') ? addr.substring(2) : addr;
  }

  Future<void> _routeRequest(WcRequestInfo req) async {
    final context = _ctx;
    if (context == null || !context.mounted) {
      await wcRespondErr(
        topic: req.topic,
        id: req.id,
        code: PlatformInt64Util.from(5000),
        message: 'Wallet UI unavailable',
      );
      return;
    }

    final method = req.method;
    switch (method) {
      case 'personal_sign':
      case 'eth_sign':
        await _handleSignMessage(context, req);
      case 'eth_signTypedData':
      case 'eth_signTypedData_v3':
      case 'eth_signTypedData_v4':
        await _handleTypedData(context, req);
      case 'eth_sendTransaction':
      case 'eth_signTransaction':
        await _handleSendTransaction(context, req);
      default:
        await wcRespondErr(
          topic: req.topic,
          id: req.id,
          code: PlatformInt64Util.from(5001),
          message: 'Unsupported method: $method',
        );
    }
  }

  Future<void> _handleSignMessage(
    BuildContext context,
    WcRequestInfo req,
  ) async {
    String? message;
    try {
      final params = jsonDecode(req.paramsJson);
      if (params is List && params.isNotEmpty) {
        // personal_sign: [data, address] · eth_sign: [address, data]
        if (req.method == 'eth_sign' && params.length >= 2) {
          message = params[1]?.toString();
        } else {
          message = params[0]?.toString();
        }
      }
    } catch (_) {
      message = req.paramsJson;
    }

    if (!context.mounted) return;

    showSignMessageModal(
      context: context,
      message: message,
      appTitle: req.peerName,
      appIcon: req.peerIcon ?? '',
      onMessageSigned: (pubkey, sig) async {
        await wcRespondOk(
          topic: req.topic,
          id: req.id,
          resultJson: jsonEncode(sig),
        );
        if (context.mounted) Navigator.of(context).pop();
      },
      onDismiss: () async {
        await wcRespondErr(
          topic: req.topic,
          id: req.id,
          code: PlatformInt64Util.from(5000),
          message: 'User rejected',
        );
      },
    );
  }

  Future<void> _handleTypedData(
    BuildContext context,
    WcRequestInfo req,
  ) async {
    TypedDataEip712? typed;
    try {
      final params = jsonDecode(req.paramsJson);
      // eth_signTypedData_v4: [address, typedDataObject|string]
      dynamic raw;
      if (params is List && params.length >= 2) {
        raw = params[1];
      } else {
        raw = params;
      }
      if (raw is String) {
        typed = TypedDataEip712.fromJsonString(raw);
      } else if (raw is Map<String, dynamic>) {
        typed = TypedDataEip712.fromJson(raw);
      } else if (raw is Map) {
        typed = TypedDataEip712.fromJson(Map<String, dynamic>.from(raw));
      }
    } catch (e) {
      debugPrint('wc typedData parse: $e');
      await wcRespondErr(
        topic: req.topic,
        id: req.id,
        code: PlatformInt64Util.from(5002),
        message: 'Invalid typed data: $e',
      );
      return;
    }

    if (typed == null) {
      await wcRespondErr(
        topic: req.topic,
        id: req.id,
        code: PlatformInt64Util.from(5002),
        message: 'Invalid typed data params',
      );
      return;
    }

    if (!context.mounted) return;

    showSignMessageModal(
      context: context,
      typedData: typed,
      appTitle: req.peerName.isEmpty ? 'Sign Typed Data' : req.peerName,
      appIcon: req.peerIcon ?? '',
      onMessageSigned: (pubkey, sig) async {
        await wcRespondOk(
          topic: req.topic,
          id: req.id,
          resultJson: jsonEncode(sig),
        );
        if (context.mounted) Navigator.of(context).pop();
      },
      onDismiss: () async {
        await wcRespondErr(
          topic: req.topic,
          id: req.id,
          code: PlatformInt64Util.from(5000),
          message: 'User rejected',
        );
      },
    );
  }

  Future<void> _handleSendTransaction(
    BuildContext context,
    WcRequestInfo req,
  ) async {
    final appState = Provider.of<AppState>(context, listen: false);

    Map<String, dynamic>? txParams;
    try {
      final params = jsonDecode(req.paramsJson);
      if (params is List && params.isNotEmpty && params[0] is Map) {
        txParams = Map<String, dynamic>.from(params[0] as Map);
      } else if (params is Map) {
        txParams = Map<String, dynamic>.from(params);
      }
    } catch (e) {
      await wcRespondErr(
        topic: req.topic,
        id: req.id,
        code: PlatformInt64Util.from(5002),
        message: 'Invalid tx params: $e',
      );
      return;
    }

    if (txParams == null) {
      await wcRespondErr(
        topic: req.topic,
        id: req.id,
        code: PlatformInt64Util.from(5002),
        message: 'Invalid parameters for eth_sendTransaction',
      );
      return;
    }

    final from = txParams['from'] as String?;
    final to = txParams['to'] as String?;
    final value = txParams['value'] as String?;
    final dataHex = txParams['data']?.toString();

    BigInt? parseHexBig(dynamic v) {
      if (v == null) return null;
      final s = v.toString().replaceFirst(RegExp(r'^0x'), '');
      if (s.isEmpty) return BigInt.zero;
      return BigInt.tryParse(s, radix: 16);
    }

    final gasLimit = parseHexBig(txParams['gas'] ?? txParams['gasLimit']);
    final maxFeePerGas = parseHexBig(txParams['maxFeePerGas']);
    final maxPriorityFeePerGas = parseHexBig(txParams['maxPriorityFeePerGas']);
    final gasPrice = parseHexBig(txParams['gasPrice']);
    final chainId = parseHexBig(txParams['chainId']);

    Uint8List? data;
    if (dataHex != null && dataHex.isNotEmpty && dataHex != '0x') {
      try {
        data = Uint8List.fromList(
          hexToBytes(dataHex.replaceFirst(RegExp(r'^0x'), '')),
        );
      } catch (_) {
        data = null;
      }
    }

    final evmRequest = TransactionRequestEVM(
      nonce: null,
      from: from,
      to: to,
      value: value,
      gasLimit: gasLimit,
      data: data,
      maxFeePerGas: maxFeePerGas,
      maxPriorityFeePerGas: maxPriorityFeePerGas,
      gasPrice: gasPrice,
      chainId: chainId,
      accessList: null,
      blobVersionedHashes: null,
      maxFeePerBlobGas: null,
    );

    FTokenInfo? mbToken;
    try {
      mbToken = appState.wallet?.tokens
          .firstWhere((t) => t.addrType == kEvmAddressType && t.native);
    } catch (_) {
      mbToken = null;
    }

    if (mbToken == null) {
      await wcRespondErr(
        topic: req.topic,
        id: req.id,
        code: PlatformInt64Util.from(5003),
        message: 'No native EVM token configured',
      );
      return;
    }

    final valueAmount = value != null && value != '0x' && value != '0x0'
        ? (parseHexBig(value) ?? BigInt.zero)
        : BigInt.zero;

    final tokenInfo = BaseTokenInfo(
      value: valueAmount.toString(),
      symbol: mbToken.symbol,
      decimals: mbToken.decimals,
    );

    final metadata = TransactionMetadataInfo(
      chainHash: appState.chain?.chainHash ?? BigInt.zero,
      hash: null,
      info: null,
      icon: req.peerIcon,
      title: req.peerName.isEmpty ? 'EVM Transaction' : req.peerName,
      signer: appState.account?.addr,
      tokenInfo: tokenInfo,
      broadcast: req.method == 'eth_sendTransaction',
    );

    final transactionRequest = TransactionRequestInfo(
      metadata: metadata,
      scilla: null,
      evm: evmRequest,
    );

    if (!context.mounted) return;

    final amountStr = fromWei(
      value: valueAmount.toString(),
      decimals: mbToken.decimals,
    ).toString();

    // transfer.dart calls onDismiss after onConfirm and on sheet close —
    // guard so we only respond once.
    var responded = false;
    Future<void> respondOnce(Future<void> Function() fn) async {
      if (responded) return;
      responded = true;
      await fn();
    }

    showConfirmTransactionModal(
      context: context,
      tx: transactionRequest,
      to: to ?? '',
      token: mbToken,
      amount: amountStr,
      onConfirm: (tx) async {
        final hash = tx.transactionHash;
        await respondOnce(() async {
          if (hash.isEmpty) {
            await wcRespondErr(
              topic: req.topic,
              id: req.id,
              code: PlatformInt64Util.from(5004),
              message: 'Transaction failed',
            );
          } else {
            await wcRespondOk(
              topic: req.topic,
              id: req.id,
              resultJson: jsonEncode(hash),
            );
          }
        });
        if (context.mounted) Navigator.of(context).pop();
      },
      onDismiss: () async {
        await respondOnce(() async {
          await wcRespondErr(
            topic: req.topic,
            id: req.id,
            code: PlatformInt64Util.from(5000),
            message: 'User rejected',
          );
        });
      },
    );
  }

  static String _platformName() {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.linux:
        return 'linux';
      default:
        return 'unknown';
    }
  }

  static String _packageName() {
    if (kIsWeb) return kWcAppUrl;
    try {
      if (Platform.isAndroid) return 'com.zilpaymobile';
      if (Platform.isIOS) return 'io.zilpay.bearby';
    } catch (_) {}
    return 'com.zilpaymobile';
  }
}
