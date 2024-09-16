import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'router.dart';
import 'services/auth_guard.dart';
import 'state/app_state.dart';
import './theme/theme_provider.dart';

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
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          final currentTheme = themeProvider.currentTheme;
          return MaterialApp(
            title: 'ZilPay Wallet',
            theme: ThemeData(
              primaryColor: currentTheme.primaryPurple,
              scaffoldBackgroundColor: currentTheme.background
            ),
            initialRoute: '/new_wallet_options',
            onGenerateRoute: AppRouter(authGuard: authGuard, appState: appState).onGenerateRoute,
          );
        },
      ),
    );
  }
}
