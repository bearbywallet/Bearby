import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:zilpay/src/rust/api/connections.dart';
import 'package:zilpay/src/rust/api/wallet.dart';
import 'package:zilpay/src/rust/api/provider.dart';
import 'package:zilpay/src/rust/models/connection.dart';
import 'package:zilpay/state/app_state.dart';
import 'package:zilpay/config/zilliqa_legacy_messages.dart';
import 'package:zilpay/modals/app_connect.dart';
import 'package:zilpay/web3/web3_utils.dart'; // Import the utils
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';

class ZilPayLegacyMessage {
  final String type;
  final Map<String, dynamic> payload;
  final String uuid;

  ZilPayLegacyMessage({
    required this.type,
    required this.payload,
    required this.uuid,
  });

  factory ZilPayLegacyMessage.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    final uuid = json['uuid'] ?? "";
    final payload = json['payload'] as Map<String, dynamic>? ?? {};

    if (type == null || !ZilliqaLegacyMessages.allTypes.contains(type)) {
      throw FormatException('Invalid or unknown message type: $type');
    }

    return ZilPayLegacyMessage(type: type, payload: payload, uuid: uuid);
  }

  String payloadToJsonString() {
    return jsonEncode(payload);
  }

  Map<String, dynamic> toJson() {
    return {'type': type, 'payload': payload, 'uuid': uuid};
  }

  @override
  String toString() {
    return 'ZilPayMessage(type: $type, payload: $payload uuid: $uuid)';
  }
}

class ZilPayLegacyHandler {
  final WebViewController webViewController;
  final String initialUrl;

  ZilPayLegacyHandler({
    required this.webViewController,
    required this.initialUrl,
  });

  Future<void> _sendResponse(
      String type, Map<String, Object?> payload, String uuid) async {
    final response =
        ZilPayLegacyMessage(type: type, payload: payload, uuid: uuid).toJson();
    final jsonString = jsonEncode(response);
    await webViewController
        .runJavaScript('window.postMessage($jsonString, "*")');
  }

  Future<void> sendData(AppState appState) async {
    await appState.syncConnections();
    final currentDomain = Uri.parse(initialUrl).host;
    final isConnected =
        Web3Utils.isDomainConnected(currentDomain, appState.connections);
    Map<String, String>? account;

    if (isConnected) {
      final (bech32, base16) = await zilliqaGetBech32Base16Address(
        walletIndex: BigInt.from(appState.selectedWallet),
        accountIndex: appState.wallet!.selectedAccount,
      );
      account = {"base16": base16, "bech32": bech32};
    }

    _sendResponse(
        ZilliqaLegacyMessages.getWalletData,
        {
          'account': account,
          'network': appState.chain?.testnet ?? false ? 'testnet' : 'mainnet',
          'isConnect': isConnected,
          'isEnable': true,
        },
        "");
  }

  Future<void> handleLegacyZilPayMessage(
    ZilPayLegacyMessage message,
    BuildContext context,
  ) async {
    final appState = Provider.of<AppState>(context, listen: false);
    final currentDomain = Uri.parse(initialUrl).host;

    switch (message.type) {
      case ZilliqaLegacyMessages.getWalletData:
        await sendData(appState);
        break;

      case ZilliqaLegacyMessages.contentProxyMethod:
        BigInt chainHash = appState.chain?.chainHash ?? BigInt.zero;
        try {
          String jsonRes = await providerReqProxy(
            payload: message.payloadToJsonString(),
            chainHash: chainHash,
          );
          _sendResponse(ZilliqaLegacyMessages.contentProxyResult,
              {'resolve': jsonDecode(jsonRes)}, message.uuid);
        } catch (e) {
          _sendResponse(ZilliqaLegacyMessages.responseToDapp,
              {'reject': e.toString()}, message.uuid);
        }
        break;

      case ZilliqaLegacyMessages.callToSignTx:
        debugPrint('Sign transaction request: ${message.payload}');
        break;

      case ZilliqaLegacyMessages.signMessage:
        debugPrint('Sign message request: ${message.payload}');
        break;

      case ZilliqaLegacyMessages.connectApp:
        await appState.syncConnections();
        final isAlreadyConnected =
            Web3Utils.isDomainConnected(currentDomain, appState.connections);

        if (isAlreadyConnected) {
          final (bech32, base16) = await zilliqaGetBech32Base16Address(
            walletIndex: BigInt.from(appState.selectedWallet),
            accountIndex: appState.wallet!.selectedAccount,
          );
          Map<String, String> account = {"base16": base16, "bech32": bech32};
          _sendResponse(ZilliqaLegacyMessages.responseToDapp,
              {'account': account}, message.uuid);
          return;
        }

        final title = message.payload['title'] as String? ?? 'Unknown App';
        final icon = message.payload['icon'] as String? ?? '';
        final pageInfo = await Web3Utils.extractPageInfo(webViewController);

        if (!context.mounted) return;

        showAppConnectModal(
          context: context,
          title: title,
          uuid: message.uuid,
          iconUrl: icon,
          onDecision: (accepted, selectedIndices) async {
            final colorsMap = pageInfo['colors'] as Map<String, Object?>?;
            final walletIndexes = Uint64List.fromList(
                selectedIndices.map((index) => BigInt.from(index)).toList());

            ConnectionInfo connectionInfo = ConnectionInfo(
              domain: currentDomain,
              walletIndexes: walletIndexes,
              favicon: icon,
              title: title,
              description: pageInfo['description'] as String?,
              lastConnected: BigInt.from(DateTime.now().millisecondsSinceEpoch),
              canReadAccounts: true,
              canRequestSignatures: true,
              canSuggestTokens: false,
              canSuggestTransactions: true,
            );
            Map<String, String>? account;

            if (accepted) {
              await createNewConnection(conn: connectionInfo);
              await appState.syncConnections();
              final (bech32, base16) = await zilliqaGetBech32Base16Address(
                walletIndex: BigInt.from(appState.selectedWallet),
                accountIndex: appState.wallet!.selectedAccount,
              );
              account = {"base16": base16, "bech32": bech32};
            }

            await _sendResponse(
                ZilliqaLegacyMessages.responseToDapp,
                {
                  'account': account,
                },
                message.uuid);
          },
        );
        break;

      case ZilliqaLegacyMessages.disconnectApp:
        debugPrint('Disconnect app request: ${message.payload}');
        _sendResponse(ZilliqaLegacyMessages.responseToDapp, {'account': null},
            message.uuid);
        break;

      default:
        debugPrint('Unhandled message type: ${message.type}');
    }
  }
}
