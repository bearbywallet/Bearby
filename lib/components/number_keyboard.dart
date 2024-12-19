import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/state/app_state.dart';

class NumberKeyboard extends StatelessWidget {
  final Function(String) onKeyPressed;
  final VoidCallback onBackspace;
  final VoidCallback? onDotPress;

  const NumberKeyboard({
    super.key,
    required this.onKeyPressed,
    required this.onBackspace,
    this.onDotPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<AppState>(context).currentTheme;

    Widget buildKey(String value, {bool isIcon = false}) {
      return GestureDetector(
        onTap: () {
          if (value == '←') {
            onBackspace();
          } else if (value == '.') {
            onDotPress?.call();
          } else {
            onKeyPressed(value);
          }
        },
        child: Container(
          width: 80,
          height: 40,
          alignment: Alignment.center,
          child: isIcon
              ? Icon(
                  Icons.arrow_back,
                  color: theme.textPrimary,
                  size: 24,
                )
              : Text(
                  value,
                  style: TextStyle(
                    color: theme.textPrimary,
                    fontSize: 32,
                    fontWeight: FontWeight.w500,
                  ),
                ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: ['1', '2', '3'].map((e) => buildKey(e)).toList(),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: ['4', '5', '6'].map((e) => buildKey(e)).toList(),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: ['7', '8', '9'].map((e) => buildKey(e)).toList(),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              buildKey('.'),
              buildKey('0'),
              buildKey('←', isIcon: true),
            ],
          ),
        ],
      ),
    );
  }
}
