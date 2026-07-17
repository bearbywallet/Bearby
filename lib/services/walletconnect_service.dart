import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:reown_walletkit/reown_walletkit.dart';
import 'package:walletconnect_pay/walletconnect_pay_platform_interface.dart';
import 'package:bearby/config/walletconnect.dart';
import 'package:bearby/config/web3_constants.dart';
import 'package:bearby/l10n/app_localizations.dart';
import 'package:bearby/mixins/eip712.dart';
import 'package:bearby/mixins/transaction_parsing.dart';
import 'package:bearby/modals/app_connect.dart';
import 'package:bearby/modals/sign_message.dart';
import 'package:bearby/modals/swich_chain_modal.dart';
import 'package:bearby/modals/transfer.dart';
import 'package:bearby/router.dart';
import 'package:bearby/src/rust/api/btc.dart';
import 'package:bearby/src/rust/api/transaction.dart';
import 'package:bearby/src/rust/api/utils.dart';
import 'package:bearby/src/rust/api/wallet.dart';
import 'package:bearby/src/rust/models/btc_chain.dart';
import 'package:bearby/src/rust/models/ftoken.dart';
import 'package:bearby/src/rust/models/provider.dart';
import 'package:bearby/src/rust/models/transactions/base_token.dart';
import 'package:bearby/src/rust/models/transactions/request.dart';
import 'package:bearby/src/rust/models/transactions/transaction_metadata.dart';
import 'package:bearby/state/app_state.dart';
import 'package:bearby/web3/request_builders.dart';
import 'package:bearby/web3/web3_utils.dart';

/// SDK handler typedef is `dynamic Function(String, dynamic)` — that boundary
/// is quarantined here: params are cast to Object? immediately and never
/// travel further as dynamic.
typedef _WcHandler = Future<void> Function(String topic, Object? params);

/// Snapshot of the active wallet/account before a temporary signer switch.
typedef _Selection = ({BigInt wallet, BigInt account});

/// Shared modal completion plumbing: single-shot ok/reject + selection restore.
///
/// [context] is captured when the request modal is shown and is only used for
/// [Navigator.pop] after a response. Callers must not assume it stays mounted
/// across awaits — always check [BuildContext.mounted] before pop (done here).
class _RequestResponder {
  final WalletConnectService _service;
  final String topic;
  final int id;
  final BuildContext context;
  final _Selection? previous;
  bool responded = false;

  _RequestResponder({
    required WalletConnectService service,
    required this.topic,
    required this.id,
    required this.context,
    required this.previous,
  }) : _service = service;

  Future<void> ok(Object? result) async {
    if (responded) return;
    responded = true;
    // Keep the temporary signer switch; notify other sessions now that the
    // user confirmed (events were suppressed during the pre-consent switch).
    _service._emitAccountsChangedIfNeeded(previous);
    await _service._respond(topic, id, result);
    if (context.mounted) Navigator.pop(context);
    await _service._redirectToDapp(topic);
  }

  Future<void> rejected() async {
    if (responded) return;
    responded = true;
    await _service._restoreSelection(previous);
    await _service._respondError(topic, Errors.USER_REJECTED, id: id);
  }

  /// Malformed signed payload after the user already confirmed — restore
  /// selection, error the dapp, and dismiss the modal so it cannot stick open.
  Future<void> failMalformed() async {
    if (responded) return;
    responded = true;
    await _service._restoreSelection(previous);
    await _service._respondError(
      topic,
      Errors.MALFORMED_REQUEST_PARAMS,
      id: id,
    );
    if (context.mounted) Navigator.pop(context);
  }
}

class WalletConnectService extends ChangeNotifier {
  final AppState appState;
  final GoRouter router;

  ReownWalletKit? _walletKit;
  String? _lastAddress;
  BigInt? _lastChainId;
  String _registrationFingerprint = '';
  List<WcSessionView> _cachedSessionViews = const <WcSessionView>[];
  Completer<void>? _initCompleter;
  Object? _initError;

  /// >0 suppresses accountsChanged/chainChanged emission (temporary switches).
  int _suppressAppStateEvents = 0;

  WalletConnectService({required this.appState, required this.router});

  bool get isReady => _walletKit != null;

  List<SessionData> get sessions {
    final kit = _walletKit;
    if (kit == null) return const <SessionData>[];
    return kit.sessions.getAll();
  }

  List<WcSessionView> get sessionViews => _cachedSessionViews;

  BuildContext? get _context {
    final fromRoot = rootNavigatorKey.currentContext;
    if (fromRoot != null) return fromRoot;
    return router.routerDelegate.navigatorKey.currentContext;
  }

  // ────────────────────────── lifecycle ──────────────────────────

