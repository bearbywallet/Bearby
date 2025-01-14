import 'package:zilpay/src/rust/models/ftoken.dart';

class DefaultTokens {
  static List<FTokenInfo> defaultFtokens() {
    // this is math with providers
    return [
      zil(),
      eth(),
      bsc(),
    ];
  }

  static FTokenInfo zil() {
    return FTokenInfo(
        name: 'Zilliqa',
        symbol: 'ZIL',
        decimals: 12,
        addr: 'zil1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq9yf6pz',
        logo:
            'https://raw.githubusercontent.com/spothq/cryptocurrency-icons/master/svg/color/zil.svg',
        balances: {},
        default_: true,
        native: true,
        providerIndex:
            BigInt.from(0)); //DefaultNetworkProviders.defaultNetworks[0]
  }

  static FTokenInfo eth() {
    return FTokenInfo(
        name: 'Ethereum',
        symbol: 'ETH',
        decimals: 18,
        addr: '0x0000000000000000000000000000000000000000',
        logo:
            'https://raw.githubusercontent.com/spothq/cryptocurrency-icons/master/svg/color/eth.svg',
        balances: {},
        default_: true,
        native: true,
        providerIndex: BigInt.from(1));
  }

  static FTokenInfo bsc() {
    return FTokenInfo(
        name: 'BNB',
        symbol: 'BNB',
        decimals: 18,
        addr: '0x0000000000000000000000000000000000000000',
        logo:
            'https://raw.githubusercontent.com/spothq/cryptocurrency-icons/master/svg/color/bnb.svg',
        balances: {},
        default_: true,
        native: true,
        providerIndex: BigInt.from(2));
  }
}
