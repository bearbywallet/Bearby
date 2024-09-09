import 'package:flutter/widgets.dart';

class LoginPage extends StatelessWidget {
  final VoidCallback afterLogin;

  const LoginPage({Key? key, required this.afterLogin}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF0F0F0), 
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Вход',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF333333),
              ),
            ),
            SizedBox(height: 20),
            SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                print('Попытка входа');
                afterLogin();
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  'Войти',
                  style: TextStyle(
                    color: const Color(0xFFFFFFFF),
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
