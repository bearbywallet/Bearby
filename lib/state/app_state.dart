import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zilpay/ledger/ledger_view_controller.dart';
import 'package:zilpay/mixins/gas_eip1559.dart';
import 'package:zilpay/services/preferences_service.dart';
import 'package:zilpay/src/rust/api/backend.dart';
import 'package:zilpay/src/rust/api/book.dart';
import 'package:zilpay/src/rust/api/connections.dart';
import 'package:zilpay/src/rust/api/settings.dart';
import 'package:zilpay/src/rust/api/token.dart';
import 'package:zilpay/src/rust/api/transaction.dart';
import 'package:zilpay/src/rust/api/wallet.dart';
import 'package:zilpay/src/rust/models/account.dart';
import 'package:zilpay/src/rust/models/background.dart';
import 'package:zilpay/src/rust/models/book.dart';
import 'package:zilpay/src/rust/models/connection.dart';
import 'package:zilpay/src/rust/models/provider.dart';
import 'package:zilpay/src/rust/models/wallet.dart';
import 'package:zilpay/theme/app_theme.dart';

class AppState extends ChangeNotifier with WidgetsBindingObserver {
  final LedgerViewController ledgerViewController = LedgerViewController();

  List<AddressBookEntryInfo> _book = [];
  List<ConnectionInfo> _connections = [];
  DateTime _lastRateUpdateTime = DateTime.fromMillisecondsSinceEpoch(0);
  GasFeeOption _selectedGasOption = GasFeeOption.market;
  bool _showAddressesThroughTransactionHistory = false;

  static const Duration _rateUpdateCooldown = Duration(minutes: 1);

  late BackgroundState _state;
  late String _cahceDir;
  late PreferencesService _prefs;
  int _selectedWallet = 0;
  bool _hideBalance = false;
  bool _isTileView = false;
  bool _browserUrlBarTop = false;

  final Brightness _systemBrightness =
      PlatformDispatcher.instance.platformBrightness;

  AppState({
    required BackgroundState state,
    required String cahceDir,
    required PreferencesService prefs,
  }) {
    WidgetsBinding.instance.addObserver(this);
    _state = state;
    _cahceDir = cahceDir;
    _prefs = prefs;
  }

  void setSelectedWallet(int index) {
    _selectedWallet = index;
    notifyListeners();
  }

  bool get isTileView => _isTileView;
  bool get browserUrlBarTop => _browserUrlBarTop;
  bool get showAddressesThroughTransactionHistory => _showAddressesThroughTransactionHistory;
  GasFeeOption get selectedGasOption => _selectedGasOption;
  String get cahceDir => _cahceDir;
  bool get hideBalance => _hideBalance;
  List<WalletInfo> get wallets => _state.wallets;
  Locale? get locale => state.locale != null ? Locale(state.locale!) : null;
  List<ConnectionInfo> get connections => _connections;
  List<AddressBookEntryInfo> get book => _book;
  BackgroundState get state => _state;

  AppTheme get currentTheme {
    switch (_state.appearances) {
      case 0:
        return _systemBrightness == Brightness.dark ? DarkTheme() : LightTheme();
      case 1:
        return DarkTheme();
      case 2:
        return LightTheme();
      default:
        return _systemBrightness == Brightness.dark ? DarkTheme() : LightTheme();
    }
  }

  WalletInfo? get wallet => _state.wallets[_selectedWallet];

  NetworkConfigInfo? get chain {
    BigInt? hash = account?.chainHash;
    if (hash == null) return null;
    return getChain(hash);
  }

  AccountInfo? get account {
    if (wallet == null) return null;
    int index = wallet!.selectedAccount.toInt();
    return wallet!.accounts[index];
  }

  int get selectedWallet => _selectedWallet;

  void setHideBalance(bool value) async {
    _hideBalance = value;
    await _prefs.setHideBalance(value);
    notifyListeners();
  }

  Future<void> syncData() async {
    _state = await getData();
    await syncBook();
    await syncConnections();
    _loadPreferences();
    notifyListeners();
  }

  void _loadPreferences() {
    _hideBalance = _prefs.getHideBalance();
    _isTileView = _prefs.getIsTileView(_selectedWallet);
    _browserUrlBarTop = _prefs.getBrowserUrlBarTop();
    _showAddressesThroughTransactionHistory = _prefs.getShowAddressesHistory(_selectedWallet);
    _loadGasOption();
  }

  void _loadGasOption() {
    final optionName = _prefs.getGasOption(_selectedWallet);
    if (optionName != null) {
      try {
        _selectedGasOption = GasFeeOption.values.firstWhere(
          (option) => option.name == optionName,
        );
      } catch (e) {
        _selectedGasOption = GasFeeOption.market;
      }
    }
  }

  Future<void> syncBook() async {
    _book = await getAddressBookList();
    notifyListeners();
  }

  Future<void> syncConnections() async {
    _connections = await getConnectionsList(walletIndex: BigInt.from(_selectedWallet));
    notifyListeners();
  }

  Future<void> syncRates({bool force = false}) async {
    if (chain?.testnet == true || wallet?.settings.ratesApiOptions == 0) return;
    final now = DateTime.now();

    if (!force && now.difference(_lastRateUpdateTime) < _rateUpdateCooldown) {
      return;
    }

    try {
      await updateRates(walletIndex: BigInt.from(_selectedWallet));
      _lastRateUpdateTime = now;
    } catch (e) {
      debugPrint("error sync rates: $e");
    }

    notifyListeners();
  }

  Future<void> updateSelectedAccount(BigInt walletIndex, BigInt accountIndex) async {
    await selectAccount(walletIndex: walletIndex, accountIndex: accountIndex);
    await syncData();
    notifyListeners();
  }

  Future<void> setAppearancesCode(int code, bool compactNumbers) async {
    await setTheme(appearancesCode: code, compactNumbers: compactNumbers);
    _state = await getData();
    notifyListeners();

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: currentTheme.brightness,
      statusBarBrightness: currentTheme.brightness == Brightness.light
          ? Brightness.dark
          : Brightness.light,
      systemNavigationBarColor: currentTheme.background,
      systemNavigationBarIconBrightness: currentTheme.brightness,
    ));
  }

  Future<void> setSelectedGasOption(GasFeeOption option) async {
    _selectedGasOption = option;
    await _prefs.setGasOption(_selectedWallet, option.name);
    notifyListeners();
  }

  set isTileView(bool value) {
    if (_isTileView != value) {
      _isTileView = value;
      notifyListeners();
    }
  }

  Future<void> updateIsTileView(bool value) async {
    if (_isTileView != value) {
      _isTileView = value;
      await _prefs.setIsTileView(_selectedWallet, value);
      notifyListeners();
    }
  }

  Future<void> setShowAddressesThroughTransactionHistory(bool value) async {
    _showAddressesThroughTransactionHistory = value;
    await _prefs.setShowAddressesHistory(_selectedWallet, value);
    notifyListeners();
  }

  Future<void> setBrowserUrlBarTop(bool value) async {
    _browserUrlBarTop = value;
    await _prefs.setBrowserUrlBarTop(value);
    notifyListeners();
  }

  Future<void> startTrackHistoryWorker() async {
    try {
      Stream<String> stream = startHistoryWorker(walletIndex: BigInt.from(selectedWallet));
      stream.listen((event) async {
        notifyListeners();
      });
    } catch (e) {
      debugPrint("start worker error: $e");
    }
  }

  NetworkConfigInfo? getChain(BigInt hash) {
    return state.providers.firstWhere((e) => e.chainHash == hash);
  }
}
