import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:zilpay/src/rust/api/backend.dart';
import 'package:zilpay/src/rust/api/ledger.dart';

import 'services/auth_guard.dart';
import 'state/app_state.dart';

import 'package:zilpay/src/rust/frb_generated.dart';
import 'app.dart';

Future<String> getStoragePath() async {
  final appDocDir = await getApplicationDocumentsDirectory();
  return appDocDir.path;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();

  BackgroundState state;

  try {
    String appDocPath = await getStoragePath();

    state = await startService(path: "$appDocPath/storage");
    final authGuard = AuthGuard();
    final appState = AppState(state: state);

    await authGuard.initialize(state.wallets.isNotEmpty);

    print(await scanLedgerDevices());

    runApp(ZilPayApp(authGuard: authGuard, appState: appState));
  } catch (e) {
    print("try start, Error: $e");
  }
}
