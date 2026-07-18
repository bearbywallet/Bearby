import 'dart:async';
import 'dart:ui';

import 'package:bearby/src/rust/api/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bearby/ledger/ledger_view_controller.dart';
import 'package:bearby/mixins/gas_eip1559.dart';
import 'package:bearby/config/storage_keys.dart';
import 'package:bearby/config/web3_constants.dart';
import 'package:bearby/services/walletconnect_service.dart';
import 'package:bearby/src/rust/api/local_storage.dart';
import 'package:bearby/src/rust/api/backend.dart';
import 'package:bearby/src/rust/api/book.dart';
import 'package:bearby/src/rust/api/connections.dart';
import 'package:bearby/src/rust/api/settings.dart';
import 'package:bearby/src/rust/api/token.dart';
import 'package:bearby/src/rust/api/transaction.dart';
import 'package:bearby/src/rust/api/wallet.dart';
import 'package:bearby/src/rust/models/account.dart';
import 'package:bearby/src/rust/models/background.dart';
import 'package:bearby/src/rust/models/book.dart';
import 'package:bearby/src/rust/models/connection.dart';
import 'package:bearby/src/rust/models/provider.dart';
import 'package:bearby/src/rust/models/wallet.dart';
import 'package:bearby/theme/app_theme.dart';

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
  late LocalStorageImpl _storage;
  int _selectedWallet = -1;
  bool _hideBalance = false;
  bool _isTileView = false;
  bool _browserUrlBarTop = false;
  bool _isSyncingBalances = false;
  bool _isSyncingRates = false;

  final Brightness _systemBrightness =
      PlatformDispatcher.instance.platformBrightness;

  AppState({
    required BackgroundState state,
    required String cahceDir,
    required LocalStorageImpl storage,
  }) {
    WidgetsBinding.instance.addObserver(this);
    _state = state;
    _cahceDir = cahceDir;
    _storage = storage;
  }

  LocalStorageImpl get storage => _storage;

  void setSelectedWallet(int index) {
    _selectedWallet = index;
    notifyListeners();
  }

  void clearAuthentication() {
    _selectedWallet = -1;
    notifyListeners();
  }

  bool get isTileView => _isTileView;
  bool get browserUrlBarTop => _browserUrlBarTop;
  bool get showAddressesThroughTransactionHistory =>
      _showAddressesThroughTransactionHistory;
  GasFeeOption get selectedGasOption => _selectedGasOption;
  String get cahceDir => _cahceDir;
  bool get hideBalance => _hideBalance;
  bool get isSyncingBalances => _isSyncingBalances;
  bool get isSyncingRates => _isSyncingRates;
  List<WalletInfo> get wallets => _state.wallets;
  Locale? get locale => state.locale != null ? Locale(state.locale!) : null;
  List<ConnectionInfo> get connections => _connections;
  List<AddressBookEntryInfo> get book => _book;
  BackgroundState get state => _state;

  AppTheme get currentTheme {
    switch (_state.appearances) {
      case 0:
        return _systemBrightness == Brightness.dark
            ? DarkTheme()
            : LightTheme();
      case 1:
        return DarkTheme();
      case 2:
        return LightTheme();
      default:
        return _systemBrightness == Brightness.dark
            ? DarkTheme()
            : LightTheme();
    }
  }

  WalletInfo? get wallet {
    if (_selectedWallet < 0) return null;
    return _state.wallets.elementAtOrNull(_selectedWallet);
  }

  NetworkConfigInfo? get chain {
    BigInt? hash = wallet?.chainHash;
    if (hash == null) return null;
    return getChain(hash);
  }

  List<AccountInfo> get accounts {
    if (wallet == null) return [];
    int index = wallet!.selectedAccount.toInt();
    if (index < 0) return [];

    return wallet!.accounts[wallet!.slip44]?[wallet?.bip] ?? [];
  }

  AccountInfo? get account {
    if (wallet == null) return null;
    int index = wallet!.selectedAccount.toInt();
    if (index < 0) return null;
    return accounts.elementAtOrNull(index);
  }

  BigInt get accountBalanceKey =>
      addressToHash(addr: account?.addr ?? '');

  int get selectedWallet => _selectedWallet;

  /// Safe BigInt accessor — throws if no wallet is selected.
  BigInt get selectedWalletIndex {
    if (_selectedWallet < 0) {
      throw StateError('No wallet selected');
    }
    return BigInt.from(_selectedWallet);
  }

  BigInt? get selectedWalletIndexOrNull {
    if (_selectedWallet < 0) return null;
    return BigInt.from(_selectedWallet);
  }

  Future<void> setHideBalance(bool value) async {
    _hideBalance = value;
    await _storage.set_(key: StorageKeys.hideBalance, value: value.toString());
    notifyListeners();
  }

  Future<void> syncData() async {
    _state = await getData();
    await syncBook();
    await syncConnections();
    await _loadPreferences();
    notifyListeners();
  }

  Future<void> _loadPreferences() async {
    final hideBalance = await _storage.get_(key: StorageKeys.hideBalance);
    _hideBalance = hideBalance == 'true';

    final isTileView = await _storage.get_(
      key: StorageKeys.tokensCardStyleKey(_selectedWallet),
    );
    _isTileView = isTileView == 'true';

    final browserUrlBarTop = await _storage.get_(
      key: StorageKeys.browserUrlBarTop,
    );
    _browserUrlBarTop = browserUrlBarTop == 'true';

    final showAddressesHistory = await _storage.get_(
      key: StorageKeys.showAddressesHistoryKey(_selectedWallet),
    );
    _showAddressesThroughTransactionHistory = showAddressesHistory == 'true';

    await _loadGasOption();
  }

  Future<void> _loadGasOption() async {
    final optionName = await _storage.get_(
      key: StorageKeys.gasOptionKey(_selectedWallet),
    );
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
    final index = selectedWalletIndexOrNull;
    if (index == null) return;
    _connections = await getConnectionsList(walletIndex: index);
    notifyListeners();
  }

  /// Wraps the Rust balance sync so token amount UI can react while it runs.
  Future<void> syncBalancesTracked({required BigInt walletIndex}) async {
    _isSyncingBalances = true;
    notifyListeners();
    try {
      await syncBalances(walletIndex: walletIndex);
    } finally {
      _isSyncingBalances = false;
      notifyListeners();
    }
  }

  Future<void> syncRates({bool force = false}) async {
    if (chain?.testnet == true || wallet?.settings.ratesApiOptions == 0) return;
    final walletIndex = selectedWalletIndexOrNull;
    if (walletIndex == null) return;
    final now = DateTime.now();
    final tokens = wallet?.tokens;

    final hasZeroRate = tokens?.any((token) => token.rate == 0) ?? false;

    if (!force &&
        !hasZeroRate &&
        now.difference(_lastRateUpdateTime) < _rateUpdateCooldown) {
      return;
    }

    _isSyncingRates = true;
    notifyListeners();
    try {
      await updateRates(walletIndex: walletIndex);
      _lastRateUpdateTime = now;
    } catch (e) {
      debugPrint("error sync rates: $e");
    } finally {
      _isSyncingRates = false;
      notifyListeners();
    }
  }

  /// Pulls token balances from the chain and pushes them to the UI (via
  /// [syncData]) BEFORE fetching external rate quotes. The second
  /// [syncData] repaints the token list with the new rates.
  ///
  /// Sequencing rationale: rate fetches hit external HTTP endpoints
  /// (coingecko / zilstream / bearby-rates) and can take several seconds.
  /// Users should see updated balances while rates are still loading,
  /// not all at once at the end of the refresh.
  Future<void> refreshBalancesAndRates({required BigInt walletIndex}) async {
    await syncBalancesTracked(walletIndex: walletIndex);
    await syncData();
    await syncRates();
    await syncData();
  }

  Future<void> updateSelectedAccount(
      BigInt walletIndex, BigInt accountIndex) async {
    await selectAccount(walletIndex: walletIndex, accountIndex: accountIndex);
    await syncData();
    notifyListeners();
    // Notify WalletConnect dApps (accountsChanged) — fire-and-forget.
    unawaited(_notifyWalletConnectAccountChanged());
  }

  Future<void> _notifyWalletConnectAccountChanged() async {
    try {
      final acc = account;
      final ch = chain;
      if (acc == null || ch == null) return;
      final ns = _wcNamespaceForSlip44(ch.slip44);
      if (ns == null) return;
      final caip2 = '$ns:${ch.chainId}';
      await WalletConnectService.instance.onAccountsChanged(
        address: acc.addr,
        caip2: caip2,
      );
    } catch (e) {
      debugPrint('[wc] account-change notify: $e');
    }
  }

  static String? _wcNamespaceForSlip44(int slip44) {
    switch (slip44) {
      case kEthereumSlip44:
      case kZilliqaSlip44:
        return 'eip155';
      case kSolanaSlip44:
        return 'solana';
      case kTronSlip44:
        return 'tron';
      default:
        return null;
    }
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
    await _storage.set_(
      key: StorageKeys.gasOptionKey(_selectedWallet),
      value: option.name,
    );
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
      await _storage.set_(
        key: StorageKeys.tokensCardStyleKey(_selectedWallet),
        value: value.toString(),
      );
      notifyListeners();
    }
  }

  Future<void> setShowAddressesThroughTransactionHistory(bool value) async {
    _showAddressesThroughTransactionHistory = value;
    await _storage.set_(
      key: StorageKeys.showAddressesHistoryKey(_selectedWallet),
      value: value.toString(),
    );
    notifyListeners();
  }

  Future<void> setBrowserUrlBarTop(bool value) async {
    _browserUrlBarTop = value;
    await _storage.set_(
      key: StorageKeys.browserUrlBarTop,
      value: value.toString(),
    );
    notifyListeners();
  }

  Future<void> startTrackHistoryWorker() async {
    final walletIndex = selectedWalletIndexOrNull;
    if (walletIndex == null) return;
    try {
      Stream<String> stream = startHistoryWorker(walletIndex: walletIndex);
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
