import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:zilpay/config/eip1193.dart';
import 'package:zilpay/mixins/amount.dart';
import 'package:zilpay/mixins/eip712.dart';
import 'package:zilpay/modals/app_connect.dart';
import 'package:zilpay/modals/sign_message.dart';
import 'package:zilpay/modals/transfer.dart';
import 'package:zilpay/src/rust/api/connections.dart';
import 'package:zilpay/src/rust/api/provider.dart';
import 'package:zilpay/src/rust/api/wallet.dart';
import 'package:zilpay/src/rust/models/connection.dart';
import 'package:zilpay/src/rust/models/transactions/base_token.dart';
import 'package:zilpay/src/rust/models/transactions/evm.dart';
import 'package:zilpay/src/rust/models/transactions/request.dart';
import 'package:zilpay/src/rust/models/transactions/transaction_metadata.dart';
import 'package:zilpay/state/app_state.dart';
import 'package:zilpay/web3/message.dart';
import 'dart:developer' as dev;

import 'package:zilpay/web3/web3_utils.dart';

class Web3EIP1193Handler {
  final WebViewController webViewController;
  final String _currentDomain;

  Web3EIP1193Handler({
    required this.webViewController,
    required String initialUrl,
  }) : _currentDomain = Uri.parse(initialUrl).host;

