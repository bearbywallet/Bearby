import 'package:flutter/material.dart';

import '../components/bottom_nav_bar.dart';
import '../components/gradient_bg.dart';
import './home_page.dart';
import './history_page.dart';
import './browser_page.dart';

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  static List<Widget> _pages = <Widget>[
    GradientBackground(child: HomePage()),
    GradientBackground(child: HistoryPage()),
    GradientBackground(child: BrowserPage())
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
