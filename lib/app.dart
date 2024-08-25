import 'package:flutter/material.dart';
import 'routes.dart';

class ZilPayApp extends StatelessWidget {
  const ZilPayApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Flutter App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/settings',
      onGenerateRoute: RouteGenerator.generateRoute,
    );
  }
}
