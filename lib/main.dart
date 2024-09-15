import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';

import 'services/auth_guard.dart';
import 'state/app_state.dart';

import 'package:zilpay/src/rust/frb_generated.dart';
import 'package:zilpay/src/rust/frb_generated.dart';
import 'app.dart';


Future<void> printApplicationDocumentsDirectory() async {
  try {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String appDocPath = appDocDir.path;
    print('Application Documents Directory: $appDocPath');
  } catch (e) {
    print('Error getting directory: $e');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();

  final authGuard = AuthGuard();
  await authGuard.initialize();
  
  final appState = AppState();
  await appState.initialize();
  
  runApp(ZilPayApp(authGuard: authGuard, appState: appState));
}

