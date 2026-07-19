import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kDebugMode, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart'
    show PlatformInt64Util, Uint16List, Uint64List;
import 'package:provider/provider.dart';

import 'package:bearby/config/ftokens.dart';
import 'package:bearby/config/walletconnect.dart';
import 'package:bearby/config/web3_constants.dart';
import 'package:bearby/mixins/eip712.dart';
import 'package:bearby/mixins/transaction_parsing.dart';
import 'package:bearby/modals/add_chain.dart';
import 'package:bearby/modals/app_connect.dart';
import 'package:bearby/modals/sign_message.dart';
import 'package:bearby/modals/swich_chain_modal.dart';
import 'package:bearby/modals/transfer.dart';
import 'package:bearby/src/rust/api/provider.dart';
import 'package:bearby/src/rust/api/utils.dart';
import 'package:bearby/src/rust/api/walletconnect.dart';
import 'package:bearby/src/rust/models/ftoken.dart';
import 'package:bearby/src/rust/models/provider.dart';
import 'package:bearby/src/rust/models/walletconnect/ffi.dart';
import 'package:bearby/state/app_state.dart';
import 'package:bearby/utils/utils.dart';
import 'package:bearby/web3/request_builders.dart';

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

  /// Debug builds only — avoids WC metadata noise in release/profile.
  void _log(String msg) {
    if (kDebugMode) debugPrint('[wc] $msg');
  }

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
    final w = appState.wallet;
    _log(
      'approve wallet="${w?.walletName}" selectedAccount=${w?.selectedAccount} '
      'uiSlip44=${w?.slip44} uiBip=${w?.bip} '
      'mapSlip44s=${w?.accounts.keys.toList()}',
    );
    _log(
      'proposal required=${proposal.required_.map((n) => '${n.key}[${n.chains.join(",")}] m=${n.methods}').join('; ')} '
      'optional=${proposal.optional.map((n) => '${n.key}[${n.chains.join(",")}] m=${n.methods}').join('; ')}',
    );

    final out = <WcNamespaceApproval>[];
    final seen = <String>{};

    void addNs(WcNamespaceInfo ns, {required bool required}) {
      if (!seen.add(ns.key)) return;

      if (!required && ns.key == 'bip122') {
        _log('skip ns=bip122: optional (AppKit default chain = sort().first)');
        return;
      }

      final slip44 = _slip44ForNamespace(ns.key);
      if (slip44 == null) {
        _log('skip ns=${ns.key}: unsupported namespace');
        return;
      }

      // Selected wallet only: accounts[slip44][bip][accountIndex] — same
      // account index across chains (see WalletDataV2.slip44_accounts).
      final addrs = _addressesForSlip44(appState, slip44, selectedIndexes);
      if (addrs.isEmpty) {
        _log(
          'skip ns=${ns.key}: selected wallet has no accounts[$slip44] '
          'at idx=${selectedIndexes.isEmpty ? appState.wallet?.selectedAccount : selectedIndexes}',
        );
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

  /// BIP purpose used when accounts were created for [slip44]
  /// (`DerivationPath::default_bip` in bearby-core).
  int _defaultBip(int slip44) {
    if (slip44 == kBitcoinlip44) return 84; // BIP84 P2WPKH
    return 44;
  }

  /// Addresses for [slip44] from the **selected wallet only**.
  ///
  /// Structure: `wallet.accounts[slip44][bip][accountIndex]`.
  /// The same [selectedIndexes] / `selectedAccount` apply to every slip44
  /// (acc 0 Solana ↔ acc 0 Bitcoin on the same seed). Never reads other wallets.
  List<String> _addressesForSlip44(
    AppState appState,
    int slip44,
    List<int> selectedIndexes,
  ) {
    final w = appState.wallet;
    if (w == null) return const [];

    final byBip = w.accounts[slip44];
    if (byBip == null || byBip.isEmpty) return const [];

    final preferredBip = _defaultBip(slip44);
    final bip = byBip.containsKey(preferredBip)
        ? preferredBip
        : (byBip.containsKey(w.bip) ? w.bip : byBip.keys.first);
    final list = byBip[bip];
    if (list == null || list.isEmpty) return const [];

    // Connect modal indices == account index; same across slip44 maps.
    final indexes = selectedIndexes.isNotEmpty
        ? selectedIndexes
        : <int>[w.selectedAccount.toInt()];

    final out = <String>[];
    final seen = <String>{};
    for (final i in indexes) {
      if (i < 0 || i >= list.length) continue;
      final a = list[i].addr;
      if (a.isEmpty) continue;
      if (seen.add(a)) out.add(a);
    }

    // If preferred bip missed (e.g. only BIP44 BTC stored), try any bip with
    // enough accounts for the same indexes.
    if (out.isEmpty) {
      for (final entry in byBip.entries) {
        final alt = entry.value;
        for (final i in indexes) {
          if (i < 0 || i >= alt.length) continue;
          final a = alt[i].addr;
          if (a.isNotEmpty && seen.add(a)) out.add(a);
        }
        if (out.isNotEmpty) break;
      }
    }

    _log(
      'addrs slip44=$slip44 bip=$bip idx=$indexes '
      'wallet="${w.walletName}" → $out',
    );
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

  /// True if [address] appears as the address segment of any CAIP-10 account
  /// on the session (eip155:1:0xabc → 0xabc), case-insensitive.
  Future<bool> _sessionOwnsAddress(String topic, String address) async {
    final needle = address.toLowerCase();
    if (needle.isEmpty) return false;
    List<WcSessionInfo> sessions;
    try {
      sessions = await wcSessions();
    } catch (e) {
      _log('sessionOwnsAddress sessions: $e');
      return false;
    }
    for (final s in sessions) {
      if (s.topic != topic) continue;
      for (final acc in s.accounts) {
        final parts = acc.split(':');
        final addr = parts.isNotEmpty ? parts.last : acc;
        if (addr.toLowerCase() == needle) return true;
      }
      final preview = s.accounts.length > 6
          ? '${s.accounts.take(6).join(', ')}…(+${s.accounts.length - 6})'
          : s.accounts.join(', ');
      _log(
        'sessionOwnsAddress miss addr=$address '
        'topic=${topic.length > 12 ? topic.substring(0, 12) : topic}… '
        'accounts=[$preview]',
      );
      return false;
    }
    _log(
      'sessionOwnsAddress no session topic='
      '${topic.length > 12 ? topic.substring(0, 12) : topic}… '
      'sessions=${sessions.length}',
    );
    return false;
  }

  String _preview(String? raw, [int max = 96]) {
    if (raw == null) return 'null';
    if (raw.length <= max) return raw;
    return '${raw.substring(0, max)}…';
  }

  /// Extract EVM signer address from WC params by method.
  String? _evmSignerFromParams(String method, dynamic params) {
    if (params is! List || params.isEmpty) return null;
    // personal_sign: [data, address]
    // eth_sign / eth_signTypedData*: [address, data]
    if (method == 'personal_sign') {
      if (params.length < 2) return null;
      return params[1]?.toString();
    }
    return params[0]?.toString();
  }

  BigInt? _evmAccountIndexForAddress(AppState appState, String address) {
    final w = appState.wallet;
    if (w == null) return null;
    final needle = address.toLowerCase();
    if (needle.isEmpty) return null;

    final slipOrder = <int>[
      if (w.slip44 == kEthereumSlip44 || w.slip44 == kZilliqaSlip44) w.slip44,
      kEthereumSlip44,
      kZilliqaSlip44,
    ];
    final seen = <int>{};
    for (final slip in slipOrder) {
      if (!seen.add(slip)) continue;
      final byBip = w.accounts[slip];
      if (byBip == null || byBip.isEmpty) continue;
      final list = byBip[44] ?? byBip.values.first;
      for (var i = 0; i < list.length; i++) {
        if (list[i].addr.toLowerCase() == needle) {
          return BigInt.from(i);
        }
      }
    }
    return null;
  }

  Future<void> notifyActiveNetwork(AppState appState) async {
    if (!_started) return;
    final ch = appState.chain;
    final acc = appState.account;
    if (ch == null || acc == null) {
      _log('notifyActiveNetwork skip: no chain/account');
      return;
    }
    final ns = ch.slip44 == kEthereumSlip44 || ch.slip44 == kZilliqaSlip44
        ? 'eip155'
        : ch.slip44 == kSolanaSlip44
            ? 'solana'
            : ch.slip44 == kTronSlip44
                ? 'tron'
                : ch.slip44 == kBitcoinlip44
                    ? 'bip122'
                    : null;
    if (ns == null) {
      _log('notifyActiveNetwork skip: unsupported slip44=${ch.slip44}');
      return;
    }
    final id = ch.chainId.toInt();
    final caip2 = ns == 'bip122'
        ? (kBtcCaip2ByChainId[id] ?? kBtcCaip2ByChainId[0]!)
        : ns == 'solana'
            ? (kSolanaCaip2ByChainId[id] ?? 'solana:${ch.chainId}')
            : ns == 'eip155'
                ? 'eip155:$id'
                : '$ns:${ch.chainId}';
    _log('notifyActiveNetwork caip2=$caip2 addr=${acc.addr}');
    await onChainChanged(caip2: caip2);
    await onAccountsChanged(address: acc.addr, caip2: caip2);
  }

  Future<bool> _rejectIfUnauthorized({
    required WcRequestInfo req,
    required String? address,
  }) async {
    if (address == null || address.isEmpty) {
      _log('auth missing address method=${req.method}');
      await wcRespondErr(
        topic: req.topic,
        id: req.id,
        code: PlatformInt64Util.from(5002),
        message: 'Missing signer address',
      );
      return true;
    }
    final ok = await _sessionOwnsAddress(req.topic, address);
    if (ok) return false;
    _log(
      'auth reject method=${req.method} addr=$address '
      'topic=${req.topic.length > 12 ? req.topic.substring(0, 12) : req.topic}…',
    );
    await wcRespondErr(
      topic: req.topic,
      id: req.id,
      code: PlatformInt64Util.from(4100),
      message: 'Unauthorized address',
    );
    return true;
  }

  Future<void> _routeRequest(WcRequestInfo req) async {
    final method = req.method;
    _log(
      'route id=${req.id} method=$method chain=${req.chainId} '
      'topic=${req.topic.length > 12 ? req.topic.substring(0, 12) : req.topic}… '
      'params=${_preview(req.paramsJson)}',
    );

    final context = _ctx;
    if (context == null || !context.mounted) {
      _log('route abort UI unavailable id=${req.id} method=$method');
      await wcRespondErr(
        topic: req.topic,
        id: req.id,
        code: PlatformInt64Util.from(5000),
        message: 'Wallet UI unavailable',
      );
      return;
    }

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
      case 'wallet_switchEthereumChain':
        await _handleSwitchEthereumChain(context, req);
      case 'wallet_addEthereumChain':
        await _handleAddEthereumChain(context, req);
      default:
        _log('route unsupported id=${req.id} method=$method');
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
    _log(
      'signMessage enter method=${req.method} id=${req.id} '
      'chain=${req.chainId}',
    );
    dynamic params;
    String? message;
    try {
      params = jsonDecode(req.paramsJson);
      if (params is List && params.isNotEmpty) {
        if (req.method == 'eth_sign' && params.length >= 2) {
          message = params[1]?.toString();
        } else {
          message = params[0]?.toString();
        }
      }
      _log(
        'signMessage params kind=${params.runtimeType} '
        'len=${params is List ? params.length : '-'} '
        'raw=${_preview(req.paramsJson)}',
      );
    } catch (e) {
      _log('signMessage params jsonDecode failed: $e');
      message = req.paramsJson;
      params = null;
    }

    final address = _evmSignerFromParams(req.method, params);
    _log('signMessage signer addr=$address');
    if (await _rejectIfUnauthorized(req: req, address: address)) return;

    final displayMessage = message == null
        ? null
        : (req.method == 'personal_sign'
            ? decodePersonalSignMessage(message)
            : message);

    if (!context.mounted) {
      _log('signMessage abort unmounted id=${req.id}');
      await wcRespondErr(
        topic: req.topic,
        id: req.id,
        code: PlatformInt64Util.from(5000),
        message: 'Wallet UI unavailable',
      );
      return;
    }

    final appState = context.read<AppState>();
    final w = appState.wallet;
    final signAccountIndex = address == null
        ? null
        : _evmAccountIndexForAddress(appState, address);
    if (signAccountIndex == null) {
      _log(
        'signMessage no local account for addr=$address '
        'uiSlip44=${w?.slip44} uiAccount=${w?.selectedAccount}',
      );
      await wcRespondErr(
        topic: req.topic,
        id: req.id,
        code: PlatformInt64Util.from(4100),
        message: 'Requested address not in wallet',
      );
      return;
    }
    _log(
      'signMessage show modal method=${req.method} '
      'msgLen=${displayMessage?.length ?? 0} '
      'display=${_preview(displayMessage)} addr=$address '
      'signAccount=$signAccountIndex '
      'uiWallet="${w?.walletName}" uiSlip44=${w?.slip44} '
      'uiAccount=${w?.selectedAccount} uiAddr=${appState.account?.addr}',
    );

    var responded = false;
    Future<void> respondOnce(Future<void> Function() fn) async {
      if (responded) {
        _log('signMessage respondOnce skip (already responded) id=${req.id}');
        return;
      }
      responded = true;
      try {
        await fn();
      } catch (e) {
        _log('signMessage respondOnce error id=${req.id}: $e');
      }
    }

    showSignMessageModal(
      context: context,
      message: displayMessage,
      appTitle: req.peerName,
      appIcon: req.peerIcon ?? '',
      accountIndex: signAccountIndex,
      onMessageSigned: (pubkey, sig) async {
        await respondOnce(() async {
          _log(
            'signMessage ok method=${req.method} id=${req.id} '
            'sigLen=${sig.length} sig=${_preview(sig, 22)} '
            'pubkey=${_preview(pubkey, 18)}',
          );
          await wcRespondOk(
            topic: req.topic,
            id: req.id,
            resultJson: jsonEncode(sig),
          );
          _log('signMessage wcRespondOk done id=${req.id}');
        });
        if (context.mounted) Navigator.of(context).pop();
      },
      onDismiss: () async {
        await respondOnce(() async {
          _log('signMessage reject/dismiss method=${req.method} id=${req.id}');
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

  Future<void> _handleTypedData(
    BuildContext context,
    WcRequestInfo req,
  ) async {
    _log('typedData method=${req.method} id=${req.id}');
    TypedDataEip712? typed;
    dynamic paramsDecoded;
    try {
      paramsDecoded = jsonDecode(req.paramsJson);
      dynamic raw;
      if (paramsDecoded is List && paramsDecoded.length >= 2) {
        raw = paramsDecoded[1];
      } else {
        raw = paramsDecoded;
      }
      if (raw is String) {
        typed = TypedDataEip712.fromJsonString(raw);
      } else if (raw is Map<String, dynamic>) {
        typed = TypedDataEip712.fromJson(raw);
      } else if (raw is Map) {
        typed = TypedDataEip712.fromJson(Map<String, dynamic>.from(raw));
      }
    } catch (e) {
      _log('typedData parse: $e');
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

    final address = _evmSignerFromParams(req.method, paramsDecoded);
    if (await _rejectIfUnauthorized(req: req, address: address)) return;

    if (!context.mounted) return;

    final appState = context.read<AppState>();
    final signAccountIndex = address == null
        ? null
        : _evmAccountIndexForAddress(appState, address);
    if (signAccountIndex == null) {
      _log('typedData no local account for addr=$address');
      await wcRespondErr(
        topic: req.topic,
        id: req.id,
        code: PlatformInt64Util.from(4100),
        message: 'Requested address not in wallet',
      );
      return;
    }

    _log(
      'typedData show modal method=${req.method} addr=$address '
      'signAccount=$signAccountIndex uiAccount=${appState.wallet?.selectedAccount}',
    );

    var responded = false;
    Future<void> respondOnce(Future<void> Function() fn) async {
      if (responded) return;
      responded = true;
      await fn();
    }

    showSignMessageModal(
      context: context,
      typedData: typed,
      appTitle: req.peerName.isEmpty ? 'Sign Typed Data' : req.peerName,
      appIcon: req.peerIcon ?? '',
      accountIndex: signAccountIndex,
      onMessageSigned: (pubkey, sig) async {
        await respondOnce(() async {
          _log('typedData ok method=${req.method} sigLen=${sig.length}');
          await wcRespondOk(
            topic: req.topic,
            id: req.id,
            resultJson: jsonEncode(sig),
          );
        });
        if (context.mounted) Navigator.of(context).pop();
      },
      onDismiss: () async {
        await respondOnce(() async {
          _log('typedData reject method=${req.method}');
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

  Future<void> _handleSendTransaction(
    BuildContext context,
    WcRequestInfo req,
  ) async {
    final isSignOnly = req.method == 'eth_signTransaction';
    _log(
      'tx method=${req.method} id=${req.id} signOnly=$isSignOnly '
      'chain=${req.chainId}',
    );

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
      _log('tx bad params: $e');
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
        message: 'Invalid parameters for ${req.method}',
      );
      return;
    }

    // Prefer embedded tx chainId; else inject from WC session request CAIP-2 (eip155:N).
    if (txParams[kParamChainId] == null && txParams['chain_id'] == null) {
      final parts = req.chainId.split(':');
      if (parts.length >= 2 && parts[0] == 'eip155') {
        final n = int.tryParse(parts[1]);
        if (n != null) {
          txParams[kParamChainId] = '0x${n.toRadixString(16)}';
          _log('tx injected chainId from req.chainId=${req.chainId}');
        }
      }
    }

    final from = txParams[kParamFrom]?.toString();
    if (await _rejectIfUnauthorized(req: req, address: from)) return;

    final mbToken = nativeEvmToken(appState);
    if (mbToken == null) {
      _log('tx no native EVM token');
      await wcRespondErr(
        topic: req.topic,
        id: req.id,
        code: PlatformInt64Util.from(5003),
        message: 'No native EVM token configured',
      );
      return;
    }

    final transactionRequest = buildEvmTransactionRequestInfo(
      txParams: txParams,
      appState: appState,
      broadcast: !isSignOnly,
      nativeToken: mbToken,
      title: req.peerName.isEmpty ? null : req.peerName,
      icon: req.peerIcon,
    );

    final to = txParams[kParamTo]?.toString() ?? '';
    final valueAmount = evmValueAmount(txParams[kParamValue]?.toString());

    if (!context.mounted) return;

    final amountStr = fromWei(
      value: valueAmount.toString(),
      decimals: mbToken.decimals,
    ).toString();

    _log(
      'tx show modal method=${req.method} to=$to value=$valueAmount '
      'broadcast=${!isSignOnly}',
    );

    var responded = false;
    Future<void> respondOnce(Future<void> Function() fn) async {
      if (responded) return;
      responded = true;
      await fn();
    }

    showConfirmTransactionModal(
      context: context,
      tx: transactionRequest,
      to: to,
      token: mbToken,
      amount: amountStr,
      onConfirm: (tx) async {
        await respondOnce(() async {
          if (isSignOnly) {
            final raw = tx.signedEvmTransaction;
            if (raw == null || raw.isEmpty) {
              _log('tx signOnly missing signedTransaction');
              await wcRespondErr(
                topic: req.topic,
                id: req.id,
                code: PlatformInt64Util.from(5004),
                message: 'Missing signed transaction payload',
              );
              return;
            }
            _log('tx signOnly ok rawLen=${raw.length}');
            await wcRespondOk(
              topic: req.topic,
              id: req.id,
              resultJson: jsonEncode(raw),
            );
          } else {
            final hash = tx.transactionHash;
            if (hash.isEmpty) {
              _log('tx send missing hash');
              await wcRespondErr(
                topic: req.topic,
                id: req.id,
                code: PlatformInt64Util.from(5004),
                message: 'Transaction failed',
              );
              return;
            }
            _log('tx send ok hash=$hash');
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
          _log('tx reject method=${req.method}');
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

  NetworkConfigInfo _networkWithRpc(NetworkConfigInfo base, List<String> rpc) {
    return NetworkConfigInfo(
      name: base.name,
      logo: base.logo,
      chain: base.chain,
      shortName: base.shortName,
      rpc: rpc,
      features: base.features,
      chainId: base.chainId,
      chainIds: base.chainIds,
      slip44: base.slip44,
      diffBlockTime: base.diffBlockTime,
      chainHash: base.chainHash,
      ens: base.ens,
      explorers: base.explorers,
      fallbackEnabled: base.fallbackEnabled,
      testnet: base.testnet,
      ftokens: base.ftokens,
    );
  }

  Future<void> _handleSwitchEthereumChain(
    BuildContext context,
    WcRequestInfo req,
  ) async {
    _log('switchChain id=${req.id}');
    final appState = Provider.of<AppState>(context, listen: false);

    BigInt chainId;
    try {
      final params = jsonDecode(req.paramsJson);
      if (params is! List || params.isEmpty || params[0] is! Map) {
        await wcRespondErr(
          topic: req.topic,
          id: req.id,
          code: PlatformInt64Util.from(5002),
          message: 'Invalid parameters for wallet_switchEthereumChain',
        );
        return;
      }
      final chainParams = Map<String, dynamic>.from(params[0] as Map);
      final raw = chainParams[kParamChainId] ?? chainParams['chain_id'];
      if (raw == null) {
        await wcRespondErr(
          topic: req.topic,
          id: req.id,
          code: PlatformInt64Util.from(5002),
          message: 'Missing chainId',
        );
        return;
      }
      final s = raw.toString().replaceFirst(RegExp(r'^0[xX]'), '');
      chainId = BigInt.parse(s, radix: 16);
    } catch (e) {
      _log('switchChain parse: $e');
      await wcRespondErr(
        topic: req.topic,
        id: req.id,
        code: PlatformInt64Util.from(5002),
        message: 'Invalid chainId: $e',
      );
      return;
    }

    NetworkConfigInfo? target;
    for (final p in appState.state.providers) {
      if (p.slip44 == kBitcoinlip44) continue;
      if (p.chainId == chainId &&
          !(p.slip44 == kZilliqaSlip44 && p.chainId == kZilliqaChainId)) {
        target = p;
        break;
      }
    }

    if (target == null) {
      try {
        final mainnetJson = await rootBundle.loadString(kMainnetChainsPath);
        final testnetJson = await rootBundle.loadString(kTestnetChainsPath);
        final (mainnetChains, testnetChains) = await getNetworks(
          mainnetJson: mainnetJson,
          testnetJson: testnetJson,
        );
        for (final chain in [...mainnetChains, ...testnetChains]) {
          if (chain.chainId == chainId &&
              !(chain.slip44 == kZilliqaSlip44 &&
                  chain.chainId == kZilliqaChainId)) {
            target = chain;
            break;
          }
        }
        if (target != null) {
          await addProvider(providerConfig: target);
          await appState.syncData();
        }
      } catch (e) {
        _log('switchChain catalog: $e');
      }
    }

    if (target == null) {
      _log('switchChain unrecognized chainId=$chainId');
      await wcRespondErr(
        topic: req.topic,
        id: req.id,
        code: PlatformInt64Util.from(4902),
        message: 'Unrecognized chain ID',
      );
      return;
    }

    if (!context.mounted) return;

    var responded = false;
    Future<void> respondOnce(Future<void> Function() fn) async {
      if (responded) return;
      responded = true;
      await fn();
    }

    showSwitchChainNetworkModal(
      context: context,
      selectedChainId: chainId,
      filtersBySlip44: const [kEthereumSlip44, kZilliqaSlip44],
      onNetworkSelected: () async {
        // Modal already emits WC chainChanged + accountsChanged.
        _log('switchChain ok chainId=$chainId');
        await respondOnce(() async {
          await wcRespondOk(
            topic: req.topic,
            id: req.id,
            resultJson: 'null',
          );
        });
      },
      onReject: () async {
        _log('switchChain reject');
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

  Future<void> _handleAddEthereumChain(
    BuildContext context,
    WcRequestInfo req,
  ) async {
    _log('addChain id=${req.id}');
    final appState = Provider.of<AppState>(context, listen: false);

    Map<String, dynamic> chainParams;
    try {
      final params = jsonDecode(req.paramsJson);
      if (params is! List || params.isEmpty || params[0] is! Map) {
        await wcRespondErr(
          topic: req.topic,
          id: req.id,
          code: PlatformInt64Util.from(5002),
          message: 'Invalid parameters for wallet_addEthereumChain',
        );
        return;
      }
      chainParams = Map<String, dynamic>.from(params[0] as Map);
    } catch (e) {
      await wcRespondErr(
        topic: req.topic,
        id: req.id,
        code: PlatformInt64Util.from(5002),
        message: 'Invalid addChain params: $e',
      );
      return;
    }

    if (!chainParams.containsKey(kParamChainId) ||
        !chainParams.containsKey(kParamChainName) ||
        !chainParams.containsKey(kParamNativeCurrency) ||
        !chainParams.containsKey(kParamRpcUrls)) {
      await wcRespondErr(
        topic: req.topic,
        id: req.id,
        code: PlatformInt64Util.from(5002),
        message: 'Missing required chain fields',
      );
      return;
    }

    final rpcUrls = (chainParams[kParamRpcUrls] as List<dynamic>)
        .where(
            (url) => url is String && url.toString().startsWith(kHttpsProtocol))
        .cast<String>()
        .toList();
    if (rpcUrls.isEmpty) {
      await wcRespondErr(
        topic: req.topic,
        id: req.id,
        code: PlatformInt64Util.from(5002),
        message: 'No valid HTTPS rpcUrls',
      );
      return;
    }

    final nativeCurrency =
        Map<String, dynamic>.from(chainParams[kParamNativeCurrency] as Map);
    final chainId = BigInt.parse(
      chainParams[kParamChainId].toString().replaceFirst(RegExp(r'^0[xX]'), ''),
      radix: 16,
    );
    final explorers =
        ((chainParams[kParamBlockExplorerUrls] as List?) ?? const [])
            .map((url) => ExplorerInfo(
                  name: kDefaultExplorerName,
                  url: url.toString(),
                  standard: kDefaultExplorerStandard,
                ))
            .toList();
    final symbol = nativeCurrency[kParamSymbol]?.toString() ?? 'ETH';
    final name = nativeCurrency[kParamName]?.toString() ?? 'Ether';

    NetworkConfigInfo? foundChain;
    if (appState.state.providers.any((c) => c.chainId == chainId)) {
      final chain =
          appState.state.providers.firstWhere((c) => c.chainId == chainId);
      final mergedRpc = {...chain.rpc, ...rpcUrls}.toList();
      foundChain = _networkWithRpc(chain, mergedRpc);
    } else {
      try {
        final mainnetJson = await rootBundle.loadString(kMainnetChainsPath);
        final testnetJson = await rootBundle.loadString(kTestnetChainsPath);
        final (mainnetChains, _) = await getNetworks(
          mainnetJson: mainnetJson,
          testnetJson: testnetJson,
        );
        if (mainnetChains.any((c) => c.chainId == chainId)) {
          final chain = mainnetChains.firstWhere((c) => c.chainId == chainId);
          final mergedRpc = {...chain.rpc, ...rpcUrls}.toList();
          foundChain = _networkWithRpc(chain, mergedRpc);
        }
      } catch (e) {
        _log('addChain catalog: $e');
      }
    }

    final logo =
        'https://static.cx.metamask.io/api/v1/tokenIcons/$chainId/$zeroEVM.png';

    foundChain ??= NetworkConfigInfo(
      ftokens: [
        FTokenInfo(
          logo: logo,
          name: name,
          symbol: symbol,
          decimals: kDefaultEvmDecimals,
          addr: zeroEVM,
          addrType: kEvmAddressType,
          balances: {},
          rate: 0,
          default_: false,
          native: true,
          chainHash: BigInt.zero,
        )
      ],
      name: chainParams[kParamChainName].toString(),
      logo: logo,
      chain: chainParams[kParamChainName].toString(),
      shortName: symbol,
      rpc: rpcUrls,
      features: Uint16List.fromList(kDefaultEvmFeatures),
      chainId: chainId,
      chainIds: Uint64List.fromList([chainId, 0]),
      slip44: kEthereumSlip44,
      diffBlockTime: BigInt.zero,
      chainHash: BigInt.zero,
      explorers: explorers,
      fallbackEnabled: true,
      testnet: name.toLowerCase().contains(kTestnetIdentifier),
    );

    foundChain = _networkWithRpc(foundChain, foundChain.rpc.toSet().toList());

    if (!context.mounted) return;

    var responded = false;
    Future<void> respondOnce(Future<void> Function() fn) async {
      if (responded) return;
      responded = true;
      await fn();
    }

    showAddChainModal(
      context: context,
      title: req.peerName,
      appIcon: req.peerIcon ?? '',
      chain: foundChain,
      onConfirm: (selectedRpc) async {
        try {
          final updated = _networkWithRpc(foundChain!, selectedRpc);
          await createOrUpdateChain(providerConfig: updated);
          await appState.syncData();
          _log('addChain ok chainId=$chainId');
          await respondOnce(() async {
            await wcRespondOk(
              topic: req.topic,
              id: req.id,
              resultJson: 'null',
            );
          });
        } catch (e) {
          _log('addChain error: $e');
          await respondOnce(() async {
            await wcRespondErr(
              topic: req.topic,
              id: req.id,
              code: PlatformInt64Util.from(5000),
              message: e.toString(),
            );
          });
        }
      },
      onReject: () async {
        _log('addChain reject');
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
