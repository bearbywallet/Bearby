import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/state/app_state.dart';

class SwipeButton extends StatefulWidget {
  final double width;
  final double height;
  final String text;
  final Future<void> Function() onSwipeComplete;

  const SwipeButton({
    super.key,
    this.width = 300.0,
    this.height = 56.0,
    required this.text,
    required this.onSwipeComplete,
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
    if (_isLoading) return;
    setState(() {
      _isDragging = true;
      _dragExtent += details.delta.dx;
      _dragExtent = _dragExtent.clamp(0.0, widget.width - height);
    });
  }

  void _onDragEnd(DragEndDetails details) async {
    if (_isLoading) return;
    if (_dragExtent >= widget.width - height) {
      setState(() {
        _isLoading = true;
      });

      for (var i = 0; i < 30; i++) {
        await Future.delayed(const Duration(milliseconds: 10));
        setState(() {
          _shrinkWidth = widget.width - (i * (widget.width - height) / 30);
        });
      }

      await widget.onSwipeComplete();

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

  double get height => widget.height;

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<AppState>(context).currentTheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 10),
      width: _shrinkWidth,
      height: height,
      decoration: BoxDecoration(
        color: theme.primaryPurple,
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: Stack(
        children: [
          if (!_isLoading)
            Center(
              child: Text(
                widget.text,
                style: TextStyle(
                  color: theme.textPrimary,
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
                  color: theme.textPrimary,
                  strokeWidth: 3,
                ),
              ),
            ),
          if (!_isLoading)
            GestureDetector(
              onHorizontalDragUpdate: _onDragUpdate,
              onHorizontalDragEnd: _onDragEnd,
              child: Container(
                margin: const EdgeInsets.all(4),
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width:
                            _isDragging ? _dragExtent + height - 8 : height - 8,
                        height: height - 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular((height - 8) / 2),
                          gradient: LinearGradient(
                            colors: [
                              theme.secondaryPurple.withValues(alpha: 0.1),
                              theme.secondaryPurple,
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
                                  borderRadius:
                                      BorderRadius.circular((height - 8) / 2),
                                ),
                              ),
                            Container(
                              width: height - 8,
                              height: height - 8,
                              decoration: BoxDecoration(
                                color: theme.secondaryPurple,
                                borderRadius:
                                    BorderRadius.circular((height - 8) / 2),
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
                                width: widget.width,
                                height: widget.height,
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
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
