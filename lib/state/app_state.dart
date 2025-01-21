import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:zilpay/src/rust/api/backend.dart';
import 'package:zilpay/src/rust/api/book.dart';
import 'package:zilpay/src/rust/api/connections.dart';
import 'package:zilpay/src/rust/api/settings.dart';
import 'package:zilpay/src/rust/api/token.dart';
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
  Map<String, double> _rates = {};

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

  List<ConnectionInfo> get connections {
    return _connections;
  }

  List<AddressBookEntryInfo> get book {
    return _book;
  }

  Map<String, double> get rates {
    return _rates;
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
    // await syncTokenRates();
    notifyListeners();
  }

  Future<void> syncBook() async {
    _book = await getAddressBookList();

    notifyListeners();
  }

  Future<void> syncTokenRates() async {
    if (wallet?.settings.currencyConvert?.isEmpty ?? true) {
      return;
    }

    try {
      String value = await getRates();

      Map<String, dynamic> rawJson = jsonDecode(value);
      Map<String, double> jsonValue = rawJson
          .map((key, value) => MapEntry(key, double.parse(value.toString())));
      _rates = jsonValue;

      notifyListeners();
    } catch (e) {
      debugPrint("error get rates $e");
    }
  }

  Future<void> updateTokensRates() async {
    if (wallet?.settings.currencyConvert?.isEmpty ?? true) {
      return;
    }

    try {
      await updateRates();
      notifyListeners();
    } catch (e) {
      debugPrint("error fetch rates $e");
    }
  }

  Future<void> syncConnections() async {
    _connections = await getConnectionsList();

    notifyListeners();
  }

  Future<void> updateSelectedAccount(
      BigInt walletIndex, BigInt accountIndex) async {
    await selectAccount(walletIndex: walletIndex, accountIndex: accountIndex);
    await syncData();

    notifyListeners();
  }

  Future<void> setAppearancesCode(int code) async {
    await setTheme(appearancesCode: code);
    _state = await getData();
    notifyListeners();
  }

  NetworkConfigInfo? getChain(BigInt hash) {
    return state.providers.firstWhere((e) => e.chainHash == hash);
  }
}
