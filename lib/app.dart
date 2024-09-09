import 'package:flutter/widgets.dart';
import 'routes.dart';
import 'theme/app_theme.dart';

class ZilPayApp extends StatelessWidget {
  const ZilPayApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WidgetsApp(
      title: 'ZilPay App',
      color: AppTheme.primaryColor, 
      initialRoute: '/',
      onGenerateRoute: RouteGenerator.generateRoute,
      builder: (context, child) {
        // Применяем глобальные стили здесь
        return Container(
          color: AppTheme.backgroundColor,
          child: child,
        );
      },
      textStyle: AppTheme.bodyMedium, 
    );
  }
}
