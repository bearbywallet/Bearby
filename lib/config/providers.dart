import 'package:zilpay/src/rust/models/provider.dart';

String chainNameBySymbol(String symbol) {
  if (symbol == DefaultNetworkProviders.zil().tokenSymbol) {
    return "zilliqa";
  } else if (symbol == DefaultNetworkProviders.eth().tokenSymbol) {
    return "ethereum";
  } else if (symbol == DefaultNetworkProviders.bsc().tokenSymbol) {
    return "binance";
  } else {
    return "";
  }
}

String? symbolByChainName(String name) {
  if (name == "zilliqa") {
    return DefaultNetworkProviders.zil().tokenSymbol;
  } else if (name == "ethereum") {
    return DefaultNetworkProviders.eth().tokenSymbol;
  } else if (name == "binance") {
    return DefaultNetworkProviders.bsc().tokenSymbol;
  }

  return null;
}

bool isMainnetNetwork(BigInt chainId) {
  final mainnetChainIds = [
    BigInt.from(1), // Ethereum Mainnet
    BigInt.from(56), // BNB Smart Chain Mainnet
    BigInt.from(32770) // Zilliqa Mainnet
  ];

  return mainnetChainIds.contains(chainId);
}

class DefaultNetworkProviders {
  static List<NetworkConfigInfo> mainnetNetworks() {
    return [
      zil(),
      eth(),
      bsc(),
    ];
  }

  static List<NetworkConfigInfo> testnetNetworks() {
    return [
      zilTestnet(),
      ethTestnet(),
      bscTestnet(),
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

  static NetworkConfigInfo zilTestnet() {
    return NetworkConfigInfo(
      tokenSymbol: "ZIL",
      logo:
          "https://raw.githubusercontent.com/spothq/cryptocurrency-icons/master/svg/color/zil.svg",
      networkName: 'Zilliqa Testnet',
      chainId: BigInt.from(32769),
      fallbackEnabled: true,
      urls: [
        'https://dev-api.zilliqa.com',
      ],
      explorerUrls: ['https://viewblock.io/zilliqa?network=testnet'],
      default_: false,
      bip49: "zil:m/44'/313'/0'/0/",
    );
  }

  static NetworkConfigInfo ethTestnet() {
    return NetworkConfigInfo(
      tokenSymbol: "ETH",
      logo:
          "https://raw.githubusercontent.com/spothq/cryptocurrency-icons/master/svg/color/eth.svg",
      networkName: 'Sepolia Testnet',
      chainId: BigInt.from(11155111),
      fallbackEnabled: true,
      urls: [
        "https://rpc.sepolia.org",
        "https://rpc2.sepolia.org",
      ],
      explorerUrls: ['https://sepolia.etherscan.io'],
      default_: false,
      bip49: "evm:m/44'/60'/0'/0/",
    );
  }

  static NetworkConfigInfo bscTestnet() {
    return NetworkConfigInfo(
      tokenSymbol: "BNB",
      logo:
          "https://raw.githubusercontent.com/spothq/cryptocurrency-icons/master/svg/color/bnb.svg",
      networkName: 'BNB Smart Chain Testnet',
      chainId: BigInt.from(97),
      fallbackEnabled: true,
      urls: [
        "https://data-seed-prebsc-1-s1.binance.org:8545",
        "https://data-seed-prebsc-2-s1.binance.org:8545",
        "https://data-seed-prebsc-1-s2.binance.org:8545"
      ],
      explorerUrls: ['https://testnet.bscscan.com'],
      default_: false,
      bip49: "evm:m/44'/60'/0'/0/",
    );
  }
}
