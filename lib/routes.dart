import 'package:flutter/widgets.dart';
import 'pages/home_page.dart';
import 'pages/settings_page.dart';
import 'pages/login_page.dart';
import 'pages/error_page.dart';
import 'services/auth_service.dart';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return _buildRoute(settings, HomePage());
      case '/settings':
        return _guardedRoute(settings, SettingsPage());
      default:
        return _errorRoute();
    }
  }

  static Route<dynamic> _buildRoute(RouteSettings settings, Widget page) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;
        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);
        return SlideTransition(position: offsetAnimation, child: child);
      },
    );
  }

  static Route<dynamic> _guardedRoute(RouteSettings settings, Widget page) {
    return _buildRoute(
      settings,
      authService.isAuthenticated
          ? page
          : LoginPage(afterLogin: () => _navigateToRouteAfterLogin(settings)),
    );
  }

  static void _navigateToRouteAfterLogin(RouteSettings settings) {
    // Implement navigation logic here
  }

  static Route<dynamic> _errorRoute() {
    return _buildRoute(RouteSettings(name: '/error'), ErrorPage());
  }
}
