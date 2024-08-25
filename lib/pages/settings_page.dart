import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _darkMode = false;
  bool _notifications = true;
  String _selectedLanguage = 'English';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Dark Mode'),
            value: _darkMode,
            onChanged: (bool value) {
              setState(() {
                _darkMode = value;
              });
            },
          ),
          SwitchListTile(
            title: const Text('Notifications'),
            value: _notifications,
            onChanged: (bool value) {
              setState(() {
                _notifications = value;
              });
            },
          ),
          ListTile(
            title: const Text('Language'),
            trailing: DropdownButton<String>(
              value: _selectedLanguage,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedLanguage = newValue;
                  });
                }
              },
              items: <String>['English', 'Russian', 'Spanish']
                .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton(
              child: const Text('Apply Settings'),
              onPressed: () {
                // Here you would typically save the settings
                // For now, we'll just show a snackbar
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Settings applied')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
