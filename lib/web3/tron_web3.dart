import 'dart:convert';
import 'package:bearby/config/eip1193.dart';
import 'package:bearby/config/tip1193.dart';
import 'package:bearby/modals/app_connect.dart';
import 'package:bearby/modals/sign_message.dart';
import 'package:bearby/src/rust/api/connections.dart';
import 'package:bearby/src/rust/api/provider.dart';
import 'package:bearby/src/rust/models/connection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:provider/provider.dart';
import 'package:bearby/config/web3_constants.dart';
import 'package:bearby/l10n/app_localizations.dart';
import 'package:bearby/src/rust/api/wallet.dart';
import 'package:bearby/state/app_state.dart';
import 'package:bearby/web3/message.dart';
import 'package:bearby/web3/web3_utils.dart';

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
      if (window.__bearby_response_handlers && window.__bearby_response_handlers["$uuid"]) {
        const handler = window.__bearby_response_handlers["$uuid"];
        handler(responseData);
        delete window.__bearby_response_handlers["$uuid"];
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
      if (typeof window.handleBearbyEvent === 'function') {
        window.handleBearbyEvent($jsonEventData);
      } else {
        console.log('Bearby TRON: window.handleBearbyEvent not found. Event "$eventName" not sent.');
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
    final tronMethod = Web3EIP1193Method.fromValue(method);

    switch (tronMethod) {
      case Web3EIP1193Method.ethChainId:
        await _handleChainId(message, appState);
        break;
      case Web3EIP1193Method.getInitProviderData:
        await _handleGetInitProviderData(message, context);
        break;
      case Web3EIP1193Method.ethRequestAccounts ||
            Web3EIP1193Method.tronRequestAccounts ||
            Web3EIP1193Method.ethAccounts:
        final appState = Provider.of<AppState>(context, listen: false);
        await _handleEthRequestAccounts(message, context, appState);
        break;
      case Web3EIP1193Method.ethSign:
      case Web3EIP1193Method.personalSign:
      case Web3EIP1193Method.tronSignMessageV2:
        await _handleMessageSigning(
          message: message,
          context: context,
          appState: appState,
        );
        break;
      case Web3EIP1193Method.ethGetBalance:
      case Web3EIP1193Method.ethGetTransactionByHash:
      case Web3EIP1193Method.ethGetTransactionReceipt:
      case Web3EIP1193Method.ethCall:
      case Web3EIP1193Method.ethEstimateGas:
      case Web3EIP1193Method.ethBlockNumber:
      case Web3EIP1193Method.ethGetBlockByNumber:
      case Web3EIP1193Method.ethGetBlockByHash:
      case Web3EIP1193Method.netVersion:
      case Web3EIP1193Method.ethGetCode:
      case Web3EIP1193Method.ethGetStorageAt:
      case Web3EIP1193Method.ethGasPrice:
      case Web3EIP1193Method.ethGetTransactionCount:
        final appState = Provider.of<AppState>(context, listen: false);
        final chain = appState.chain;
        final evmMethod = Web3EIP1193Method.fromValue(method);
        await _proxyRpcRequest(
          method: evmMethod.value,
          uuid: message.uuid,
          params: message.payload['params'],
          chainHash: chain?.chainHash ?? BigInt.zero,
        );
        break;
      default:
        final l10n = AppLocalizations.of(context);
        return _returnError(
          message.uuid,
          TronWeb3ErrorCode.unsupportedMethod,
          l10n?.web3ErrorNoMethod ?? '',
        );
    }
  }

  Future<void> _handleMessageSigning({
    required ZilPayWeb3Message message,
    required BuildContext context,
    required AppState appState,
  }) async {
    final method = message.payload['method'] as String;

    if (_isRequestActive(method)) {
      return _returnError(
        message.uuid,
        TronWeb3ErrorCode.resourceUnavailable,
        AppLocalizations.of(context)?.web3ErrorRequestInProgress ?? '',
      );
    }

    _addActiveRequest(method);
    final l10n = AppLocalizations.of(context);

    try {
      final connection =
          Web3Utils.findConnected(_currentDomain, appState.connections);

      if (connection == null) {
        _removeActiveRequest(method);
        return _returnError(
          message.uuid,
          TronWeb3ErrorCode.unauthorized,
          l10n?.web3ErrorNotConnected ?? '',
        );
      }

      final params = message.payload['params'] as dynamic;
      if (params == null) {
        _removeActiveRequest(method);
        return _returnError(
          message.uuid,
          TronWeb3ErrorCode.invalidInput,
          l10n?.web3ErrorInvalidParams(method, "") ?? '',
        );
      }

      // {method: tron_signMessageV2, params: {transaction: dasdsa, options: {}, input: dasdsa, isSignMessageV2: true}}
      final dataToSign = params['input'];
      final messageContent = decodePersonalSignMessage(dataToSign);

      if (!context.mounted) {
        _removeActiveRequest(method);
        return;
      }

      showSignMessageModal(
        context: context,
        message: messageContent,
        onMessageSigned: (pubkey, sig) async {
          await _sendResponse(
            type: kBearbyResponseType,
            uuid: message.uuid,
            result: sig,
          );
          _removeActiveRequest(method);
          if (context.mounted) {
            Navigator.pop(context);
          }
        },
        onDismiss: () {
          _returnError(
            message.uuid,
            TronWeb3ErrorCode.internalError,
            AppLocalizations.of(context)?.web3ErrorUserRejected ?? '',
          );
          _removeActiveRequest(method);
        },
        appTitle: "",
        appIcon: message.icon ?? '',
      );
    } catch (e) {
      _removeActiveRequest(method);
      debugPrint('Error in $method: $e');
      _returnError(
        message.uuid,
        TronWeb3ErrorCode.internalError,
        'Error processing $method: $e',
      );
    }
  }

  Future<void> _handleChainId(
    ZilPayWeb3Message message,
    AppState appState,
  ) async {
    final chain = appState.chain!;
    final chainIdHex = '$kHexPrefix${chain.chainId.toRadixString(kHexRadix)}';

    _sendResponse(
      type: kBearbyResponseType,
      uuid: message.uuid,
      result: chainIdHex,
    );
  }

  Future<void> _proxyRpcRequest({
    required String method,
    required String uuid,
    required BigInt chainHash,
    List<dynamic>? params,
  }) async {
    try {
      final payload = jsonEncode({
        'method': method,
        'params': params ?? [],
        'jsonrpc': kJsonRpcVersion,
        'id': uuid,
      });

      final jsonRes =
          await providerReqProxy(payload: payload, chainHash: chainHash);
      final response = jsonDecode(jsonRes);

      if (response['error'] != null) {
        final error = response['error'];
        final errorCode =
            error['code'] as int? ?? TronWeb3ErrorCode.internalError.code;
        final errorMessage = error['message'] as String? ?? '';

        _sendResponse(
          type: kBearbyResponseType,
          uuid: uuid,
          errorCode: TronWeb3ErrorCode.values.firstWhere(
            (e) => e.code == errorCode,
            orElse: () => TronWeb3ErrorCode.internalError,
          ),
          errorMessage: errorMessage,
        );
      } else {
        _sendResponse(
          type: kBearbyResponseType,
          uuid: uuid,
          result: response['result'],
        );
      }
    } catch (e) {
      _returnError(
        uuid,
        TronWeb3ErrorCode.internalError,
        'Failed to proxy RPC request: $e',
      );
    }
  }

  Future<void> _handleEthRequestAccounts(
    ZilPayWeb3Message message,
    BuildContext context,
    AppState appState,
  ) async {
    final method = message.payload['method'] as String;

    if (_isRequestActive(method)) {
      return _returnError(
        message.uuid,
        TronWeb3ErrorCode.resourceUnavailable,
        AppLocalizations.of(context)?.web3ErrorRequestInProgress ?? '',
      );
    }

    _addActiveRequest(method);

    try {
      await appState.syncConnections();
      final connection = Web3Utils.findConnected(
        _currentDomain,
        appState.connections,
      );

      final addresses = await _getWalletAddresses(appState);

      if (connection != null &&
          appState.wallet?.accounts.length ==
              connection.accountIndexes.length) {
        _removeActiveRequest(method);

        _sendNotification(eventName: 'dataChanged', data: {
          'address': addresses.first,
          'name': appState.account?.name,
          'type': 0,
          'isAuth': true,
          'chainId': '0x${appState.chain?.chainId.toRadixString(16)}',
        });

        return _sendResponse(
          type: kBearbyResponseType,
          uuid: message.uuid,
          result: addresses,
        );
      }

      String? title = await webViewController.getTitle();

      if (!context.mounted) {
        _removeActiveRequest(method);
        return;
      }

      showAppConnectModal(
        context: context,
        title: message.title ?? "",
        uuid: message.uuid,
        iconUrl: message.icon ?? "",
        onReject: () {
          _sendResponse(
            type: kBearbyResponseType,
            uuid: message.uuid,
            result: <void>[],
          );
          _removeActiveRequest(method);
        },
        onConfirm: (selectedIndices) async {
          try {
            if (selectedIndices.isEmpty) {
              return _sendResponse(
                type: kBearbyResponseType,
                uuid: message.uuid,
                result: <void>[],
              );
            }

            final accountIndexes = Uint64List.fromList(selectedIndices);
            final connectionInfo = ConnectionInfo(
              domain: _currentDomain,
              accountIndexes: accountIndexes,
              favicon: message.icon,
              title: title ?? "",
              description: message.description,
              lastConnected: BigInt.from(DateTime.now().millisecondsSinceEpoch),
              canReadAccounts: true,
              canRequestSignatures: true,
              canSuggestTokens: false,
              canSuggestTransactions: true,
            );

            await createUpdateConnection(
              walletIndex: BigInt.from(appState.selectedWallet),
              conn: connectionInfo,
            );
            await appState.syncConnections();

            final connectedAddr = filterByIndexes(addresses, accountIndexes);
            _sendNotification(eventName: 'dataChanged', data: {
              'address': connectedAddr.first,
              'name': appState.account?.name,
              'type': 0,
              'isAuth': true,
              'chainId': '0x${appState.chain?.chainId.toRadixString(16)}',
            });
            _sendResponse(
              type: kBearbyResponseType,
              uuid: message.uuid,
              result: connectedAddr,
            );
          } finally {
            _removeActiveRequest(method);
          }
        },
      );
    } catch (e) {
      _removeActiveRequest(method);
      _returnError(
        message.uuid,
        TronWeb3ErrorCode.internalError,
        'Error processing request: $e',
      );
    }
  }

  Future<void> _handleGetInitProviderData(
    ZilPayWeb3Message message,
    BuildContext context,
  ) async {
    if (_isRequestActive(Web3EIP1193Method.getInitProviderData.value)) {
      return _returnError(
        message.uuid,
        TronWeb3ErrorCode.resourceUnavailable,
        AppLocalizations.of(context)?.web3ErrorRequestInProgress ?? '',
      );
    }

    _addActiveRequest(Web3EIP1193Method.getInitProviderData.value);

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      await appState.syncConnections();

      final connection = Web3Utils.findConnected(
        _currentDomain,
        appState.connections,
      );

      final account = appState.account;
      final chain = appState.chain;

      if (!context.mounted) {
        return;
      }

      if (account == null || chain == null) {
        _removeActiveRequest(Web3EIP1193Method.getInitProviderData.value);
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
      final chainIdHex = '0x${chain.chainId.toRadixString(16)}';

      _sendResponse(
        type: kBearbyResponseType,
        uuid: message.uuid,
        result: {
          'address': isAuth ? account.addr : null,
          'name': isAuth ? account.name : null,
          'type': 0,
          'isAuth': isAuth,
          'chainId': chainIdHex,
        },
      );
    } catch (e) {
      debugPrint("Error in getInitProviderData: $e");
      _returnError(
        message.uuid,
        TronWeb3ErrorCode.internalError,
        'Error processing getInitProviderData: $e',
      );
    } finally {
      _removeActiveRequest(Web3EIP1193Method.getInitProviderData.value);
    }
  }

  Future<List<String>> _getWalletAddresses(AppState appState) async {
    List<String> addresses = [];
    final selectedAccountIndex = appState.wallet?.selectedAccount.toInt();

    addresses = (appState.wallet?.accounts ?? []).map((a) => a.addr).toList();

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
