import 'dart:convert';
import 'dart:typed_data';
import 'package:bearby/config/eip1193.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';
import 'package:bearby/config/web3_constants.dart';
import 'package:bearby/l10n/app_localizations.dart';
import 'package:bearby/modals/app_connect.dart';
import 'package:bearby/src/rust/api/wallet.dart';
import 'package:bearby/src/rust/models/connection.dart';
import 'package:bearby/src/rust/models/provider.dart';
import 'package:bearby/state/app_state.dart';
import 'package:bearby/web3/message.dart';
import 'package:bearby/web3/web3_utils.dart';

class TronNodeConfig {
  final String fullNode;
  final String solidityNode;
  final String eventServer;
  final String chainId;
  final String chain;

  const TronNodeConfig({
    required this.fullNode,
    required this.solidityNode,
    required this.eventServer,
    required this.chainId,
    required this.chain,
  });

  factory TronNodeConfig.fromChain(NetworkConfigInfo chain) {
    final rpcUrls = chain.rpc.where((url) => url.isNotEmpty).toList();
    final primaryNode = rpcUrls.isNotEmpty ? rpcUrls.first : '';
    final chainName = chain.name.toLowerCase().replaceAll(' ', '-');

    return TronNodeConfig(
      fullNode: primaryNode,
      solidityNode: primaryNode,
      eventServer: primaryNode,
      chainId: chain.chainId.toString(),
      chain: chainName,
    );
  }

  Map<String, dynamic> toJson() => {
        'fullNode': fullNode,
        'solidityNode': solidityNode,
        'eventServer': eventServer,
        'chainId': chainId,
        'chain': chain,
      };
}

class TronInitProviderData {
  final String address;
  final TronNodeConfig node;
  final String name;
  final int type;
  final bool isAuth;
  final String chainId;
  final List<TronPhishingItem>? phishingList;
  final TronConnectNodeConfig? connectNode;

  const TronInitProviderData({
    required this.address,
    required this.node,
    required this.name,
    required this.type,
    required this.isAuth,
    required this.chainId,
    this.phishingList,
    this.connectNode,
  });

  Map<String, dynamic> toJson() => {
        'address': address,
        'node': node.toJson(),
        'name': name,
        'type': type,
        'isAuth': isAuth,
        'chainId': chainId,
        if (phishingList != null)
          'phishingList': phishingList!.map((p) => p.toJson()).toList(),
        if (connectNode != null) 'connectNode': connectNode!.toJson(),
      };
}

class TronPhishingItem {
  final String url;
  final bool? isVisit;

  const TronPhishingItem({required this.url, this.isVisit});

  Map<String, dynamic> toJson() => {
        'url': url,
        if (isVisit != null) 'isVisit': isVisit,
      };
}

class TronConnectNodeConfig {
  final String fullNode;
  final String solidityNode;
  final String eventServer;

  const TronConnectNodeConfig({
    required this.fullNode,
    required this.solidityNode,
    required this.eventServer,
  });

  factory TronConnectNodeConfig.fromChain(NetworkConfigInfo chain) {
    final rpcUrls = chain.rpc.where((url) => url.isNotEmpty).toList();
    final primaryNode = rpcUrls.isNotEmpty ? rpcUrls.first : '';

    return TronConnectNodeConfig(
      fullNode: primaryNode,
      solidityNode: primaryNode,
      eventServer: primaryNode,
    );
  }

  Map<String, dynamic> toJson() => {
        'fullNode': fullNode,
        'solidityNode': solidityNode,
        'eventServer': eventServer,
      };
}

enum TronWeb3Method {
  getInitProviderData('getInitProviderData');

  final String value;
  const TronWeb3Method(this.value);

  static TronWeb3Method fromValue(String value) {
    return TronWeb3Method.values.firstWhere(
      (m) => m.value == value,
      orElse: () => TronWeb3Method.getInitProviderData,
    );
  }
}

enum TronWeb3ErrorCode {
  userRejected(4001),
  unauthorized(4100),
  unsupportedMethod(4200),
  disconnected(4900),
  internalError(-32603),
  invalidInput(-32000),
  resourceUnavailable(-32002);

