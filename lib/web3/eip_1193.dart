import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:zilpay/modals/app_connect.dart';
import 'package:zilpay/src/rust/api/connections.dart';
import 'package:zilpay/src/rust/models/connection.dart';
import 'package:zilpay/state/app_state.dart';
import 'package:zilpay/web3/message.dart';
import 'package:zilpay/web3/web3_utils.dart';

enum Web3EIP1193Method {
  ethRequestAccounts('eth_requestAccounts'),
  ethAccounts('eth_accounts'),
  ethSign('eth_sign'),
  ethSendTransaction('eth_sendTransaction'),
  ethGetBalance('eth_getBalance'),
  ethGetTransactionByHash('eth_getTransactionByHash'),
  ethGetTransactionReceipt('eth_getTransactionReceipt'),
  ethCall('eth_call'),
  ethEstimateGas('eth_estimateGas'),
  ethBlockNumber('eth_blockNumber'),
  ethGetBlockByNumber('eth_getBlockByNumber'),
  ethGetBlockByHash('eth_getBlockByHash'),
  ethSubscribe('eth_subscribe'),
  ethUnsubscribe('eth_unsubscribe'),
  netVersion('net_version'),
  ethChainId('eth_chainId'),
  ethGetCode('eth_getCode'),
  ethGetStorageAt('eth_getStorageAt');

  final String value;
  const Web3EIP1193Method(this.value);
}

enum Web3EIP1193ErrorCode {
  userRejectedRequest(4001),
  unauthorized(4100),
  unsupportedMethod(4200),
  disconnected(4900),
  chainDisconnected(4901),
  internalError(-32603),
  invalidInput(-32000);

  final int code;
  const Web3EIP1193ErrorCode(this.code);
}

class Web3EIP1193Handler {
  final WebViewController webViewController;
  final String initialUrl;

  Web3EIP1193Handler({
    required this.webViewController,
    required this.initialUrl,
  });

  Future<void> _sendResponse({
    required String type,
    required String uuid,
    Map<String, dynamic>? payload,
    dynamic result,
    Web3EIP1193ErrorCode? errorCode,
    String? errorMessage,
  }) async {
    final responsePayload = <String, dynamic>{};
    if (payload != null) responsePayload.addAll(payload);
    if (result != null) responsePayload['result'] = result;
    if (errorCode != null && errorMessage != null) {
      responsePayload['error'] = {
        'code': errorCode.code,
        'message': errorMessage,
      };
    }

    final response = ZilPayWeb3Message(
      type: type,
      uuid: uuid,
      payload: responsePayload,
    ).toJson();

    final jsonString = jsonEncode(response);
    await webViewController
        .runJavaScript('window.postMessage($jsonString, `*`)');
  }

