import 'package:flutter/material.dart';
import '../state/app_state.dart';

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final appState = AppState();
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Text('Choose Theme:'),
            // DropdownButton<AppTheme>(
            //   value: appState.currentTheme,
            //   onChanged: (AppTheme? newValue) {
            //     if (newValue != null) {
            //       appState.setTheme(newValue);
            //     }
            //   },
            //   items: AppTheme.values.map((AppTheme theme) {
            //     return DropdownMenuItem<AppTheme>(
            //       value: theme,
            //       child: Text(theme.toString().split('.').last),
            //     );
            //   }).toList(),
            // ),
          ],
        ),
      ),
    );
  }
}
