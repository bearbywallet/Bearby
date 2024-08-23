import 'dart:io';

import 'package:flutter/material.dart';
import 'package:zilpay/src/rust/api/simple.dart';
import 'package:zilpay/src/rust/frb_generated.dart';
import 'package:path_provider/path_provider.dart';

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
  await RustLib.init();

  runApp(const MyApp());

  printApplicationDocumentsDirectory();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('flutter_rust_bridge quickstart')),
        body: Center(
          child: Text(
              'Action: Call Rust `greet("Tom")`\nResult: `${greet(name: "Tom")}`'),
        ),
      ),
    );
  }
}