  Future<void> handleWeb3EIP1193Message(
    ZilPayWeb3Message message,
    BuildContext context,
  ) async {
    final appState = Provider.of<AppState>(context, listen: false);
    final chain = appState.chain;

    try {
      final currentDomain = Uri.parse(initialUrl).host;
      final method = message.payload['method'] as String?;
      if (method == null) {
        debugPrint('Error: No method specified in payload');
        return _returnError(message.uuid,
            Web3EIP1193ErrorCode.unsupportedMethod, 'No method specified');
      }

      final zilPayMethod = Web3EIP1193Method.values.firstWhere(
        (m) => m.value == method,
        orElse: () => Web3EIP1193Method.ethRequestAccounts,
      );

      switch (zilPayMethod) {
        case Web3EIP1193Method.ethRequestAccounts:
          await appState.syncConnections();
          final foundConnection =
              Web3Utils.isDomainConnected(currentDomain, appState.connections);
          final pageInfo = await Web3Utils.extractPageInfo(webViewController);
          List<String> addresses =
              (appState.wallet?.accounts ?? []).map((a) => a.addr).toList();

          if (chain?.slip44 == 313) {
            // TODO: Zilliqa.
          }

          if (foundConnection != null &&
              appState.wallet?.accounts.length ==
                  foundConnection.walletIndexes.length) {
            return await _sendResponse(
              type: 'ZILPAY_RESPONSE',
              uuid: message.uuid,
              result: addresses,
            );
          }

          if (!context.mounted) return;

          showAppConnectModal(
              context: context,
              title: "",
              uuid: message.uuid,
              iconUrl: "",
              onDecision: (accepted, selectedIndices) async {
                final walletIndexes = Uint64List.fromList(selectedIndices);
                ConnectionInfo connectionInfo = ConnectionInfo(
                  domain: currentDomain,
                  walletIndexes: walletIndexes,
                  favicon: message.icon,
                  title: "",
                  colors: null,
                  description: pageInfo['description'] as String?,
                  lastConnected:
                      BigInt.from(DateTime.now().millisecondsSinceEpoch),
                  canReadAccounts: true,
                  canRequestSignatures: true,
                  canSuggestTokens: false,
                  canSuggestTransactions: true,
                );

                if (accepted) {
                  // TODO: create or update
                  await createNewConnection(conn: connectionInfo);
                  await appState.syncConnections();
                }

                List<String> connectedAddr = Web3Utils.filterByIndexes(
                  addresses,
                  walletIndexes,
                );

                await _sendResponse(
                  type: 'ZILPAY_RESPONSE',
                  uuid: message.uuid,
                  result: connectedAddr,
                );
              });
          break;
        case Web3EIP1193Method.ethAccounts:
          await appState.syncConnections();
          final foundConnection =
              Web3Utils.isDomainConnected(currentDomain, appState.connections);
          List<String> addresses =
              (appState.wallet?.accounts ?? []).map((a) => a.addr).toList();
          List<String> connectedAddr = Web3Utils.filterByIndexes(
            addresses,
            foundConnection?.walletIndexes ?? Uint64List.fromList([]),
          );
          await _sendResponse(
            type: 'ZILPAY_RESPONSE',
            uuid: message.uuid,
            result: connectedAddr,
          );
          break;
        case Web3EIP1193Method.ethSign:
          _returnError(message.uuid, Web3EIP1193ErrorCode.unsupportedMethod,
              'Method "eth_sign" is not supported');
          break;
        case Web3EIP1193Method.ethSendTransaction:
          _returnError(message.uuid, Web3EIP1193ErrorCode.unsupportedMethod,
              'Method "eth_sendTransaction" is not supported');
          break;
        case Web3EIP1193Method.ethGetBalance:
          _returnError(message.uuid, Web3EIP1193ErrorCode.unsupportedMethod,
              'Method "eth_getBalance" is not supported');
          break;
        case Web3EIP1193Method.ethGetTransactionByHash:
          _returnError(message.uuid, Web3EIP1193ErrorCode.unsupportedMethod,
              'Method "eth_getTransactionByHash" is not supported');
          break;
        case Web3EIP1193Method.ethGetTransactionReceipt:
          _returnError(message.uuid, Web3EIP1193ErrorCode.unsupportedMethod,
              'Method "eth_getTransactionReceipt" is not supported');
          break;
        case Web3EIP1193Method.ethCall:
          _returnError(message.uuid, Web3EIP1193ErrorCode.unsupportedMethod,
              'Method "eth_call" is not supported');
          break;
        case Web3EIP1193Method.ethEstimateGas:
          _returnError(message.uuid, Web3EIP1193ErrorCode.unsupportedMethod,
              'Method "eth_estimateGas" is not supported');
          break;
        case Web3EIP1193Method.ethBlockNumber:
          _returnError(message.uuid, Web3EIP1193ErrorCode.unsupportedMethod,
              'Method "eth_blockNumber" is not supported');
          break;
        case Web3EIP1193Method.ethGetBlockByNumber:
          _returnError(message.uuid, Web3EIP1193ErrorCode.unsupportedMethod,
              'Method "eth_getBlockByNumber" is not supported');
          break;
        case Web3EIP1193Method.ethGetBlockByHash:
          _returnError(message.uuid, Web3EIP1193ErrorCode.unsupportedMethod,
              'Method "eth_getBlockByHash" is not supported');
          break;
        case Web3EIP1193Method.ethSubscribe:
          _returnError(message.uuid, Web3EIP1193ErrorCode.unsupportedMethod,
              'Method "eth_subscribe" is not supported');
          break;
        case Web3EIP1193Method.ethUnsubscribe:
          _returnError(message.uuid, Web3EIP1193ErrorCode.unsupportedMethod,
              'Method "eth_unsubscribe" is not supported');
          break;
        case Web3EIP1193Method.netVersion:
          _returnError(message.uuid, Web3EIP1193ErrorCode.unsupportedMethod,
              'Method "net_version" is not supported');
          break;
        case Web3EIP1193Method.ethChainId:
          _returnError(message.uuid, Web3EIP1193ErrorCode.unsupportedMethod,
              'Method "eth_chainId" is not supported');
          break;
        case Web3EIP1193Method.ethGetCode:
          _returnError(message.uuid, Web3EIP1193ErrorCode.unsupportedMethod,
              'Method "eth_getCode" is not supported');
          break;
        case Web3EIP1193Method.ethGetStorageAt:
          _returnError(message.uuid, Web3EIP1193ErrorCode.unsupportedMethod,
              'Method "eth_getStorageAt" is not supported');
          break;
      }
    } catch (e) {
      debugPrint('Error handling message: $e');
      _returnError(message.uuid, Web3EIP1193ErrorCode.internalError,
          'Error processing message: $e');
    }
  }

  void _returnError(
      String uuid, Web3EIP1193ErrorCode errorCode, String errorMessage) {
    _sendResponse(
      type: 'ZILPAY_RESPONSE',
      uuid: uuid,
      errorCode: errorCode,
      errorMessage: errorMessage,
    );
  }
}
