import 'package:flutter/widgets.dart';
import 'package:zilpay/src/rust/api/simple.dart';
import 'settings_page.dart';
import '../components/button.dart';

class HomePage extends StatelessWidget {
  Future<void> handleUnlock() async {
    await Future.delayed(Duration(seconds: 2)); 
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color(0xFF2C2C2C), 
      child: Center(
        child: CustomButton(
          text: "Unlock",
          color: Color(0xFF9C27B0),
          width: 200,
          height: 48,
          borderRadius: 24,
          fontSize: 16,
          onPressed: handleUnlock,
          loaderColor: Color(0xFFFFFFFF),
        ),
      ),
    );
  }
}

