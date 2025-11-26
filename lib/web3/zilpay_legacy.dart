import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/mixins/transaction_parsing.dart';
import 'package:zilpay/modals/sign_message.dart';
import 'package:zilpay/modals/transfer.dart';
import 'package:zilpay/src/rust/api/backend.dart';
import 'package:zilpay/src/rust/api/connections.dart';
import 'package:zilpay/src/rust/api/utils.dart';
import 'package:zilpay/src/rust/api/wallet.dart';
import 'package:zilpay/src/rust/api/provider.dart';
import 'package:zilpay/src/rust/models/connection.dart';
import 'package:zilpay/src/rust/models/ftoken.dart';
import 'package:zilpay/src/rust/models/transactions/base_token.dart';
import 'package:zilpay/src/rust/models/transactions/request.dart';
import 'package:zilpay/src/rust/models/transactions/scilla.dart';
import 'package:zilpay/src/rust/models/transactions/transaction_metadata.dart';
import 'package:zilpay/state/app_state.dart';
import 'package:zilpay/config/zilliqa_legacy_messages.dart';
import 'package:zilpay/modals/app_connect.dart';
import 'package:zilpay/web3/message.dart';
import 'package:zilpay/web3/web3_utils.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';

class ZilPayLegacyTransactionParam {
  final String vname;
  final String type;
  final String value;

  const ZilPayLegacyTransactionParam({
    required this.vname,
    required this.type,
    required this.value,
  });

  factory ZilPayLegacyTransactionParam.fromJson(Map<String, dynamic> json) =>
      ZilPayLegacyTransactionParam(
        vname: json['vname'] as String,
        type: json['type'] as String,
        value: json['value'] as String,
      );

  Map<String, String> toJson() => {
        'vname': vname,
        'type': type,
        'value': value,
      };
}

class ZilPayLegacyHandler {
  final InAppWebViewController webViewController;
  final AppState appState;
  StreamSubscription<BlockEvent>? _blockStreamSubscription;
  String? _lastKnownAddress;
  bool isConnected = false;

  ZilPayLegacyHandler({
    required this.webViewController,
    required this.appState,
  }) {
    _lastKnownAddress = appState.account?.addr;
    appState.addListener(_handleAppStateChange);
  }

  void _handleAppStateChange() async {
    final newAccount = appState.account;
    if (newAccount != null && newAccount.addr != _lastKnownAddress) {
      _lastKnownAddress = newAccount.addr;
      final accountDetails = await _getAccountIfConnected(appState);
      _sendResponse(
        type: ZilliqaLegacyMessages.addressChanged,
        payload: {
          'account': accountDetails,
          'isConnect': accountDetails != null,
          'isEnable': true,
        },
        uuid: "",
      );
    }
  }

  void dispose() {
    appState.removeListener(_handleAppStateChange);
    webViewController.dispose();
    _blockStreamSubscription?.cancel();
    stopBlockWorker();
  }

  Future<void> _sendResponse({
    required String type,
    required Map<String, Object?> payload,
    required String uuid,
  }) async {
    final response = ZilPayWeb3Message(
      type: type,
      payload: payload,
      uuid: uuid,
    ).toJson();

    final jsonString = jsonEncode(response);
    try {
      await webViewController.evaluateJavascript(
        source: '''
        window.dispatchEvent(new MessageEvent('message', { 
          data: $jsonString
        }));
        ''',
      );
    } catch (e) {
      debugPrint("legacy: evaluateJavascript error: $e");
      rethrow;
    }
  }

  Future<Map<String, String>?> _getAccountIfConnected(AppState appState) async {
    final webUrl = await webViewController.getUrl();
    final currentDomain = Uri.parse(webUrl.toString()).host;
    final connected =
        Web3Utils.findConnected(currentDomain, appState.connections);

    if (connected == null) {
      isConnected = false;
      return null;
    }

    final (bech32, base16) = await zilliqaGetBech32Base16Address(
      walletIndex: BigInt.from(appState.selectedWallet),
      accountIndex: appState.wallet!.selectedAccount,
    );

    isConnected = true;

    return {"base16": base16, "bech32": bech32};
  }

