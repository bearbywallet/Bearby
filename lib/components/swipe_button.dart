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
  final Color? backgroundColor;
  final Color? textColor;
  final Color? secondaryColor;

  const SwipeButton({
    super.key,
    this.width = 300.0,
    this.height = 56.0,
    required this.text,
    this.onSwipeComplete,
    this.disabled = false,
    this.backgroundColor,
    this.textColor,
    this.secondaryColor,
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

  Widget _buildSwipeThumb(Color secColor, ColorFilter colorFilter) {
    return Container(
      width: widget.height - 8,
      height: widget.height - 8,
      decoration: BoxDecoration(
        color: widget.disabled ? secColor.withValues(alpha: 0.5) : secColor,
        borderRadius: BorderRadius.circular((widget.height - 8) / 2),
        boxShadow: [
          BoxShadow(
            color: Provider.of<AppState>(context)
                .currentTheme
                .background
                .withValues(alpha: 0.3),
            blurRadius: 4,
          ),
        ],
      ),
      child: SvgPicture.asset(
        "assets/icons/right_circle_arrow.svg",
        width: widget.height - 8,
        height: widget.height - 8,
        colorFilter: colorFilter,
      ),
    );
  }

  Widget _buildDragBackground(Color secColor) {
    return Container(
      width: _isDragging ? _dragExtent + widget.height - 8 : widget.height - 8,
      height: widget.height - 8,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular((widget.height - 8) / 2),
        gradient: LinearGradient(
          colors: [
            widget.disabled
                ? secColor.withValues(alpha: 0.05)
                : secColor.withValues(alpha: 0.1),
            widget.disabled ? secColor.withValues(alpha: 0.5) : secColor,
          ],
          stops: const [0.0, 0.9],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        children: [
          if (_isDragging) Expanded(child: Container()),
          _buildSwipeThumb(
            secColor,
            ColorFilter.mode(
              widget.disabled
                  ? Provider.of<AppState>(context)
                      .currentTheme
                      .background
                      .withValues(alpha: 0.5)
                  : Provider.of<AppState>(context).currentTheme.background,
              BlendMode.srcIn,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<AppState>(context).currentTheme;
    final bgColor = widget.backgroundColor ?? theme.primaryPurple;
    final txtColor = widget.textColor ?? theme.textPrimary;
    final secColor = widget.secondaryColor ?? theme.secondaryPurple;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: _isLoading ? _shrinkAnimation.value : widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: widget.disabled ? bgColor.withValues(alpha: 0.5) : bgColor,
        borderRadius: BorderRadius.circular(widget.height / 2),
      ),
      child: Stack(
        children: [
          if (!_isLoading)
            Center(
              child: Text(
                widget.text,
                style: TextStyle(
                  color: widget.disabled
                      ? txtColor.withValues(alpha: 0.5)
                      : txtColor,
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
                  color: txtColor,
                  strokeWidth: 3,
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
                  child: _buildDragBackground(secColor),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
