/// WhiteBird SDK embed configuration.
///
/// `merchantPass` is the SDK embed credential (used client-side by design —
/// the SDK sends it as `Authorization: Basic` to issue client tokens).
/// API-key secrets never live in the app; they stay on the Bearby proxy.
class WhiteBirdConfig {
  const WhiteBirdConfig._();

  static const String merchantId = 'f1a14643-242e-4111-b9d5-7e29b624dc21';
  static const String merchantPass =
      'ZjFhMTQ2NDMtMjQyZS00MTExLWI5ZDUtN2UyOWI2MjRkYzIxOjBiUTF1b2ozb01qcFZ3b0JISFpM';

  /// Testnet SDK bundle. Mainnet URL lands together with `wb.bearby.ru`.
  static const String sdkScriptUrlTestnet =
      'https://sdk.dev.wbdevel.net/v2.0/integration/wbExchangeSdk-v001.js';

  /// How long stored WhiteBird JWTs stay trusted before forcing re-login.
  static const Duration tokenTtl = Duration(days: 90);

  /// Synthetic fiat token addr_type — mirrors
  /// `rust/src/models/exchange/whitebird/assets.rs::FIAT_ADDR_TYPE`.
  static const int fiatAddrType = 200;
}