  Future<void> sendData(AppState appState) async {
    await appState.syncConnections();
    final account = await _getAccountIfConnected(appState);

    await _sendResponse(
      type: ZilliqaLegacyMessages.getWalletData,
      payload: {
        'account': account,
        'http': appState.chain!.rpc.first,
        'network': appState.chain?.testnet ?? false ? 'testnet' : 'mainnet',
        'isConnect': account != null,
        'isEnable': true,
      },
      uuid: "",
    );
  }

  void handleStartBlockWorker(AppState appState) {
    if (_blockStreamSubscription != null) {
      return;
    }

    final blockStream =
        startBlockWorker(walletIndex: BigInt.from(appState.selectedWallet));

    _blockStreamSubscription = blockStream.listen((block) {
      if (block.blockNumber != null) {
        _sendResponse(
          type: ZilliqaLegacyMessages.newBlock,
          payload: {'block': block.blockNumber!.toInt()},
          uuid: "",
        );
      }
    });
  }

  Future<void> _handleContentProxyMethod(
    ZilPayWeb3Message message,
    AppState appState,
  ) async {
    final chainHash = appState.chain?.chainHash ?? BigInt.zero;

    try {
      final jsonRes = await providerReqProxy(
        payload: message.payloadToJsonString(),
        chainHash: chainHash,
      );

      await _sendResponse(
        type: ZilliqaLegacyMessages.contentProxyResult,
        payload: {'resolve': jsonDecode(jsonRes)},
        uuid: message.uuid,
      );
    } catch (e) {
      await _sendResponse(
        type: ZilliqaLegacyMessages.responseToDapp,
        payload: {'reject': e.toString()},
        uuid: message.uuid,
      );
    }
  }

