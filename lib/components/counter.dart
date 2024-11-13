import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/theme/theme_provider.dart';

class CounterIcons {
  static const String minus = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32">
  <circle cx="16" cy="16" r="15" fill="none" stroke="currentColor" stroke-width="2"/>
  <line x1="8" y1="16" x2="24" y2="16" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
</svg>
''';

  static const String plus = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32">
  <circle cx="16" cy="16" r="15" fill="none" stroke="currentColor" stroke-width="2"/>
  <line x1="8" y1="16" x2="24" y2="16" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
  <line x1="16" y1="8" x2="16" y2="24" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
</svg>
''';
}

class Counter extends StatefulWidget {
  final double iconSize;
  final Color? iconColor;
  final TextStyle? numberStyle;
  final Duration animationDuration;
  final int initialValue;
  final ValueChanged<int>? onChanged;

  const Counter({
    super.key,
    this.iconSize = 32,
    this.iconColor,
    this.numberStyle,
    this.animationDuration = const Duration(milliseconds: 300),
    this.initialValue = 0,
    this.onChanged,
  });

  @override
  State<Counter> createState() => _CounterState();
}

class _CounterState extends State<Counter> with SingleTickerProviderStateMixin {
  late int _count;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _count = widget.initialValue;
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.2),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.0),
        weight: 50,
      ),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _animate() {
    _controller.forward(from: 0);
  }

  void _increment() {
    setState(() {
      _count++;
      _animate();
      widget.onChanged?.call(_count);
    });
  }

  void _decrement() {
    if (_count > 0) {
      setState(() {
        _count--;
        _animate();
        widget.onChanged?.call(_count);
      });
    }
  }

  @override
  void didUpdateWidget(Counter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue) {
      setState(() {
        _count = widget.initialValue;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;

    return SizedBox(
      width: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: SvgPicture.string(
              CounterIcons.minus,
              width: widget.iconSize,
              height: widget.iconSize,
              colorFilter: ColorFilter.mode(
                _count > 0
                    ? widget.iconColor ?? theme.secondaryPurple
                    : (widget.iconColor ?? theme.secondaryPurple)
                        .withOpacity(0.3),
                BlendMode.srcIn,
              ),
            ),
            onPressed: _count > 0 ? _decrement : null,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) => Transform.scale(
                scale: _scaleAnimation.value,
                child: child,
              ),
              child: Text(
                '$_count',
                style: widget.numberStyle ??
                    TextStyle(
                      fontSize: 14,
                      color: theme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
          ),
          IconButton(
            icon: SvgPicture.string(
              CounterIcons.plus,
              width: widget.iconSize,
              height: widget.iconSize,
              colorFilter: ColorFilter.mode(
                widget.iconColor ?? theme.secondaryPurple,
                BlendMode.srcIn,
              ),
            ),
            onPressed: _increment,
          ),
        ],
      ),
    );
  }
}
