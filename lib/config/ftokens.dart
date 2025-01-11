import 'package:zilpay/src/rust/models/ftoken.dart';

class DefaultTokens {
  static FTokenInfo zil({Map<BigInt, String> balances = const {}}) {
    return FTokenInfo(
        name: 'Zilliqa',
        symbol: 'ZIL',
        decimals: 12,
        addr: 'zil1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq9yf6pz',
        logo:
            'https://assets.coingecko.com/coins/images/2687/small/Zilliqa-logo.png',
        balances: balances,
        default_: true,
        native: true,
        providerIndex: BigInt.from(0));
  }

  static FTokenInfo eth({Map<BigInt, String> balances = const {}}) {
    return FTokenInfo(
        name: 'Ethereum',
        symbol: 'ETH',
        decimals: 18,
        addr: '0x0000000000000000000000000000000000000000',
        logo:
            'https://assets.coingecko.com/coins/images/279/small/ethereum.png',
        balances: balances,
        default_: true,
        native: true,
        providerIndex: BigInt.from(1));
  }

  static FTokenInfo bsc({Map<BigInt, String> balances = const {}}) {
    return FTokenInfo(
        name: 'BNB',
        symbol: 'BNB',
        decimals: 18,
        addr: '0x0000000000000000000000000000000000000000',
        logo:
            'https://assets.coingecko.com/coins/images/825/small/bnb-icon2_2x.png',
        balances: balances,
        default_: true,
        native: true,
        providerIndex: BigInt.from(2));
  }
}
