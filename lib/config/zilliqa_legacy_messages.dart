/// Zilliqa Legacy Messages Configuration
/// Defines message types for communication between the wallet and dApps
class ZilliqaLegacyMessages {
  static const String _appPrefix = 'zil-pay';

  // Wallet State Messages
  static const String getWalletData = '@/$_appPrefix/injected-get-wallet-data';
  static const String addressChanged = '@/$_appPrefix/address-changed';
  static const String networkChanged = '@/$_appPrefix/network-changed';
  static const String lockStatusUpdated = '@/$_appPrefix/lack-status-updated';

  // Content Proxy Messages
  static const String contentProxyMethod =
      '@/$_appPrefix/request-through-content';
  static const String contentProxyResult =
      '@/$_appPrefix/response-from-content';

  // Transaction Messages
  static const String callToSignTx = '@/$_appPrefix/request-to-sign-tx';
  static const String txResult = '@/$_appPrefix/response-tx-result';

  // Message Signing Messages
  static const String signMessage = '@/$_appPrefix/request-to-sign-message';
  static const String signMessageResponse =
      '@/$_appPrefix/response-sign-message';

  // Block Updates
  static const String newBlock = '@/$_appPrefix/new-block-created';

  // Encryption/Decryption Messages
  static const String addEncryption = '@/$_appPrefix/request-add-encryption';
  static const String responseEncryption = '@/$_appPrefix/response-encryption';
  static const String addDecryption = '@/$_appPrefix/add-decryption';
  static const String responseDecryption = '@/$_appPrefix/response-decryption';

  // DApp Connection Messages
  static const String connectApp = '@/$_appPrefix/request-to-connect-dapp';
  static const String responseToDapp = '@/$_appPrefix/response-dapp-connect';
  static const String disconnectApp =
      '@/$_appPrefix/request-to-disconnect-dapp';

  /// All message types as a list for easy iteration
  static const List<String> allTypes = [
    getWalletData,
    addressChanged,
    networkChanged,
    lockStatusUpdated,
    contentProxyMethod,
    contentProxyResult,
    callToSignTx,
    txResult,
    signMessage,
    signMessageResponse,
    newBlock,
    addEncryption,
    responseEncryption,
    addDecryption,
    responseDecryption,
    connectApp,
    responseToDapp,
    disconnectApp,
  ];
}

class ZilPayMessage {
  final String type;
  final Map<String, dynamic> payload;

  ZilPayMessage({
    required this.type,
    required this.payload,
  });

  /// Creates a ZilPayMessage from a JSON map
  factory ZilPayMessage.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    final payload = json['payload'] as Map<String, dynamic>? ?? {};

    if (type == null || !ZilliqaLegacyMessages.allTypes.contains(type)) {
      throw FormatException('Invalid or unknown message type: $type');
    }

    return ZilPayMessage(
      type: type,
      payload: payload,
    );
  }

  /// Converts the message back to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'payload': payload,
    };
  }

  @override
  String toString() {
    return 'ZilPayMessage(type: $type, payload: $payload)';
  }
}
