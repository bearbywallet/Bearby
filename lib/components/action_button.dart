import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/state/app_state.dart';

class CustomActionButton extends StatefulWidget {
  final String label;
  final String iconPath;
  final VoidCallback onPressed;

  const CustomActionButton({
    super.key,
    required this.label,
    required this.iconPath,
    required this.onPressed,
  });

  @override
  State<CustomActionButton> createState() => CustomActionButtonState();
}

class CustomActionButtonState extends State<CustomActionButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<AppState>(context).currentTheme;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onPressed,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: _isPressed ? 0.5 : 1.0,
        child: Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: theme.cardBackground,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
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
                colorFilter: ColorFilter.mode(
                  theme.primaryPurple,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(height: 6),
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
