enum Web3EIP1193Method {
  ethRequestAccounts('eth_requestAccounts'),
  ethAccounts('eth_accounts'),
  ethSign('eth_sign'),
  ethSendTransaction('eth_sendTransaction'),
  ethGetBalance('eth_getBalance'),
  ethGetTransactionByHash('eth_getTransactionByHash'),
  ethGetTransactionReceipt('eth_getTransactionReceipt'),
  ethCall('eth_call'),
  ethEstimateGas('eth_estimateGas'),
  ethBlockNumber('eth_blockNumber'),
  ethGetBlockByNumber('eth_getBlockByNumber'),
  ethGetBlockByHash('eth_getBlockByHash'),
  ethSubscribe('eth_subscribe'),
  ethUnsubscribe('eth_unsubscribe'),
  netVersion('net_version'),
  ethChainId('eth_chainId'),
  ethGetCode('eth_getCode'),
  ethGetStorageAt('eth_getStorageAt'),
  ethGasPrice('eth_gasPrice'),
  ethSignTypedData('eth_signTypedData'),
  ethSignTypedDataV4('eth_signTypedData_v4'),
  ethGetTransactionCount('eth_getTransactionCount'),
  personalSign('personal_sign'),

  walletAddEthereumChain('wallet_addEthereumChain'),
  walletSwitchEthereumChain('wallet_switchEthereumChain'),
  walletWatchAsset('wallet_watchAsset'),
  walletGetPermissions('wallet_getPermissions'),
  walletRequestPermissions('wallet_requestPermissions'),
  walletScanQRCode('wallet_scanQRCode'),
  ethGetEncryptionPublicKey('eth_getEncryptionPublicKey'),
  ethDecrypt('eth_decrypt');

  final String value;
  const Web3EIP1193Method(this.value);
}

enum Web3EIP1193ErrorCode {
  userRejectedRequest(4001),
  unauthorized(4100),
  unsupportedMethod(4200),
  disconnected(4900),
  chainDisconnected(4901),
  internalError(-32603),
  chainNotAdded(4902),
  invalidInput(-32000);

  final int code;
  const Web3EIP1193ErrorCode(this.code);
}
