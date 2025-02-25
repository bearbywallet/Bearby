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
  late AnimationController _controller;
  double _dragExtent = 0.0;
  bool _isDragging = false;
  bool _isLoading = false;
  double _shrinkWidth = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _shrinkWidth = widget.width;
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

  void _onDragEnd(DragEndDetails details) async {
    if (_isLoading || widget.disabled) return;
    if (_dragExtent >= widget.width - widget.height) {
      setState(() => _isLoading = true);

      for (var i = 0; i < 30; i++) {
        await Future.delayed(const Duration(milliseconds: 10));
        setState(() => _shrinkWidth =
            widget.width - (i * (widget.width - widget.height) / 30));
      }

      if (widget.onSwipeComplete != null) {
        await widget.onSwipeComplete!();
      }

      setState(() {
        _isLoading = false;
        _shrinkWidth = widget.width;
      });
    }

    setState(() {
      _isDragging = false;
      _dragExtent = 0.0;
    });
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<AppState>(context).currentTheme;
    final bgColor = widget.backgroundColor ?? theme.primaryPurple;
    final txtColor = widget.textColor ?? theme.textPrimary;
    final secColor = widget.secondaryColor ?? theme.secondaryPurple;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 10),
      width: _shrinkWidth,
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
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: _isDragging
                            ? _dragExtent + widget.height - 8
                            : widget.height - 8,
                        height: widget.height - 8,
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular((widget.height - 8) / 2),
                          gradient: LinearGradient(
                            colors: [
                              widget.disabled
                                  ? secColor.withValues(alpha: 0.05)
                                  : secColor.withValues(alpha: 0.1),
                              widget.disabled
                                  ? secColor.withValues(alpha: 0.5)
                                  : secColor,
                            ],
                            stops: const [0.0, 0.9],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                        ),
                        child: Row(
                          children: [
                            if (_isDragging)
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                      (widget.height - 8) / 2),
                                ),
                              ),
                            Container(
                              width: widget.height - 8,
                              height: widget.height - 8,
                              decoration: BoxDecoration(
                                color: widget.disabled
                                    ? secColor.withValues(alpha: 0.5)
                                    : secColor,
                                borderRadius: BorderRadius.circular(
                                    (widget.height - 8) / 2),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        theme.background.withValues(alpha: 0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 0),
                                  ),
                                ],
                              ),
                              child: SvgPicture.asset(
                                "assets/icons/right_circle_arrow.svg",
                                width: widget.height - 8,
                                height: widget.height - 8,
                                colorFilter: ColorFilter.mode(
                                  widget.disabled
                                      ? theme.background.withValues(alpha: 0.5)
                                      : theme.background,
                                  BlendMode.srcIn,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
