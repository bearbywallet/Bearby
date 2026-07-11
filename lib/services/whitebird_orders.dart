import 'package:bearby/src/rust/models/exchange/whitebird/orders.dart';

extension WhiteBirdOpenOrderX on WhiteBirdOpenOrder {
  /// Sell order still waiting for the user's crypto deposit. It is WhiteBird's
  /// single active order: it blocks creating new orders, so it can never be
  /// locally dismissed — only completed, cancelled inside the SDK, or expired.
  bool get awaitingDeposit =>
      isSell && !cryptoReceived && (depositAddress?.isNotEmpty ?? false);
}