  final int code;
  const TronWeb3ErrorCode(this.code);
}

class TronWeb3Handler {
  final InAppWebViewController webViewController;
  final String _currentDomain;
  final AppState appState;
  bool isConnected = false;

  final Set<String> _activeRequests = {};
  String? _lastKnownAddress;
  String? _lastKnownChainId;

  TronWeb3Handler({
    required this.webViewController,
    required String initialUrl,
    required this.appState,
  }) : _currentDomain = Uri.parse(initialUrl).host {
    _lastKnownAddress = appState.account?.addr;
    _lastKnownChainId = appState.chain?.chainId.toString();
    appState.addListener(_handleAppStateChange);
  }

  void dispose() {
    appState.removeListener(_handleAppStateChange);
    webViewController.dispose();
  }

  void _handleAppStateChange() async {
    try {
      await webViewController.getUrl();
    } catch (e) {
      debugPrint("WebView $e");
      return;
    }

    final newAccount = appState.account;
    final newChain = appState.chain;

    if (newAccount != null && newAccount.addr != _lastKnownAddress) {
      _lastKnownAddress = newAccount.addr;
      final addresses = await _getWalletAddresses(appState);
      await _sendNotification(
        eventName: 'accountsChanged',
        data: addresses,
      );
    }

    if (newChain != null && newChain.chainId.toString() != _lastKnownChainId) {
      _lastKnownChainId = newChain.chainId.toString();
      await _sendNotification(
        eventName: 'chainChanged',
        data: {'chainId': newChain.chainId.toString()},
      );
    }
  }

  Future<void> _sendResponse({
    required String type,
    required String uuid,
    Map<String, dynamic>? payload,
    dynamic result,
    TronWeb3ErrorCode? errorCode,
    String? errorMessage,
  }) async {
    final responsePayload = <String, dynamic>{
      if (payload != null) ...payload,
      if (result != null) 'result': result,
      if (errorCode != null && errorMessage != null)
        'error': {'code': errorCode.code, 'message': errorMessage},
    };

    final response = ZilPayWeb3Message(
      type: type,
      uuid: uuid,
      payload: responsePayload,
    ).toJson();

    final jsonResponse = jsonEncode(response);
    final jsCode = '''
    (function() {
      const responseData = $jsonResponse;
      if (window.__zilpay_response_handlers && window.__zilpay_response_handlers["$uuid"]) {
        const handler = window.__zilpay_response_handlers["$uuid"];
        handler(responseData);
        delete window.__zilpay_response_handlers["$uuid"];
      } else {
        window.dispatchEvent(new MessageEvent('message', { 
          data: responseData
        }));
      }
    })();
    ''';

    try {
      await webViewController.evaluateJavascript(source: jsCode);
    } catch (e) {
      debugPrint("evaluateJavascript error: $e");
    }
  }

  void _returnError(
    String uuid,
    TronWeb3ErrorCode errorCode,
    String errorMessage,
  ) {
    _sendResponse(
      type: kBearbyResponseType,
      uuid: uuid,
      errorCode: errorCode,
      errorMessage: errorMessage,
    );
  }

  Future<void> _sendNotification({
    required String eventName,
    required dynamic data,
  }) async {
    final eventData = {
      'event': eventName,
      'data': data,
    };
    final jsonEventData = jsonEncode(eventData);

    final jsCode = '''
    (function() {
      if (typeof window.handleZilPayEvent === 'function') {
        console.log('ZilPay TRON: Calling handleZilPayEvent with:', $jsonEventData);
        window.handleZilPayEvent($jsonEventData);
      } else {
        console.log('ZilPay TRON: window.handleZilPayEvent not found. Event "$eventName" not sent.');
      }
    })();
    ''';
    try {
      await webViewController.evaluateJavascript(source: jsCode);
    } catch (e) {
      debugPrint("TRON notification error: $e");
    }
  }

