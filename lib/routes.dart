import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'pages/settings_page.dart';
import 'pages/login_page.dart';
import 'services/auth_service.dart';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => HomePage());
      case '/settings':
        return _guardedRoute(settings, SettingsPage());
      case '/login':
        return MaterialPageRoute(builder: (_) => LoginPage());
      default:
        return _errorRoute();
    }
  }

  static Route<dynamic> _guardedRoute(RouteSettings settings, Widget page) {
    return MaterialPageRoute(
      builder: (_) => authService.isAuthenticated
          ? page
          : LoginPage(afterLogin: () => _navigateToRouteAfterLogin(settings)),
    );
  }

  static void _navigateToRouteAfterLogin(RouteSettings settings) {
    // Navigator.of(settings.context!).pushReplacementNamed(settings.name!);
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
