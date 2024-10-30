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
            builder: (context, child) {
              final mediaQuery = MediaQuery.of(context);
              final screenWidth = mediaQuery.size.width;

              double textScale = 1.0;

              if (screenWidth <= 375) {
                textScale = 0.8;
              } else if (screenWidth <= 390) {
                textScale = 0.8;
              } else if (screenWidth <= 414) {
                textScale = 0.9;
              } else if (screenWidth <= 428) {
                textScale = 0.95;
              }

              return MediaQuery(
                data: mediaQuery.copyWith(
                  textScaleFactor: textScale,
                ),
                child: child!,
              );
            },
            theme: ThemeData(
                primaryColor: currentTheme.primaryPurple,
                scaffoldBackgroundColor: currentTheme.background),
            initialRoute: '/net_setup',
            onGenerateRoute: AppRouter(authGuard: authGuard, appState: appState)
                .onGenerateRoute,
          );
        },
      ),
    );
  }
}
