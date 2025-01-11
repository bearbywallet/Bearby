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
        'https://eth-mainnet.g.alchemy.com/v2',
        'https://mainnet.infura.io/v3',
        'https://rpc.ankr.com/eth'
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
        'https://bsc-dataseed1.bnbchain.org',
        'https://bsc-dataseed2.bnbchain.org',
        'https://bsc-dataseed3.bnbchain.org',
        'https://bsc-dataseed4.bnbchain.org'
      ],
      explorerUrls: ['https://bscscan.com'],
      default_: true,
      bip49: "evm:m/44'/60'/0'/0/",
    );
  }
}
