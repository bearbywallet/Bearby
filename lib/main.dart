import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:zilpay/src/rust/api/backend.dart';
import 'package:zilpay/src/rust/models/background.dart';

import 'services/auth_guard.dart';
import 'state/app_state.dart';

import 'package:zilpay/src/rust/frb_generated.dart';
import 'app.dart';

Future<String> getStoragePath() async {
  final appDocDir = await getApplicationSupportDirectory();
  return appDocDir.path;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await RustLib.init();

  BackgroundState state;

  try {
    String appDocPath = await getStoragePath();
    final tempDir = await getTemporaryDirectory();

    final directory = Directory(tempDir.path);

    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    state = await loadService(path: "$appDocPath/storage");

    final appState = AppState(
      state: state,
      cahceDir: tempDir.path,
    );

    await appState.loadHideBalance();

    final authGuard = AuthGuard(state: appState);

    runApp(ZilPayApp(authGuard: authGuard, appState: appState));
  } catch (e) {
    debugPrint("try start, Error: $e");
  }
}