  Future<void> _handleCallToSignTx(
    ZilPayWeb3Message message,
    BuildContext context,
  ) async {
    try {
      final appState = Provider.of<AppState>(context, listen: false);

      if (appState.account?.addrType == 1 && appState.chain?.slip44 == 313) {
        await zilliqaSwapChain(
          walletIndex: BigInt.from(appState.selectedWallet),
          accountIndex: appState.wallet!.selectedAccount,
        );
        await appState.syncData();
      }

      FTokenInfo? ftoken = appState.wallet?.tokens
          .firstWhere((t) => t.addrType == 0 && t.native);

      if (ftoken == null) throw Exception('Native token not found');

      final amount = BigInt.parse(message.payload['amount'].toString());
      final gasPrice = BigInt.parse(message.payload['gasPrice'].toString());
      final gasLimit = BigInt.parse(message.payload['gasLimit'].toString());
      final toAddr = message.payload['toAddr'] as String;
      final code = message.payload['code'] as String? ?? "";
      final data = message.payload['data'] as String? ?? "";
      final title = message.payload['title'] as String? ?? "";
      final account = appState.account!;

      final chainHash = appState.chain?.chainHash ?? BigInt.zero;
      final chainId = appState.account?.chainId ??
          appState.chain?.chainIds.last ??
          BigInt.zero;
      final nonce = BigInt.zero;

      final scillaRequest = TransactionRequestScilla(
        chainId: chainId.toInt(),
        nonce: nonce,
        gasPrice: gasPrice,
        gasLimit: gasLimit,
        toAddr: toAddr,
        amount: amount,
        code: code,
        data: data,
      );

      var tokenInfo = BaseTokenInfo(
        value: amount.toString(),
        symbol: ftoken.symbol,
        decimals: ftoken.decimals,
      );

      String recipient = toAddr;
      String tokenAmount =
          fromWei(value: amount.toString(), decimals: ftoken.decimals)
              .toString();

      final (toAddress, ftAmount, ftMeta, teg) =
          await Web3Utils.fetchTokenMetaLegacyZilliqa(
        data: data,
        contracAddr: toAddr,
        walletIndex: BigInt.from(appState.selectedWallet),
      );

      if (ftMeta != null) {
        tokenAmount = fromWei(
                value: (ftAmount ?? BigInt.zero).toString(),
                decimals: ftMeta.decimals)
            .toString();
        recipient = toAddress!;
        tokenInfo = BaseTokenInfo(
          value: tokenAmount,
          symbol: ftMeta.symbol,
          decimals: ftMeta.decimals,
        );
        ftoken = ftMeta;
      }

      final metadata = TransactionMetadataInfo(
        chainHash: chainHash,
        hash: null,
        info: teg,
        icon: message.icon,
        title: title,
        signer: null,
        tokenInfo: tokenInfo,
      );

      final transactionRequest = TransactionRequestInfo(
        metadata: metadata,
        scilla: scillaRequest,
        evm: null,
      );

      if (account.addrType == 1) {
        await zilliqaSwapChain(
          walletIndex: BigInt.from(appState.selectedWallet),
          accountIndex: appState.wallet!.selectedAccount,
        );
        await appState.syncData();
      }

      if (!context.mounted) return;

      showConfirmTransactionModal(
        context: context,
        tx: transactionRequest,
        to: recipient,
        token: ftoken,
        amount: tokenAmount,
        onConfirm: (tx) {
          _sendResponse(
            type: ZilliqaLegacyMessages.txResult,
            payload: {
              'resolve': {
                'amount': tx.amount.toString(),
                'code': code,
                'data': data,
                'gasLimit': tx.gasLimit.toString(),
                'gasPrice': tx.gasPrice.toString(),
                'nonce': tx.nonce.toString(),
                'priority': false,
                'pubKey': metadata.signer,
                'signature': tx.sig,
                'toAddr': toAddr,
                'version': 0,
                'from': tx.sender,
                'hash': tx.transactionHash,
              }
            },
            uuid: message.uuid,
          );
          Navigator.pop(context);
        },
        onDismiss: () {
          _sendResponse(
            type: ZilliqaLegacyMessages.txResult,
            payload: {'reject': "Rejected by user"},
            uuid: message.uuid,
          );
        },
      );
    } catch (e) {
      debugPrint('Error handling transaction: $e');
      await _sendResponse(
        type: ZilliqaLegacyMessages.txResult,
        payload: {'reject': e.toString()},
        uuid: message.uuid,
      );
    }
  }

  Future<void> _handleSignMessage(
    ZilPayWeb3Message message,
    BuildContext context,
  ) async {
    final messageContent = message.payload['content'] as String? ?? '';
    final title = message.payload['title'] as String? ?? 'Sign Message';
    final icon = message.payload['icon'] as String? ?? '';

    final appState = Provider.of<AppState>(context, listen: false);
    final account = appState.account!;

    if (account.addrType == 1) {
      await zilliqaSwapChain(
        walletIndex: BigInt.from(appState.selectedWallet),
        accountIndex: appState.wallet!.selectedAccount,
      );
      await appState.syncData();
    }

    if (!context.mounted) return;

    showSignMessageModal(
      context: context,
      message: messageContent,
      onMessageSigned: (pubkey, sig) async {
        String signature =
            sig.startsWith("0x") ? sig.replaceFirst("0x", "") : sig;

        await _sendResponse(
          type: ZilliqaLegacyMessages.signMessageResponse,
          payload: {
            'resolve': {
              'message': messageContent,
              'signature': signature,
              'publicKey': pubkey,
            },
          },
          uuid: message.uuid,
        );
        if (context.mounted) {
          Navigator.pop(context);
        }
      },
      onDismiss: () async {
        await _sendResponse(
          type: ZilliqaLegacyMessages.signMessageResponse,
          payload: {'reject': 'Rejected by user'},
          uuid: message.uuid,
        );
      },
      appTitle: title,
      appIcon: icon,
    );
  }

