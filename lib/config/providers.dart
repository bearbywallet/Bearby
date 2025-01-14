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
      tokenSymbol: "ZIL",
      logo:
          "https://raw.githubusercontent.com/spothq/cryptocurrency-icons/master/svg/color/zil.svg",
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
      tokenSymbol: "ETH",
      logo:
          "https://raw.githubusercontent.com/spothq/cryptocurrency-icons/master/svg/color/eth.svg",
      networkName: 'Ethereum Mainnet',
      chainId: BigInt.from(1),
      fallbackEnabled: true,
      urls: [
        "https://eth.llamarpc.com",
        "https://1rpc.io/eth",
        "https://eth.drpc.org",
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
      tokenSymbol: "BNB",
      logo:
          "https://raw.githubusercontent.com/spothq/cryptocurrency-icons/master/svg/color/bnb.svg",
      networkName: 'BNB Smart Chain Mainnet',
      chainId: BigInt.from(56),
      fallbackEnabled: true,
      urls: [
        "https://bsc-dataseed.binance.org",
      ],
      explorerUrls: ['https://bscscan.com'],
      default_: true,
      bip49: "evm:m/44'/60'/0'/0/",
    );
  }
}