  Future<void> handleWeb3TronMessage(
    ZilPayWeb3Message message,
    BuildContext context,
  ) async {
    final method = message.payload['method'] as String?;

    if (method == null) {
      final l10n = AppLocalizations.of(context);
      return _returnError(
        message.uuid,
        TronWeb3ErrorCode.unsupportedMethod,
        l10n?.web3ErrorNoMethod ?? '',
      );
    }

    final tronMethod = TronWeb3Method.fromValue(method);

    switch (tronMethod) {
      case TronWeb3Method.getInitProviderData:
        await _handleGetInitProviderData(message, context);
        break;
      default:
        final l10n = AppLocalizations.of(context);
        _returnError(
          message.uuid,
          TronWeb3ErrorCode.unsupportedMethod,
          l10n?.web3ErrorUnsupportedMethod(method) ?? '',
        );
        break;
    }
  }

  Future<void> _handleGetInitProviderData(
    ZilPayWeb3Message message,
    BuildContext context,
  ) async {
    if (_isRequestActive(TronWeb3Method.getInitProviderData.value)) {
      return _returnError(
        message.uuid,
        TronWeb3ErrorCode.resourceUnavailable,
        AppLocalizations.of(context)?.web3ErrorRequestInProgress ?? '',
      );
    }

    _addActiveRequest(TronWeb3Method.getInitProviderData.value);

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      await appState.syncConnections();

      final connection = Web3Utils.findConnected(
        _currentDomain,
        appState.connections,
      );

      final account = appState.account;
      final chain = appState.chain;

      if (account == null || chain == null) {
        _removeActiveRequest(TronWeb3Method.getInitProviderData.value);
        return _returnError(
          message.uuid,
          TronWeb3ErrorCode.unauthorized,
          AppLocalizations.of(context)?.web3ErrorNotConnected ?? '',
        );
      }

      final addresses = await _getWalletAddresses(appState);
      final connectedAddresses = connection != null
          ? Web3Utils.filterByIndexes(addresses, connection.accountIndexes)
          : <String>[];

      final isAuth = connection != null &&
          connectedAddresses
              .any((addr) => addr.toLowerCase() == account.addr.toLowerCase());

      final nodeConfig = TronNodeConfig.fromChain(chain);
      final connectNodeConfig =
          connection != null ? TronConnectNodeConfig.fromChain(chain) : null;

      final responseData = TronInitProviderData(
        address: account.addr,
        node: nodeConfig,
        name: account.name,
        type: 0,
        isAuth: isAuth,
        chainId: chain.chainId.toString(),
        phishingList: null,
        connectNode: connectNodeConfig,
      );

      _sendResponse(
        type: kBearbyResponseType,
        uuid: message.uuid,
        result: responseData.toJson(),
      );
    } catch (e) {
      debugPrint("Error in getInitProviderData: $e");
      _returnError(
        message.uuid,
        TronWeb3ErrorCode.internalError,
        'Error processing getInitProviderData: $e',
      );
    } finally {
      _removeActiveRequest(TronWeb3Method.getInitProviderData.value);
    }
  }

  Future<List<String>> _getWalletAddresses(AppState appState) async {
    List<String> addresses = [];
    final selectedAccountIndex = appState.wallet?.selectedAccount.toInt();

    if (appState.chain?.slip44 == kZilliqaSlip44) {
      addresses = await getZilEthChecksumAddresses(
          walletIndex: BigInt.from(appState.selectedWallet));
    } else {
      addresses = (appState.wallet?.accounts ?? []).map((a) => a.addr).toList();
    }

    if (selectedAccountIndex != null &&
        selectedAccountIndex >= 0 &&
        selectedAccountIndex < addresses.length) {
      isConnected = false;
      return [addresses[selectedAccountIndex]];
    }

    isConnected = true;
    return addresses;
  }

  bool _isRequestActive(String method) {
    return _activeRequests.contains(method);
  }

  void _addActiveRequest(String method) {
    _activeRequests.add(method);
  }

  void _removeActiveRequest(String method) {
    _activeRequests.remove(method);
  }
}
