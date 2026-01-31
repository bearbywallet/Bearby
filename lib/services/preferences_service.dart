import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static PreferencesService? _instance;
  static SharedPreferences? _prefs;

  PreferencesService._();

  static Future<PreferencesService> getInstance() async {
    _instance ??= PreferencesService._();
    _prefs ??= await SharedPreferences.getInstance();
    return _instance!;
  }

  static const String _hideBalanceKey = "hide_balance_key";
  static const String _gasOptionKey = "gas_option_key";
  static const String _tokensCardStyleKey = "tokens_card_styles_key";
  static const String _showAddressesHistoryKey =
      "show_addresses_transaction_history_key";
  static const String _browserUrlBarTopKey = "browser_url_bar_top_key";

  bool getHideBalance() => _prefs?.getBool(_hideBalanceKey) ?? false;
  Future<void> setHideBalance(bool value) =>
      _prefs!.setBool(_hideBalanceKey, value);

  String? getGasOption(int walletIndex) =>
      _prefs?.getString("$_gasOptionKey:$walletIndex");
  Future<void> setGasOption(int walletIndex, String value) =>
      _prefs!.setString("$_gasOptionKey:$walletIndex", value);

  bool getIsTileView(int walletIndex) =>
      _prefs?.getBool("$_tokensCardStyleKey:$walletIndex") ?? false;
  Future<void> setIsTileView(int walletIndex, bool value) =>
      _prefs!.setBool("$_tokensCardStyleKey:$walletIndex", value);

  bool getShowAddressesHistory(int walletIndex) =>
      _prefs?.getBool("$_showAddressesHistoryKey:$walletIndex") ?? false;
  Future<void> setShowAddressesHistory(int walletIndex, bool value) =>
      _prefs!.setBool("$_showAddressesHistoryKey:$walletIndex", value);

  bool getBrowserUrlBarTop() => _prefs?.getBool(_browserUrlBarTopKey) ?? false;
  Future<void> setBrowserUrlBarTop(bool value) =>
      _prefs!.setBool(_browserUrlBarTopKey, value);
}
