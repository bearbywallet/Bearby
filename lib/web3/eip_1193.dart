import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/config/eip1193.dart';
import 'package:zilpay/config/ftokens.dart';
import 'package:zilpay/mixins/eip712.dart';
import 'package:zilpay/modals/add_chain.dart';
import 'package:zilpay/modals/app_connect.dart';
import 'package:zilpay/modals/sign_message.dart';
import 'package:zilpay/modals/swich_chain_modal.dart';
import 'package:zilpay/modals/transfer.dart';
import 'package:zilpay/modals/watch_asset_modal.dart';
import 'package:zilpay/src/rust/api/connections.dart';
import 'package:zilpay/src/rust/api/provider.dart';
import 'package:zilpay/src/rust/api/token.dart';
import 'package:zilpay/src/rust/api/utils.dart';
import 'package:zilpay/src/rust/api/wallet.dart';
import 'package:zilpay/src/rust/models/connection.dart';
import 'package:zilpay/src/rust/models/ftoken.dart';
import 'package:zilpay/src/rust/models/provider.dart';
import 'package:zilpay/src/rust/models/transactions/base_token.dart';
import 'package:zilpay/src/rust/models/transactions/evm.dart';
import 'package:zilpay/src/rust/models/transactions/request.dart';
import 'package:zilpay/src/rust/models/transactions/transaction_metadata.dart';
import 'package:zilpay/state/app_state.dart';
import 'package:zilpay/web3/message.dart';
import 'dart:developer' as dev;

import 'package:zilpay/web3/web3_utils.dart';

extension NetworkConfigInfoExtension on NetworkConfigInfo {
  NetworkConfigInfo copyWith({
    String? name,
    String? logo,
    String? chain,
    String? shortName,
    List<String>? rpc,
    Uint16List? features,
    BigInt? chainId,
    Uint64List? chainIds,
    int? slip44,
    BigInt? diffBlockTime,
    BigInt? chainHash,
    String? ens,
    List<ExplorerInfo>? explorers,
    bool? fallbackEnabled,
    bool? testnet,
    List<FTokenInfo>? ftokens,
  }) {
    return NetworkConfigInfo(
      ftokens: ftokens ?? this.ftokens,
      name: name ?? this.name,
      logo: logo ?? this.logo,
      chain: chain ?? this.chain,
      shortName: shortName ?? this.shortName,
      rpc: rpc ?? this.rpc,
      features: features ?? this.features,
      chainId: chainId ?? this.chainId,
      chainIds: chainIds ?? this.chainIds,
      slip44: slip44 ?? this.slip44,
      diffBlockTime: diffBlockTime ?? this.diffBlockTime,
      chainHash: chainHash ?? this.chainHash,
      ens: ens ?? this.ens,
      explorers: explorers ?? this.explorers,
      fallbackEnabled: fallbackEnabled ?? this.fallbackEnabled,
      testnet: testnet ?? this.testnet,
    );
  }
}

class Web3EIP1193Handler {
  final InAppWebViewController webViewController;
  final String _currentDomain;
  final Set<String> _activeRequests = {};

  Web3EIP1193Handler({
    required this.webViewController,
    required String initialUrl,
  }) : _currentDomain = Uri.parse(initialUrl).host;

  bool _isRequestActive(String method) {
    return _activeRequests.contains(method);
  }

  void _addActiveRequest(String method) {
    _activeRequests.add(method);
  }

  void _removeActiveRequest(String method) {
    _activeRequests.remove(method);
  }

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

