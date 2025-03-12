import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/l10n/app_localizations.dart';
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
                title:
                    AppLocalizations.of(context)?.appTitle ?? 'ZilPay Wallet',
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: const [
                  Locale('en'),
                  Locale('ru'),
                ],
                locale: appState.locale,
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
                  brightness: currentTheme.brightness,
                  primaryColor: currentTheme.primaryPurple,
                  cardColor: currentTheme.cardBackground,
                  scaffoldBackgroundColor: currentTheme.background,
                  canvasColor: currentTheme.background,
                  textTheme: TextTheme(
                    bodyLarge: TextStyle(color: currentTheme.textPrimary),
                    bodyMedium: TextStyle(color: currentTheme.textSecondary),
                  ),
                  pageTransitionsTheme: const PageTransitionsTheme(
                    builders: {
                      TargetPlatform.android:
                          FadeUpwardsPageTransitionsBuilder(),
                      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
                    },
                  ),
                  colorScheme: currentTheme.brightness == Brightness.light
                      ? ColorScheme.light(
                          primary: currentTheme.primaryPurple,
                          secondary: currentTheme.secondaryPurple,
                          error: currentTheme.danger,
                          surface: currentTheme.cardBackground,
                        )
                      : ColorScheme.dark(
                          primary: currentTheme.primaryPurple,
                          secondary: currentTheme.secondaryPurple,
                          error: currentTheme.danger,
                          surface: currentTheme.cardBackground,
                        ),
                  switchTheme: SwitchThemeData(
                    trackColor: WidgetStateProperty.resolveWith((states) {
                      if (!states.contains(WidgetState.selected)) {
                        return currentTheme.textSecondary
                            .withValues(alpha: 0.3);
                      }
                      return null;
                    }),
                    thumbColor: WidgetStateProperty.resolveWith((states) {
                      if (!states.contains(WidgetState.selected)) {
                        return currentTheme.textSecondary;
                      }
                      return null;
                    }),
                    trackOutlineColor:
                        WidgetStateProperty.resolveWith((states) {
                      if (!states.contains(WidgetState.selected)) {
                        return currentTheme.cardBackground;
                      }
                      return currentTheme.cardBackground;
                    }),
                  ),
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