  Future<void> _handleConnectApp(
    ZilPayWeb3Message message,
    AppState appState,
    BuildContext context,
  ) async {
    await appState.syncConnections();

    final webUrl = await webViewController.getUrl();
    final currentDomain = Uri.parse(webUrl.toString()).host;

    final isAlreadyConnected =
        Web3Utils.findConnected(currentDomain, appState.connections);

    if (isAlreadyConnected != null) {
      final (bech32, base16) = await zilliqaGetBech32Base16Address(
        walletIndex: BigInt.from(appState.selectedWallet),
        accountIndex: appState.wallet!.selectedAccount,
      );

      await _sendResponse(
        type: ZilliqaLegacyMessages.responseToDapp,
        payload: {
          'account': {"base16": base16, "bech32": bech32}
        },
        uuid: message.uuid,
      );
      return;
    }

    if (appState.account?.addrType == 1) {
      await zilliqaSwapChain(
        walletIndex: BigInt.from(appState.selectedWallet),
        accountIndex: appState.wallet!.selectedAccount,
      );
      await appState.syncData();
    }

    if (!context.mounted) return;

    showAppConnectModal(
      context: context,
      title: message.title ?? "",
      uuid: message.uuid,
      colors: message.colors,
      iconUrl: message.icon ?? "",
      onReject: () {
        _sendResponse(
          type: ZilliqaLegacyMessages.responseToDapp,
          payload: {'reject': 'Rejected by user'},
          uuid: message.uuid,
        );
      },
      onConfirm: (selectedIndices) async {
        final walletIndexes = Uint64List.fromList(
            selectedIndices.map((index) => BigInt.from(index)).toList());

        final connectionInfo = ConnectionInfo(
          domain: currentDomain,
          accountIndexes: walletIndexes,
          favicon: message.icon,
          title: message.title ?? "",
          colors: message.colors,
          description: message.description,
          lastConnected: BigInt.from(DateTime.now().millisecondsSinceEpoch),
          canReadAccounts: true,
          canRequestSignatures: true,
          canSuggestTokens: false,
          canSuggestTransactions: true,
        );

        Map<String, String>? account;

        if (selectedIndices.isNotEmpty) {
          await createUpdateConnection(
            walletIndex: BigInt.from(appState.selectedWallet),
            conn: connectionInfo,
          );

          await appState.syncConnections();

          final (bech32, base16) = await zilliqaGetBech32Base16Address(
            walletIndex: BigInt.from(appState.selectedWallet),
            accountIndex: appState.wallet!.selectedAccount,
          );

          account = {"base16": base16, "bech32": bech32};
        }

        await _sendResponse(
          type: ZilliqaLegacyMessages.responseToDapp,
          payload: {'account': account},
          uuid: message.uuid,
        );
      },
    );
  }

  Future<void> handleLegacyZilPayMessage(
    ZilPayWeb3Message message,
    BuildContext context,
  ) async {
    final appState = Provider.of<AppState>(context, listen: false);

    switch (message.type) {
      case ZilliqaLegacyMessages.getWalletData:
        await sendData(appState);
        break;

      case ZilliqaLegacyMessages.contentProxyMethod:
        await _handleContentProxyMethod(message, appState);
        break;

      case ZilliqaLegacyMessages.callToSignTx:
        await _handleCallToSignTx(message, context);
        break;

      case ZilliqaLegacyMessages.signMessage:
        await _handleSignMessage(message, context);
        break;

      case ZilliqaLegacyMessages.connectApp:
        await _handleConnectApp(message, appState, context);
        break;

      case ZilliqaLegacyMessages.watchBlock:
        handleStartBlockWorker(appState);
        break;

      case ZilliqaLegacyMessages.disconnectApp:
        await _sendResponse(
          type: ZilliqaLegacyMessages.responseToDapp,
          payload: {'account': null},
          uuid: message.uuid,
        );
        break;

      default:
        debugPrint('Unhandled message type: ${message.type}');
        await _sendResponse(
          type: ZilliqaLegacyMessages.responseToDapp,
          payload: {'reject': 'Unsupported message type: ${message.type}'},
          uuid: message.uuid,
        );
    }
  }
}
