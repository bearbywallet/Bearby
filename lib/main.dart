import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:zilpay/src/rust/api/simple.dart';
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
  runApp(const ZilPayApp());
}
