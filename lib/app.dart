import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:bearby/l10n/app_localizations.dart';
import 'router.dart';
import 'services/deep_link_service.dart';
import 'state/app_state.dart';

class BearbyApp extends StatefulWidget {
  final AppState appState;

  const BearbyApp({super.key, required this.appState});

  @override
  State<BearbyApp> createState() => _BearbyAppState();
}

class _BearbyAppState extends State<BearbyApp> {
  late final GoRouter _router;
  final _deepLinkService = DeepLinkService();

  @override
  void initState() {
    super.initState();
    _router = createRouter(widget.appState);
    _deepLinkService.initialize(_router, widget.appState);
  }

  @override
  void dispose() {
    _deepLinkService.dispose();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: widget.appState,
      child: Builder(
        builder: (context) {
          return Consumer<AppState>(
            builder: (context, appState, _) {
              final currentTheme = appState.currentTheme;

              return MaterialApp.router(
                routerConfig: _router,
                // debugShowCheckedModeBanner: false,
                title:
                    AppLocalizations.of(context)?.appTitle ?? 'Bearby Wallet',
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
              );
            },
          );
        },
      ),
    );
  }
}
