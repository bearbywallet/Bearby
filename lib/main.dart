import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:zilpay/src/rust/api/backend.dart';

import 'services/auth_guard.dart';
import 'state/app_state.dart';

import 'package:zilpay/src/rust/frb_generated.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();

  try {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String appDocPath = appDocDir.path;

    List<WalletInfo> wallets = await startService(path: appDocPath);

    final authGuard = AuthGuard();
    await authGuard.initialize(wallets.isNotEmpty);

    final appState = AppState();
    await appState.initialize();

    runApp(ZilPayApp(authGuard: authGuard, appState: appState));
  } catch (e) {
    print('Error getting directory: $e');
  }
}
