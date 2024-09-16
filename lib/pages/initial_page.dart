import 'package:flutter/material.dart';

class InitialPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Initial Page'),
            SizedBox(height: 20),
            ElevatedButton(
              child: Text('Go to Main Page'),
              onPressed: () {
                Navigator.of(context).pushReplacementNamed('/new_wallet_options');
              },
            ),
          ],
        ),
      ),
    );
  }
}