  /// WalletConnect Pay only ships native plugins for Android/iOS. On other
  /// platforms [kit.init] would throw MissingPluginException after sign is
  /// already set up. Install a no-op platform impl so WalletKit 1.4+ can
  /// finish init (Pay APIs remain unavailable off-mobile).
  void _ensureWalletConnectPayPlatform() {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      WalletconnectPayPlatform.instance = _NoopWalletconnectPayPlatform();
    }
  }

  /// Lazy entry: kit + relay + registrations. Call only from [waitUntilReady]
  /// / first WC use — never from app cold start.
  Future<void> init() async {
    if (_walletKit != null) return;
    final pending = _initCompleter;
    if (pending != null) {
      await pending.future;
      return;
    }

    final completer = Completer<void>();
    _initCompleter = completer;
    _initError = null;

    try {
      _ensureWalletConnectPayPlatform();
      final kit = ReownWalletKit(
        core: ReownCore(projectId: kWalletConnectProjectId),
        metadata: kBearbyWalletMetadata,
      );
      await kit.init();
      _walletKit = kit;
      _syncRegistrations();
      kit.onSessionProposal.subscribe(_onSessionProposal);
      kit.onSessionDelete.subscribe(_onSessionDelete);
      kit.onSessionExpire.subscribe(_onSessionExpire);
      _lastAddress = appState.account?.addr;
      _lastChainId = appState.chain?.chainId;
      appState.addListener(_onAppStateChanged);
      _refreshSessionViews();
      notifyListeners();
      if (!completer.isCompleted) completer.complete();
    } catch (e) {
      // Relay/init failure must never break app startup.
      _initError = e;
      debugPrint('WalletConnect init failed: $e');
      if (!completer.isCompleted) completer.complete();
      // Allow waitUntilReady()/pair() to retry after connectivity returns.
      _initCompleter = null;
    }
  }

  /// Wait until [init] finishes (success or failure).
  Future<void> waitUntilReady() async {
    if (_walletKit != null) return;
    final pending = _initCompleter;
    if (pending != null) {
      await pending.future;
    } else {
      await init();
    }
  }

  @override
  void dispose() {
    final kit = _walletKit;
    if (kit != null) {
      kit.onSessionProposal.unsubscribe(_onSessionProposal);
      kit.onSessionDelete.unsubscribe(_onSessionDelete);
      kit.onSessionExpire.unsubscribe(_onSessionExpire);
    }
    appState.removeListener(_onAppStateChanged);
    super.dispose();
  }

  // ────────────────────────── pairing ──────────────────────────

  Future<void> pair(String uri) async {
    await waitUntilReady();
    final kit = _walletKit;
    if (kit == null) {
      final detail = _initError;
      throw StateError(
        detail == null
            ? 'WalletConnect is not initialized'
            : 'WalletConnect failed to start: $detail',
      );
    }

    final trimmed = uri.trim();
    if (!trimmed.startsWith('wc:')) {
      // Do not embed the payload — it may be a full clipboard dump.
      throw const FormatException('Not a WalletConnect URI');
    }

    // Re-sync so bip122 accounts exist before the proposal arrives.
    _syncRegistrations();

    try {
      await kit.pair(uri: Uri.parse(trimmed));
    } catch (e) {
      debugPrint('WC pair failed: $e');
      rethrow;
    }
  }

  Future<void> disconnectSession(String topic) async {
    final kit = _walletKit;
    if (kit == null) return;
    try {
      await kit.disconnectSession(
        topic: topic,
        reason: Errors.getSdkError(Errors.USER_DISCONNECTED).toSignError(),
      );
    } catch (e) {
      debugPrint('WC disconnect failed: $e');
    } finally {
      _refreshSessionViews();
      notifyListeners();
    }
  }

  // ────────────────────── chain / account registry ──────────────────────

  /// NetworkConfigInfo → CAIP-2. Derivable for eip155/tron; const map for
  /// solana/btc; null for unsupported (Scilla-only, zilpay-BTC).
  static String? caip2ForProvider(NetworkConfigInfo provider) {
    if (provider.chainIds.isEmpty) return null;
    final chainId = provider.chainIds.first;
    switch (provider.slip44) {
      case kEthereumSlip44:
      case kZilliqaSlip44: // Zilliqa EVM mode → eip155:32769
        return 'eip155:$chainId';
      case kTronSlip44:
        return 'tron:0x${chainId.toRadixString(16)}';
      case kSolanaSlip44:
        return kSolanaCaip2ByChainId[chainId.toInt()];
      case kBitcoinlip44:
        final caip2 = kBtcCaip2ByChainId[chainId.toInt()];
        // chainIds.first == 2 (zilpay) has no public genesis CAIP-2.
        return caip2;
      default:
        return null;
    }
  }

  String _computeRegistrationFingerprint() {
    final buffer = StringBuffer();
    // Active-wallet-only registration (v1) — fingerprint that wallet.
    buffer.write(appState.selectedWallet);
    buffer.write('|');
    final wallet = appState.wallet;
    if (wallet != null) {
      buffer
        ..write(wallet.walletAddress)
        ..write(':')
        ..write(wallet.slip44)
        ..write(':')
        ..write(wallet.bip)
        ..write(':');
      final accounts = wallet.accounts[wallet.slip44]?[wallet.bip] ?? const [];
      for (final a in accounts) {
        buffer
          ..write(a.addr)
          ..write(',')
          ..write(a.addrType)
          ..write(';');
      }
    }
    for (final p in appState.state.providers) {
      buffer
        ..write(p.chainHash)
        ..write(',');
    }
    return buffer.toString();
  }

  void _syncRegistrations() {
    final kit = _walletKit;
    if (kit == null) return;
    final fingerprint = _computeRegistrationFingerprint();
    if (fingerprint == _registrationFingerprint &&
        _registrationFingerprint.isNotEmpty) {
      return;
    }
    _registrationFingerprint = fingerprint;
    _registerChains(kit);
  }

  void _registerChains(ReownWalletKit kit) {
    for (final provider in appState.state.providers) {
      final caip2 = caip2ForProvider(provider);
      if (caip2 == null) continue;
      final colon = caip2.indexOf(':');
      if (colon <= 0) continue;
      final namespace = caip2.substring(0, colon);
      final addresses = _addressesForNamespace(namespace);

      for (final address in addresses) {
        try {
          kit.registerAccount(chainId: caip2, accountAddress: address);
        } catch (e) {
          debugPrint('WC registerAccount $caip2/$address failed: $e');
        }
      }
      for (final entry in _handlersFor(namespace).entries) {
        try {
          kit.registerRequestHandler(
            chainId: caip2,
            method: entry.key,
            handler: _guard(entry.value),
          );
        } catch (e) {
          debugPrint('WC registerRequestHandler $caip2/${entry.key}: $e');
        }
      }
      final events = kWcEventsByNamespace[namespace] ?? const <String>[];
      for (final event in events) {
        try {
          kit.registerEventEmitter(chainId: caip2, event: event);
        } catch (e) {
          debugPrint('WC registerEventEmitter $caip2/$event: $e');
        }
      }
    }
  }

  /// Active-wallet addresses matching [namespace] address-family (v1 contract).
  ///
  /// Scans every slip44/bip map on the **active wallet** (not only the current
  /// chain's slip44) so multi-chain HD wallets register eip155 + bip122, etc.
  List<String> _addressesForNamespace(String namespace) {
    final addrType = kWcAddrTypeByNamespace[namespace];
    if (addrType == null) return const <String>[];

    final wallet = appState.wallet;
    if (wallet == null) return const <String>[];

    final seen = <String>{};
    for (final bipMap in wallet.accounts.values) {
      for (final accountList in bipMap.values) {
        for (final account in accountList) {
          if (account.addrType == addrType) {
            seen.add(account.addr);
          }
        }
      }
    }
    return List<String>.from(seen, growable: false);
  }

  /// Session-approved bare addresses for [namespace] (never the full registry).
  List<String> _sessionAccountsFor(String topic, String namespace) {
    final session = _walletKit?.sessions.get(topic);
    final ns = session?.namespaces[namespace];
    if (ns == null) return const <String>[];
    final seen = <String>{
      for (final caip10 in ns.accounts) _bareWcAddress(caip10),
    };
    return List<String>.from(seen, growable: false);
  }

  Map<String, _WcHandler> _handlersFor(String namespace) {
    switch (namespace) {
      case 'eip155':
        return {
          for (final method in kWcEvmSigningMethods)
            if (_evmHandler(method) case final handler?) method: handler,
        };
      case 'solana':
        return {
          for (final method in kWcSolanaMethods)
            if (_solanaHandler(method) case final handler?) method: handler,
        };
      case 'tron':
        return {
          for (final method in kWcTronMethods)
            if (_tronHandler(method) case final handler?) method: handler,
        };
      case 'bip122':
        return {
          for (final method in kWcBtcMethods)
            if (_btcHandler(method) case final handler?) method: handler,
        };
      default:
        return const {};
    }
  }

  _WcHandler? _evmHandler(String method) {
    switch (method) {
      case 'personal_sign':
        return _personalSign;
      case 'eth_sign':
        return _ethSign;
      case 'eth_signTypedData_v4':
        return _ethSignTypedDataV4;
      case 'eth_sendTransaction':
        return _ethSendTransaction;
      case 'wallet_switchEthereumChain':
        return _walletSwitchChain;
      default:
        return null;
    }
  }

  _WcHandler? _solanaHandler(String method) {
    switch (method) {
      case 'solana_getAccounts':
      case 'solana_requestAccounts':
        return _solanaGetAccounts;
      case 'solana_signMessage':
        return _solanaSignMessage;
      case 'solana_signTransaction':
        return _solanaSignTransaction;
      case 'solana_signAndSendTransaction':
        return _solanaSignAndSendTransaction;
      default:
        return null;
    }
  }

  _WcHandler? _tronHandler(String method) {
    switch (method) {
      case 'tron_signMessage':
        return _tronSignMessage;
      case 'tron_signTransaction':
        return _tronSignTransaction;
      default:
        return null;
    }
  }

  _WcHandler? _btcHandler(String method) {
    switch (method) {
      case 'sendTransfer':
        return _btcSendTransfer;
      case 'getAccountAddresses':
        return _btcGetAccountAddresses;
      case 'signPsbt':
        return _btcSignPsbt;
      case 'signMessage':
        return _btcSignMessage;
      default:
        return null;
    }
  }

  // ignore: avoid_annotating_with_dynamic — SDK-imposed signature
  dynamic Function(String, dynamic) _guard(_WcHandler handler) {
    return (String topic, dynamic params) async {
      try {
        await handler(topic, params as Object?);
      } catch (e) {
        debugPrint('WC handler error: $e');
        await _respondError(topic, Errors.MALFORMED_REQUEST_PARAMS);
      }
    };
  }

  // ─────────────────── request plumbing (shared, DRY) ───────────────────

  ({ReownWalletKit kit, int id, String chainId})? _pendingRequest(
    String topic,
  ) {
    final kit = _walletKit;
    if (kit == null) return null;
    final matching = kit.pendingRequests
        .getAll()
        .where((r) => r.topic == topic)
        .toList(growable: false);
    if (matching.isEmpty) return null;
    final last = matching.last;
    return (kit: kit, id: last.id, chainId: last.chainId);
  }

  Future<void> _respond(String topic, int id, Object? result) async {
    final kit = _walletKit;
    if (kit == null) return;
    try {
      await kit.respondSessionRequest(
        topic: topic,
        response: JsonRpcResponse(id: id, jsonrpc: '2.0', result: result),
      );
    } catch (e) {
      debugPrint('WC respond failed: $e');
    }
  }

  Future<void> _respondError(
    String topic,
    String sdkErrorKey, {
    int? id,
  }) async {
    final kit = _walletKit;
    if (kit == null) return;
    final requestId = id ?? _pendingRequest(topic)?.id;
    if (requestId == null) return;
    final err = Errors.getSdkError(sdkErrorKey);
    try {
      await kit.respondSessionRequest(
        topic: topic,
        response: JsonRpcResponse(
          id: requestId,
          jsonrpc: '2.0',
          error: JsonRpcError(code: err.code, message: err.message),
        ),
      );
    } catch (e) {
      debugPrint('WC respondError failed: $e');
    }
  }

  ({String name, String icon, Redirect? redirect}) _peerOf(String topic) {
    final metadata = _walletKit?.sessions.get(topic)?.peer.metadata;
    final icons = metadata?.icons;
    final icon = (icons != null && icons.isNotEmpty) ? icons.first : '';
    return (
      name: metadata?.name ?? 'WalletConnect',
      icon: icon,
      redirect: metadata?.redirect,
    );
  }

  Future<void> _redirectToDapp(String topic) async {
    final kit = _walletKit;
    if (kit == null) return;
    try {
      await kit.redirectToDapp(
        topic: topic,
        redirect: _peerOf(topic).redirect,
      );
    } catch (_) {
      // No redirect metadata / QR-originated session — silently skip.
    }
  }

  void _notifyUserError(String message) {
    final context = _context;
    if (context == null || !context.mounted) return;
    final theme = appState.currentTheme;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: theme.bodyLarge.copyWith(color: theme.buttonText),
        ),
        backgroundColor: theme.danger,
      ),
    );
  }

  FTokenInfo? _nativeTokenFor(int addrType) {
    final tokens = appState.wallet?.tokens;
    if (tokens == null || tokens.isEmpty) return null;
    for (final token in tokens) {
      if (token.native && token.addrType == addrType) return token;
    }
    for (final token in tokens) {
      if (token.native) return token;
    }
    return tokens.first;
  }

  String _displayAmount(Object? rawValue, FTokenInfo nativeToken) {
    final amount = hexToBigInt(rawValue) ?? BigInt.zero;
    return fromWei(
      value: amount.toString(),
      decimals: nativeToken.decimals,
    ).toString();
  }

  /// EVM hex addresses compare case-insensitively; base58 chains are exact.
  static bool _addressesEqual(String a, String b) {
    if (a == b) return true;
    final aHex = a.startsWith(kHexPrefix) || a.startsWith('0X');
    final bHex = b.startsWith(kHexPrefix) || b.startsWith('0X');
    if (aHex || bHex) {
      return a.toLowerCase() == b.toLowerCase();
    }
    return false;
  }

  _Selection? _selectionSnapshot() {
    final w = appState.selectedWalletIndexOrNull;
    final a = appState.wallet?.selectedAccount;
    if (w == null || a == null) return null;
    return (wallet: w, account: a);
  }

  Future<void> _restoreSelection(_Selection? previous) async {
    if (previous == null) return;
    final currentW = appState.selectedWalletIndexOrNull;
    final currentA = appState.wallet?.selectedAccount;
    if (currentW == previous.wallet && currentA == previous.account) {
      return;
    }
    _suppressAppStateEvents++;
    try {
      if (currentW != previous.wallet) {
        appState.setSelectedWallet(previous.wallet.toInt());
      }
      await appState.updateSelectedAccount(previous.wallet, previous.account);
      _lastAddress = appState.account?.addr;
      _lastChainId = appState.chain?.chainId;
    } catch (e) {
      debugPrint('WC restoreSelection failed: $e');
    } finally {
      _suppressAppStateEvents--;
    }
  }

  void _emitAccountsChangedIfNeeded(_Selection? previous) {
    final kit = _walletKit;
    if (kit == null) return;
    final account = appState.account;
    final addr = account?.addr;
    if (account == null || addr == null) return;
    if (previous != null) {
      final currentW = appState.selectedWalletIndexOrNull;
      final currentA = appState.wallet?.selectedAccount;
      if (currentW == previous.wallet && currentA == previous.account) {
        return; // no switch happened
      }
    }
    _lastAddress = addr;
    if (account.addrType == kBtcAddressType) {
      unawaited(_emitBtcAddressesChanged());
      return;
    }
    final namespace = _namespaceForAddrType(account.addrType);
    if (namespace == null) return;
    _emitToNamespaceSessions(
      kit,
      namespace,
      kAccountsChangedEvent,
      (session) => _sessionHasBareAddress(session, namespace, addr)
          ? <String>[addr]
          : null,
    );
  }

  /// WC namespace for an account address family (null if unregistered).
  static String? _namespaceForAddrType(int addrType) {
    switch (addrType) {
      case kEvmAddressType:
        return 'eip155';
      case kSolanaAddressType:
        return 'solana';
      case kTronAddressType:
        return 'tron';
      case kBtcAddressType:
        return 'bip122';
      default:
        return null;
    }
  }

  /// True if [address] is among [session]'s approved bare addresses for [namespace].
  bool _sessionHasBareAddress(
    SessionData session,
    String namespace,
    String address,
  ) {
    final ns = session.namespaces[namespace];
    if (ns == null) return false;
    for (final caip10 in ns.accounts) {
      if (_addressesEqual(_bareWcAddress(caip10), address)) return true;
    }
    return false;
  }

  /// CAIP-2 ids approved on a namespace (derived from CAIP-10 accounts).
  static Set<String> _namespaceChains(Namespace ns) {
    final chains = <String>{};
    for (final caip10 in ns.accounts) {
      final i = caip10.lastIndexOf(':');
      if (i > 0) chains.add(caip10.substring(0, i));
    }
    return chains;
  }

  /// True if [address] is among session-approved accounts for [caip2]'s namespace.
  bool _isSessionAccount(String topic, String caip2, String address) {
    final colon = caip2.indexOf(':');
    if (colon <= 0) return false;
    final namespace = caip2.substring(0, colon);
    for (final approved in _sessionAccountsFor(topic, namespace)) {
      if (_addressesEqual(approved, address)) return true;
    }
    return false;
  }

  /// Session-scope signer gate + select. Only addresses the session approved
  /// may be switched to / used for signing. Restores [previous] if the switch
  /// fails mid-way. When [addressOptional] is true and [address] is empty,
  /// authorizes the currently selected account against the session.
  Future<bool> _ensureAuthorizedSigner({
    required String topic,
    required String caip2,
    required String? address,
    required _Selection? previous,
    bool addressOptional = false,
  }) async {
    final String? target;
    if (address != null && address.isNotEmpty) {
      target = address;
    } else if (addressOptional) {
      target = appState.account?.addr;
    } else {
      return false;
    }
    if (target == null || target.isEmpty) return false;
    if (!_isSessionAccount(topic, caip2, target)) return false;
    if (!await _ensureSigner(target)) {
      await _restoreSelection(previous);
      return false;
    }
    return true;
  }

  /// Finds the wallet/account owning [address], selects it, returns true.
  /// Does not emit accountsChanged (caller handles on confirm/reject).
  /// On mid-switch failure, restores the pre-switch selection (M1).
  Future<bool> _ensureSigner(String? address) async {
    if (address == null || address.isEmpty) return false;

    final current = appState.account?.addr;
    if (current != null && _addressesEqual(current, address)) {
      return true;
    }

    final before = _selectionSnapshot();
    for (var w = 0; w < appState.wallets.length; w++) {
      final wallet = appState.wallets[w];
      final accounts = wallet.accounts[wallet.slip44]?[wallet.bip] ?? const [];
      for (var a = 0; a < accounts.length; a++) {
        if (!_addressesEqual(accounts[a].addr, address)) continue;
        _suppressAppStateEvents++;
        try {
          final selected = appState.selectedWalletIndexOrNull;
          if (selected == null || selected.toInt() != w) {
            appState.setSelectedWallet(w);
          }
          await appState.updateSelectedAccount(
            BigInt.from(w),
            BigInt.from(a),
          );
          // Keep trackers in sync without broadcasting.
          _lastAddress = appState.account?.addr;
          _lastChainId = appState.chain?.chainId;
          return true;
        } catch (e) {
          debugPrint('WC ensureSigner failed: $e');
          await _restoreSelection(before);
          return false;
        } finally {
          _suppressAppStateEvents--;
        }
      }
    }
    return false;
  }

  List<int>? _slip44FilterForCaip2(String caip2) {
    if (caip2.startsWith('eip155:')) {
      return const [kEthereumSlip44, kZilliqaSlip44];
    }
    if (caip2.startsWith('tron:')) {
      return const [kTronSlip44];
    }
    if (caip2.startsWith('solana:')) {
      return const [kSolanaSlip44];
    }
    if (caip2.startsWith('bip122:')) {
      return const [kBitcoinlip44];
    }
    return null;
  }

  /// CAIP-10 → bare address (`namespace:ref:addr` → `addr`).
  static String _bareWcAddress(String address) {
    final parts = address.split(':');
    if (parts.length >= 3) return parts.last;
    return address;
  }

  /// Bare address from a request param map key (handles CAIP-10).
  static String? _bareParam(Map<String, Object?>? map, String key) {
    final raw = map?[key]?.toString();
    if (raw == null || raw.isEmpty) return null;
    return _bareWcAddress(raw);
  }

  /// Provider whose CAIP-2 matches [caip2] (no modal / no active-chain switch).
  NetworkConfigInfo? _providerForCaip2(String caip2) {
    for (final p in appState.state.providers) {
      if (caip2ForProvider(p) == caip2) return p;
    }
    return null;
  }

  /// First bip122 CAIP-2 from a namespace (`chains` or account CAIP-10).
  static String? _firstBip122Caip2(Namespace? ns) {
    if (ns == null) return null;
    final chains = ns.chains;
    if (chains != null) {
      for (final c in chains) {
        if (c.startsWith('bip122:')) return c;
      }
    }
    for (final a in ns.accounts) {
      final parts = a.split(':');
      if (parts.length >= 2 && parts[0] == 'bip122') {
        return '${parts[0]}:${parts[1]}';
      }
    }
    return null;
  }

  Future<NetworkConfigInfo?> _ensureChain(
    BuildContext context,
    String caip2,
  ) async {
    NetworkConfigInfo? provider;
    for (final p in appState.state.providers) {
      if (caip2ForProvider(p) == caip2) {
        provider = p;
        break;
      }
    }
    if (provider == null) return null;

    final active = appState.chain;
    if (active != null && active.chainHash == provider.chainHash) {
      return provider;
    }

    final target = provider;
    final completer = Completer<bool>();
    showSwitchChainNetworkModal(
      context: context,
      selectedChainId:
          target.chainIds.isNotEmpty ? target.chainIds.first : target.chainId,
      filtersBySlip44: _slip44FilterForCaip2(caip2),
      onNetworkSelected: () {
        if (!completer.isCompleted) completer.complete(true);
      },
      onReject: () {
        if (!completer.isCompleted) completer.complete(false);
      },
    );
    final approved = await completer.future;
    if (!approved) return null;

    final after = appState.chain;
    if (after == null || after.chainHash != target.chainHash) {
      return null;
    }
    return target;
  }

  // ─────────────────────────── EVM handlers ───────────────────────────

  Future<void> _personalSign(String topic, Object? params) =>
      _signMessageFlow(topic, params, messageIndex: 0, addressIndex: 1);

  Future<void> _ethSign(String topic, Object? params) =>
      _signMessageFlow(topic, params, messageIndex: 1, addressIndex: 0);

  Future<void> _signMessageFlow(
    String topic,
    Object? params, {
    required int messageIndex,
    required int addressIndex,
  }) async {
    final pending = _pendingRequest(topic);
    final context = _context;
    if (pending == null || context == null || !context.mounted) return;

    final list = params is List ? List<Object?>.of(params) : const <Object?>[];
    if (list.length < 2) {
      return _respondError(
        topic,
        Errors.MALFORMED_REQUEST_PARAMS,
        id: pending.id,
      );
    }

    final previous = _selectionSnapshot();
    final address = list[addressIndex]?.toString();
    if (!await _ensureAuthorizedSigner(
      topic: topic,
      caip2: pending.chainId,
      address: address,
      previous: previous,
    )) {
      return _respondError(
        topic,
        Errors.UNAUTHORIZED_METHOD,
        id: pending.id,
      );
    }

    final dataToSign = list[messageIndex]?.toString() ?? '';
    final message = decodePersonalSignMessage(dataToSign);

    if (!context.mounted) {
      await _restoreSelection(previous);
      return;
    }
    final peer = _peerOf(topic);
    final responder = _RequestResponder(
      service: this,
      topic: topic,
      id: pending.id,
      context: context,
      previous: previous,
    );
    showSignMessageModal(
      context: context,
      message: message,
      appTitle: peer.name,
      appIcon: peer.icon,
      onMessageSigned: (pubkey, sig) => responder.ok(sig),
      onDismiss: () => unawaited(responder.rejected()),
    );
  }

  Future<void> _ethSignTypedDataV4(String topic, Object? params) async {
    final pending = _pendingRequest(topic);
    final context = _context;
    if (pending == null || context == null || !context.mounted) return;

    final list = params is List ? List<Object?>.of(params) : const <Object?>[];
    if (list.length < 2) {
      return _respondError(
        topic,
        Errors.MALFORMED_REQUEST_PARAMS,
        id: pending.id,
      );
    }

    final previous = _selectionSnapshot();
    final address = list[0]?.toString();
    if (!await _ensureAuthorizedSigner(
      topic: topic,
      caip2: pending.chainId,
      address: address,
      previous: previous,
    )) {
      return _respondError(
        topic,
        Errors.UNAUTHORIZED_METHOD,
        id: pending.id,
      );
    }

    final rawTypedData = list[1]?.toString() ?? '';

    final TypedDataEip712 typedData;
    try {
      // Top-level [compute] only — nested Isolate.run closures capture `this`
      // (Completers, listeners) and crash with "unsendable" errors.
      typedData = rawTypedData.length > kWcIsolatePayloadThreshold
          ? await compute(_wcParseTypedData, rawTypedData)
          : _wcParseTypedData(rawTypedData);
    } catch (e) {
      await _restoreSelection(previous);
      return _respondError(
        topic,
        Errors.MALFORMED_REQUEST_PARAMS,
        id: pending.id,
      );
    }

    if (!context.mounted) {
      await _restoreSelection(previous);
      return;
    }
    final peer = _peerOf(topic);
    final responder = _RequestResponder(
      service: this,
      topic: topic,
      id: pending.id,
      context: context,
      previous: previous,
    );
    showSignMessageModal(
      context: context,
      typedData: typedData,
      appTitle: peer.name,
      appIcon: peer.icon,
      onMessageSigned: (pubkey, sig) => responder.ok(sig),
      onDismiss: () => unawaited(responder.rejected()),
    );
  }

  Future<void> _ethSendTransaction(String topic, Object? params) async {
    final pending = _pendingRequest(topic);
    final context = _context;
    if (pending == null || context == null || !context.mounted) return;

    final list = params is List ? List<Object?>.of(params) : const <Object?>[];
    final txParams = list.isNotEmpty && list.first is Map
        ? Map<String, Object?>.from(list.first as Map)
        : null;
    if (txParams == null) {
      return _respondError(
        topic,
        Errors.MALFORMED_REQUEST_PARAMS,
        id: pending.id,
      );
    }

    final previous = _selectionSnapshot();
    final from = txParams[kParamFrom]?.toString();
    if (!await _ensureAuthorizedSigner(
      topic: topic,
      caip2: pending.chainId,
      address: from,
      previous: previous,
    )) {
      return _respondError(
        topic,
        Errors.UNAUTHORIZED_METHOD,
        id: pending.id,
      );
    }

    if (!context.mounted) {
      await _restoreSelection(previous);
      return;
    }
    final provider = await _ensureChain(context, pending.chainId);
    if (provider == null) {
      await _restoreSelection(previous);
      return _respondError(topic, Errors.USER_REJECTED, id: pending.id);
    }

    final nativeToken = _nativeTokenFor(kEvmAddressType);
    if (nativeToken == null) {
      await _restoreSelection(previous);
      return _respondError(
        topic,
        Errors.MALFORMED_REQUEST_PARAMS,
        id: pending.id,
      );
    }

    final peer = _peerOf(topic);
    final TransactionRequestInfo tx;
    try {
      tx = buildEvmTransactionRequest(
        txParams: txParams,
        nativeToken: nativeToken,
        chainHash: provider.chainHash,
        signerAddr: appState.account?.addr,
        title: peer.name,
        icon: peer.icon,
      );
    } catch (e) {
      await _restoreSelection(previous);
      return _respondError(
        topic,
        Errors.MALFORMED_REQUEST_PARAMS,
        id: pending.id,
      );
    }

    if (!context.mounted) {
      await _restoreSelection(previous);
      return;
    }
    final responder = _RequestResponder(
      service: this,
      topic: topic,
      id: pending.id,
      context: context,
      previous: previous,
    );
    showConfirmTransactionModal(
      context: context,
      tx: tx,
      to: txParams[kParamTo]?.toString() ?? '',
      token: nativeToken,
      amount: _displayAmount(txParams[kParamValue], nativeToken),
      onConfirm: (signed) => responder.ok(signed.transactionHash),
      onDismiss: () => unawaited(responder.rejected()),
    );
  }

  Future<void> _walletSwitchChain(String topic, Object? params) async {
    final pending = _pendingRequest(topic);
    final context = _context;
    if (pending == null || context == null || !context.mounted) return;

    final list = params is List ? List<Object?>.of(params) : const <Object?>[];
    final first = list.isNotEmpty && list.first is Map
        ? Map<String, Object?>.from(list.first as Map)
        : null;
    final chainIdHex = first?[kParamChainId]?.toString();
    if (chainIdHex == null) {
      return _respondError(
        topic,
        Errors.MALFORMED_REQUEST_PARAMS,
        id: pending.id,
      );
    }

    final chainId = hexToBigInt(chainIdHex);
    if (chainId == null) {
      return _respondError(
        topic,
        Errors.MALFORMED_REQUEST_PARAMS,
        id: pending.id,
      );
    }

    final caip2 = 'eip155:$chainId';
    final provider = await _ensureChain(context, caip2);
    if (provider == null) {
      return _respondError(topic, Errors.USER_REJECTED, id: pending.id);
    }
    await _respond(topic, pending.id, null);
    await _redirectToDapp(topic);
  }

  // ────────────────────────── Solana handlers ──────────────────────────

  Future<void> _solanaGetAccounts(String topic, Object? params) async {
    final pending = _pendingRequest(topic);
    if (pending == null) return;
    final accounts = _sessionAccountsFor(topic, 'solana');
    final result = List<Map<String, String>>.generate(
      accounts.length,
      (i) => {'pubkey': accounts[i]},
      growable: false,
    );
    await _respond(topic, pending.id, result);
  }

  Future<void> _solanaSignMessage(String topic, Object? params) async {
    final pending = _pendingRequest(topic);
    final context = _context;
    if (pending == null || context == null || !context.mounted) return;

    final map = params is Map ? Map<String, Object?>.from(params) : null;
    final messageB58 = map?['message']?.toString();
    final pubkey = map?['pubkey']?.toString();
    if (messageB58 == null || messageB58.isEmpty) {
      return _respondError(
        topic,
        Errors.MALFORMED_REQUEST_PARAMS,
        id: pending.id,
      );
    }

    final previous = _selectionSnapshot();
    if (!await _ensureAuthorizedSigner(
      topic: topic,
      caip2: pending.chainId,
      address: pubkey,
      previous: previous,
      addressOptional: true,
    )) {
      return _respondError(
        topic,
        Errors.UNAUTHORIZED_METHOD,
        id: pending.id,
      );
    }

    final String decoded;
    try {
      final bytes = _base58Decode(messageB58);
      decoded = utf8.decode(bytes);
    } catch (_) {
      await _restoreSelection(previous);
      return _respondError(
        topic,
        Errors.MALFORMED_REQUEST_PARAMS,
        id: pending.id,
      );
    }

    if (!context.mounted) {
      await _restoreSelection(previous);
      return;
    }
    final peer = _peerOf(topic);
    final responder = _RequestResponder(
      service: this,
      topic: topic,
      id: pending.id,
      context: context,
      previous: previous,
    );
    showSignMessageModal(
      context: context,
      message: decoded,
      appTitle: peer.name,
      appIcon: peer.icon,
      onMessageSigned: (pk, sig) => responder.ok({'signature': sig}),
      onDismiss: () => unawaited(responder.rejected()),
    );
  }

  Future<void> _solanaSignTransaction(String topic, Object? params) =>
      _solanaTxFlow(topic, params, broadcast: false);

  Future<void> _solanaSignAndSendTransaction(String topic, Object? params) =>
      _solanaTxFlow(topic, params, broadcast: true);

  Future<void> _solanaTxFlow(
    String topic,
    Object? params, {
    required bool broadcast,
  }) async {
    final pending = _pendingRequest(topic);
    final context = _context;
    if (pending == null || context == null || !context.mounted) return;

    final map = params is Map ? Map<String, Object?>.from(params) : null;
    final txBase64 = map?['transaction']?.toString();
    if (txBase64 == null) {
      return _respondError(
        topic,
        Errors.MALFORMED_REQUEST_PARAMS,
        id: pending.id,
      );
    }

    final previous = _selectionSnapshot();
    final feePayer = map?['pubkey']?.toString() ??
        map?['feePayer']?.toString() ??
        map?['publicKey']?.toString();
    if (!await _ensureAuthorizedSigner(
      topic: topic,
      caip2: pending.chainId,
      address: feePayer,
      previous: previous,
      addressOptional: true,
    )) {
      return _respondError(
        topic,
        Errors.UNAUTHORIZED_METHOD,
        id: pending.id,
      );
    }

    final Uint8List messageBytes;
    try {
      messageBytes = txBase64.length > kWcIsolatePayloadThreshold
          ? await compute(_wcBase64Decode, txBase64)
          : _wcBase64Decode(txBase64);
    } catch (_) {
      await _restoreSelection(previous);
      return _respondError(
        topic,
        Errors.MALFORMED_REQUEST_PARAMS,
        id: pending.id,
      );
    }

    if (!context.mounted) {
      await _restoreSelection(previous);
      return;
    }
    final nativeToken = _nativeTokenFor(kSolanaAddressType);
    final provider = await _ensureChain(context, pending.chainId);
    if (provider == null || nativeToken == null) {
      await _restoreSelection(previous);
      return _respondError(topic, Errors.USER_REJECTED, id: pending.id);
    }

    final peer = _peerOf(topic);
    final tx = TransactionRequestInfo(
      metadata: TransactionMetadataInfo(
        chainHash: provider.chainHash,
        hash: null,
        info: null,
        icon: peer.icon,
        title: peer.name,
        signer: appState.account?.addr,
        tokenInfo: BaseTokenInfo(
          value: '0',
          symbol: nativeToken.symbol,
          decimals: nativeToken.decimals,
        ),
        broadcast: broadcast,
      ),
      scilla: null,
      evm: null,
      solana: messageBytes,
    );

    if (!context.mounted) {
      await _restoreSelection(previous);
      return;
    }
    final responder = _RequestResponder(
      service: this,
      topic: topic,
      id: pending.id,
      context: context,
      previous: previous,
    );
    showConfirmTransactionModal(
      context: context,
      tx: tx,
      to: '',
      token: nativeToken,
      amount: '0',
      onConfirm: (signed) async {
        if (broadcast) {
          await responder.ok({'signature': signed.transactionHash});
        } else {
          final signedSolana = signed.solana;
          if (signedSolana == null) {
            await responder.failMalformed();
          } else {
            final signature = signedSolana.signature;
            final message = signedSolana.message;
            final wire = Uint8List(1 + signature.length + message.length)
              ..[0] = 0x01
              ..setAll(1, signature)
              ..setAll(1 + signature.length, message);
            await responder.ok({
              'signature': signed.transactionHash, // base58, what wallet-adapter reads
              'transaction': base64Encode(wire), // full signed tx for dapps that use it
            });
          }
        }
      },
      onDismiss: () => unawaited(responder.rejected()),
    );
  }

  // ─────────────────────────── Tron handlers ───────────────────────────

  Future<void> _tronSignTransaction(String topic, Object? params) async {
    final pending = _pendingRequest(topic);
    final context = _context;
    if (pending == null || context == null || !context.mounted) return;

    final map = params is Map ? Map<String, Object?>.from(params) : null;
    final transaction = _extractTronTransaction(map);
    if (transaction == null) {
      return _respondError(
        topic,
        Errors.MALFORMED_REQUEST_PARAMS,
        id: pending.id,
      );
    }

    final previous = _selectionSnapshot();
    final address = map?['address']?.toString();
    if (!await _ensureAuthorizedSigner(
      topic: topic,
      caip2: pending.chainId,
      address: address,
      previous: previous,
      addressOptional: true,
    )) {
      return _respondError(
        topic,
        Errors.UNAUTHORIZED_METHOD,
        id: pending.id,
      );
    }

    if (!context.mounted) {
      await _restoreSelection(previous);
      return;
    }
    final provider = await _ensureChain(context, pending.chainId);
    final nativeToken = _nativeTokenFor(kTronAddressType);
    if (provider == null || nativeToken == null) {
      await _restoreSelection(previous);
      return _respondError(topic, Errors.USER_REJECTED, id: pending.id);
    }

    final peer = _peerOf(topic);
    final tx = buildTronTransactionRequest(
      transaction: transaction,
      nativeToken: nativeToken,
      chainHash: provider.chainHash,
      signerAddr: appState.account?.addr,
      title: peer.name,
      icon: peer.icon,
      broadcast: false,
    );

    if (!context.mounted) {
      await _restoreSelection(previous);
      return;
    }
    final responder = _RequestResponder(
      service: this,
      topic: topic,
      id: pending.id,
      context: context,
      previous: previous,
    );
    showConfirmTransactionModal(
      context: context,
      tx: tx,
      to: tronTransferTo(transaction),
      token: nativeToken,
      amount: fromWei(
        value: tronTransferAmount(transaction),
        decimals: nativeToken.decimals,
      ).toString(),
      onConfirm: (signed) async {
        final signedTron = signed.tron;
        if (signedTron == null) {
          await responder.failMalformed();
          return;
        }
        // Typed signed payload → TronWeb JSON string for the WC response.
        final jsonStr = tronTransactionToJson(tx: signedTron);
        // Must use top-level [compute]; a nested Isolate.run closure
        // captures WalletConnectService (Completer, AppState listeners).
        final decoded = jsonStr.length > kWcIsolatePayloadThreshold
            ? await compute(_wcDecodeJsonMap, jsonStr)
            : _wcDecodeJsonMap(jsonStr);
        await responder.ok(decoded);
      },
      onDismiss: () => unawaited(responder.rejected()),
    );
  }

  Future<void> _tronSignMessage(String topic, Object? params) async {
    final pending = _pendingRequest(topic);
    final context = _context;
    if (pending == null || context == null || !context.mounted) return;

    final map = params is Map ? Map<String, Object?>.from(params) : null;
    final message = map?['message']?.toString();
    if (message == null || message.isEmpty) {
      return _respondError(
        topic,
        Errors.MALFORMED_REQUEST_PARAMS,
        id: pending.id,
      );
    }

    final previous = _selectionSnapshot();
    final address = map?['address']?.toString();
    if (!await _ensureAuthorizedSigner(
      topic: topic,
      caip2: pending.chainId,
      address: address,
      previous: previous,
      addressOptional: true,
    )) {
      return _respondError(
        topic,
        Errors.UNAUTHORIZED_METHOD,
        id: pending.id,
      );
    }

    if (!context.mounted) {
      await _restoreSelection(previous);
      return;
    }
    final peer = _peerOf(topic);
    final responder = _RequestResponder(
      service: this,
      topic: topic,
      id: pending.id,
      context: context,
      previous: previous,
    );
    showSignMessageModal(
      context: context,
      message: message,
      appTitle: peer.name,
      appIcon: peer.icon,
      onMessageSigned: (pubkey, sig) => responder.ok({'signature': sig}),
      onDismiss: () => unawaited(responder.rejected()),
    );
  }

  Map<String, Object?>? _extractTronTransaction(Map<String, Object?>? map) {
    if (map == null) return null;
    final raw = map['transaction'];
    if (raw is! Map) return null;
    final nested = raw['transaction'];
    if (nested is Map) {
      return Map<String, Object?>.from(nested);
    }
    return Map<String, Object?>.from(raw);
  }

  // ──────────────────── bip122 (Bitcoin) handlers ────────────────────

  /// bip122 addresses payload per spec: first external address of the active
  /// purpose, every UTXO-bearing address, plus ≤2 unused receive and ≤2 unused
  /// change addresses (gap-limit rule: never >20 unused).
  ///
  /// [caip2] selects the BTC provider/chainHash — never the active UI chain —
  /// so a testnet session stays correct while mainnet is selected (and vice versa).
  /// **v1:** `intentions` filter is ignored (superset returned — spec-tolerable).
  Future<List<Map<String, String>>?> _btcAccountAddressesPayload(
    String caip2,
  ) async {
    final walletIndex = appState.selectedWalletIndexOrNull;
    final wallet = appState.wallet;
    final provider = _providerForCaip2(caip2);
    if (walletIndex == null || wallet == null || provider == null) return null;

    final Map<int, AddressChainInfo> chains;
    try {
      chains = await getBtcAddresses(
        walletIndex: walletIndex,
        accountIndex: wallet.selectedAccount,
        chainHash: provider.chainHash,
      );
    } catch (e) {
      debugPrint('WC getBtcAddresses failed: $e');
      return null;
    }

    final activeType = kBtcAddrTypeByBip[wallet.bip.toInt()];
    if (activeType == null) return null;
    final active = chains[activeType];
    if (active == null) return null;

    final result = <Map<String, String>>[];
    final seen = <String>{};
    void add(BtcAddressEntryInfo entry) {
      if (seen.add(entry.address)) {
        result.add({'address': entry.address, 'path': entry.path});
      }
    }

    if (active.external_.isNotEmpty) add(active.external_.first);
    for (final chainInfo in chains.values) {
      for (final entry in chainInfo.external_) {
        if (entry.utxos.isNotEmpty) add(entry);
      }
      for (final entry in chainInfo.internal) {
        if (entry.utxos.isNotEmpty) add(entry);
      }
    }
    for (final list in [active.external_, active.internal]) {
      var unused = 0;
      for (final entry in list) {
        if (entry.history.isEmpty && entry.utxos.isEmpty) {
          add(entry);
          if (++unused >= 2) break;
        }
      }
    }
    return List<Map<String, String>>.from(result, growable: false);
  }

  Future<void> _btcGetAccountAddresses(String topic, Object? params) async {
    final pending = _pendingRequest(topic);
    if (pending == null) return;

    final map = params is Map ? Map<String, Object?>.from(params) : null;
    final previous = _selectionSnapshot();
    // Read-only: authorize the connected account, never pop a network switch.
    if (!await _ensureAuthorizedSigner(
      topic: topic,
      caip2: pending.chainId,
      address: _bareParam(map, 'account'),
      previous: previous,
      addressOptional: true,
    )) {
      return _respondError(topic, Errors.UNAUTHORIZED_METHOD, id: pending.id);
    }

    final payload = await _btcAccountAddressesPayload(pending.chainId);
    if (payload == null) {
      await _restoreSelection(previous);
      return _respondError(topic, Errors.USER_REJECTED, id: pending.id);
    }
    await _respond(topic, pending.id, payload);
    await _restoreSelection(previous); // read-only: never keep a silent switch
  }

  Future<void> _btcSendTransfer(String topic, Object? params) async {
    final pending = _pendingRequest(topic);
    final context = _context;
    if (pending == null || context == null || !context.mounted) return;

    final map = params is Map ? Map<String, Object?>.from(params) : null;
    final recipient = map?['recipientAddress']?.toString();
    final amount = map?['amount']?.toString();
    if (map == null ||
        recipient == null ||
        recipient.isEmpty ||
        amount == null ||
        BigInt.tryParse(amount) == null) {
      return _respondError(
        topic,
        Errors.MALFORMED_REQUEST_PARAMS,
        id: pending.id,
      );
    }
    if (map['memo'] != null) {
      // OP_RETURN not supported in v1 — explicit error, never a silent drop.
      return _respondError(
        topic,
        Errors.UNSUPPORTED_METHODS,
        id: pending.id,
      );
    }

    final previous = _selectionSnapshot();
    if (!await _ensureAuthorizedSigner(
      topic: topic,
      caip2: pending.chainId,
      address: _bareParam(map, 'account'),
      previous: previous,
    )) {
      return _respondError(topic, Errors.UNAUTHORIZED_METHOD, id: pending.id);
    }

    if (!context.mounted) {
      await _restoreSelection(previous);
      return;
    }
    final provider = await _ensureChain(context, pending.chainId);
    final nativeToken = _nativeTokenFor(kBtcAddressType);
    final walletIndex = appState.selectedWalletIndexOrNull;
    final accountIndex = appState.wallet?.selectedAccount;
    if (provider == null ||
        nativeToken == null ||
        walletIndex == null ||
        accountIndex == null) {
      await _restoreSelection(previous);
      return _respondError(topic, Errors.USER_REJECTED, id: pending.id);
    }

    final peer = _peerOf(topic);
    final TransactionRequestInfo tx;
    try {
      tx = await createTokenTransfer(
        params: TokenTransferParamsInfo(
          walletIndex: walletIndex,
          accountIndex: accountIndex,
          token: nativeToken,
          amount: amount,
          recipient: recipient,
          icon: peer.icon,
        ),
      );
    } catch (e) {
      debugPrint('WC btc sendTransfer build failed: $e');
      await _restoreSelection(previous);
      return _respondError(
        topic,
        Errors.MALFORMED_REQUEST_PARAMS,
        id: pending.id,
      );
    }

    if (!context.mounted) {
      await _restoreSelection(previous);
      return;
    }
    final responder = _RequestResponder(
      service: this,
      topic: topic,
      id: pending.id,
      context: context,
      previous: previous,
    );
    showConfirmTransactionModal(
      context: context,
      tx: tx,
      to: recipient,
      token: nativeToken,
      amount: fromWei(value: amount, decimals: nativeToken.decimals).toString(),
      onConfirm: (signed) async {
        await responder.ok({'txid': signed.transactionHash});
        // Cached chain state; post-sync re-emit is future work.
        unawaited(_emitBtcAddressesChanged());
      },
      onDismiss: () => unawaited(responder.rejected()),
    );
  }

  Future<void> _btcSignPsbt(String topic, Object? params) async {
    final pending = _pendingRequest(topic);
    final context = _context;
    if (pending == null || context == null || !context.mounted) return;

    final map = params is Map ? Map<String, Object?>.from(params) : null;
    final psbtBase64 = map?['psbt']?.toString();
    final rawInputs = map?['signInputs'];
    if (psbtBase64 == null || psbtBase64.isEmpty || rawInputs is! List) {
      return _respondError(
        topic,
        Errors.MALFORMED_REQUEST_PARAMS,
        id: pending.id,
      );
    }
    final broadcast = map?['broadcast'] == true;

    final previous = _selectionSnapshot();
    if (!await _ensureAuthorizedSigner(
      topic: topic,
      caip2: pending.chainId,
      address: _bareParam(map, 'account'),
      previous: previous,
    )) {
      return _respondError(topic, Errors.UNAUTHORIZED_METHOD, id: pending.id);
    }

    if (!context.mounted) {
      await _restoreSelection(previous);
      return;
    }
    final provider = await _ensureChain(context, pending.chainId);
    final nativeToken = _nativeTokenFor(kBtcAddressType);
    final walletIndex = appState.selectedWalletIndexOrNull;
    final accountIndex = appState.wallet?.selectedAccount;
    if (provider == null ||
        nativeToken == null ||
        walletIndex == null ||
        accountIndex == null) {
      await _restoreSelection(previous);
      return _respondError(topic, Errors.USER_REJECTED, id: pending.id);
    }

    final peer = _peerOf(topic);
    final TransactionRequestInfo tx;
    try {
      final signInputs = _parseWcSignInputs(rawInputs);
      tx = await btcPsbtToRequest(
        walletIndex: walletIndex,
        accountIndex: accountIndex,
        psbtBase64: psbtBase64,
        signInputs: signInputs,
        broadcast: broadcast,
        title: peer.name,
        icon: peer.icon,
      );
    } catch (e) {
      debugPrint('WC btc signPsbt build failed: $e');
      await _restoreSelection(previous);
      return _respondError(
        topic,
        Errors.MALFORMED_REQUEST_PARAMS,
        id: pending.id,
      );
    }

    final btcPayload = tx.btc;
    final tokenInfo = tx.metadata.tokenInfo;
    if (btcPayload == null || tokenInfo == null || !context.mounted) {
      await _restoreSelection(previous);
      return _respondError(
        topic,
        Errors.MALFORMED_REQUEST_PARAMS,
        id: pending.id,
      );
    }
    final responder = _RequestResponder(
      service: this,
      topic: topic,
      id: pending.id,
      context: context,
      previous: previous,
    );
    final firstOut = btcPayload.$1.output.isNotEmpty
        ? btcPayload.$1.output.first
        : null;
    showConfirmTransactionModal(
      context: context,
      tx: tx,
      to: firstOut?.address ?? '',
      token: nativeToken,
      amount: fromWei(
        value: tokenInfo.value,
        decimals: nativeToken.decimals,
      ).toString(),
      onConfirm: (signed) async {
        final signedBtc = signed.btc;
        if (signedBtc == null) {
          await responder.failMalformed();
          return;
        }
        try {
          final psbt = btcFinalizedPsbtFromSigned(
            tx: signedBtc,
            witnessUtxos: btcPayload.$2.witnessUtxos,
          );
          await responder.ok({
            'psbt': psbt,
            if (broadcast) 'txid': signed.transactionHash,
          });
          // Cached chain state; post-sync re-emit is future work.
          if (broadcast) unawaited(_emitBtcAddressesChanged());
        } catch (e) {
          debugPrint('WC btc finalize PSBT failed: $e');
          await responder.failMalformed();
        }
      },
      onDismiss: () => unawaited(responder.rejected()),
    );
  }

  /// bip122 `signMessage` — BIP-137 ecdsa only; `protocol: "bip322"` is unsupported (v1).
  Future<void> _btcSignMessage(String topic, Object? params) async {
    final pending = _pendingRequest(topic);
    final context = _context;
    if (pending == null || context == null || !context.mounted) return;

    final map = params is Map ? Map<String, Object?>.from(params) : null;
    final message = map?['message']?.toString();
    if (message == null || message.isEmpty) {
      return _respondError(
        topic,
        Errors.MALFORMED_REQUEST_PARAMS,
        id: pending.id,
      );
    }
    final protocol = map?['protocol']?.toString();
    if (protocol != null && protocol != 'ecdsa') {
      return _respondError(
        topic,
        Errors.UNSUPPORTED_METHODS,
        id: pending.id,
      );
    }

    final previous = _selectionSnapshot();
    // Authorize the connected *account*; sub-address ownership is checked in Rust.
    final accountParam = _bareParam(map, 'account');
    final signAddress = _bareParam(map, 'address') ?? accountParam;
    if (!await _ensureAuthorizedSigner(
      topic: topic,
      caip2: pending.chainId,
      address: accountParam,
      previous: previous,
      addressOptional: true,
    )) {
      return _respondError(topic, Errors.UNAUTHORIZED_METHOD, id: pending.id);
    }

    if (!context.mounted) {
      await _restoreSelection(previous);
      return;
    }
    final peer = _peerOf(topic);
    final responder = _RequestResponder(
      service: this,
      topic: topic,
      id: pending.id,
      context: context,
      previous: previous,
    );
    showSignMessageModal(
      context: context,
      message: message,
      appTitle: peer.name,
      appIcon: peer.icon,
      btcSignAddress: signAddress,
      onMessageSigned: (address, sig) =>
          responder.ok({'address': address, 'signature': sig}),
      onBtcMessageSigned: (signed) => responder.ok({
        'address': signed.address,
        'signature': signed.signatureBase64,
        'messageHash': signed.messageHashHex,
      }),
      onDismiss: () => unawaited(responder.rejected()),
    );
  }

  /// Spec: emit after approval and whenever a UTXO is spent/created.
  ///
  /// Independent of the active UI chain — each bip122 session chain gets its
  /// own address payload (mainnet session while testnet is selected still works).
  Future<void> _emitBtcAddressesChanged() async {
    final kit = _walletKit;
    if (kit == null) return;

    final payloadCache = <String, List<Map<String, String>>?>{};
    Future<List<Map<String, String>>?> payloadFor(String caip2) async {
      if (payloadCache.containsKey(caip2)) return payloadCache[caip2];
      final payload = await _btcAccountAddressesPayload(caip2);
      payloadCache[caip2] = payload;
      return payload;
    }

    for (final session in kit.sessions.getAll()) {
      final ns = session.namespaces['bip122'];
      if (ns == null || !ns.events.contains(kWcBtcAddressesChangedEvent)) {
        continue;
      }
      for (final caip2 in _namespaceChains(ns)) {
        final payload = await payloadFor(caip2);
        if (payload == null) continue;
        unawaited(
          _emitSessionEvent(
            kit,
            topic: session.topic,
            caip2: caip2,
            event: kWcBtcAddressesChangedEvent,
            data: payload,
          ),
        );
      }
    }
  }

  List<WcSignInputInfo> _parseWcSignInputs(List<Object?> raw) {
    return List<WcSignInputInfo>.generate(raw.length, (i) {
      final item = raw[i];
      if (item is! Map) {
        throw const FormatException('signInputs entry must be an object');
      }
      final map = Map<String, Object?>.from(item);
      final address = map['address']?.toString();
      final indexRaw = map['index'];
      final index = indexRaw is int
          ? indexRaw
          : int.tryParse(indexRaw?.toString() ?? '');
      if (address == null || address.isEmpty || index == null) {
        throw const FormatException('signInputs requires address and index');
      }
      final sighashRaw = map['sighashTypes'];
      Uint32List? sighashTypes;
      if (sighashRaw is List) {
        final values = List<int>.generate(sighashRaw.length, (j) {
          final v = sighashRaw[j];
          if (v is int) return v;
          final parsed = int.tryParse(v?.toString() ?? '');
          if (parsed == null) {
            throw const FormatException('invalid sighashTypes entry');
          }
          return parsed;
        });
        sighashTypes = Uint32List.fromList(values);
      }
      return WcSignInputInfo(
        address: address,
        index: index,
        sighashTypes: sighashTypes,
      );
    }, growable: false);
  }

  // ──────────────── session proposal & lifecycle events ────────────────

  void _onSessionProposal(SessionProposalEvent? event) {
    if (event == null) return;
    final kit = _walletKit;
    final context = _context;
    final generated =
        event.params.generatedNamespaces ?? <String, Namespace>{};
    if (kit == null || context == null || !context.mounted) {
      unawaited(_rejectProposal(event.id));
      return;
    }
    final metadata = event.params.proposer.metadata;
    final icons = metadata.icons;
    final l10n = AppLocalizations.of(context);
    final pairErrorMsg =
        l10n?.wcPairFailed ?? 'WalletConnect pairing failed';
    final approveErrorMsg =
        l10n?.wcApproveFailed ?? 'WalletConnect session approval failed';
    showAppConnectModal(
      context: context,
      title: metadata.name,
      uuid: event.id.toString(),
      iconUrl: icons.isNotEmpty ? icons.first : '',
      onConfirm: (selectedIndices) async {
        try {
          final allowed = _allowedAddressesFromSelection(selectedIndices);
          if (allowed.isEmpty) {
            await _rejectProposal(
              event.id,
              reasonKey: Errors.USER_REJECTED,
            );
            _notifyUserError(pairErrorMsg);
            return;
          }
          // SDK leaves generated empty when no registered accounts match the
          // proposal (e.g. dApp eip155-only + wallet BTC-only). Rebuild from
          // proposal + our registered handlers so optional namespaces that we
          // *can* support still settle.
          final namespacesToFilter = generated.isNotEmpty
              ? generated
              : _namespacesFromProposal(
                  required: event.params.requiredNamespaces,
                  optional: event.params.optionalNamespaces,
                  allowedAddrs: allowed,
                );
          final filtered = _filterNamespaces(namespacesToFilter, allowed);
          if (filtered.isEmpty) {
            final dappNs = <String>{
              ...event.params.requiredNamespaces.keys,
              ...event.params.optionalNamespaces.keys,
            };
            final walletNs = <String>[
              for (final ns in kWcAddrTypeByNamespace.keys)
                if (_addressesForNamespace(ns).isNotEmpty) ns,
            ];
            final reason =
                'No shared chains: dApp asked $dappNs, wallet has $walletNs. '
                'For Bitcoin open the bip122 / Bitcoin network on the dApp '
                '(this QR is often Ethereum-only AppKit).';
            await _rejectProposal(
              event.id,
              reasonKey: Errors.UNSUPPORTED_ACCOUNTS,
            );
            _notifyUserError(reason);
            return;
          }

          // Pre-check required namespaces before SDK call.
          if (!_requiredNamespacesSatisfied(
            event.params.requiredNamespaces,
            filtered,
          )) {
            await _rejectProposal(
              event.id,
              reasonKey: Errors.UNSUPPORTED_ACCOUNTS,
            );
            _notifyUserError(pairErrorMsg);
            return;
          }

          final hasTron = filtered.containsKey('tron');
          final bip122Ns = filtered['bip122'];
          final btcCaip2 = _firstBip122Caip2(bip122Ns);
          final btcAddresses = btcCaip2 == null
              ? null
              : await _btcAccountAddressesPayload(btcCaip2);
          final sessionProperties = <String, String>{
            if (hasTron) ...kWcTronSessionProperties,
            if (btcAddresses != null)
              kWcBtcAddressesProperty: jsonEncode(btcAddresses),
          };
          final response = await kit.approveSession(
            id: event.id,
            namespaces: filtered,
            sessionProperties:
                sessionProperties.isEmpty ? null : sessionProperties,
          );
          _refreshSessionViews();
          notifyListeners();
          final topic = response.session?.topic ?? response.topic;
          if (topic.isNotEmpty) {
            await _redirectToDapp(topic);
          }
          if (btcCaip2 != null && btcAddresses != null) {
            unawaited(_emitBtcAddressesChanged());
          }
        } catch (e) {
          debugPrint('WC approve failed: $e');
          await _rejectProposal(event.id);
          _notifyUserError(approveErrorMsg);
        }
      },
      onReject: () => unawaited(_rejectProposal(event.id)),
    );
  }

  /// Build approve namespaces when SDK `generatedNamespaces` is empty.
  ///
  /// Intersects proposal chains/methods/events with wallet-registered handlers
  /// and [allowedAddrs] of the matching address family. Keys may be bare
  /// namespaces (`eip155`) or CAIP-2 (`eip155:1`).
  Map<String, Namespace> _namespacesFromProposal({
    required Map<String, RequiredNamespace> required,
    required Map<String, RequiredNamespace> optional,
    required Set<String> allowedAddrs,
  }) {
    final merged = <String, RequiredNamespace>{
      ...optional,
      ...required, // required wins on key clash
    };
    final result = <String, Namespace>{};

    for (final entry in merged.entries) {
      final key = entry.key;
      final req = entry.value;
      final namespace = key.contains(':') ? key.split(':').first : key;
      final addrType = kWcAddrTypeByNamespace[namespace];
      if (addrType == null) continue;

      final walletAddrs = _addressesForNamespace(namespace);
      final matching = <String>[
        for (final a in walletAddrs)
          if (allowedAddrs.any((allowed) => _addressesEqual(allowed, a))) a,
      ];
      if (matching.isEmpty) continue;

      // Chains: explicit list, or single CAIP-2 key, or all registered providers.
      final chainSet = <String>{};
      final listed = req.chains;
      if (listed != null && listed.isNotEmpty) {
        chainSet.addAll(listed);
      } else if (key.contains(':')) {
        chainSet.add(key);
      } else {
        for (final p in appState.state.providers) {
          final caip2 = caip2ForProvider(p);
          if (caip2 != null && caip2.startsWith('$namespace:')) {
            chainSet.add(caip2);
          }
        }
      }
      if (chainSet.isEmpty) continue;

      // Methods: only those we registered handlers for.
      final handlers = _handlersFor(namespace).keys.toSet();
      final methods = <String>[
        for (final m in req.methods)
          if (handlers.contains(m)) m,
      ];
      // Events we emit for this namespace, intersected with dApp request.
      final ourEvents = kWcEventsByNamespace[namespace] ?? const <String>[];
      final events = <String>[
        for (final e in req.events)
          if (ourEvents.contains(e)) e,
      ];

      final accounts = <String>[
        for (final chain in chainSet)
          for (final addr in matching) '$chain:$addr',
      ];
      if (accounts.isEmpty) continue;

      // Merge if same namespace key already present (e.g. eip155 + eip155:1).
      final nsKey = namespace;
      final existing = result[nsKey];
      if (existing != null) {
        final acc = <String>{...existing.accounts, ...accounts};
        final meth = <String>{...existing.methods, ...methods};
        final ev = <String>{...existing.events, ...events};
        final ch = <String>{
          ...?existing.chains,
          ...chainSet,
        };
        result[nsKey] = Namespace(
          chains: List<String>.from(ch, growable: false),
          accounts: List<String>.from(acc, growable: false),
          methods: List<String>.from(meth, growable: false),
          events: List<String>.from(ev, growable: false),
        );
      } else {
        result[nsKey] = Namespace(
          chains: List<String>.from(chainSet, growable: false),
          accounts: List<String>.from(accounts, growable: false),
          methods: List<String>.from(methods, growable: false),
          events: List<String>.from(events, growable: false),
        );
      }
    }
    return result;
  }

  /// Every key in [required] must have non-empty accounts in [filtered].
  bool _requiredNamespacesSatisfied(
    Map<String, RequiredNamespace> required,
    Map<String, Namespace> filtered,
  ) {
    for (final key in required.keys) {
      final ns = filtered[key];
      if (ns == null || ns.accounts.isEmpty) return false;
    }
    return true;
  }

  Set<String> _allowedAddressesFromSelection(List<int> selectedIndices) {
    final accounts = appState.accounts;
    final allowed = <String>{};
    for (final i in selectedIndices) {
      if (i < 0 || i >= accounts.length) continue;
      allowed.add(accounts[i].addr);
    }
    return allowed;
  }

  Map<String, Namespace> _filterNamespaces(
    Map<String, Namespace> generated,
    Set<String> allowedAddrs,
  ) {
    final result = <String, Namespace>{};
    for (final entry in generated.entries) {
      final accounts = <String>[];
      for (final caip10 in entry.value.accounts) {
        final bare = _bareWcAddress(caip10);
        var ok = false;
        for (final allowed in allowedAddrs) {
          if (_addressesEqual(allowed, bare)) {
            ok = true;
            break;
          }
        }
        if (ok) accounts.add(caip10);
      }
      if (accounts.isEmpty) continue;
      result[entry.key] = Namespace(
        chains: entry.value.chains,
        accounts: List<String>.from(accounts, growable: false),
        methods: entry.value.methods,
        events: entry.value.events,
      );
    }
    return result;
  }

  Future<void> _rejectProposal(
    int id, {
    String reasonKey = Errors.USER_REJECTED,
  }) async {
    try {
      await _walletKit?.rejectSession(
        id: id,
        reason: Errors.getSdkError(reasonKey).toSignError(),
      );
    } catch (e) {
      debugPrint('WC reject failed: $e');
    }
  }

  void _onSessionDelete(SessionDelete? event) {
    _refreshSessionViews();
    notifyListeners();
  }

  void _onSessionExpire(SessionExpire? event) {
    _refreshSessionViews();
    notifyListeners();
  }

  void _onAppStateChanged() {
    final kit = _walletKit;
    if (kit == null) return;

    _syncRegistrations();

    if (_suppressAppStateEvents > 0) {
      // Keep trackers current without broadcasting.
      _lastAddress = appState.account?.addr;
      _lastChainId = appState.chain?.chainId;
      return;
    }

    final account = appState.account;
    final chain = appState.chain;

    if (account != null && account.addr != _lastAddress) {
      _lastAddress = account.addr;
      if (account.addrType == kBtcAddressType) {
        unawaited(_emitBtcAddressesChanged());
      } else {
        final namespace = _namespaceForAddrType(account.addrType);
        if (namespace != null) {
          _emitToNamespaceSessions(
            kit,
            namespace,
            kAccountsChangedEvent,
            (session) => _sessionHasBareAddress(session, namespace, account.addr)
                ? <String>[account.addr]
                : null,
          );
        }
      }
    }
    if (chain != null && chain.chainId != _lastChainId) {
      _lastChainId = chain.chainId;
      // Every eip155 session gets chainChanged on *its* approved chains.
      _emitToNamespaceSessions(
        kit,
        'eip155',
        kChainChangedEvent,
        (_) => chain.chainId.toInt(),
      );
    }
  }

  /// Emit [event] to every session that approved it, once per approved
  /// [namespace] chain of that session — independent of the active UI chain.
  void _emitToNamespaceSessions(
    ReownWalletKit kit,
    String namespace,
    String event,
    Object? Function(SessionData session) dataFor,
  ) {
    for (final session in kit.sessions.getAll()) {
      final ns = session.namespaces[namespace];
      if (ns == null || !ns.events.contains(event)) continue;
      final data = dataFor(session);
      if (data == null) continue;
      for (final caip2 in _namespaceChains(ns)) {
        unawaited(
          _emitSessionEvent(
            kit,
            topic: session.topic,
            caip2: caip2,
            event: event,
            data: data,
          ),
        );
      }
    }
  }

  Future<void> _emitSessionEvent(
    ReownWalletKit kit, {
    required String topic,
    required String caip2,
    required String event,
    required Object data,
  }) async {
    try {
      await kit.emitSessionEvent(
        topic: topic,
        chainId: caip2,
        event: SessionEventParams(name: event, data: data),
      );
    } catch (e) {
      debugPrint('WC emit $event/$caip2 failed: $e');
    }
  }

  void _refreshSessionViews() {
    final all = sessions;
    _cachedSessionViews = List<WcSessionView>.generate(
      all.length,
      (i) => WcSessionView.fromSession(all[i]),
      growable: false,
    );
  }
}

