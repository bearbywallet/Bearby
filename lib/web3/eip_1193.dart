import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:zilpay/modals/app_connect.dart';
import 'package:zilpay/src/rust/api/connections.dart';
import 'package:zilpay/src/rust/api/provider.dart';
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
  ethGetStorageAt('eth_getStorageAt'),
  ethGasPrice('eth_gasPrice'),
  ethSignTypedData('eth_signTypedData'),
  ethSignTypedDataV4('eth_signTypedData_v4'),
  ethGetTransactionCount('eth_getTransactionCount'),
  personalSign('personal_sign'),

  walletAddEthereumChain('wallet_addEthereumChain'),
  walletSwitchEthereumChain('wallet_switchEthereumChain'),
  walletWatchAsset('wallet_watchAsset'),
  walletGetPermissions('wallet_getPermissions'),
  walletRequestPermissions('wallet_requestPermissions'),
  walletScanQRCode('wallet_scanQRCode'),
  ethGetEncryptionPublicKey('eth_getEncryptionPublicKey'),
  ethDecrypt('eth_decrypt');

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
          List<String> addresses =
              (appState.wallet?.accounts ?? []).map((a) => a.addr).toList();

          if (chain?.slip44 == 313) {
            // TODO: Zilliqa.
          }

          if (foundConnection != null &&
              appState.wallet?.accounts.length ==
                  foundConnection.accountIndexes.length) {
            return await _sendResponse(
              type: 'ZILPAY_RESPONSE',
              uuid: message.uuid,
              result: addresses,
            );
          }

          if (!context.mounted) return;

          showAppConnectModal(
              context: context,
              title: message.title ?? "",
              colors: message.colors,
              uuid: message.uuid,
              iconUrl: message.icon ?? "",
              onDecision: (accepted, selectedIndices) async {
                final accountIndexes = Uint64List.fromList(selectedIndices);
                ConnectionInfo connectionInfo = ConnectionInfo(
                  domain: currentDomain,
                  accountIndexes: accountIndexes,
                  favicon: message.icon,
                  title: message.title ?? "",
                  colors: message.colors,
                  description: message.description,
                  lastConnected:
                      BigInt.from(DateTime.now().millisecondsSinceEpoch),
                  canReadAccounts: true,
                  canRequestSignatures: true,
                  canSuggestTokens: false,
                  canSuggestTransactions: true,
                );

                if (accepted) {
                  await createUpdateConnection(
                    walletIndex: BigInt.from(
                      appState.selectedWallet,
                    ),
                    conn: connectionInfo,
                  );
                  await appState.syncConnections();
                }

                List<String> connectedAddr = Web3Utils.filterByIndexes(
                  addresses,
                  accountIndexes,
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
            foundConnection?.accountIndexes ?? Uint64List.fromList([]),
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
          await _proxyRpcRequest(
            method: zilPayMethod.value,
            uuid: message.uuid,
            params: message.payload['params'],
            chainHash: chain?.chainHash ?? BigInt.zero,
          );
          break;
        case Web3EIP1193Method.ethGetTransactionByHash:
          await _proxyRpcRequest(
            method: zilPayMethod.value,
            uuid: message.uuid,
            params: message.payload['params'],
            chainHash: chain?.chainHash ?? BigInt.zero,
          );
          break;
        case Web3EIP1193Method.ethGetTransactionReceipt:
          await _proxyRpcRequest(
            method: zilPayMethod.value,
            uuid: message.uuid,
            params: message.payload['params'],
            chainHash: chain?.chainHash ?? BigInt.zero,
          );
          break;
        case Web3EIP1193Method.ethCall:
          await _proxyRpcRequest(
            method: zilPayMethod.value,
            uuid: message.uuid,
            params: message.payload['params'],
            chainHash: chain?.chainHash ?? BigInt.zero,
          );
          break;
        case Web3EIP1193Method.ethEstimateGas:
          await _proxyRpcRequest(
            method: zilPayMethod.value,
            uuid: message.uuid,
            params: message.payload['params'],
            chainHash: chain?.chainHash ?? BigInt.zero,
          );
          break;
        case Web3EIP1193Method.ethBlockNumber:
          await _proxyRpcRequest(
            method: zilPayMethod.value,
            uuid: message.uuid,
            params: message.payload['params'],
            chainHash: chain?.chainHash ?? BigInt.zero,
          );
          break;
        case Web3EIP1193Method.ethGetBlockByNumber:
          await _proxyRpcRequest(
            method: zilPayMethod.value,
            uuid: message.uuid,
            params: message.payload['params'],
            chainHash: chain?.chainHash ?? BigInt.zero,
          );
          break;
        case Web3EIP1193Method.ethGetBlockByHash:
          await _proxyRpcRequest(
            method: zilPayMethod.value,
            uuid: message.uuid,
            params: message.payload['params'],
            chainHash: chain?.chainHash ?? BigInt.zero,
          );
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
          await _proxyRpcRequest(
            method: zilPayMethod.value,
            uuid: message.uuid,
            params: message.payload['params'],
            chainHash: chain?.chainHash ?? BigInt.zero,
          );
          break;
        case Web3EIP1193Method.ethChainId:
          await _proxyRpcRequest(
            method: zilPayMethod.value,
            uuid: message.uuid,
            params: message.payload['params'],
            chainHash: chain?.chainHash ?? BigInt.zero,
          );
          break;
        case Web3EIP1193Method.ethGetCode:
          await _proxyRpcRequest(
            method: zilPayMethod.value,
            uuid: message.uuid,
            params: message.payload['params'],
            chainHash: chain?.chainHash ?? BigInt.zero,
          );
          break;
        case Web3EIP1193Method.ethGetStorageAt:
          await _proxyRpcRequest(
            method: zilPayMethod.value,
            uuid: message.uuid,
            params: message.payload['params'],
            chainHash: chain?.chainHash ?? BigInt.zero,
          );
          break;
        case Web3EIP1193Method.ethGasPrice:
          await _proxyRpcRequest(
            method: zilPayMethod.value,
            uuid: message.uuid,
            params: message.payload['params'],
            chainHash: chain?.chainHash ?? BigInt.zero,
          );
          break;
        case Web3EIP1193Method.ethSignTypedData:
          debugPrint('Called: eth_signTypedData');
          _returnError(message.uuid, Web3EIP1193ErrorCode.unsupportedMethod,
              'Method "eth_signTypedData" is not supported');
          break;
        case Web3EIP1193Method.ethSignTypedDataV4:
          debugPrint('Called: eth_signTypedData_v4');
          _returnError(message.uuid, Web3EIP1193ErrorCode.unsupportedMethod,
              'Method "eth_signTypedData_v4" is not supported');
          break;
        case Web3EIP1193Method.ethGetTransactionCount:
          debugPrint('Called: eth_getTransactionCount');
          await _proxyRpcRequest(
            method: zilPayMethod.value,
            uuid: message.uuid,
            params: message.payload['params'],
            chainHash: chain?.chainHash ?? BigInt.zero,
          );
          break;
        case Web3EIP1193Method.personalSign:
          debugPrint('Called: personal_sign');
          _returnError(message.uuid, Web3EIP1193ErrorCode.unsupportedMethod,
              'Method "personal_sign" is not supported');
          break;

        case Web3EIP1193Method.walletAddEthereumChain:
          debugPrint('Called: wallet_addEthereumChain');
          _returnError(message.uuid, Web3EIP1193ErrorCode.unsupportedMethod,
              'Method "wallet_addEthereumChain" is not supported by ZilPay');
          break;
        case Web3EIP1193Method.walletSwitchEthereumChain:
          debugPrint('Called: wallet_switchEthereumChain');
          _returnError(message.uuid, Web3EIP1193ErrorCode.unsupportedMethod,
              'Method "wallet_switchEthereumChain" is not supported by ZilPay');
          break;
        case Web3EIP1193Method.walletWatchAsset:
          debugPrint('Called: wallet_watchAsset');
          _returnError(message.uuid, Web3EIP1193ErrorCode.unsupportedMethod,
              'Method "wallet_watchAsset" is not supported by ZilPay');
          break;
        case Web3EIP1193Method.walletGetPermissions:
          debugPrint('Called: wallet_getPermissions');
          _returnError(message.uuid, Web3EIP1193ErrorCode.unsupportedMethod,
              'Method "wallet_getPermissions" is not supported by ZilPay');
          break;
        case Web3EIP1193Method.walletRequestPermissions:
          debugPrint('Called: wallet_requestPermissions');
          _returnError(message.uuid, Web3EIP1193ErrorCode.unsupportedMethod,
              'Method "wallet_requestPermissions" is not supported by ZilPay');
          break;
        case Web3EIP1193Method.walletScanQRCode:
          debugPrint('Called: wallet_scanQRCode');
          _returnError(message.uuid, Web3EIP1193ErrorCode.unsupportedMethod,
              'Method "wallet_scanQRCode" is not supported by ZilPay');
          break;
        case Web3EIP1193Method.ethGetEncryptionPublicKey:
          debugPrint('Called: eth_getEncryptionPublicKey');
          _returnError(message.uuid, Web3EIP1193ErrorCode.unsupportedMethod,
              'Method "eth_getEncryptionPublicKey" is not supported by ZilPay');
          break;
        case Web3EIP1193Method.ethDecrypt:
          debugPrint('Called: eth_decrypt');
          _returnError(message.uuid, Web3EIP1193ErrorCode.unsupportedMethod,
              'Method "eth_decrypt" is not supported by ZilPay');
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

  Future<void> _proxyRpcRequest({
    required String method,
    required String uuid,
    required BigInt chainHash,
    List<dynamic>? params,
  }) async {
    try {
      final payload = {
        'method': method,
        'params': params ?? [],
        'jsonrpc': '2.0',
        'id': uuid,
      };

      final payloadJson = jsonEncode(payload);
      final jsonRes = await providerReqProxy(
        payload: payloadJson,
        chainHash: chainHash,
      );
      final response = jsonDecode(jsonRes);
      if (response.containsKey('error') && response['error'] != null) {
        final error = response['error'];
        final errorCode =
            error['code'] as int? ?? Web3EIP1193ErrorCode.internalError.code;
        final errorMessage =
            error['message'] as String? ?? 'Unknown error from RPC provider';

        await _sendResponse(
          type: 'ZILPAY_RESPONSE',
          uuid: uuid,
          errorCode: Web3EIP1193ErrorCode.values.firstWhere(
            (e) => e.code == errorCode,
            orElse: () => Web3EIP1193ErrorCode.internalError,
          ),
          errorMessage: errorMessage,
        );
      } else {
        await _sendResponse(
          type: 'ZILPAY_RESPONSE',
          uuid: uuid,
          result: response['result'],
        );
      }
    } catch (e) {
      debugPrint('RPC proxy error: $e');
      _returnError(
        uuid,
        Web3EIP1193ErrorCode.internalError,
        'Failed to proxy RPC request: $e',
      );
    }
  }
}
