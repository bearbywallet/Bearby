import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'router.dart';
import 'services/auth_guard.dart';
import 'state/app_state.dart';

class ZilPayApp extends StatelessWidget {
  final AuthGuard authGuard;
  final AppState appState;

  const ZilPayApp({super.key, required this.authGuard, required this.appState});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authGuard),
        ChangeNotifierProvider.value(value: appState),
      ],
      child: Builder(
        builder: (context) {
          return Consumer<AppState>(
            builder: (context, appState, _) {
              final currentTheme = appState.currentTheme;

              return MaterialApp(
                title: 'ZilPay Wallet',
                builder: (context, child) {
                  final mediaQuery = MediaQuery.of(context);
                  final screenWidth = mediaQuery.size.width;

                  double textScale = 1.0;

                  if (screenWidth <= 375) {
                    textScale = 0.8;
                  } else if (screenWidth <= 390) {
                    textScale = 0.85;
                  }

                  return MediaQuery(
                    data: mediaQuery.copyWith(
                      textScaler: TextScaler.linear(textScale),
                    ),
                    child: child!,
                  );
                },
                theme: ThemeData(
                  primaryColor: currentTheme.primaryPurple,
                  scaffoldBackgroundColor: currentTheme.background,
                ),
                initialRoute: '/',
                onGenerateRoute: AppRouter(
                  authGuard: Provider.of<AuthGuard>(context, listen: false),
                  appState: Provider.of<AppState>(context, listen: false),
                ).onGenerateRoute,
              );
            },
          );
        },
      ),
    );
  }
}