    final jsResponse = jsonEncode(response);
    final jsCode = '''
    (function() {
      const responseData = $jsResponse;
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

    await webViewController.evaluateJavascript(source: jsCode);
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
    List<String> addresses = [];
    final selectedAccountIndex = appState.wallet?.selectedAccount.toInt();

    if (appState.chain?.slip44 == 313) {
      addresses = await getZilEthChecksumAddresses(
          walletIndex: BigInt.from(appState.selectedWallet));
    } else {
      addresses = (appState.wallet?.accounts ?? []).map((a) => a.addr).toList();
    }

    if (selectedAccountIndex != null &&
        selectedAccountIndex >= 0 &&
        selectedAccountIndex < addresses.length) {
      return [addresses[selectedAccountIndex]];
    }

    return addresses;
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
        case Web3EIP1193Method.walletGetPermissions:
          await _handleWalletGetPermissions(message, appState);
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
        case Web3EIP1193Method.walletWatchAsset:
          await _handleWalletWatchAsset(message, context, appState);
          break;

        case Web3EIP1193Method.walletAddEthereumChain:
          await _handleWalletAddEthereumChain(message, context, appState);
          break;

        case Web3EIP1193Method.walletSwitchEthereumChain:
          await _handleWalletSwitchEthereumChain(message, context, appState);
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
    final method = message.payload['method'] as String;

    if (_isRequestActive(method)) {
      return _returnError(
        message.uuid,
        Web3EIP1193ErrorCode.resourceUnavailable,
        'A similar request is already being processed',
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

        return _sendResponse(
          type: 'ZILPAY_RESPONSE',
          uuid: message.uuid,
          result: addresses,
        );
      }

      String? title = await webViewController.getTitle();

      if (appState.account?.addrType == 0 && appState.chain?.slip44 == 313) {
        await zilliqaSwapChain(
          walletIndex: BigInt.from(appState.selectedWallet),
          accountIndex: appState.wallet!.selectedAccount,
        );
        await appState.syncData();
      }

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
            type: 'ZILPAY_RESPONSE',
            uuid: message.uuid,
            result: <void>[],
          );
          _removeActiveRequest(method);
        },
        onConfirm: (selectedIndices) async {
          try {
            if (selectedIndices.isEmpty) {
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
            _sendResponse(
              type: 'ZILPAY_RESPONSE',
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
        Web3EIP1193ErrorCode.internalError,
        'Error processing request: $e',
      );
    }
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
    final method = message.payload['method'] as String;

    if (_isRequestActive(method)) {
      return _returnError(
        message.uuid,
        Web3EIP1193ErrorCode.resourceUnavailable,
        'A similar request is already being processed',
      );
    }

    _addActiveRequest(method);

    try {
      final connection =
          Web3Utils.findConnected(_currentDomain, appState.connections);

      if (connection == null) {
        _removeActiveRequest(method);
        return _returnError(
          message.uuid,
          Web3EIP1193ErrorCode.unauthorized,
          'This domain is not connected. Please connect first.',
        );
      }

      final params = message.payload['params'] as List<dynamic>?;
      if (params == null || params.length < 2) {
        _removeActiveRequest(method);
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

      if (!connectedAddresses
          .map((a) => a.toLowerCase())
          .contains(address.toLowerCase())) {
        _removeActiveRequest(method);
        return _returnError(
          message.uuid,
          Web3EIP1193ErrorCode.unauthorized,
          'The requested address is not authorized',
        );
      }

      final messageContent =
          isPersonalSign ? decodePersonalSignMessage(dataToSign) : dataToSign;

      if (appState.account?.addrType == 0 && appState.chain?.slip44 == 313) {
        await zilliqaSwapChain(
          walletIndex: BigInt.from(appState.selectedWallet),
          accountIndex: appState.wallet!.selectedAccount,
        );
        await appState.syncData();
      }

      if (!context.mounted) {
        _removeActiveRequest(method);
        return;
      }

      showSignMessageModal(
        context: context,
        message: messageContent,
        onMessageSigned: (pubkey, sig) async {
          await _sendResponse(
            type: 'ZILPAY_RESPONSE',
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
            Web3EIP1193ErrorCode.userRejectedRequest,
            'User rejected',
          );
          _removeActiveRequest(method);
        },
        appTitle: isPersonalSign ? 'Sign Message' : 'Sign Ethereum Message',
        appIcon: message.icon ?? '',
      );
    } catch (e) {
      _removeActiveRequest(method);
      final methodName = isPersonalSign ? 'personal_sign' : 'eth_sign';
      dev.log('Error in $methodName: $e', name: 'web3_handler');
      _returnError(
        message.uuid,
        Web3EIP1193ErrorCode.internalError,
        'Error processing $methodName: $e',
      );
    }
  }

  Future<void> _handleEthSendTransaction(
    ZilPayWeb3Message message,
    BuildContext context,
    AppState appState,
  ) async {
    final method = message.payload['method'] as String;

    if (_isRequestActive(method)) {
      return _returnError(
        message.uuid,
        Web3EIP1193ErrorCode.resourceUnavailable,
        'A similar request is already being processed',
      );
    }

    _addActiveRequest(method);

    try {
      final connection = Web3Utils.findConnected(
        _currentDomain,
        appState.connections,
      );

      if (connection == null) {
        _removeActiveRequest(method);
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
        _removeActiveRequest(method);
        return _returnError(
          message.uuid,
          Web3EIP1193ErrorCode.invalidInput,
          'Invalid parameters for eth_sendTransaction',
        );
      }

      final txParams = params[0] as Map<String, dynamic>;
      final from = txParams['from'] as String?;

      if (from == null) {
        _removeActiveRequest(method);
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

      if (!connectedAddresses.contains(from.toLowerCase())) {
        _removeActiveRequest(method);
        return _returnError(
          message.uuid,
          Web3EIP1193ErrorCode.unauthorized,
          'The requested address is not authorized',
        );
      }

      String? title = await webViewController.getTitle();

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

      FTokenInfo? mbToken = appState.wallet?.tokens
          .firstWhere((t) => t.addrType == 1 && t.native);

      if (mbToken == null) {
        _removeActiveRequest(method);
        return _returnError(
          message.uuid,
          Web3EIP1193ErrorCode.internalError,
          'No native token found',
        );
      }

      final BigInt valueAmount = value != null && value != '0x0'
          ? BigInt.parse(value.replaceFirst('0x', ''), radix: 16)
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
        icon: message.icon,
        title: title ?? "EVM Transaction",
        signer: null,
        tokenInfo: tokenInfo,
      );

      final transactionRequest = TransactionRequestInfo(
        metadata: metadata,
        scilla: null,
        evm: evmRequest,
      );

      if (appState.account?.addrType == 0 && appState.chain?.slip44 == 313) {
        await zilliqaSwapChain(
          walletIndex: BigInt.from(appState.selectedWallet),
          accountIndex: appState.wallet!.selectedAccount,
        );
        await appState.syncData();
      }

      if (!context.mounted) {
        _removeActiveRequest(method);
        return;
      }

      showConfirmTransactionModal(
        context: context,
        tx: transactionRequest,
        to: to ?? "",
        colors: connection.colors,
        token: mbToken,
        amount: fromWei(
          value: valueAmount.toString(),
          decimals: mbToken.decimals,
        ).toString(),
        onConfirm: (tx) {
          _sendResponse(
            type: 'ZILPAY_RESPONSE',
            uuid: message.uuid,
            result: tx.transactionHash,
          );
          if (context.mounted) {
            Navigator.pop(context);
          }
          _removeActiveRequest(method);
        },
        onDismiss: () {
          _returnError(
            message.uuid,
            Web3EIP1193ErrorCode.userRejectedRequest,
            'User rejected the request',
          );
          _removeActiveRequest(method);
        },
      );
    } catch (e) {
      _removeActiveRequest(method);
      dev.log('Error in eth_sendTransaction: $e', name: 'web3_handler');
      _returnError(
        message.uuid,
        Web3EIP1193ErrorCode.internalError,
        'Error processing eth_sendTransaction: $e',
      );
    }
  }

  Future<void> _handleWalletGetPermissions(
    ZilPayWeb3Message message,
    AppState appState,
  ) async {
    try {
      await appState.syncConnections();
      final connection =
          Web3Utils.findConnected(_currentDomain, appState.connections);

      if (connection == null) {
        return _sendResponse(
          type: 'ZILPAY_RESPONSE',
          uuid: message.uuid,
          result: [],
        );
      }

      final addresses = await _getWalletAddresses(appState);
      final connectedAddr =
          filterByIndexes(addresses, connection.accountIndexes);

      _sendResponse(
        type: 'ZILPAY_RESPONSE',
        uuid: message.uuid,
        result: [
          {
            'parentCapability': 'eth_accounts',
            'caveats': [
              {
                'type': 'filterResponse',
                'value': connectedAddr,
              }
            ],
          }
        ],
      );
    } catch (e) {
      dev.log('Error in wallet_getPermissions: $e', name: 'web3_handler');
      _returnError(
        message.uuid,
        Web3EIP1193ErrorCode.internalError,
        'Error processing wallet_getPermissions: $e',
      );
    }
  }

  Future<void> _handleWalletRequestPermissions(
    ZilPayWeb3Message message,
    BuildContext context,
    AppState appState,
  ) async {
    final method = message.payload['method'] as String;

    if (_isRequestActive(method)) {
      return _returnError(
        message.uuid,
        Web3EIP1193ErrorCode.resourceUnavailable,
        'A similar request is already being processed',
      );
    }

    _addActiveRequest(method);

    try {
      final params = message.payload['params'] as List<dynamic>?;
      if (params == null ||
          params.isEmpty ||
          params[0] is! Map<String, dynamic>) {
        _removeActiveRequest(method);
        return _returnError(
          message.uuid,
          Web3EIP1193ErrorCode.invalidInput,
          'Invalid parameters for wallet_requestPermissions',
        );
      }

      final requestParams = params[0] as Map<String, dynamic>;

      if (!requestParams.containsKey('eth_accounts')) {
        _removeActiveRequest(method);
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
          appState.wallet?.accounts.length ==
              connection.accountIndexes.length) {
        _removeActiveRequest(method);
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

      String? title = await webViewController.getTitle();

      if (appState.account?.addrType == 0 && appState.chain?.slip44 == 313) {
        await zilliqaSwapChain(
          walletIndex: BigInt.from(appState.selectedWallet),
          accountIndex: appState.wallet!.selectedAccount,
        );
        await appState.syncData();
      }

      if (!context.mounted) {
        _removeActiveRequest(method);
        return;
      }

      showAppConnectModal(
        context: context,
        title: title ?? "",
        uuid: message.uuid,
        iconUrl: message.icon ?? "",
        onReject: () {
          _returnError(
            message.uuid,
            Web3EIP1193ErrorCode.userRejectedRequest,
            'User rejected the request',
          );
          _removeActiveRequest(method);
        },
        onConfirm: (selectedIndices) async {
          try {
            if (selectedIndices.isEmpty) {
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
          } finally {
            _removeActiveRequest(method);
          }
        },
      );
    } catch (e) {
      _removeActiveRequest(method);
      dev.log('Error in wallet_requestPermissions: $e', name: 'web3_handler');
      _returnError(
        message.uuid,
        Web3EIP1193ErrorCode.internalError,
        'Error processing wallet_requestPermissions: $e',
      );
    }
  }

  Future<void> _handleEthSignTypedDataV4(
    ZilPayWeb3Message message,
    BuildContext context,
    AppState appState,
  ) async {
    final method = message.payload['method'] as String;

    if (_isRequestActive(method)) {
      return _returnError(
        message.uuid,
        Web3EIP1193ErrorCode.resourceUnavailable,
        'A similar request is already being processed',
      );
    }

    _addActiveRequest(method);

    try {
      final connection =
          Web3Utils.findConnected(_currentDomain, appState.connections);
      if (connection == null) {
        _removeActiveRequest(method);
        return _returnError(
          message.uuid,
          Web3EIP1193ErrorCode.unauthorized,
          'This domain is not connected. Please connect first.',
        );
      }

      final params = message.payload['params'] as List<dynamic>?;
      if (params == null || params.length < 2) {
        _removeActiveRequest(method);
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
        _removeActiveRequest(method);
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
      final isAuthorized = connectedAddresses
          .any((a) => a.toLowerCase() == normalizedAddress.toLowerCase());

      if (!isAuthorized) {
        _removeActiveRequest(method);
        return _returnError(
          message.uuid,
          Web3EIP1193ErrorCode.unauthorized,
          'The requested address is not authorized',
        );
      }

      if (appState.account?.addrType == 0 && appState.chain?.slip44 == 313) {
        await zilliqaSwapChain(
          walletIndex: BigInt.from(appState.selectedWallet),
          accountIndex: appState.wallet!.selectedAccount,
        );
        await appState.syncData();
      }

      String? title = await webViewController.getTitle();

      if (!context.mounted) {
        _removeActiveRequest(method);
        return;
      }

      showSignMessageModal(
        context: context,
        typedData: typedDataeip712,
        onMessageSigned: (pubkey, sig) async {
          await _sendResponse(
            type: 'ZILPAY_RESPONSE',
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
            Web3EIP1193ErrorCode.userRejectedRequest,
            'User rejected',
          );
          _removeActiveRequest(method);
        },
        appTitle: title ?? 'Sign Typed Data',
        appIcon: message.icon ?? '',
      );
    } catch (e) {
      _removeActiveRequest(method);
      dev.log('Error in eth_signTypedData_v4: $e', name: 'web3_handler');
      _returnError(
        message.uuid,
        Web3EIP1193ErrorCode.internalError,
        'Error processing eth_signTypedData_v4: $e',
      );
    }
  }

  Future<void> _handleWalletWatchAsset(
    ZilPayWeb3Message message,
    BuildContext context,
    AppState appState,
  ) async {
    final method = message.payload['method'] as String;

    if (_isRequestActive(method)) {
      return _returnError(
        message.uuid,
        Web3EIP1193ErrorCode.resourceUnavailable,
        'A similar request is already being processed',
      );
    }

    _addActiveRequest(method);

    try {
      final connection =
          Web3Utils.findConnected(_currentDomain, appState.connections);
      if (connection == null) {
        _removeActiveRequest(method);
        return _returnError(
          message.uuid,
          Web3EIP1193ErrorCode.unauthorized,
          'This domain is not authorized to suggest tokens.',
        );
      }

      final params = message.payload['params'] as Map<String, dynamic>?;
      if (params == null || params['type'] != 'ERC20') {
        _removeActiveRequest(method);
        return _returnError(
          message.uuid,
          Web3EIP1193ErrorCode.invalidInput,
          'Invalid parameters for wallet_watchAsset. Expected ERC20 token type.',
        );
      }

      final options = params['options'] as Map<String, dynamic>?;
      if (options == null ||
          !options.containsKey('address') ||
          !options.containsKey('symbol') ||
          !options.containsKey('decimals')) {
        _removeActiveRequest(method);
        return _returnError(
          message.uuid,
          Web3EIP1193ErrorCode.invalidInput,
          'Missing required fields: address, symbol, or decimals.',
        );
      }

      final tokenAddress = options['address'] as String;
      final tokenSymbol = options['symbol'] as String;
      final tokenImage = options['image'] as String?;

      final tokenExists = appState.wallet?.tokens.any((t) =>
          t.addr.toLowerCase() == tokenAddress.toLowerCase() &&
          t.addrType == 1);

      if (tokenExists == true) {
        _removeActiveRequest(method);
        return _sendResponse(
          type: 'ZILPAY_RESPONSE',
          uuid: message.uuid,
          result: true,
        );
      }

      String? title = await webViewController.getTitle();

      if (appState.account?.addrType == 0 && appState.chain?.slip44 == 313) {
        await zilliqaSwapChain(
          walletIndex: BigInt.from(appState.selectedWallet),
          accountIndex: appState.wallet!.selectedAccount,
        );
        await appState.syncData();
      }

      if (!context.mounted) {
        _removeActiveRequest(method);
        return;
      }

      showWatchAssetModal(
        context: context,
        appTitle: title ?? "",
        appIcon: message.icon ?? "",
        tokenAddress: tokenAddress,
        tokenName: tokenSymbol,
        tokenSymbol: tokenSymbol,
        tokenIconUrl: tokenImage ?? appState.wallet?.tokens.first.logo,
        onConfirm: (ftoken) async {
          await addFtoken(
            meta: ftoken,
            walletIndex: BigInt.from(appState.selectedWallet),
          );
          _sendResponse(
            type: 'ZILPAY_RESPONSE',
            uuid: message.uuid,
            result: true,
          );
          await appState.syncData();
          _removeActiveRequest(method);
        },
        onCancel: () {
          _sendResponse(
            type: 'ZILPAY_RESPONSE',
            uuid: message.uuid,
            result: false,
          );
          _removeActiveRequest(method);
        },
      );
    } catch (e) {
      _removeActiveRequest(method);
      dev.log('Error in wallet_watchAsset: $e', name: 'web3_handler');
      _returnError(
        message.uuid,
        Web3EIP1193ErrorCode.internalError,
        'Error processing wallet_watchAsset: $e',
      );
    }
  }

  Future<void> _handleWalletAddEthereumChain(
    ZilPayWeb3Message message,
    BuildContext context,
    AppState appState,
  ) async {
    final method = message.payload['method'] as String;

    if (_isRequestActive(method)) {
      return _returnError(
        message.uuid,
        Web3EIP1193ErrorCode.resourceUnavailable,
        'A similar request is already being processed',
      );
    }

    _addActiveRequest(method);

    try {
      final params = message.payload['params'] as List<dynamic>?;
      if (params == null ||
          params.isEmpty ||
          params[0] is! Map<String, dynamic>) {
        _removeActiveRequest(method);
        return _returnError(
          message.uuid,
          Web3EIP1193ErrorCode.invalidInput,
          'Invalid parameters for wallet_addEthereumChain',
        );
      }

      final chainParams = params[0] as Map<String, dynamic>;

      if (!chainParams.containsKey('chainId') ||
          !chainParams.containsKey('chainName') ||
          !chainParams.containsKey('nativeCurrency') ||
          !chainParams.containsKey('rpcUrls') ||
          !chainParams.containsKey('blockExplorerUrls')) {
        _removeActiveRequest(method);
        return _returnError(
          message.uuid,
          Web3EIP1193ErrorCode.invalidInput,
          'Missing required fields for wallet_addEthereumChain',
        );
      }

      final rpcUrls = (chainParams['rpcUrls'] as List<dynamic>)
          .where((url) => url is String && url.startsWith('https'))
          .cast<String>()
          .toList();

      if (rpcUrls.isEmpty) {
        _removeActiveRequest(method);
        return _returnError(
          message.uuid,
          Web3EIP1193ErrorCode.invalidInput,
          'No valid HTTP RPC URLs provided',
        );
      }

      final nativeCurrency =
          chainParams['nativeCurrency'] as Map<String, dynamic>;
      final chainId = BigInt.parse(
          chainParams['chainId'].toString().replaceFirst('0x', ''),
          radix: 16);
      final explorers = (chainParams['blockExplorerUrls'] as List<dynamic>)
          .map((url) => ExplorerInfo(name: 'Explorer', url: url, standard: 0))
          .toList();
      final symbol = nativeCurrency['symbol'].toString();
      final name = nativeCurrency['name'].toString();

      NetworkConfigInfo? foundChain;

      if (appState.state.providers.any((c) => c.chainId == chainId)) {
        final chain =
            appState.state.providers.firstWhere((c) => c.chainId == chainId);

        chain.rpc.addAll(rpcUrls);

        foundChain = chain;
      } else {
        final String mainnetJsonData =
            await rootBundle.loadString('assets/chains/mainnet-chains.json');
        final List<NetworkConfigInfo> mainnetChains =
            await getChainsProvidersFromJson(jsonStr: mainnetJsonData);

        if (mainnetChains.any((c) => c.chainId == chainId)) {
          final chain = mainnetChains.firstWhere((c) => c.chainId == chainId);

          chain.rpc.addAll(rpcUrls.map((v) => v));

          foundChain = chain;
        }
      }
      String logo =
          "https://static.cx.metamask.io/api/v1/tokenIcons/$chainId/$zeroEVM.png";

      foundChain ??= NetworkConfigInfo(
        ftokens: [
          FTokenInfo(
            logo: logo,
            name: name,
            symbol: symbol,
            decimals: 18,
            addr: zeroEVM,
            addrType: 1,
            balances: {},
            rate: 0,
            default_: false,
            native: true,
            chainHash: BigInt.zero,
          )
        ],
        name: chainParams['chainName'] as String,
        logo: logo,
        chain: chainParams['chainName'] as String,
        shortName: symbol,
        rpc: rpcUrls,
        features: Uint16List.fromList([155, 1559, 4844]),
        chainId: chainId,
        chainIds: Uint64List.fromList([chainId, 0]),
        slip44: 60,
        diffBlockTime: BigInt.zero,
        chainHash: BigInt.zero,
        explorers: explorers,
        fallbackEnabled: true,
        testnet: name.toLowerCase().contains("test"),
      );

      foundChain = foundChain.copyWith(
        rpc: foundChain.rpc.toSet().toList(),
      );
      String? title = await webViewController.getTitle();

      if (!context.mounted) {
        _removeActiveRequest(method);
        return;
      }

      showAddChainModal(
        context: context,
        title: title ?? "",
        appIcon: message.icon ?? '',
        chain: foundChain,
        onConfirm: (selectedRpc) async {
          try {
            foundChain = foundChain!.copyWith(
              rpc: selectedRpc,
            );
            await createOrUpdateChain(providerConfig: foundChain!);
            _sendResponse(
              type: 'ZILPAY_RESPONSE',
              uuid: message.uuid,
              result: null,
            );
          } catch (e) {
            debugPrint("add network error: $e");
            _returnError(
              message.uuid,
              Web3EIP1193ErrorCode.userRejectedRequest,
              e.toString(),
            );
          } finally {
            _removeActiveRequest(method);
          }
        },
        onReject: () {
          _returnError(
            message.uuid,
            Web3EIP1193ErrorCode.userRejectedRequest,
            'User rejected the request',
          );
          _removeActiveRequest(method);
        },
      );
    } catch (e) {
      _removeActiveRequest(method);
      dev.log('Error in wallet_addEthereumChain: $e', name: 'web3_handler');
      _returnError(
        message.uuid,
        Web3EIP1193ErrorCode.internalError,
        'Error processing wallet_addEthereumChain: $e',
      );
    }
  }

  Future<void> _handleWalletSwitchEthereumChain(
    ZilPayWeb3Message message,
    BuildContext context,
    AppState appState,
  ) async {
    final method = message.payload['method'] as String;

    if (_isRequestActive(method)) {
      return _returnError(
        message.uuid,
        Web3EIP1193ErrorCode.resourceUnavailable,
        'A similar request is already being processed',
      );
    }

    _addActiveRequest(method);

    try {
      final params = message.payload['params'] as List<dynamic>?;
      if (params == null ||
          params.isEmpty ||
          params[0] is! Map<String, dynamic>) {
        _removeActiveRequest(method);
        return _returnError(
          message.uuid,
          Web3EIP1193ErrorCode.invalidInput,
          'Invalid parameters for wallet_switchEthereumChain',
        );
      }

      final chainParams = params[0] as Map<String, dynamic>;
      if (!chainParams.containsKey('chainId')) {
        _removeActiveRequest(method);
        return _returnError(
          message.uuid,
          Web3EIP1193ErrorCode.invalidInput,
          'Missing required field: chainId',
        );
      }

      final chainId = BigInt.parse(
        chainParams['chainId'].toString().replaceFirst('0x', ''),
        radix: 16,
      );

      if (appState.account?.addrType == 0 && appState.chain?.slip44 == 313) {
        await zilliqaSwapChain(
          walletIndex: BigInt.from(appState.selectedWallet),
          accountIndex: appState.wallet!.selectedAccount,
        );
        await appState.syncData();
      }

      NetworkConfigInfo? targetNetwork;
      final List<NetworkConfigInfo> providers = appState.state.providers;

      for (final provider in providers) {
        if (provider.chainId == chainId &&
            !(provider.slip44 == 313 && provider.chainId == BigInt.one)) {
          targetNetwork = provider;
          break;
        }
      }

      if (targetNetwork == null) {
        final String mainnetJsonData =
            await rootBundle.loadString('assets/chains/mainnet-chains.json');
        final String testnetJsonData =
            await rootBundle.loadString('assets/chains/testnet-chains.json');
        final List<NetworkConfigInfo> mainnetChains =
            await getChainsProvidersFromJson(jsonStr: mainnetJsonData);
        final List<NetworkConfigInfo> testnetChains =
            await getChainsProvidersFromJson(jsonStr: testnetJsonData);

        for (final chain in mainnetChains) {
          if (chain.chainId == chainId &&
              !(chain.slip44 == 313 && chain.chainId == BigInt.one)) {
            targetNetwork = chain;
            break;
          }
        }

        if (targetNetwork == null) {
          for (final chain in testnetChains) {
            if (chain.chainId == chainId &&
                !(chain.slip44 == 313 && chain.chainId == BigInt.one)) {
              targetNetwork = chain;
              break;
            }
          }
        }

        if (targetNetwork != null) {
          await addProvider(providerConfig: targetNetwork);
          await appState.syncData();
        } else {
          _removeActiveRequest(method);
          return _returnError(
            message.uuid,
            Web3EIP1193ErrorCode.chainNotAdded,
            'The requested chain has not been added. Use wallet_addEthereumChain first.',
          );
        }
      }

      final connection =
          Web3Utils.findConnected(_currentDomain, appState.connections);

      if (connection != null) {
        await selectAccountsChain(
          walletIndex: BigInt.from(appState.selectedWallet),
          chainHash: targetNetwork.chainHash,
        );
        await appState.syncData();

        _sendResponse(
          type: 'ZILPAY_RESPONSE',
          uuid: message.uuid,
          result: null,
        );
        _removeActiveRequest(method);
      } else {
        showSwitchChainNetworkModal(
          context: context,
          selectedChainId: chainId,
          onNetworkSelected: () {
            _sendResponse(
              type: 'ZILPAY_RESPONSE',
              uuid: message.uuid,
              result: null,
            );
            _removeActiveRequest(method);
          },
          onReject: () {
            _returnError(
              message.uuid,
              Web3EIP1193ErrorCode.userRejectedRequest,
              'User rejected the request',
            );
            _removeActiveRequest(method);
          },
        );
      }
    } catch (e) {
      _removeActiveRequest(method);
      _returnError(
        message.uuid,
        Web3EIP1193ErrorCode.internalError,
        'Error processing wallet_switchEthereumChain: $e',
      );
    }
  }
}