  Future<void> _sendResponse({
    required String type,
    required String uuid,
    Map<String, dynamic>? payload,
    dynamic result,
    Web3EIP1193ErrorCode? errorCode,
    String? errorMessage,
  }) async {
    final responsePayload = {
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

    await webViewController
        .runJavaScript('window.postMessage(${jsonEncode(response)}, `*`)');
  }

  void _returnError(
    String uuid,
    Web3EIP1193ErrorCode errorCode,
    String errorMessage,
  ) {
    _sendResponse(
      type: 'ZILPAY_RESPONSE',
      uuid: uuid,
      errorCode: errorCode,
      errorMessage: errorMessage,
    );
  }

  Future<List<String>> _getWalletAddresses(AppState appState) async {
    final addresses =
        (appState.wallet?.accounts ?? []).map((a) => a.addr).toList();
    return appState.chain?.slip44 == 313
        ? await convertBech32AddressesToEthChecksum(addresses: addresses)
        : addresses;
  }

  Future<void> handleWeb3EIP1193Message(
    ZilPayWeb3Message message,
    BuildContext context,
  ) async {
    final appState = Provider.of<AppState>(context, listen: false);
    final chain = appState.chain;

    try {
      final method = message.payload['method'] as String?;
      if (method == null) {
        return _returnError(
          message.uuid,
          Web3EIP1193ErrorCode.unsupportedMethod,
          'No method specified',
        );
      }

      final zilPayMethod = Web3EIP1193Method.values.firstWhere(
        (m) => m.value == method,
        orElse: () => Web3EIP1193Method.ethRequestAccounts,
      );

      switch (zilPayMethod) {
        case Web3EIP1193Method.ethRequestAccounts:
          await _handleEthRequestAccounts(message, context, appState);
          break;
        case Web3EIP1193Method.walletRequestPermissions:
          await _handleWalletRequestPermissions(message, context, appState);
          break;

        case Web3EIP1193Method.ethAccounts:
          await _handleEthAccounts(message, appState);
          break;

        case Web3EIP1193Method.ethSign:
        case Web3EIP1193Method.personalSign:
          await _handleEthereumSigning(
            message: message,
            context: context,
            appState: appState,
            isPersonalSign: zilPayMethod == Web3EIP1193Method.personalSign,
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
        case Web3EIP1193Method.ethChainId:
        case Web3EIP1193Method.ethGetCode:
        case Web3EIP1193Method.ethGetStorageAt:
        case Web3EIP1193Method.ethGasPrice:
        case Web3EIP1193Method.ethGetTransactionCount:
          await _proxyRpcRequest(
            method: zilPayMethod.value,
            uuid: message.uuid,
            params: message.payload['params'],
            chainHash: chain?.chainHash ?? BigInt.zero,
          );
          break;

        case Web3EIP1193Method.ethSignTypedDataV4:
          await _handleEthSignTypedDataV4(
            message,
            context,
            appState,
          );
          break;

        case Web3EIP1193Method.ethSendTransaction:
          await _handleEthSendTransaction(message, context, appState);
          break;

        default:
          _returnError(
            message.uuid,
            Web3EIP1193ErrorCode.unsupportedMethod,
            'Method "${zilPayMethod.value}" is not supported',
          );
          break;
      }
    } catch (e) {
      dev.log('Error handling message: $e', name: 'web3_handler');
      _returnError(
        message.uuid,
        Web3EIP1193ErrorCode.internalError,
        'Error processing message: $e',
      );
    }
  }

  Future<void> _handleEthRequestAccounts(
    ZilPayWeb3Message message,
    BuildContext context,
    AppState appState,
  ) async {
    await appState.syncConnections();
    final connection = Web3Utils.findConnected(
      _currentDomain,
      appState.connections,
    );
    final addresses = await _getWalletAddresses(appState);

    if (connection != null &&
        appState.wallet?.accounts.length == connection.accountIndexes.length) {
      return _sendResponse(
        type: 'ZILPAY_RESPONSE',
        uuid: message.uuid,
        result: addresses,
      );
    }

    if (!context.mounted) return;

    showAppConnectModal(
      context: context,
      title: message.title ?? "",
      // colors: message.colors,
      uuid: message.uuid,
      iconUrl: message.icon ?? "",
      onDecision: (accepted, selectedIndices) async {
        if (!accepted) {
          return _sendResponse(
            type: 'ZILPAY_RESPONSE',
            uuid: message.uuid,
            result: <void>[],
          );
        }

        final accountIndexes = Uint64List.fromList(selectedIndices);
        final connectionInfo = ConnectionInfo(
          domain: _currentDomain,
          accountIndexes: accountIndexes,
          favicon: message.icon,
          title: message.title ?? "",
          // colors: message.colors,
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
        _sendResponse(
          type: 'ZILPAY_RESPONSE',
          uuid: message.uuid,
          result: connectedAddr,
        );
      },
    );
  }

  Future<void> _handleEthAccounts(
    ZilPayWeb3Message message,
    AppState appState,
  ) async {
    await appState.syncConnections();
    final connection =
        Web3Utils.findConnected(_currentDomain, appState.connections);
    final addresses = await _getWalletAddresses(appState);
    final connectedAddr =
        filterByIndexes(addresses, connection?.accountIndexes ?? Uint64List(0));
    _sendResponse(
      type: 'ZILPAY_RESPONSE',
      uuid: message.uuid,
      result: connectedAddr,
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
        'jsonrpc': '2.0',
        'id': uuid,
      });

      final jsonRes =
          await providerReqProxy(payload: payload, chainHash: chainHash);
      final response = jsonDecode(jsonRes);

      if (response['error'] != null) {
        final error = response['error'];
        final errorCode =
            error['code'] as int? ?? Web3EIP1193ErrorCode.internalError.code;
        final errorMessage = error['message'] as String? ?? 'Unknown RPC error';

        _sendResponse(
          type: 'ZILPAY_RESPONSE',
          uuid: uuid,
          errorCode: Web3EIP1193ErrorCode.values.firstWhere(
            (e) => e.code == errorCode,
            orElse: () => Web3EIP1193ErrorCode.internalError,
          ),
          errorMessage: errorMessage,
        );
      } else {
        _sendResponse(
          type: 'ZILPAY_RESPONSE',
          uuid: uuid,
          result: response['result'],
        );
      }
    } catch (e) {
      dev.log('RPC proxy error: $e', name: 'web3_handler');
      _returnError(
        uuid,
        Web3EIP1193ErrorCode.internalError,
        'Failed to proxy RPC request: $e',
      );
    }
  }

  Future<void> _handleEthereumSigning({
    required ZilPayWeb3Message message,
    required BuildContext context,
    required AppState appState,
    required bool isPersonalSign,
  }) async {
    try {
      final connection =
          Web3Utils.findConnected(_currentDomain, appState.connections);

      if (connection == null) {
        return _returnError(
          message.uuid,
          Web3EIP1193ErrorCode.unauthorized,
          'This domain is not connected. Please connect first.',
        );
      }

      final params = message.payload['params'] as List<dynamic>?;
      if (params == null || params.length < 2) {
        final methodName = isPersonalSign ? 'personal_sign' : 'eth_sign';
        final paramOrder =
            isPersonalSign ? '[message, address]' : '[address, message]';
        return _returnError(
          message.uuid,
          Web3EIP1193ErrorCode.invalidInput,
          'Invalid parameters for $methodName. Required: $paramOrder',
        );
      }

      final address =
          isPersonalSign ? params[1] as String : params[0] as String;
      final dataToSign =
          isPersonalSign ? params[0] as String : params[1] as String;

      final addresses = await _getWalletAddresses(appState);
      final connectedAddresses =
          filterByIndexes(addresses, connection.accountIndexes);

      if (!connectedAddresses.contains(address)) {
        return _returnError(
          message.uuid,
          Web3EIP1193ErrorCode.unauthorized,
          'The requested address is not authorized',
        );
      }

      // TODO: the backend do it automaticly.
      final messageContent = isPersonalSign
          ? decodePersonalSignMessage(dataToSign)
          : "Ethereum Signed Message:\n${dataToSign.length}\n$dataToSign";

      if (!context.mounted) return;

      showSignMessageModal(
        context: context,
        // colors: connection.colors,
        message: messageContent,
        onMessageSigned: (pubkey, sig) async {
          await _sendResponse(
            type: 'ZILPAY_RESPONSE',
            uuid: message.uuid,
            result: sig,
          );
        },
        onDismiss: () => _returnError(
          message.uuid,
          Web3EIP1193ErrorCode.userRejectedRequest,
          'User rejected',
        ),
        appTitle: isPersonalSign ? 'Sign Message' : 'Sign Ethereum Message',
        appIcon: message.icon ?? '',
      );
    } catch (e) {
      final method = isPersonalSign ? 'personal_sign' : 'eth_sign';
      dev.log('Error in $method: $e', name: 'web3_handler');
      _returnError(
        message.uuid,
        Web3EIP1193ErrorCode.internalError,
        'Error processing $method: $e',
      );
    }
  }

  Future<void> _handleEthSendTransaction(
    ZilPayWeb3Message message,
    BuildContext context,
    AppState appState,
  ) async {
    try {
      final connection = Web3Utils.findConnected(
        _currentDomain,
        appState.connections,
      );

      if (connection == null) {
        return _returnError(
          message.uuid,
          Web3EIP1193ErrorCode.unauthorized,
          'This domain is not connected. Please connect first.',
        );
      }

      final params = message.payload['params'] as List<dynamic>?;
      if (params == null ||
          params.isEmpty ||
          params[0] is! Map<String, dynamic>) {
        return _returnError(
          message.uuid,
          Web3EIP1193ErrorCode.invalidInput,
          'Invalid parameters for eth_sendTransaction',
        );
      }

      final txParams = params[0] as Map<String, dynamic>;
      final from = txParams['from'] as String?;

      if (from == null) {
        return _returnError(
          message.uuid,
          Web3EIP1193ErrorCode.invalidInput,
          'Missing required parameter: from',
        );
      }

      final addresses = await _getWalletAddresses(appState);
      List<String> connectedAddresses =
          filterByIndexes(addresses, connection.accountIndexes)
              .map((a) => a.toLowerCase())
              .toList();

      if (!connectedAddresses.contains(from)) {
        return _returnError(
          message.uuid,
          Web3EIP1193ErrorCode.unauthorized,
          'The requested address is not authorized',
        );
      }

      final BigInt? chainId = txParams['chainId'] != null
          ? BigInt.parse(txParams['chainId'].toString().replaceFirst('0x', ''),
              radix: 16)
          : null;
      final BigInt? gasLimit = txParams['gas'] != null
          ? BigInt.parse(txParams['gas'].toString().replaceFirst('0x', ''),
              radix: 16)
          : null;
      final BigInt? maxFeePerGas = txParams['maxFeePerGas'] != null
          ? BigInt.parse(
              txParams['maxFeePerGas'].toString().replaceFirst('0x', ''),
              radix: 16)
          : null;
      final BigInt? maxPriorityFeePerGas =
          txParams['maxPriorityFeePerGas'] != null
              ? BigInt.parse(
                  txParams['maxPriorityFeePerGas']
                      .toString()
                      .replaceFirst('0x', ''),
                  radix: 16)
              : null;
      final BigInt? gasPrice = txParams['gasPrice'] != null
          ? BigInt.parse(txParams['gasPrice'].toString().replaceFirst('0x', ''),
              radix: 16)
          : null;
      final String? value = txParams['value'] as String?;
      final String? to = txParams['to'] as String?;

      final Uint8List? data = txParams['data'] != null
          ? Uint8List.fromList(
              hexToBytes(txParams['data'].toString().replaceFirst('0x', '')))
          : null;

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

      final tokenIndex =
          appState.wallet!.tokens.indexWhere((t) => t.addrType == 1);
      if (tokenIndex == -1) {
        return _returnError(
          message.uuid,
          Web3EIP1193ErrorCode.internalError,
          'No token information found',
        );
      }

      final BigInt valueAmount = value != null && value != '0x0'
          ? BigInt.parse(value.replaceFirst('0x', ''), radix: 16)
          : BigInt.zero;

      final tokenInfo = BaseTokenInfo(
        value: valueAmount.toString(),
        symbol: appState.wallet!.tokens[tokenIndex].symbol,
        decimals: appState.wallet!.tokens[tokenIndex].decimals,
      );

      final metadata = TransactionMetadataInfo(
        chainHash: appState.chain?.chainHash ?? BigInt.zero,
        hash: null,
        info: null,
        icon: message.icon,
        title: message.title ?? "EVM Transaction",
        signer: null,
        tokenInfo: tokenInfo,
      );

      final transactionRequest = TransactionRequestInfo(
        metadata: metadata,
        scilla: null,
        evm: evmRequest,
      );

      if (!context.mounted) return;

      showConfirmTransactionModal(
        context: context,
        tx: transactionRequest,
        to: to ?? "",
        colors: connection.colors,
        tokenIndex: tokenIndex,
        amount: adjustAmountToDouble(
                valueAmount, appState.wallet!.tokens[tokenIndex].decimals)
            .toString(),
        onConfirm: (tx) {
          _sendResponse(
            type: 'ZILPAY_RESPONSE',
            uuid: message.uuid,
            result: tx.transactionHash,
          );
          if (context.mounted) {
            Navigator.pop(context);
          }
        },
        onDismiss: () {
          _returnError(
            message.uuid,
            Web3EIP1193ErrorCode.userRejectedRequest,
            'User rejected the request',
          );
        },
      );
    } catch (e) {
      dev.log('Error in eth_sendTransaction: $e', name: 'web3_handler');
      _returnError(
        message.uuid,
        Web3EIP1193ErrorCode.internalError,
        'Error processing eth_sendTransaction: $e',
      );
    }
  }

  Future<void> _handleWalletRequestPermissions(
    ZilPayWeb3Message message,
    BuildContext context,
    AppState appState,
  ) async {
    final params = message.payload['params'] as List<dynamic>?;
    if (params == null ||
        params.isEmpty ||
        params[0] is! Map<String, dynamic>) {
      return _returnError(
        message.uuid,
        Web3EIP1193ErrorCode.invalidInput,
        'Invalid parameters for wallet_requestPermissions',
      );
    }

    final requestParams = params[0] as Map<String, dynamic>;

    if (!requestParams.containsKey('eth_accounts')) {
      return _returnError(
        message.uuid,
        Web3EIP1193ErrorCode.invalidInput,
        'Only eth_accounts permission is supported',
      );
    }

    await appState.syncConnections();
    final connection = Web3Utils.findConnected(
      _currentDomain,
      appState.connections,
    );
    final addresses = await _getWalletAddresses(appState);

    if (connection != null &&
        appState.wallet?.accounts.length == connection.accountIndexes.length) {
      return _sendResponse(
        type: 'ZILPAY_RESPONSE',
        uuid: message.uuid,
        result: {
          'permissions': [
            {
              'parentCapability': 'eth_accounts',
              'caveats': [
                {
                  'type': 'filterResponse',
                  'value': addresses,
                }
              ],
            }
          ]
        },
      );
    }

    if (!context.mounted) return;

    showAppConnectModal(
      context: context,
      title: message.title ?? "",
      uuid: message.uuid,
      iconUrl: message.icon ?? "",
      onDecision: (accepted, selectedIndices) async {
        if (!accepted) {
          return _returnError(
            message.uuid,
            Web3EIP1193ErrorCode.userRejectedRequest,
            'User rejected the request',
          );
        }

        final accountIndexes = Uint64List.fromList(selectedIndices);
        final connectionInfo = ConnectionInfo(
          domain: _currentDomain,
          accountIndexes: accountIndexes,
          favicon: message.icon,
          title: message.title ?? "",
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
        _sendResponse(
          type: 'ZILPAY_RESPONSE',
          uuid: message.uuid,
          result: {
            'permissions': [
              {
                'parentCapability': 'eth_accounts',
                'caveats': [
                  {
                    'type': 'filterResponse',
                    'value': connectedAddr,
                  }
                ],
              }
            ]
          },
        );
      },
    );
  }

  Future<void> _handleEthSignTypedDataV4(
    ZilPayWeb3Message message,
    BuildContext context,
    AppState appState,
  ) async {
    try {
      final connection =
          Web3Utils.findConnected(_currentDomain, appState.connections);
      if (connection == null) {
        return _returnError(
          message.uuid,
          Web3EIP1193ErrorCode.unauthorized,
          'This domain is not connected. Please connect first.',
        );
      }

      final params = message.payload['params'] as List<dynamic>?;
      if (params == null || params.length < 2) {
        return _returnError(
          message.uuid,
          Web3EIP1193ErrorCode.invalidInput,
          'Invalid parameters for eth_signTypedData_v4. Required: [address, typedData]',
        );
      }

      final address = params[0] as String;
      final rawTypedData = params[1] as String;

      TypedDataEip712 typedDataeip712;

      try {
        typedDataeip712 = TypedDataEip712.fromJsonString(rawTypedData);
      } catch (e) {
        return _returnError(
          message.uuid,
          Web3EIP1193ErrorCode.invalidInput,
          'Invalid typedData format: ${e.toString()}',
        );
      }

      final addresses = await _getWalletAddresses(appState);
      final connectedAddresses =
          filterByIndexes(addresses, connection.accountIndexes);

      final normalizedAddress = address.toLowerCase();
      final isAuthorized =
          connectedAddresses.any((a) => a.toLowerCase() == normalizedAddress);

      if (!isAuthorized) {
        return _returnError(
          message.uuid,
          Web3EIP1193ErrorCode.unauthorized,
          'The requested address is not authorized',
        );
      }

      if (!context.mounted) return;

      showSignMessageModal(
        context: context,
        typedData: typedDataeip712,
        onMessageSigned: (pubkey, sig) async {
          await _sendResponse(
            type: 'ZILPAY_RESPONSE',
            uuid: message.uuid,
            result: sig,
          );
        },
        onDismiss: () => _returnError(
          message.uuid,
          Web3EIP1193ErrorCode.userRejectedRequest,
          'User rejected',
        ),
        appTitle: 'Sign Typed Data',
        appIcon: message.icon ?? '',
      );
    } catch (e) {
      dev.log('Error in eth_signTypedData_v4: $e', name: 'web3_handler');
      _returnError(
        message.uuid,
        Web3EIP1193ErrorCode.internalError,
        'Error processing eth_signTypedData_v4: $e',
      );
    }
  }
}
