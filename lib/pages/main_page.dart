import 'package:flutter/material.dart';

import '../components/bottom_nav_bar.dart';
import './home_page.dart';

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;
  
  static List<Widget> _pages = <Widget>[
    HomePage(),
    Center(child: Text('Home Page')),
    Center(child: Text('Browser Page')),
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
          CustomBottomNavigationBarItem(icon: Icons.account_balance_wallet),
          CustomBottomNavigationBarItem(icon: Icons.flash_on),
          CustomBottomNavigationBarItem(icon: Icons.language),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
