class EVMMessages {
  static const String request = 'ZILPAY_REQUEST';
  static const String response = 'ZILPAY_RESPONSE';
  static const String connect = 'connect';
  static const String disconnect = 'disconnect';
  static const String chainChanged = 'chainChanged';
  static const String accountsChanged = 'accountsChanged';
  static const String requestAccounts = 'eth_requestAccounts';
  static const String getAccounts = 'eth_accounts';
  static const String signMessage = 'eth_sign';
  static const String personalSign = 'personal_sign';
  static const String signTypedData = 'eth_signTypedData';
  static const String sendTransaction = 'eth_sendTransaction';
  static const String switchChain = 'wallet_switchEthereumChain';
}
