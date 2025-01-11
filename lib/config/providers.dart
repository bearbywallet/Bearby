import 'package:zilpay/src/rust/models/provider.dart';

class DefaultNetworkProviders {
  static List<NetworkConfigInfo> defaultNetworks() {
    return [
      zil(),
      eth(),
      bsc(),
    ];
  }

  static NetworkConfigInfo zil() {
    return NetworkConfigInfo(
      networkName: 'Zilliqa Mainnet',
      chainId: BigInt.from(32770),
      fallbackEnabled: true,
      urls: [
        'https://api.zq2-protomainnet.zilliqa.com',
      ],
      explorerUrls: ['https://viewblock.io/zilliqa'],
      default_: true,
      bip49: "zil:m/44'/313'/0'/0/",
    );
  }

  static NetworkConfigInfo eth() {
    return NetworkConfigInfo(
      networkName: 'Ethereum Mainnet',
      chainId: BigInt.from(1),
      fallbackEnabled: true,
      urls: [
        "https://eth.llamarpc.com",
        "https://api.zan.top/eth-mainnet",
        "https://singapore.rpc.blxrbdn.com"
      ],
      explorerUrls: ['https://etherscan.io'],
      default_: true,
      bip49: "evm:m/44'/60'/0'/0/",
    );
  }

  static NetworkConfigInfo bsc() {
    return NetworkConfigInfo(
      networkName: 'BNB Smart Chain Mainnet',
      chainId: BigInt.from(56),
      fallbackEnabled: true,
      urls: [
        "https://binance.llamarpc.com",
        "https://bsc-pokt.nodies.app",
      ],
      explorerUrls: ['https://bscscan.com'],
      default_: true,
      bip49: "evm:m/44'/60'/0'/0/",
    );
  }
}
