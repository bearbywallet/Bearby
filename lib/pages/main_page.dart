import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../components/bottom_nav_bar.dart';
import '../src/rust/api/token.dart';
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
      _loadInitialData();
    }
  }

  Future<void> _loadInitialData() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final walletIndex = appState.selectedWalletIndex;

    try {
      await syncBalances(walletIndex: walletIndex);
    } catch (_) {}

    await appState.syncRates();
    await appState.syncData();
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
            CustomBottomNavigationBarItem(iconPath: 'assets/icons/wallet.svg'),
            CustomBottomNavigationBarItem(iconPath: 'assets/icons/history.svg'),
            CustomBottomNavigationBarItem(iconPath: 'assets/icons/nav.svg'),
          ],
          currentIndex: widget.shell.currentIndex,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
