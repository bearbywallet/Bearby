class StorageKeys {
  static const hideBalance = 'hide_balance_key';
  static const gasOption = 'gas_option_key';
  static const tokensCardStyle = 'tokens_card_styles_key';
  static const showAddressesHistory = 'show_addresses_transaction_history_key';
  static const browserUrlBarTop = 'browser_url_bar_top_key';
  static const testnetEnabled = 'testnet_enabled';
  static const deletedTokensCache = 'deleted_tokens_cache';

  static String gasOptionKey(int walletIndex) => '$gasOption:$walletIndex';
  static String tokensCardStyleKey(int walletIndex) =>
      '$tokensCardStyle:$walletIndex';
  static String showAddressesHistoryKey(int walletIndex) =>
      '$showAddressesHistory:$walletIndex';
  static String deletedTokensCacheKey(BigInt chainHash) =>
      '${deletedTokensCache}_$chainHash';
}
