import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

              SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: currentTheme.brightness,
                statusBarBrightness: currentTheme.brightness == Brightness.light
                    ? Brightness.dark
                    : Brightness.light,
                systemNavigationBarColor: currentTheme.background,
                systemNavigationBarIconBrightness: currentTheme.brightness,
              ));

              return MaterialApp(
                // debugShowCheckedModeBanner: false,
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
                  Locale('ja'),
                  Locale('zh'),
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
                  canvasColor: Colors.transparent,
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
                  checkboxTheme: CheckboxThemeData(
                    side: BorderSide(
                      color: currentTheme.primaryPurple,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(3.0),
                    ),
                  ),
                  colorScheme: currentTheme.brightness == Brightness.light
                      ? ColorScheme.light(
                          primary: currentTheme.primaryPurple,
                          secondary: currentTheme.secondaryPurple,
                          error: currentTheme.danger,
                          surface: currentTheme.buttonText,
                        )
                      : ColorScheme.dark(
                          primary: currentTheme.primaryPurple,
                          secondary: currentTheme.secondaryPurple,
                          error: currentTheme.danger,
                          surface: currentTheme.buttonText,
                        ),
                  switchTheme: SwitchThemeData(
                    overlayColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return currentTheme.primaryPurple
                            .withValues(alpha: 0.1);
                      }
                      return null;
                    }),
                    trackColor: WidgetStateProperty.resolveWith((states) {
                      if (!states.contains(WidgetState.selected)) {
                        return currentTheme.textSecondary
                            .withValues(alpha: 0.3);
                      }

                      return currentTheme.primaryPurple.withValues(alpha: 0.2);
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
