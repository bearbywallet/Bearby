import 'dart:ui';

import 'package:flutter/material.dart';
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
  List<AddressBookEntryInfo> _book = [];
  List<ConnectionInfo> _connections = [];
  DateTime _lastRateUpdateTime = DateTime.fromMillisecondsSinceEpoch(0);
  static const Duration _rateUpdateCooldown = Duration(minutes: 1);

  late BackgroundState _state;
  late String _cahceDir;
  int _selectedWallet = 0;
  final Brightness _systemBrightness =
      PlatformDispatcher.instance.platformBrightness;

  AppState({
    required BackgroundState state,
    required String cahceDir,
  }) {
    WidgetsBinding.instance.addObserver(this);
    _state = state;
    _cahceDir = cahceDir;
  }

  void setSelectedWallet(int index) {
    _selectedWallet = index;
    notifyListeners();
  }

  String get cahceDir {
    return _cahceDir;
  }

  List<WalletInfo> get wallets {
    return _state.wallets;
  }

  Locale? get locale {
    return state.locale != null ? Locale(state.locale!) : null;
  }

  List<ConnectionInfo> get connections {
    return _connections;
  }

  List<AddressBookEntryInfo> get book {
    return _book;
  }

  BackgroundState get state {
    return _state;
  }

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
    return _state.wallets[_selectedWallet];
  }

  NetworkConfigInfo? get chain {
    BigInt? hash = account?.chainHash;

    if (hash == null) {
      return null;
    }

    return getChain(hash);
  }

  AccountInfo? get account {
    if (wallet == null) {
      return null;
    }

    int index = wallet!.selectedAccount.toInt();

    return wallet!.accounts[index];
  }

  int get selectedWallet {
    return _selectedWallet;
  }

  get appDocument => null;

  Future<void> syncData() async {
    _state = await getData();
    await syncBook();
    await syncConnections();
    notifyListeners();
  }

  Future<void> syncBook() async {
    _book = await getAddressBookList();

    notifyListeners();
  }

  Future<void> syncConnections() async {
    _connections =
        await getConnectionsList(walletIndex: BigInt.from(_selectedWallet));

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

  Future<void> updateSelectedAccount(
    BigInt walletIndex,
    BigInt accountIndex,
  ) async {
    await selectAccount(walletIndex: walletIndex, accountIndex: accountIndex);
    await syncData();

    notifyListeners();
  }

  Future<void> setAppearancesCode(int code, bool compactNumbers) async {
    await setTheme(
      appearancesCode: code,
      compactNumbers: compactNumbers,
    );
    _state = await getData();
    notifyListeners();
  }

  Future<void> startTrackHistoryWorker() async {
    try {
      Stream<String> stream =
          startHistoryWorker(walletIndex: BigInt.from(selectedWallet));

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
