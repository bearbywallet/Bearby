import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/theme/app_theme.dart';
import 'package:zilpay/theme/theme_provider.dart';

class LedgerItem extends StatefulWidget {
  final Widget icon;
  final String title;
  final String id;
  final VoidCallback? onTap;
  final bool isSelected;
  final bool isLoading;

  const LedgerItem({
    super.key,
    required this.icon,
    required this.title,
    required this.id,
    this.onTap,
    this.isSelected = false,
    this.isLoading = false,
  });

  @override
  State<LedgerItem> createState() => _LedgerItemState();
}

class _LedgerItemState extends State<LedgerItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap == null || widget.isLoading) return;
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onTap == null || widget.isLoading) return;
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _handleTapCancel() {
    if (widget.onTap == null || widget.isLoading) return;
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.isLoading ? null : widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? theme.primaryPurple.withOpacity(0.1)
                  : theme.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _getContainerBorderColor(theme),
                width: widget.isSelected ? 2.5 : 2,
              ),
              boxShadow: _isPressed || widget.isLoading
                  ? null
                  : [
                      BoxShadow(
                        color: widget.isSelected
                            ? theme.primaryPurple.withOpacity(0.2)
                            : theme.primaryPurple.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Row(
              children: [
                widget.isLoading
                    ? SizedBox(
                        width: 30,
                        height: 30,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            theme.primaryPurple,
                          ),
                        ),
                      )
                    : widget.icon,
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(
                          color: _getTextColor(theme),
                          fontSize: 18,
                          fontWeight: widget.isSelected
                              ? FontWeight.w800
                              : FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.id,
                        style: TextStyle(
                          color: widget.isSelected
                              ? theme.primaryPurple.withOpacity(0.8)
                              : theme.textSecondary,
                          fontSize: 10,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (widget.isSelected && !widget.isLoading) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.check_circle,
                    color: theme.primaryPurple,
                    size: 24,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getContainerBorderColor(AppTheme theme) {
    if (widget.isLoading) {
      return theme.primaryPurple.withOpacity(0.3);
    }
    if (_isPressed) {
      return theme.primaryPurple.withOpacity(0.7);
    }
    if (widget.isSelected) {
      return theme.primaryPurple;
    }
    return theme.primaryPurple.withOpacity(0.8);
  }

  Color _getTextColor(AppTheme theme) {
    if (widget.isLoading) {
      return theme.textPrimary.withOpacity(0.7);
    }
    if (widget.isSelected) {
      return theme.primaryPurple;
    }
    return theme.textPrimary;
  }
}
