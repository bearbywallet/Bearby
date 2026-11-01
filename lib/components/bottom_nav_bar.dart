import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bearby/components/app_icon.dart';
import 'package:bearby/state/app_state.dart';
import 'package:bearby/theme/app_theme.dart';

class CustomBottomNavigationBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<CustomBottomNavigationBarItem> items;

  const CustomBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  State<CustomBottomNavigationBar> createState() =>
      _CustomBottomNavigationBarState();
}

class _CustomBottomNavigationBarState extends State<CustomBottomNavigationBar> {
  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = appState.currentTheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 600;

    final barContent = Container(
      height: isWide ? 64 : 74,
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 12 : 8,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: theme.cardBackground.withValues(alpha: isWide ? 0.82 : 0.78),
        borderRadius: isWide ? BorderRadius.circular(22) : null,
        border: isWide
            ? Border.all(
                color: theme.textPrimary.withValues(alpha: 0.10),
                width: 1.2,
              )
            : Border(
                top: BorderSide(
                  color: theme.textSecondary.withValues(alpha: 0.16),
                  width: 1.0,
                ),
              ),
        boxShadow: isWide
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(
          widget.items.length,
          (index) => Expanded(
            child: _buildNavItem(index, theme, isWide),
          ),
        ),
      ),
    );

    if (!isWide) {
      return SizedBox(
        height: 74,
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: barContent,
          ),
        ),
      );
    }

    return SizedBox(
      height: 76,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: barContent,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, AppTheme theme, bool isWide) {
    final item = widget.items[index];
    final isSelected = index == widget.currentIndex;
    final isHovered = _hoveredIndex == index;
    final color = isSelected
        ? theme.primaryPurple
        : isHovered
            ? theme.textPrimary.withValues(alpha: 0.85)
            : theme.textSecondary;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hoveredIndex = index),
      onExit: (_) => setState(() => _hoveredIndex = null),
      child: GestureDetector(
        onTap: () => widget.onTap(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: EdgeInsets.symmetric(
            horizontal: isWide ? 12 : 6,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.primaryPurple.withValues(alpha: 0.14)
                : isHovered
                    ? theme.textPrimary.withValues(alpha: 0.05)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: AppIconView(
              icon: item.icon,
              size: item.iconSize,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}

class CustomBottomNavigationBarItem {
  final AppIcon icon;
  final String? label;
  final double iconSize;

  const CustomBottomNavigationBarItem({
    required this.icon,
    this.label,
    this.iconSize = 36.0,
  });
}
