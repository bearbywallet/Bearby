import 'package:flutter/material.dart';

import 'services/auth_guard.dart';
import 'state/app_state.dart';

import 'pages/main_page.dart';
import 'pages/login_page.dart';
import 'pages/initial_page.dart';
import 'pages/history_page.dart';
import 'pages/browser_page.dart';
import 'pages/settings_page.dart';

class AppRouter {
  final AuthGuard authGuard;
  final AppState appState;

  AppRouter({required this.authGuard, required this.appState});

  Route<dynamic> onGenerateRoute(RouteSettings settings) {
    if (!authGuard.ready) {
      return MaterialPageRoute(builder: (_) => InitialPage());
    } else if (!authGuard.enabled) {
      return MaterialPageRoute(builder: (_) => LoginPage());
    }

    switch (settings.name) {
      case '/':
          return MaterialPageRoute(builder: (_) => MainPage());
      case '/history':
        return MaterialPageRoute(builder: (_) => HistoryPage());
      case '/browser':
        return MaterialPageRoute(builder: (_) => BrowserPage());
      case '/settings':
        return MaterialPageRoute(builder: (_) => SettingsPage());
      default:
        return MaterialPageRoute(builder: (_) => MainPage()); // TODO: make an error page
    }
  }
}
