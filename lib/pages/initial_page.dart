import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:bearby/components/button.dart';
import 'package:bearby/l10n/app_localizations.dart';
import 'package:bearby/mixins/status_bar.dart';
import 'package:bearby/state/app_state.dart';
import 'package:go_router/go_router.dart';
import 'package:bearby/router.dart';

class InitialPage extends StatefulWidget {
  const InitialPage({super.key});

  @override
  State<InitialPage> createState() => _InitialPageState();
}

class _InitialPageState extends State<InitialPage> with StatusBarMixin {
  @override
  void initState() {
    super.initState();
  }

  Future<void> _toggleTheme() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final newAppearance = switch (appState.state.appearances) {
      0 => PlatformDispatcher.instance.platformBrightness == Brightness.dark
          ? 2
          : 1,
      1 => 2,
      _ => 1,
    };
    await appState.setAppearancesCode(
        newAppearance, appState.state.abbreviatedNumber);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<AppState>(context).currentTheme;
    final l10n = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final maxWidth = screenWidth < 600 ? double.infinity : 600.0;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        toolbarHeight: 0,
        systemOverlayStyle: getSystemUiOverlayStyle(context),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: SvgPicture.asset(
                          'assets/icons/moon_sun.svg',
                          width: 30,
                          height: 30,
                          colorFilter: ColorFilter.mode(
                              theme.textPrimary, BlendMode.srcIn),
                        ),
                        onPressed: _toggleTheme,
                      ),
                      IconButton(
                        icon: SvgPicture.asset(
                          'assets/icons/language.svg',
                          width: 34,
                          height: 34,
                          colorFilter: ColorFilter.mode(
                              theme.textPrimary, BlendMode.srcIn),
                        ),
                        onPressed: () => context.push(AppRoutes.language),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: SvgPicture.asset(
                      'assets/icons/bear.svg',
                      width: 400,
                      height: 400,
                      colorFilter: ColorFilter.mode(
                        theme.textPrimary,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.only(left: 16, right: 16, bottom: 32),
                  child: CustomButton(
                          textColor: theme.buttonText,
                          backgroundColor: theme.primaryPurple,
                          text: l10n.initialPagegetStarted,
                          onPressed: () => context.push(AppRoutes.netSetup),
                          borderRadius: 30.0,
                          height: 56.0,
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
