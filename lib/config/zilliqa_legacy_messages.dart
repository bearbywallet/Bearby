/// Zilliqa Legacy Messages Configuration
/// Defines message types for communication between the wallet and dApps
class ZilliqaLegacyMessages {
  static const String _appPrefix = 'zil-pay';

  // Wallet State Messages
  static const String getWalletData = '@/$_appPrefix/injected-get-wallet-data';
  static const String addressChanged = '@/$_appPrefix/address-changed';
  static const String networkChanged = '@/$_appPrefix/network-changed';

  static const String watchBlock = '@/$_appPrefix/request-watch_block';

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

  // DApp Connection Messages
  static const String connectApp = '@/$_appPrefix/request-to-connect-dapp';
  static const String responseToDapp = '@/$_appPrefix/response-dapp-connect';
  static const String disconnectApp =
      '@/$_appPrefix/request-to-disconnect-dapp';

  static const List<String> allTypes = [
    getWalletData,
    addressChanged,
    networkChanged,
    contentProxyMethod,
    contentProxyResult,
    callToSignTx,
    txResult,
    signMessage,
    signMessageResponse,
    newBlock,
    connectApp,
    responseToDapp,
    disconnectApp,
  ];
}
