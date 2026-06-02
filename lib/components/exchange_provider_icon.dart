import 'package:bearby/src/rust/models/exchange.dart';

/// UI/routing helpers for [ExchangeProvider], kept in one place so every screen renders the same
/// provider iconography and labels and shares a single cross-chain predicate.
extension ExchangeProviderUi on ExchangeProvider {
  /// Brand SVG asset (web3icons branded set, downloaded into `assets/icons/`).
  String get iconAsset => map(
        thorchain: (_) => 'assets/icons/thorchain.svg',
        uniswap: (_) => 'assets/icons/uniswap.svg',
        pancakeSwap: (_) => 'assets/icons/pancakeswap.svg',
        zIlSwap: (_) => 'assets/icons/zilswap.svg',
        sunSwap: (_) => 'assets/icons/sunswap.svg',
      );

  /// Human label; pairs with [iconAsset].
  String get displayName => map(
        thorchain: (_) => 'THORChain',
        uniswap: (_) => 'Uniswap',
        pancakeSwap: (_) => 'PancakeSwap',
        zIlSwap: (_) => 'ZilSwap',
        sunSwap: (_) => 'SunSwap',
      );

  /// THORChain is a cross-chain bridge (different output asset, native send + memo / router
  /// deposit), so it is routed and rendered separately from same-chain DEX providers.
  bool get isThorchain => maybeMap(thorchain: (_) => true, orElse: () => false);
}
