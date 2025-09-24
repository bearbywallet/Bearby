import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../components/bottom_nav_bar.dart';
import './home_page.dart';
import './history_page.dart';
import './browser_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => MainPageState();
}

class MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const <Widget>[
    HomePage(),
    HistoryPage(),
    BrowserPage(),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final selectedIndex = args?['selectedIndex'] as int?;

    if (selectedIndex != null && selectedIndex != _selectedIndex) {
      setState(() {
        _selectedIndex = selectedIndex;
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
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
        child: IndexedStack(
          index: _selectedIndex,
          children: _pages,
        ),
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
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
