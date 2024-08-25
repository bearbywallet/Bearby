import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'pages/settings_page.dart';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => HomePage());
      case '/settings':
        return MaterialPageRoute(builder: (_) => SettingsPage());
      default:
        return _errorRoute();
    }
  }

  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute(builder: (_) {
      return Scaffold(
        appBar: AppBar(title: Text('Error')),
        body: Center(child: Text('Page not found')),
      );
    });
  }
}
