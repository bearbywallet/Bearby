// lib/web3/zilpay_evm.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:zilpay/state/app_state.dart';
import 'package:zilpay/config/evm_messages.dart';
import 'package:zilpay/modals/app_connect.dart';
import 'package:zilpay/modals/sign_message.dart';
import 'package:zilpay/modals/transfer.dart';
import 'package:zilpay/web3/web3_utils.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';

class ZilPayEVMHandler {
  final WebViewController webViewController;
  final String initialUrl;

  ZilPayEVMHandler({
    required this.webViewController,
    required this.initialUrl,
  });

  Future<void> _sendResponse(String uuid, Map<String, dynamic> payload) async {
    final response = {
      'type': EVMMessages.response,
      'uuid': uuid,
      ...payload,
    };
    await webViewController.runJavaScript(
      'window.dispatchEvent(new CustomEvent("message", { detail: ${jsonEncode(response)} }))',
    );
  }

  Future<void> _sendErrorResponse(String uuid, String error) async {
    await _sendResponse(uuid, {'error': error});
  }

  Future<void> sendData(AppState appState) async {
    await appState.syncConnections();
    final currentDomain = Uri.parse(initialUrl).host;
    final connected =
        Web3Utils.isDomainConnected(currentDomain, appState.connections);

    if (connected != null) {
      _sendResponse('', {
        'accounts': [],
        'chainId': '0x${appState.chain?.chainIds.first.toRadixString(16)}',
      });
    } else {
      _sendResponse('', {'accounts': [], 'chainId': null});
    }
  }

