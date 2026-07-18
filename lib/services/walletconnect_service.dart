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
import 'package:bearby/src/rust/models/transactions/base_token.dart';
import 'package:bearby/src/rust/models/transactions/evm.dart';
import 'package:bearby/src/rust/models/transactions/request.dart';
import 'package:bearby/src/rust/models/transactions/transaction_metadata.dart';
import 'package:bearby/src/rust/models/walletconnect/ffi.dart';
import 'package:bearby/state/app_state.dart';
import 'package:bearby/utils/utils.dart';

/// Methods this wallet can actually fulfill for WalletConnect sessions.
///
/// Approvals **intersect** dApp-requested methods with this list so we never
/// advertise capabilities we auto-reject (see review H3).
const List<String> kWcSupportedEip155Methods = [
  'personal_sign',
  'eth_sign',
  'eth_signTypedData',
  'eth_signTypedData_v3',
  'eth_signTypedData_v4',
  'eth_sendTransaction',
  'eth_signTransaction',
];

const List<String> kWcSupportedEip155Events = [
  'chainChanged',
  'accountsChanged',
];

/// Thin Flutter facade over the Rust WalletConnect engine.
///
/// Signing/tx confirmation stay in Dart (existing modals + FFI); the SDK only
/// transports requests/responses.
class WalletConnectService {
  WalletConnectService._();
  static final WalletConnectService instance = WalletConnectService._();

  StreamSubscription<WcEventInfo>? _sub;
  bool _started = false;
  GlobalKey<NavigatorState>? navigatorKey;

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

    _sub = wcEvents().listen(
      _onEvent,
      onError: (Object e) {
        debugPrint('wc events error: $e');
      },
      onDone: () {
        // Stream closed (e.g. after sink re-attach path); allow restart.
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
    await wcPair(uri: normalized);
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
        _showApprovalModal(field0);
      case WcEventInfo_Request(:final field0):
        _routeRequest(field0);
      case WcEventInfo_SessionDeleted():
      case WcEventInfo_SessionSettled():
      case WcEventInfo_SessionEvent():
      case WcEventInfo_RelayConnected():
      case WcEventInfo_RelayDisconnected():
        break;
      case WcEventInfo_Error(:final message):
        debugPrint('wc error: $message');
    }
  }

  BuildContext? get _ctx => navigatorKey?.currentContext;

  Future<void> _showApprovalModal(WcProposalInfo proposal) async {
    final context = _ctx;
    if (context == null || !context.mounted) {
      await wcRejectSession(proposalId: proposal.id);
      return;
    }

    final appState = Provider.of<AppState>(context, listen: false);
    final icon = proposal.peerIcon ?? '';

    showAppConnectModal(
      context: context,
      title: proposal.peerName,
      uuid: proposal.pairingTopic,
      iconUrl: icon,
      onConfirm: (selectedIndexes) async {
        try {
          final namespaces =
              _buildApprovals(appState, proposal, selectedIndexes);
          if (namespaces.isEmpty) {
            await wcRejectSession(proposalId: proposal.id);
            return;
          }
          await wcApproveSession(
            proposalId: proposal.id,
            namespaces: namespaces,
          );
        } catch (e) {
          debugPrint('wc approve failed: $e');
          await wcRejectSession(proposalId: proposal.id);
        }
      },
      onReject: () async {
        await wcRejectSession(proposalId: proposal.id);
      },
    );
  }

  List<WcNamespaceApproval> _buildApprovals(
    AppState appState,
    WcProposalInfo proposal,
    List<int> selectedIndexes,
  ) {
    final accounts = appState.accounts;
    final selectedAddrs = <String>[];
    for (final i in selectedIndexes) {
      if (i >= 0 && i < accounts.length) {
        selectedAddrs.add(accounts[i].addr);
      }
    }
    if (selectedAddrs.isEmpty && appState.account != null) {
      selectedAddrs.add(appState.account!.addr);
    }

    final out = <WcNamespaceApproval>[];
    final seen = <String>{};

    void addNs(WcNamespaceInfo ns, {required bool required}) {
      if (!seen.add(ns.key)) return;

      // Only attach accounts for namespaces that match the wallet's current chain
      // family — never put an EVM address under solana: (etc.).
      if (!_namespaceMatchesWallet(ns.key, appState)) {
        // Drop optional mismatches; required ones left empty → conforms rejects.
        if (!required) return;
      }

      final chains = ns.chains.isNotEmpty
          ? ns.chains.where((c) => _chainMatchesWallet(c, appState)).toList()
          : _defaultChainsForKey(ns.key, appState);

      if (chains.isEmpty) {
        // Prefer dropping over fabricating fake accounts.
        return;
      }

      final methods = _intersectMethods(ns.key, ns.methods);
      final events = _intersectEvents(ns.key, ns.events);
      if (methods.isEmpty && required) {
        // Cannot honestly approve a required namespace with zero methods.
        return;
      }

      final caip10 = <String>[];
      for (final chain in chains) {
        for (final addr in selectedAddrs) {
          caip10.add('$chain:${_formatAccountAddr(addr, ns.key)}');
        }
      }
      if (caip10.isEmpty) return;

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

  bool _namespaceMatchesWallet(String key, AppState appState) {
    final chain = appState.chain;
    if (chain == null) return false;
    switch (key) {
      case 'eip155':
        return chain.slip44 == kEthereumSlip44 ||
            chain.slip44 == kZilliqaSlip44;
      case 'solana':
        return chain.slip44 == kSolanaSlip44;
      case 'tron':
        return chain.slip44 == kTronSlip44;
      default:
        return false;
    }
  }

  bool _chainMatchesWallet(String caip2, AppState appState) {
    final chain = appState.chain;
    if (chain == null) return false;
    final parts = caip2.split(':');
    if (parts.length < 2) return false;
    final ns = parts[0];
    if (!_namespaceMatchesWallet(ns, appState)) return false;
    // Accept any chain ref under a matching namespace family (multi-chain wallets).
    // Prefer exact match when possible.
    final ref = parts[1];
    return ref == chain.chainId.toString() || ns == 'eip155' || ns == 'solana';
  }

  List<String> _intersectMethods(String nsKey, List<String> requested) {
    final supported = switch (nsKey) {
      'eip155' => kWcSupportedEip155Methods,
      _ => const <String>[],
    };
    return requested.where(supported.contains).toList();
  }

  List<String> _intersectEvents(String nsKey, List<String> requested) {
    final supported = switch (nsKey) {
      'eip155' => kWcSupportedEip155Events,
      _ => const <String>[],
    };
    if (requested.isEmpty) return List<String>.from(supported);
    return requested.where(supported.contains).toList();
  }

  List<String> _defaultChainsForKey(String key, AppState appState) {
    final chain = appState.chain;
    if (chain == null) return <String>[];
    if (!_namespaceMatchesWallet(key, appState)) return <String>[];
    return <String>['$key:${chain.chainId}'];
  }

  String _formatAccountAddr(String addr, String ns) {
    if (ns == 'eip155') return addr;
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
