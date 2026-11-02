import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:webview_plus/webview_plus.dart';

import 'package:bearby/web3/message.dart';

extension WebviewPlusControllerMetadata on WebviewPlusController {
  Future<Uri?> getUrl() async {
    try {
      final raw = await evaluateJavascript('window.location.href');
      if (raw is String && raw.isNotEmpty) {
        return Uri.tryParse(raw);
      }
    } catch (_) {}
    return null;
  }

  Future<String?> getTitle() async {
    try {
      final raw = await evaluateJavascript('document.title');
      if (raw is String) {
        return raw;
      }
    } catch (_) {}
    return null;
  }
}

/// Common shape of the chain-specific 1193 error-code enums
/// ([Web3EIP1193ErrorCode], [TronWeb3ErrorCode]) — both carry the
/// JSON-RPC numeric code.
abstract interface class Web3ErrorCode {
  int get code;
}

/// Serializes [payload]/[result]/[errorCode] into a [ZilPayWeb3Message] and
/// dispatches it to the in-page response-handler registry, falling back to a
/// `message` [MessageEvent] when no handler is registered for [uuid].
///
/// Used to be copy-pasted in `eip_1193.dart` and `tron_web3.dart` (DRY).
Future<void> sendWeb3Response({
  required WebviewPlusController webViewController,
  required String type,
  required String uuid,
  Map<String, dynamic>? payload,
  Object? result,
  Web3ErrorCode? errorCode,
  String? errorMessage,
}) async {
  assert(
    (errorCode == null) == (errorMessage == null),
    'errorCode and errorMessage must be provided together',
  );

  final responsePayload = <String, Object?>{
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
    await webViewController.evaluateJavascript(jsCode);
  } catch (e) {
    debugPrint("evaluateJavascript error: $e");
  }
}
