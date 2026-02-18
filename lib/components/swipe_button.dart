import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/state/app_state.dart';

class SwipeButton extends StatefulWidget {
  final double width;
  final double height;
  final String text;
  final Future<void> Function()? onSwipeComplete;
  final bool disabled;

  const SwipeButton({
    super.key,
    this.width = 300.0,
    this.height = 56.0,
    required this.text,
    this.onSwipeComplete,
    this.disabled = false,
  });

  @override
  State<SwipeButton> createState() => _SwipeButtonState();
}

class _SwipeButtonState extends State<SwipeButton>
    with SingleTickerProviderStateMixin {
  static const double _swipeThreshold = 0.8;

  late AnimationController _controller;
  late Animation<double> _shrinkAnimation;
  double _dragExtent = 0.0;
  bool _isDragging = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _shrinkAnimation = Tween<double>(begin: widget.width, end: widget.height)
        .animate(_controller)
      ..addListener(() {
        setState(() {});
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_isLoading || widget.disabled) return;
    setState(() {
      _isDragging = true;
      _dragExtent += details.delta.dx;
      _dragExtent = _dragExtent.clamp(0.0, widget.width - widget.height);
    });
  }

  Future<void> _onDragEnd(DragEndDetails details) async {
    if (_isLoading || widget.disabled) return;
    final threshold = (widget.width - widget.height) * _swipeThreshold;
    if (_dragExtent >= threshold) {
      setState(() => _isLoading = true);
      await _controller.forward();
      if (widget.onSwipeComplete != null) {
        await widget.onSwipeComplete!();
      }
      await _controller.reverse();
      setState(() => _isLoading = false);
    }
    setState(() {
      _isDragging = false;
      _dragExtent = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<AppState>(context).currentTheme;
    final thumbColor =
        widget.disabled ? theme.textSecondary : theme.primaryPurple;
    final textColor = widget.disabled
        ? theme.textSecondary.withValues(alpha: 0.5)
        : theme.textPrimary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: _isLoading ? _shrinkAnimation.value : widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.height / 2),
        border: Border.all(
          color: theme.modalBorder,
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          if (!_isLoading)
            Center(
              child: Text(
                widget.text,
                style: theme.subtitle1.copyWith(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          if (_isLoading)
            Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: theme.primaryPurple,
                  strokeWidth: 2,
                ),
              ),
            ),
          if (!_isLoading)
            GestureDetector(
              onHorizontalDragUpdate: widget.disabled ? null : _onDragUpdate,
              onHorizontalDragEnd: widget.disabled ? null : _onDragEnd,
              child: Container(
                margin: const EdgeInsets.all(4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: _isDragging
                        ? _dragExtent + widget.height - 8
                        : widget.height - 8,
                    height: widget.height - 8,
                    decoration: BoxDecoration(
                      color:
                          thumbColor.withValues(alpha: _isDragging ? 0.2 : 0.1),
                      borderRadius:
                          BorderRadius.circular((widget.height - 8) / 2),
                    ),
                    child: Row(
                      children: [
                        if (_isDragging) Expanded(child: Container()),
                        Container(
                          width: widget.height - 8,
                          height: widget.height - 8,
                          decoration: BoxDecoration(
                            color: thumbColor,
                            shape: BoxShape.circle,
                          ),
                          child: SvgPicture.asset(
                            "assets/icons/right_circle_arrow.svg",
                            width: widget.height * 0.4,
                            height: widget.height * 0.4,
                            colorFilter: ColorFilter.mode(
                              theme.background,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
