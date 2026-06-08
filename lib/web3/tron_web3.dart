import 'dart:convert';
import 'package:bearby/config/eip1193.dart';
import 'package:bearby/config/tip1193.dart';
import 'package:bearby/modals/app_connect.dart';
import 'package:bearby/modals/sign_message.dart';
import 'package:bearby/modals/swich_chain_modal.dart';
import 'package:bearby/modals/transfer.dart';
import 'package:bearby/src/rust/api/connections.dart';
import 'package:bearby/src/rust/api/provider.dart';
import 'package:bearby/src/rust/api/utils.dart';
import 'package:bearby/src/rust/models/connection.dart';
import 'package:bearby/src/rust/models/ftoken.dart';
import 'package:bearby/src/rust/models/provider.dart';
import 'package:bearby/src/rust/models/transactions/base_token.dart';
import 'package:bearby/src/rust/models/transactions/request.dart';
import 'package:bearby/src/rust/models/transactions/transaction_metadata.dart';
import 'package:bearby/src/rust/models/transactions/tron.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:provider/provider.dart';
import 'package:bearby/config/web3_constants.dart';
import 'package:bearby/l10n/app_localizations.dart';
import 'package:bearby/state/app_state.dart';
import 'package:bearby/web3/message.dart';
import 'package:bearby/web3/web3_utils.dart';

Map<String, Object?> _asObjectMap(Object? value, String label) {
  if (value is Map) {
    return Map<String, Object?>.from(value);
  }
  throw FormatException('Invalid TRON transaction $label');
}

String _stringField(Map<String, Object?> map, String key, String fallbackKey) {
  final value = map[key] ?? map[fallbackKey];
  if (value is String) return value;
  throw FormatException('Invalid TRON transaction field: $key');
}

PlatformInt64 _int64Field(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is int) {
    return value;
  }
  if (value is BigInt) {
    return value.toInt();
  }
  if (value is String) {
    final parsed = int.tryParse(value);
    if (parsed != null) {
      return parsed;
    }
  }
  throw FormatException('Invalid TRON transaction integer: $key');
}

PlatformInt64? _optionalInt64Field(Map<String, Object?> map, String key) {
  return map.containsKey(key) && map[key] != null
      ? _int64Field(map, key)
      : null;
}

TransactionRequestTron _tronRequestFromJson(Map<String, Object?> transaction) {
  final rawData = _asObjectMap(
      transaction['raw_data'] ?? transaction['rawData'], 'raw_data');
  final rawContracts = rawData['contract'];
  if (rawContracts is! List) {
    throw const FormatException('Invalid TRON transaction contracts');
  }

  final contracts = rawContracts.map((contractObject) {
    final contract = _asObjectMap(contractObject, 'contract');
    final parameter = _asObjectMap(contract['parameter'], 'parameter');
    final typeUrl = _stringField(parameter, 'type_url', 'typeUrl');
    final value = _asObjectMap(parameter['value'], 'parameter.value');

    return TronContractInfo(
      contractType: _stringField(contract, 'type', 'contractType'),
      typeUrl: typeUrl,
      value: TronContractValue.unknown(
        typeUrl: typeUrl,
        valueJson: jsonEncode(value),
      ),
    );
  }).toList(growable: false);

  return TransactionRequestTron(
    visible: transaction['visible'] as bool?,
    txId: transaction['txID'] as String? ?? transaction['tx_id'] as String?,
    rawData: TronRawDataInfo(
      contract: contracts,
      refBlockBytes: _stringField(rawData, 'ref_block_bytes', 'refBlockBytes'),
      refBlockHash: _stringField(rawData, 'ref_block_hash', 'refBlockHash'),
      expiration: _int64Field(rawData, 'expiration'),
      feeLimit: _optionalInt64Field(rawData, 'fee_limit'),
      timestamp: _int64Field(rawData, 'timestamp'),
    ),
    rawDataHex: _stringField(transaction, 'raw_data_hex', 'rawDataHex'),
  );
}

