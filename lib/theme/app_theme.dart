import 'package:flutter/widgets.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF9C27B0);
  static const Color accentColor = Color(0xFFE91E63);
  static const Color backgroundColor = Color(0xFF2C2C2C);
  static const Color surfaceColor = Color(0xFF3C3C3C);
  static const Color textColor = Color(0xFFFFFFFF);
  static const Color secondaryTextColor = Color(0xFF9E9E9E);

  static const double borderRadius = 8.0;

  static const TextStyle bodyLarge = TextStyle(
    color: textColor,
    fontSize: 16,
    fontWeight: FontWeight.normal,
  );

  static const TextStyle bodyMedium = TextStyle(
    color: textColor,
    fontSize: 14,
    fontWeight: FontWeight.normal,
  );

  static const TextStyle titleLarge = TextStyle(
    color: textColor,
    fontSize: 20,
    fontWeight: FontWeight.bold,
  );

  static BoxDecoration inputDecoration = BoxDecoration(
    color: surfaceColor,
    borderRadius: BorderRadius.circular(borderRadius),
  );

  static BoxDecoration buttonDecoration = BoxDecoration(
    color: primaryColor,
    borderRadius: BorderRadius.circular(borderRadius),
  );

  static const TextStyle buttonTextStyle = TextStyle(
    color: textColor,
    fontSize: 16,
    fontWeight: FontWeight.bold,
  );

  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(
    vertical: 12,
    horizontal: 16,
  );

  static Widget buildCustomAppBar({required String title, List<Widget>? actions}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: backgroundColor,
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: titleLarge,
            ),
          ),
          if (actions != null) ...actions,
        ],
      ),
    );
  }

  static Widget buildElevatedButton({
    required String text,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        decoration: buttonDecoration,
        padding: buttonPadding,
        child: Text(
          text,
          style: buttonTextStyle,
        ),
      ),
    );
  }
}
