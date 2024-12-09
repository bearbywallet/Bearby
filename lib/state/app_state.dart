import 'package:flutter/material.dart';
import 'package:zilpay/src/rust/api/backend.dart';

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
