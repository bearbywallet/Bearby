import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'router.dart';
import 'services/auth_guard.dart';
import 'state/app_state.dart';
import './theme/theme_provider.dart';

class ZilPayApp extends StatelessWidget {
  final AuthGuard authGuard;
  final AppState appState;

  const ZilPayApp({super.key, required this.authGuard, required this.appState});

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
                scaffoldBackgroundColor: currentTheme.background),
            initialRoute: '/cipher_setup',
            onGenerateRoute: AppRouter(authGuard: authGuard, appState: appState)
                .onGenerateRoute,
          );
        },
      ),
    );
  }
}