  Future<void> handleEVMRequest(
    Map<String, dynamic> jsonData,
    BuildContext context,
  ) async {
    final appState = Provider.of<AppState>(context, listen: false);
    final requestId = jsonData['requestId'] as String?;
    final payload = jsonData['payload'] as Map<String, dynamic>?;

    if (requestId == null || payload == null) {
      _sendErrorResponse(requestId ?? '', 'Invalid request format');
      return;
    }

    final method = payload['method'] as String?;
    final currentDomain = Uri.parse(initialUrl).host;

    switch (method) {
      case EVMMessages.requestAccounts:
      case EVMMessages.getAccounts:
        await appState.syncConnections();
        final isConnected =
            Web3Utils.isDomainConnected(currentDomain, appState.connections);

        if (isConnected) {
          final address = await evmGetAddress(
            walletIndex: BigInt.from(appState.selectedWallet),
            accountIndex: appState.wallet!.selectedAccount,
          );
          _sendResponse(requestId, {
            'result': [address]
          });
        } else {
          final pageInfo = await Web3Utils.extractPageInfo(webViewController);
          showAppConnectModal(
            context: context,
            title: pageInfo['title'] ?? 'Unknown App',
            uuid: requestId,
            iconUrl: pageInfo['favicon'] ?? '',
            onDecision: (accepted, selectedIndices) async {
              if (accepted) {
                final walletIndexes = Uint64List.fromList(
                  selectedIndices.map((index) => BigInt.from(index)).toList(),
                );
                final connectionInfo = ConnectionInfo(
                  domain: currentDomain,
                  walletIndexes: walletIndexes,
                  favicon: pageInfo['favicon'],
                  title: pageInfo['title'],
                  description: pageInfo['description'],
                  lastConnected:
                      BigInt.from(DateTime.now().millisecondsSinceEpoch),
                  canReadAccounts: true,
                  canRequestSignatures: true,
                  canSuggestTokens: false,
                  canSuggestTransactions: true,
                );
                await createNewConnection(conn: connectionInfo);
                await appState.syncConnections();
                final address = await evmGetAddress(
                  walletIndex: BigInt.from(appState.selectedWallet),
                  accountIndex: appState.wallet!.selectedAccount,
                );
                _sendResponse(requestId, {
                  'result': [address]
                });
                _sendEvent(EVMMessages.connect, {
                  'chainId':
                      '0x${appState.chain?.chainIds.first.toRadixString(16)}'
                });
              } else {
                _sendErrorResponse(requestId, 'User rejected connection');
              }
            },
          );
        }
        break;

      case EVMMessages.personalSign:
      case EVMMessages.signMessage:
        final message = payload['params']?[0] as String? ?? '';
        final address = payload['params']?[1] as String?;
        if (message.isEmpty || address == null) {
          _sendErrorResponse(requestId, 'Invalid parameters');
          return;
        }

        showSignMessageModal(
          context: context,
          message: message,
          onMessageSigned: (pubkey, sig) async {
            final signature = '0x$sig';
            _sendResponse(requestId, {'result': signature});
            Navigator.pop(context);
          },
          onDismiss: () async {
            _sendErrorResponse(requestId, 'User rejected signature');
          },
          appTitle: 'Sign Message',
          appIcon: '',
        );
        break;

      case EVMMessages.sendTransaction:
        final txParams = payload['params']?[0] as Map<String, dynamic>?;
        if (txParams == null) {
          _sendErrorResponse(requestId, 'Invalid transaction parameters');
          return;
        }

        final from = txParams['from'] as String?;
        final to = txParams['to'] as String?;
        final value = BigInt.tryParse(
                txParams['value']?.toString().replaceFirst('0x', '') ?? '0',
                radix: 16) ??
            BigInt.zero;
        final gasPrice = BigInt.tryParse(
            txParams['gasPrice']?.toString().replaceFirst('0x', '') ?? '0',
            radix: 16);
        final gasLimit = BigInt.tryParse(
                txParams['gas']?.toString().replaceFirst('0x', '') ?? '0',
                radix: 16) ??
            BigInt.from(21000);
        final data = txParams['data'] as String? ?? '';

        final chainId = appState.chain?.chainIds.first ?? BigInt.one;
        final tokenInfo = BaseTokenInfo(
          value: value.toString(),
          symbol: 'ETH',
          decimals: 18,
        );

        final txRequest = TransactionRequestInfo(
          metadata: TransactionMetadataInfo(
            chainHash: chainId,
            hash: null,
            info: 'Transaction',
            icon: '',
            title: 'Send Transaction',
            signer: from,
            tokenInfo: tokenInfo,
          ),
          evm: TransactionRequestEVM(
            chainId: chainId.toInt(),
            nonce: BigInt.zero,
            gasPrice: gasPrice ?? BigInt.zero,
            gasLimit: gasLimit,
            toAddr: to ?? '',
            value: value,
            data: data,
          ),
          scilla: null,
        );

        showConfirmTransactionModal(
          context: context,
          tx: txRequest,
          to: to ?? '',
          tokenIndex: 0,
          amount: (value / BigInt.from(10).pow(18)).toString(),
          onConfirm: (tx) {
            _sendResponse(requestId, {'result': tx.transactionHash});
            Navigator.pop(context);
          },
          onDismiss: () {
            _sendErrorResponse(requestId, 'User rejected transaction');
          },
        );
        break;

      case EVMMessages.switchChain:
        final params = payload['params']?[0] as Map<String, dynamic>?;
        final chainIdHex = params?['chainId'] as String?;
        if (chainIdHex == null) {
          _sendErrorResponse(requestId, 'Invalid chainId');
          return;
        }
        final chainId =
            BigInt.parse(chainIdHex.replaceFirst('0x', ''), radix: 16);
        _sendResponse(requestId, {'result': null});
        _sendEvent(EVMMessages.chainChanged, {'chainId': chainIdHex});
        break;

      default:
        _sendErrorResponse(requestId, 'Unsupported method: $method');
    }
  }

  Future<void> _sendEvent(String event, Map<String, dynamic> data) async {
    final eventMessage = {
      'type': 'ZILPAY_EVENT',
      'event': event,
      'data': data,
    };
    await webViewController.runJavaScript(
      'window.dispatchEvent(new CustomEvent("message", { detail: ${jsonEncode(eventMessage)} }))',
    );
    print('Sent EVM event: $eventMessage');
  }
}
