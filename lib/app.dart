import 'package:flutter/material.dart';

import 'router.dart';
import 'services/auth_guard.dart';
import 'state/app_state.dart';

import 'pages/main_page.dart';


class ZilPayApp extends StatelessWidget {
  final AuthGuard authGuard;
  final AppState appState;

  const ZilPayApp({
    Key? key,
    required this.authGuard,
    required this.appState
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ZilPay Wallet',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.purple,
        scaffoldBackgroundColor: Colors.black,
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.black,
          selectedItemColor: Colors.purple,
          unselectedItemColor: Colors.grey,
        ),
      ),
      initialRoute: '/',
      onGenerateRoute: AppRouter(authGuard: authGuard, appState: appState).onGenerateRoute,
    );
  }
}
