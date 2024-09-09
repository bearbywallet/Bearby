import 'package:flutter/widgets.dart';
import 'package:zilpay/src/rust/api/simple.dart';
import 'settings_page.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFFFFFF), 
      child: Center(
        child: Text(
          'Hello',
          style: TextStyle(
            color: const Color(0xFF000000),
            fontSize: 24,
          ),
        ),
      ),
    );
  }
}

