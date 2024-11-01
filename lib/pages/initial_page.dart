import 'package:flutter/material.dart';

class InitialPage extends StatelessWidget {
  const InitialPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Initial Page'),
            const SizedBox(height: 20),
            ElevatedButton(
              child: const Text('Go to Main Page'),
              onPressed: () {
                Navigator.of(context).pushNamed('/new_wallet_options');
              },
            ),
          ],
        ),
      ),
    );
  }
}
