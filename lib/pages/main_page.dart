import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:bearby/components/app_icon.dart';
import 'package:bearby/l10n/app_localizations.dart';
import '../components/bottom_nav_bar.dart';
import '../state/app_state.dart';

class MainPage extends StatefulWidget {
  final StatefulNavigationShell shell;

  const MainPage({super.key, required this.shell});

  @override
  State<MainPage> createState() => MainPageState();
}

class MainPageState extends State<MainPage> {
  static bool _hasInitialDataLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_hasInitialDataLoaded) {
      _hasInitialDataLoaded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _loadInitialData();
      });
    }
  }

  Future<void> _loadInitialData() async {
    final appState = Provider.of<AppState>(context, listen: false);

    try {
      await appState.refreshBalancesAndRates(
        walletIndex: appState.selectedWalletIndex,
      );
    } catch (e) {
      debugPrint('initial data load error: $e');
    }
  }

  void _onItemTapped(int index) {
    widget.shell.goBranch(
      index,
      initialLocation: index == widget.shell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color effectiveBgColor = Theme.of(context).scaffoldBackgroundColor;
    final Brightness backgroundBrightness =
        ThemeData.estimateBrightnessForColor(effectiveBgColor);
    final Brightness statusBarIconBrightness =
        backgroundBrightness == Brightness.light
            ? Brightness.dark
            : Brightness.light;
    final Brightness statusBarBrightness = backgroundBrightness;

    final SystemUiOverlayStyle overlayStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: statusBarIconBrightness,
      statusBarBrightness: statusBarBrightness,
    );

    final l10n = AppLocalizations.of(context);

    return Scaffold(
      extendBody: true,
      body: SafeArea(
        top: true,
        bottom: false,
        child: widget.shell,
      ),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        toolbarHeight: 0,
        systemOverlayStyle: overlayStyle,
      ),
      bottomNavigationBar: SafeArea(
        child: CustomBottomNavigationBar(
          items: [
            CustomBottomNavigationBarItem(
              icon: AppIcon.wallet,
              label: l10n?.notificationsSettingsPageWalletPrefix,
            ),
            CustomBottomNavigationBarItem(
              icon: AppIcon.history,
              label: l10n?.addressSelectModalContentHistory,
            ),
            CustomBottomNavigationBarItem(
              icon: AppIcon.exchange,
              label: l10n?.exchangePageTabSwap,
            ),
            CustomBottomNavigationBarItem(
              icon: AppIcon.compass,
              label: l10n?.settingsPageBrowser,
            ),
          ],
          currentIndex: widget.shell.currentIndex,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
