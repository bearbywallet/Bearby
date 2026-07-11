class StorageKeys {
  static const hideBalance = 'hide_balance_key';
  static const gasOption = 'gas_option_key';
  static const tokensCardStyle = 'tokens_card_styles_key';
  static const showAddressesHistory = 'show_addresses_transaction_history_key';
  static const browserUrlBarTop = 'browser_url_bar_top_key';
  static const testnetEnabled = 'testnet_enabled';
  static const deletedTokensCache = 'deleted_tokens_cache';
  static const whitebirdExternalClientId = 'whitebird_external_client_id';
  static const whitebirdAccessToken = 'whitebird_access_token';
  static const whitebirdRefreshToken = 'whitebird_refresh_token';
  static const whitebirdTokensSavedAt = 'whitebird_tokens_saved_at';
  static const whitebirdClientId = 'whitebird_client_id';
  static const whitebirdEmail = 'whitebird_email';
  static const whitebirdDismissedOrders = 'whitebird_dismissed_orders';

  static String gasOptionKey(int walletIndex) => '$gasOption:$walletIndex';
  static String tokensCardStyleKey(int walletIndex) =>
      '$tokensCardStyle:$walletIndex';
  static String showAddressesHistoryKey(int walletIndex) =>
      '$showAddressesHistory:$walletIndex';
  static String deletedTokensCacheKey(BigInt chainHash) =>
      '${deletedTokensCache}_$chainHash';
}
