import 'package:bearby/src/rust/models/exchange.dart';

/// UI/routing helpers for [ExchangeProvider], kept in one place so every screen renders the same
/// provider iconography and labels.
extension ExchangeProviderUi on ExchangeProvider {
  /// Brand SVG asset (web3icons branded set, downloaded into `assets/icons/`).
  String get iconAsset => map(
        relay: (_) => 'assets/icons/relay.svg',
        uniswap: (_) => 'assets/icons/uniswap.svg',
        pancakeSwap: (_) => 'assets/icons/pancakeswap.svg',
        zIlSwap: (_) => 'assets/icons/zilswap.svg',
        sunSwap: (_) => 'assets/icons/sunswap.svg',
      );

  /// Human label; pairs with [iconAsset].
  String get displayName => map(
        relay: (_) => 'Relay',
        uniswap: (_) => 'Uniswap',
        pancakeSwap: (_) => 'PancakeSwap',
        zIlSwap: (_) => 'ZilSwap',
        sunSwap: (_) => 'SunSwap',
      );
}
