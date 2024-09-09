import 'package:flutter/material.dart';
import 'routes.dart';
import 'theme/app_theme.dart';

class ZilPayApp extends StatelessWidget {
  const ZilPayApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Flutter App',
      theme: AppTheme.darkTheme,
      initialRoute: '/',
      onGenerateRoute: RouteGenerator.generateRoute,
    );
  }
}