class TronWeb3Handler {
  final InAppWebViewController webViewController;
  final AppState appState;
  bool isConnected = false;

  final Set<String> _activeRequests = {};
  String? _lastKnownAddress;
  String? _lastKnownChainId;

  TronWeb3Handler({
    required this.webViewController,
    required this.appState,
  }) {
    _lastKnownAddress = appState.account?.addr;
    _lastKnownChainId = appState.chain?.chainId.toString();
    appState.addListener(_handleAppStateChange);
  }

  void dispose() {
    appState.removeListener(_handleAppStateChange);
  }

  Future<String> _getCurrentDomain() async {
    final url = await webViewController.getUrl();
    if (url == null || url.host.isEmpty) {
      throw Exception('Unable to determine current page domain');
    }
    return url.host;
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
        eventName: kAccountsChangedEvent,
        data: addresses,
      );
    }

    if (newChain != null && newChain.chainId.toString() != _lastKnownChainId) {
      _lastKnownChainId = newChain.chainId.toString();
      await _sendNotification(
        eventName: kChainChangedEvent,
        data: {'chainId': newChain.chainId.toString()},
      );
    }
  }

  Future<void> _sendResponse({
    required String type,
    required String uuid,
    dynamic result,
    TronWeb3ErrorCode? errorCode,
    String? errorMessage,
  }) async {
    final responsePayload = <String, dynamic>{
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
      case Web3EIP1193Method.tronSign:
      case Web3EIP1193Method.ethSendTransaction:
        await _handlhSendTransaction(message, context, appState);
        break;
      case Web3EIP1193Method.ethChainId:
        await _handleChainId(message, appState);
        break;
      case Web3EIP1193Method.getInitProviderData:
      case Web3EIP1193Method.init:
        await _handleGetInitProviderData(message, context);
        break;
      case Web3EIP1193Method.ethRequestAccounts:
      case Web3EIP1193Method.tronRequestAccounts:
      case Web3EIP1193Method.ethAccounts:
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
      case Web3EIP1193Method.multiSign:
        await _handleMultiSign(message, context, appState);
        break;
      case Web3EIP1193Method.tronSignTypedData:
      case Web3EIP1193Method.tronSignTypedDataV2:
        await _handleSignTypedData(message, context, appState);
        break;
      case Web3EIP1193Method.tronProviderRequest:
        final chain = appState.chain;
        await _proxyRpcRequest(
          method: (message.payload['payload'] as Map<String, dynamic>?)?['method'] as String? ?? method ?? '',
          uuid: message.uuid,
          params: (message.payload['payload'] as Map<String, dynamic>?)?['params'],
          chainHash: chain?.chainHash ?? BigInt.zero,
        );
        break;
      case Web3EIP1193Method.walletSwitchEthereumChain:
        await _handleWalletSwitchChain(message, context, appState);
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

  Future<void> _handlhSendTransaction(
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
    final l10n = AppLocalizations.of(context);

    try {
      final currentDomain = await _getCurrentDomain();
      final connection =
          Web3Utils.findConnected(currentDomain, appState.connections);

      if (connection == null) {
        _removeActiveRequest(method);
        return _returnError(
          message.uuid,
          TronWeb3ErrorCode.unauthorized,
          l10n?.web3ErrorNotConnected ?? '',
        );
      }

      final params = message.payload['params'] as Map<String, dynamic>?;

      if (params == null || params.isEmpty) {
        _removeActiveRequest(method);
        return _returnError(
          message.uuid,
          TronWeb3ErrorCode.invalidInput,
          'Invalid parameters for eth_sendTransaction',
        );
      }

      final Map<String, dynamic> transaction = params['transaction'];
      final txParams = transaction['raw_data'] as Map<String, dynamic>;

      final Map<String, dynamic> contract = txParams['contract'][0];
      final Map<String, dynamic> value = contract['parameter']['value'];
      final String to = value['to_address'] ?? "";
      final int? amount = value['amount'];
      final BigInt valueAmount = BigInt.from(amount ?? 0);
      final FTokenInfo? mbToken = appState.wallet?.tokens.first;
      String? title = await webViewController.getTitle();

      if (mbToken == null) {
        _removeActiveRequest(method);
        return _returnError(
          message.uuid,
          TronWeb3ErrorCode.internalError,
          l10n?.web3ErrorNoNativeToken ?? '',
        );
      }

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
        title: title ?? "",
        signer: appState.account?.addr,
        tokenInfo: tokenInfo,
        broadcast: false,
      );
      final transactionRequest = TransactionRequestInfo(
        metadata: metadata,
        scilla: null,
        evm: null,
        tron: _tronRequestFromJson(transaction),
      );

      if (!context.mounted) {
        _removeActiveRequest(method);
        return;
      }

      showConfirmTransactionModal(
        context: context,
        tx: transactionRequest,
        to: to,
        colors: connection.colors,
        token: mbToken,
        amount: fromWei(
          value: valueAmount.toString(),
          decimals: mbToken.decimals,
        ).toString(),
        onConfirm: (tx) {
          _sendResponse(
            type: kBearbyResponseType,
            uuid: message.uuid,
            result: tx.tron,
          );
          if (context.mounted) {
            Navigator.pop(context);
          }
          _removeActiveRequest(method);
        },
        onDismiss: () {
          _returnError(
            message.uuid,
            TronWeb3ErrorCode.userRejected,
            AppLocalizations.of(context)?.web3ErrorUserRejectedRequest ?? '',
          );
          _removeActiveRequest(method);
        },
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
      final currentDomain = await _getCurrentDomain();
      final connection =
          Web3Utils.findConnected(currentDomain, appState.connections);

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
      final currentDomain = await _getCurrentDomain();
      final connection = Web3Utils.findConnected(
        currentDomain,
        appState.connections,
      );

      final addresses = await _getWalletAddresses(appState);

      if (connection != null &&
          appState.accounts.length == connection.accountIndexes.length) {
        _removeActiveRequest(method);

        await _sendNotification(eventName: 'dataChanged', data: {
          'address': addresses.first,
          'name': appState.account?.name,
          'type': 0,
          'isAuth': true,
          'chainId': '0x${appState.chain?.chainId.toRadixString(16)}',
        });

        final isTronMethod =
            method == Web3EIP1193Method.tronRequestAccounts.value;
        return _sendResponse(
          type: kBearbyResponseType,
          uuid: message.uuid,
          result: isTronMethod ? {'code': 200, 'message': 'OK'} : addresses,
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
          _returnError(
            message.uuid,
            TronWeb3ErrorCode.userRejected,
            'Error Rejected',
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
              domain: currentDomain,
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
              walletIndex: appState.selectedWalletIndex,
              conn: connectionInfo,
            );
            await appState.syncConnections();

            final connectedAddr = filterByIndexes(addresses, accountIndexes);
            final isTronMethod =
                method == Web3EIP1193Method.tronRequestAccounts.value;

            await _sendNotification(eventName: 'dataChanged', data: {
              'address': connectedAddr.first,
              'name': appState.account?.name,
              'type': 0,
              'isAuth': true,
              'chainId': '0x${appState.chain?.chainId.toRadixString(16)}',
            });

            await _sendResponse(
              type: kBearbyResponseType,
              uuid: message.uuid,
              result:
                  isTronMethod ? {'code': 200, 'message': 'OK'} : connectedAddr,
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

  Future<void> _handleWalletSwitchChain(
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
    final l10n = AppLocalizations.of(context);

    try {
      final params = message.payload['params'] as List<dynamic>?;
      if (params == null ||
          params.isEmpty ||
          params[0] is! Map<String, dynamic>) {
        _removeActiveRequest(method);
        return _returnError(
          message.uuid,
          TronWeb3ErrorCode.invalidInput,
          'Invalid parameters for wallet_switchEthereumChain',
        );
      }

      final chainParams = params[0] as Map<String, dynamic>;
      if (!chainParams.containsKey(kParamChainId)) {
        _removeActiveRequest(method);
        return _returnError(
          message.uuid,
          TronWeb3ErrorCode.invalidInput,
          l10n?.web3ErrorMissingChainId ?? '',
        );
      }

      final chainId = BigInt.parse(
        chainParams[kParamChainId].toString().replaceFirst(kHexPrefix, ''),
        radix: kHexRadix,
      );

      NetworkConfigInfo? targetNetwork;
      final List<NetworkConfigInfo> providers = appState.state.providers;

      for (final provider in providers) {
        if (provider.slip44 == kBitcoinlip44) {
          continue;
        }

        if (provider.chainId == chainId) {
          targetNetwork = provider;
          break;
        }
      }

      if (targetNetwork == null) {
        final String mainnetJsonData =
            await rootBundle.loadString(kMainnetChainsPath);
        final String testnetJsonData =
            await rootBundle.loadString(kTestnetChainsPath);
        final (mainnetChains, testnetChains) = await getNetworks(
            mainnetJson: mainnetJsonData, testnetJson: testnetJsonData);

        for (final chain in mainnetChains) {
          if (chain.chainId == chainId &&
              !(chain.slip44 == kZilliqaSlip44 &&
                  chain.chainId == kZilliqaChainId)) {
            targetNetwork = chain;
            break;
          }
        }

        if (targetNetwork == null) {
          for (final chain in testnetChains) {
            if (chain.chainId == chainId &&
                !(chain.slip44 == kZilliqaSlip44 &&
                    chain.chainId == kZilliqaChainId)) {
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
            TronWeb3ErrorCode.unauthorized,
            l10n?.web3ErrorChainNotAdded ?? '',
          );
        }
      }

      if (!context.mounted) {
        _removeActiveRequest(method);
        return;
      }

      showSwitchChainNetworkModal(
        context: context,
        selectedChainId: chainId,
        filtersBySlip44: [60, 195],
        onNetworkSelected: () {
          _sendResponse(
            type: kBearbyResponseType,
            uuid: message.uuid,
            result: null,
          );
          _removeActiveRequest(method);
        },
        onReject: () {
          _returnError(
            message.uuid,
            TronWeb3ErrorCode.userRejected,
            AppLocalizations.of(context)?.web3ErrorUserRejectedRequest ?? '',
          );
          _removeActiveRequest(method);
        },
      );
    } catch (e) {
      _removeActiveRequest(method);
      _returnError(
        message.uuid,
        TronWeb3ErrorCode.internalError,
        'Error processing wallet_switchEthereumChain: $e',
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

      final currentDomain = await _getCurrentDomain();
      final connection = Web3Utils.findConnected(
        currentDomain,
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

  Future<void> _handleMultiSign(
    ZilPayWeb3Message message,
    BuildContext context,
    AppState appState,
  ) async {
    const method = 'multiSign';

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
      final currentDomain = await _getCurrentDomain();
      final connection =
          Web3Utils.findConnected(currentDomain, appState.connections);

      if (connection == null) {
        _removeActiveRequest(method);
        return _returnError(
          message.uuid,
          TronWeb3ErrorCode.unauthorized,
          l10n?.web3ErrorNotConnected ?? '',
        );
      }

      final params = message.payload['params'] as Map<String, dynamic>?;
      if (params == null || params['transaction'] == null) {
        _removeActiveRequest(method);
        return _returnError(
          message.uuid,
          TronWeb3ErrorCode.invalidInput,
          l10n?.web3ErrorInvalidParams(method, '') ?? '',
        );
      }

      final Map<String, dynamic> transaction =
          params['transaction'] as Map<String, dynamic>;
      final txParams = transaction['raw_data'] as Map<String, dynamic>;
      final Map<String, dynamic> contract = txParams['contract'][0];
      final Map<String, dynamic> value = contract['parameter']['value'];
      final String to = value['to_address'] ?? '';
      final int? amount = value['amount'];
      final BigInt valueAmount = BigInt.from(amount ?? 0);
      final FTokenInfo? mbToken = appState.wallet?.tokens.first;
      String? title = await webViewController.getTitle();

      if (mbToken == null) {
        _removeActiveRequest(method);
        return _returnError(
          message.uuid,
          TronWeb3ErrorCode.internalError,
          l10n?.web3ErrorNoNativeToken ?? '',
        );
      }

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
        title: title ?? '',
        signer: appState.account?.addr,
        tokenInfo: tokenInfo,
        broadcast: false,
      );
      final transactionRequest = TransactionRequestInfo(
        metadata: metadata,
        scilla: null,
        evm: null,
        tron: _tronRequestFromJson(transaction),
      );

      if (!context.mounted) {
        _removeActiveRequest(method);
        return;
      }

      showConfirmTransactionModal(
        context: context,
        tx: transactionRequest,
        to: to,
        colors: connection.colors,
        token: mbToken,
        amount: fromWei(
          value: valueAmount.toString(),
          decimals: mbToken.decimals,
        ).toString(),
        onConfirm: (tx) {
          _sendResponse(
            type: kBearbyResponseType,
            uuid: message.uuid,
            result: tx.tron,
          );
          if (context.mounted) Navigator.pop(context);
          _removeActiveRequest(method);
        },
        onDismiss: () {
          _returnError(
            message.uuid,
            TronWeb3ErrorCode.userRejected,
            AppLocalizations.of(context)?.web3ErrorUserRejectedRequest ?? '',
          );
          _removeActiveRequest(method);
        },
      );
    } catch (e) {
      _removeActiveRequest(method);
      debugPrint('Error in multiSign: $e');
      _returnError(
        message.uuid,
        TronWeb3ErrorCode.internalError,
        'Error processing multiSign: $e',
      );
    }
  }

  Future<void> _handleSignTypedData(
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
    final l10n = AppLocalizations.of(context);

    try {
      final currentDomain = await _getCurrentDomain();
      final connection =
          Web3Utils.findConnected(currentDomain, appState.connections);

      if (connection == null) {
        _removeActiveRequest(method);
        return _returnError(
          message.uuid,
          TronWeb3ErrorCode.unauthorized,
          l10n?.web3ErrorNotConnected ?? '',
        );
      }

      final params = message.payload['params'] as Map<String, dynamic>?;
      if (params == null) {
        _removeActiveRequest(method);
        return _returnError(
          message.uuid,
          TronWeb3ErrorCode.invalidInput,
          l10n?.web3ErrorInvalidParams(method, '') ?? '',
        );
      }

      final dataToSign = jsonEncode(params['message'] ?? params);

      if (!context.mounted) {
        _removeActiveRequest(method);
        return;
      }

      showSignMessageModal(
        context: context,
        message: dataToSign,
        onMessageSigned: (pubkey, sig) async {
          await _sendResponse(
            type: kBearbyResponseType,
            uuid: message.uuid,
            result: sig,
          );
          _removeActiveRequest(method);
          if (context.mounted) Navigator.pop(context);
        },
        onDismiss: () {
          _returnError(
            message.uuid,
            TronWeb3ErrorCode.internalError,
            AppLocalizations.of(context)?.web3ErrorUserRejected ?? '',
          );
          _removeActiveRequest(method);
        },
        appTitle: '',
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

  Future<List<String>> _getWalletAddresses(AppState appState) async {
    List<String> addresses = [];
    final selectedAccountIndex = appState.wallet?.selectedAccount.toInt();

    addresses = (appState.accounts).map((a) => a.addr).toList();

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
