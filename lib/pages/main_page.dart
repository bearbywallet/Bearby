import 'package:flutter/material.dart';
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

    Navigator.of(context).push(
      MaterialPageRoute<MainPage>(
        builder: (context) => const MainPage(),
        settings: RouteSettings(
          name: '/',
          arguments: {'selectedIndex': index},
        ),
        barrierDismissible: true,
        allowSnapshotting: false,
        fullscreenDialog: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: _pages.elementAt(_selectedIndex),
      bottomNavigationBar: CustomBottomNavigationBar(
        items: [
          CustomBottomNavigationBarItem(iconPath: 'assets/icons/wallet.svg'),
          CustomBottomNavigationBarItem(iconPath: 'assets/icons/history.svg'),
          CustomBottomNavigationBarItem(iconPath: 'assets/icons/nav.svg'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
