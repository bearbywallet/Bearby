import 'package:flutter/material.dart';

class BrowserPage extends StatelessWidget {
  const BrowserPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: Column(
        children: [Center(child: Text('Browser Page'))],
      ),
    );
  }
}
