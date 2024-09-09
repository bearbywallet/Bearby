import 'package:flutter/material.dart';
import 'package:zilpay/src/rust/api/simple.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _rustGreeting = '';
  String _serviceMessage = '';

  @override
  void initState() {
    super.initState();
    _updateRustGreeting();
    _listenToService();
  }

  void _updateRustGreeting() {
    setState(() {
      _rustGreeting = greet(name: "User");
    });
  }

  void _listenToService() {
    Stream<String> serviceStream = startBackgroundService();
    serviceStream.listen((String message) {
      setState(() {
        _serviceMessage = message;
      });
    });
  }

  void _tryInitBip39() {
    setState(() {
      _rustGreeting = generateWallet(message: "green process gate doctor slide whip priority shrug diamond crumble average help");
    });
  }

  void _sendMessageToService() {
    sendMessageToService(message: 'Hello from HomePage');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ZilPay Home'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Rust Greeting: $_rustGreeting'),
            const SizedBox(height: 20),
            Text('Last Service Message: $_serviceMessage'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _sendMessageToService,
              child: const Text('Send Message to Service'),
            ),
            ElevatedButton(
              onPressed: _tryInitBip39,
              child: const Text('try init bip39'),
            ),
            ElevatedButton(
              child: const Text('Go to Settings'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
