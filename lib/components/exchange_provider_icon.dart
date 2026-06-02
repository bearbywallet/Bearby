import 'package:bearby/src/rust/models/exchange.dart';

/// Brand SVG asset for each [ExchangeProvider]. Sourced from the web3icons branded set
/// (downloaded into `assets/icons/`). Kept in one place so every screen renders the same
/// provider iconography.
String exchangeProviderIconAsset(ExchangeProvider provider) => provider.map(
      thorchain: (_) => 'assets/icons/thorchain.svg',
      uniswap: (_) => 'assets/icons/uniswap.svg',
      pancakeSwap: (_) => 'assets/icons/pancakeswap.svg',
      zIlSwap: (_) => 'assets/icons/zilswap.svg',
      sunSwap: (_) => 'assets/icons/sunswap.svg',
    );

/// Human label for each [ExchangeProvider]; pairs with [exchangeProviderIconAsset].
String exchangeProviderName(ExchangeProvider provider) => provider.map(
      thorchain: (_) => 'THORChain',
      uniswap: (_) => 'Uniswap',
      pancakeSwap: (_) => 'PancakeSwap',
      zIlSwap: (_) => 'ZilSwap',
      sunSwap: (_) => 'SunSwap',
    );

/// Verb for a native↔wrapped-native operation: 'Wrap' (native in) or 'Unwrap' (native out).
String wrapVerb({required bool isNativeIn}) => isNativeIn ? 'Wrap' : 'Unwrap';

/// Short route label for the swap UI: 'Wrap'/'Unwrap' for a 1:1 native↔wrapped op, otherwise the
/// provider name. Single source of truth shared by the page row and the confirm sheet.
String exchangeRouteLabel(
  ExchangeProvider provider, {
  required bool isWrapUnwrap,
  required bool isNativeIn,
}) =>
    isWrapUnwrap
        ? wrapVerb(isNativeIn: isNativeIn)
        : exchangeProviderName(provider);
