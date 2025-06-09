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

  static final List<Widget> _pages = <Widget>[
    const HomePage(),
    const HistoryPage(),
    // const ChatPage(),
    const BrowserPage()
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final selectedIndex = args?['selectedIndex'] as int?;

    if (selectedIndex != null) {
      _selectedIndex = selectedIndex;
    }
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) {
      return;
    }

    Navigator.push(
      context,
      PageRouteBuilder<MainPage>(
        settings: RouteSettings(
          name: '/',
          arguments: {'selectedIndex': index},
        ),
        pageBuilder: (_, __, ___) => const MainPage(),
      ),
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
      body: _pages.elementAt(_selectedIndex),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        toolbarHeight: 0,
        systemOverlayStyle: overlayStyle,
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        items: [
          CustomBottomNavigationBarItem(iconPath: 'assets/icons/wallet.svg'),
          CustomBottomNavigationBarItem(iconPath: 'assets/icons/history.svg'),
          // CustomBottomNavigationBarItem(iconPath: 'assets/icons/ai.svg'),
          CustomBottomNavigationBarItem(iconPath: 'assets/icons/nav.svg'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
