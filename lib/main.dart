import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:zilpay/src/rust/api/backend.dart';

import 'services/auth_guard.dart';
import 'state/app_state.dart';

import 'package:zilpay/src/rust/frb_generated.dart';
import 'app.dart';

Future<String> getStoragePath() async {
  if (!kReleaseMode) {
    if (Platform.isAndroid) {
      final directory = await getExternalStorageDirectory();
      final devDir = Directory('${directory?.path}/dev_storage');
      if (!await devDir.exists()) {
        await devDir.create(recursive: true);
      }
      return devDir.path;
    } else if (Platform.isIOS) {
      final directory = await getApplicationSupportDirectory();
      final devDir = Directory('${directory.path}/dev_storage');
      if (!await devDir.exists()) {
        await devDir.create(recursive: true);
      }
      return devDir.path;
    }
  }

  final appDocDir = await getApplicationDocumentsDirectory();
  return appDocDir.path;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();

  List<WalletInfo> wallets = [];

  try {
    String appDocPath = await getStoragePath();

    print(appDocPath);

    wallets = await startService(path: appDocPath);
  } catch (e) {
    if (e == "service already running") {
      wallets = await getWallets();
    } else {
      print("try start service: $e");
    }
  }

  try {
    print(wallets);
    final authGuard = AuthGuard();
    await authGuard.initialize(wallets.isNotEmpty);

    final appState = AppState();
    await appState.initialize();

    runApp(ZilPayApp(authGuard: authGuard, appState: appState));
  } catch (e) {
    print('Error try start page: $e');
  }
}