/// WalletConnect session row for the connected-dapps modal.
@immutable
class WcSessionView {
  final String topic;
  final String name;
  final String url;
  final String icon;

  const WcSessionView({
    required this.topic,
    required this.name,
    required this.url,
    required this.icon,
  });

  factory WcSessionView.fromSession(SessionData session) {
    final metadata = session.peer.metadata;
    final icons = metadata.icons;
    return WcSessionView(
      topic: session.topic,
      name: metadata.name,
      url: metadata.url,
      icon: icons.isNotEmpty ? icons.first : '',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WcSessionView &&
          runtimeType == other.runtimeType &&
          topic == other.topic &&
          name == other.name &&
          url == other.url &&
          icon == other.icon;

  @override
  int get hashCode => Object.hash(topic, name, url, icon);

  @override
  String toString() =>
      'WcSessionView(topic: $topic, name: $name, url: $url, icon: $icon)';
}

/// No-op WalletConnect Pay channel for platforms without the native plugin.
class _NoopWalletconnectPayPlatform extends WalletconnectPayPlatform {
  @override
  Future<bool> initialize({
    String? apiKey,
    String? appId,
    String? clientId,
    String? baseUrl,
  }) async =>
      false;

  @override
  Future<String> confirmPayment({required String requestJson}) async {
    throw UnsupportedError('WalletConnect Pay is not available on this platform');
  }

  @override
  Future<String> getPaymentOptions({required String requestJson}) async {
    throw UnsupportedError('WalletConnect Pay is not available on this platform');
  }

  @override
  Future<String> getRequiredPaymentActions({
    required String requestJson,
  }) async {
    throw UnsupportedError('WalletConnect Pay is not available on this platform');
  }
}

// ── Isolate entry points (top-level only — must not close over service) ──

TypedDataEip712 _wcParseTypedData(String raw) =>
    TypedDataEip712.fromJsonString(raw);

Uint8List _wcBase64Decode(String raw) => base64Decode(raw);

Map<String, Object?> _wcDecodeJsonMap(String raw) {
  final parsed = jsonDecode(raw);
  if (parsed is Map) {
    return Map<String, Object?>.from(parsed);
  }
  return <String, Object?>{};
}

/// Bitcoin-style Base58 decode for Solana WC message payloads.
List<int> _base58Decode(String input) {
  const alphabet = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';
  if (input.isEmpty) return const <int>[];

  final map = List<int>.filled(128, -1);
  for (var i = 0; i < alphabet.length; i++) {
    map[alphabet.codeUnitAt(i)] = i;
  }

  var zeros = 0;
  while (zeros < input.length && input.codeUnitAt(zeros) == 0x31) {
    zeros++;
  }

  final size = ((input.length - zeros) * 733 ~/ 1000) + 1;
  final b256 = List<int>.filled(size, 0);

  for (var i = zeros; i < input.length; i++) {
    final c = input.codeUnitAt(i);
    if (c >= map.length || map[c] == -1) {
      throw FormatException('Invalid base58 character');
    }
    var carry = map[c];
    for (var j = size - 1; j >= 0; j--) {
      carry += 58 * b256[j];
      b256[j] = carry & 0xff;
      carry >>= 8;
    }
    if (carry != 0) {
      throw FormatException('base58 overflow');
    }
  }

  var start = 0;
  while (start < size && b256[start] == 0) {
    start++;
  }

  final result = List<int>.filled(zeros + (size - start), 0);
  for (var i = 0; i < zeros; i++) {
    result[i] = 0;
  }
  var k = zeros;
  for (var i = start; i < size; i++) {
    result[k++] = b256[i];
  }
  return result;
}
