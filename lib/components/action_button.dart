import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';

class CustomActionButton extends StatefulWidget {
  final String label;
  final String iconPath;
  final VoidCallback onPressed;

  const CustomActionButton({
    Key? key,
    required this.label,
    required this.iconPath,
    required this.onPressed,
  }) : super(key: key);

  @override
  _CustomActionButtonState createState() => _CustomActionButtonState();
}

class _CustomActionButtonState extends State<CustomActionButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onPressed,
      child: AnimatedOpacity(
        duration: Duration(milliseconds: 150),
        opacity: _isPressed ? 0.5 : 1.0,
        child: Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: theme.buttonBackground.withOpacity(0.6),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                widget.iconPath,
                width: 24,
                height: 24,
                color: theme.primaryPurple,
              ),
              SizedBox(height: 6),
              Text(
                widget.label,
                style: TextStyle(
                  color: theme.buttonText,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
