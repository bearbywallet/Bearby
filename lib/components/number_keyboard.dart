import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:bearby/state/app_state.dart';

class NumberKeyboard extends StatefulWidget {
  final Function(int) onKeyPressed;
  final VoidCallback onBackspace;
  final VoidCallback? onDotPress;

  const NumberKeyboard({
    super.key,
    required this.onKeyPressed,
    required this.onBackspace,
    this.onDotPress,
  });

  @override
  NumberKeyboardState createState() => NumberKeyboardState();
}

class NumberKeyboardState extends State<NumberKeyboard>
    with SingleTickerProviderStateMixin {
  String? activeKey;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildKey(BuildContext context, String value, {bool isIcon = false}) {
    final theme = Provider.of<AppState>(context).currentTheme;
    final isActive = activeKey == value;

    void handleTap() {
      setState(() => activeKey = value);
      _controller.forward().then((_) => _controller.reverse());
      Future.delayed(const Duration(milliseconds: 200), () {
        setState(() => activeKey = null);
      });

      if (value == '←') {
        widget.onBackspace();
      } else if (value == '.') {
        widget.onDotPress?.call();
      } else {
        widget.onKeyPressed(int.parse(value));
      }
    }

    return GestureDetector(
      onTapDown: (_) {
        setState(() => activeKey = value);
        _controller.forward();
      },
      onTapUp: (_) {
        _controller.reverse();
        setState(() => activeKey = null);
        handleTap();
      },
      onTapCancel: () {
        _controller.reverse();
        setState(() => activeKey = null);
      },
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: isActive ? _scaleAnimation : const AlwaysStoppedAnimation(1.0),
        child: Container(
          width: 80,
          height: 50,
          alignment: Alignment.center,
          child: isIcon
              ? SvgPicture.asset(
                  "assets/icons/backspace.svg",
                  width: 30,
                  height: 30,
                  colorFilter: ColorFilter.mode(
                    theme.textPrimary.withValues(alpha: isActive ? 1.0 : 0.5),
                    BlendMode.srcIn,
                  ),
                )
              : Text(
                  value,
                  style: theme.headline1.copyWith(
                    color: theme.textPrimary
                        .withValues(alpha: isActive ? 1.0 : 0.5),
                    fontSize: 32,
                    fontWeight: FontWeight.w500,
                  ),
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children:
                ['1', '2', '3'].map((e) => _buildKey(context, e)).toList(),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children:
                ['4', '5', '6'].map((e) => _buildKey(context, e)).toList(),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children:
                ['7', '8', '9'].map((e) => _buildKey(context, e)).toList(),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKey(context, '.'),
              _buildKey(context, '0'),
              _buildKey(context, '←', isIcon: true),
            ],
          ),
        ],
      ),
    );
  }
}
