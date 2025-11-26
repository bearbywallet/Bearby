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
                  Locale('ko'),
                ],
                locale: appState.locale,
                builder: (context, child) {
                  final mediaQuery = MediaQuery.of(context);
                  final screenWidth = mediaQuery.size.width;

                  const double baseWidth = 390.0;

                  double scaleFactor = screenWidth / baseWidth;

                  final textScale = scaleFactor.clamp(0.85, 1.35);

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
                  splashFactory: NoSplash.splashFactory,
                  scaffoldBackgroundColor: currentTheme.background,
                  canvasColor: Colors.transparent,
                  fontFamily: 'SFRounded',
                  textTheme: TextTheme(
                    bodyLarge: TextStyle(
                        fontFamily: 'SFRounded',
                        color: currentTheme.textPrimary),
                    bodyMedium: TextStyle(
                        fontFamily: 'SFRounded',
                        color: currentTheme.textSecondary),
                    displayLarge: TextStyle(
                        fontFamily: 'SFRounded',
                        color: currentTheme.textPrimary,
                        fontSize: 34.0,
                        fontWeight: FontWeight.bold),
                    displayMedium: TextStyle(
                        fontFamily: 'SFRounded',
                        color: currentTheme.textPrimary,
                        fontSize: 28.0,
                        fontWeight: FontWeight.bold),
                    headlineMedium: TextStyle(
                        fontFamily: 'SFRounded',
                        color: currentTheme.textPrimary,
                        fontSize: 24.0,
                        fontWeight: FontWeight.w600),
                    titleMedium: TextStyle(
                        fontFamily: 'SFRounded',
                        color: currentTheme.textPrimary,
                        fontSize: 18.0,
                        fontWeight: FontWeight.w500),
                    labelLarge: TextStyle(
                        fontFamily: 'SFRounded',
                        color: currentTheme.buttonText,
                        fontSize: 16.0,
                        fontWeight: FontWeight.w500),
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
