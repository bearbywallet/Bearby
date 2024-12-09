import 'package:flutter/material.dart';
import 'package:zilpay/src/rust/api/backend.dart';

class Connection {
  final String name;
  final String url;
  final String iconUrl;
  final DateTime lastConnected;
  final String account;
  final int chainId;
  final String origin;
  final int version;

  Connection({
    required this.name,
    required this.url,
    required this.iconUrl,
    required this.lastConnected,
    required this.account,
    required this.chainId,
    required this.origin,
    this.version = 1,
  });
}

class AppState extends ChangeNotifier {
  BackgroundState _state;
  int _selectedWallet = 0;

  AppState({required BackgroundState state}) : _state = state;

  void setSelectedWallet(int index) {
    _selectedWallet = index;
    notifyListeners();
  }

  List<WalletInfo> get wallets {
    return _state.wallets;
  }

  List<Connection> get connectedDapps {
    return [
      Connection(
        name: 'Zilswap',
        url: 'https://zilswap.io',
        iconUrl: 'https://zilswap.io/assets/favicon/apple-touch-icon.png',
        lastConnected: DateTime.now().subtract(const Duration(minutes: 30)),
        account: '0x742d35Cc6634C0532925a3b844Bc454e4438f44e',
        chainId: 1,
        origin: 'mintgate.io',
      ),
      Connection(
        name: 'DragonZIL',
        url: 'dragonzil.xyz',
        iconUrl: 'https://dragonzil.xyz/favicon/apple-icon-57x57.png',
        lastConnected: DateTime.now().subtract(const Duration(days: 1)),
        account: '0x742d35Cc6634C0532925a3b844Bc454e4438f44e',
        chainId: 1,
        origin: 'dragonzil.xyz',
      ),
    ];
  }

  WalletInfo? get wallet {
    return _state.wallets[_selectedWallet];
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

  Future<void> syncData() async {
    _state = await getData();
    notifyListeners();
  }

  Future<void> initialize() async {
    // TODO: init theme form storage
  }

  Future<void> updateSelectedAccount(
      BigInt walletIndex, BigInt accountIndex) async {
    await selectAccount(walletIndex: walletIndex, accountIndex: accountIndex);
    await syncData();

    notifyListeners();
  }
}
