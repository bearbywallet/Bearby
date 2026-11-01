import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:bearby/components/app_icon.dart';
import 'package:bearby/state/app_state.dart';
import 'package:bearby/theme/app_theme.dart';

class CustomBottomNavigationBarItem {
  final AppIcon icon;
  final String? label;
  final double iconSize;

  const CustomBottomNavigationBarItem({
    required this.icon,
    this.label,
    this.iconSize = 26.0,
  });
}

class CustomBottomNavigationBar extends StatefulWidget {
  final List<CustomBottomNavigationBarItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final Color? backgroundColor;
  final Color? selectedItemColor;
  final Color? unselectedItemColor;
  final double elevation;
  final EdgeInsets padding;

  const CustomBottomNavigationBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.backgroundColor,
    this.selectedItemColor,
    this.unselectedItemColor,
    this.elevation = 8.0,
    this.padding = const EdgeInsets.symmetric(vertical: 6.0),
  });

  @override
  State<CustomBottomNavigationBar> createState() =>
      _CustomBottomNavigationBarState();
}

class _CustomBottomNavigationBarState extends State<CustomBottomNavigationBar> {
  int? _hoveredIndex;
  int? _pressedIndex;

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = appState.currentTheme;
    final screenWidth = MediaQuery.sizeOf(context).width;

    final isCompactPhone = screenWidth < 360;
    final isTablet = screenWidth >= 600 && screenWidth < 960;
    final isDesktop = screenWidth >= 960;
    final isWide = screenWidth >= 600;
    final isDark = theme.background.computeLuminance() < 0.5;

    final Color baseBg = widget.backgroundColor ?? theme.cardBackground;
    final Color selectedColor = widget.selectedItemColor ?? theme.primaryPurple;
    final Color unselectedColor =
        (widget.unselectedItemColor ?? theme.textSecondary)
            .withValues(alpha: 0.72);

    final int itemCount = widget.items.length;
    final int validCurrentIndex =
        itemCount > 0 ? widget.currentIndex.clamp(0, itemCount - 1) : 0;

    final double outerHeight = isDesktop
        ? 80.0
        : isTablet
            ? 76.0
            : isCompactPhone
                ? 68.0
                : 72.0;

    final double barHeight = isDesktop
        ? 64.0
        : isTablet
            ? 62.0
            : isCompactPhone
                ? 56.0
                : 60.0;

    final double maxIslandWidth = isDesktop
        ? 480.0
        : isTablet
            ? 440.0
            : 420.0;

    final double bottomMargin = isWide ? 12.0 : 8.0;
    final double horizontalMargin = isWide ? 24.0 : 16.0;
    const double dockRadius = 20.0;
    const double trackPadding = 6.0;
    const double pillRadius = 14.0;

    final Color topLeftBg = Color.lerp(
          baseBg,
          selectedColor,
          isDark ? 0.07 : 0.04,
        ) ??
        baseBg;

    return SizedBox(
      height: outerHeight,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalMargin,
            0,
            horizontalMargin,
            bottomMargin,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxIslandWidth),
            child: Container(
              height: barHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(dockRadius),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.42 : 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(dockRadius),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    height: barHeight,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(dockRadius),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          topLeftBg.withValues(alpha: isDark ? 0.92 : 0.94),
                          baseBg.withValues(alpha: isDark ? 0.95 : 0.96),
                        ],
                      ),
                      border: Border.all(
                        color: theme.textPrimary
                            .withValues(alpha: isDark ? 0.09 : 0.08),
                        width: 1.1,
                      ),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final double availableWidth =
                            (constraints.maxWidth - trackPadding * 2)
                                .clamp(0.0, double.infinity);
                        final double slotWidth =
                            itemCount > 0 ? availableWidth / itemCount : 0.0;
                        final double activeLeft =
                            trackPadding + validCurrentIndex * slotWidth;
                        final double pillHorizontalInset = isWide ? 6.0 : 4.0;

                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            // Subtle ambient radial glow following active tab
                            if (itemCount > 0 && slotWidth > 0)
                              AnimatedPositioned(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOutCubic,
                                left: activeLeft,
                                width: slotWidth,
                                top: 0,
                                bottom: 0,
                                child: IgnorePointer(
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: RadialGradient(
                                        radius: 0.9,
                                        colors: [
                                          selectedColor.withValues(
                                              alpha: isDark ? 0.16 : 0.10),
                                          selectedColor.withValues(alpha: 0.0),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                            // Sliding active squircle pill (matches Bearby toolbar & cards)
                            if (itemCount > 0 && slotWidth > 0)
                              AnimatedPositioned(
                                duration: const Duration(milliseconds: 280),
                                curve: Curves.easeOutCubic,
                                left: activeLeft,
                                width: slotWidth,
                                top: 6,
                                bottom: 6,
                                child: IgnorePointer(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: pillHorizontalInset,
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(pillRadius),
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            selectedColor.withValues(
                                                alpha: isDark ? 0.20 : 0.15),
                                            selectedColor.withValues(
                                                alpha: isDark ? 0.10 : 0.08),
                                          ],
                                        ),
                                        border: Border.all(
                                          color: selectedColor.withValues(
                                              alpha: isDark ? 0.36 : 0.26),
                                          width: 1.0,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                            // Interactive Icon Row
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: trackPadding,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: List.generate(itemCount, (index) {
                                  final item = widget.items[index];
                                  final isSelected = index == validCurrentIndex;
                                  final isHovered = _hoveredIndex == index;
                                  final isPressed = _pressedIndex == index;

                                  return Expanded(
                                    child: _buildIslandItem(
                                      theme: theme,
                                      item: item,
                                      index: index,
                                      isSelected: isSelected,
                                      isHovered: isHovered,
                                      isPressed: isPressed,
                                      isWide: isWide,
                                      isDark: isDark,
                                      selectedColor: selectedColor,
                                      unselectedColor: unselectedColor,
                                      pillRadius: pillRadius,
                                      pillHorizontalInset: pillHorizontalInset,
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIslandItem({
    required AppTheme theme,
    required CustomBottomNavigationBarItem item,
    required int index,
    required bool isSelected,
    required bool isHovered,
    required bool isPressed,
    required bool isWide,
    required bool isDark,
    required Color selectedColor,
    required Color unselectedColor,
    required double pillRadius,
    required double pillHorizontalInset,
  }) {
    final double baseIconSize = isWide ? item.iconSize + 2.0 : item.iconSize;

    final double targetScale = isPressed
        ? 0.90
        : isHovered && !isSelected
            ? 1.05
            : 1.0;

    final Color targetColor = isSelected
        ? selectedColor
        : isHovered
            ? theme.textPrimary
            : unselectedColor;

    Widget iconButton = MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hoveredIndex = index),
      onExit: (_) => setState(() {
        if (_hoveredIndex == index) _hoveredIndex = null;
      }),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressedIndex = index),
        onTapUp: (_) => setState(() {
          if (_pressedIndex == index) _pressedIndex = null;
        }),
        onTapCancel: () => setState(() {
          if (_pressedIndex == index) _pressedIndex = null;
        }),
        onTap: () {
          HapticFeedback.selectionClick();
          widget.onTap(index);
        },
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: pillHorizontalInset,
            vertical: 6,
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: !isSelected && isHovered
                  ? theme.textPrimary.withValues(alpha: 0.05)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(pillRadius),
            ),
            child: Center(
              child: AnimatedScale(
                duration: Duration(milliseconds: isPressed ? 90 : 200),
                curve: Curves.easeOutCubic,
                scale: targetScale,
                child: TweenAnimationBuilder<Color?>(
                  tween: ColorTween(end: targetColor),
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  builder: (context, color, _) {
                    return AppIconView(
                      icon: item.icon,
                      size: baseIconSize,
                      color: color ?? targetColor,
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (item.label != null && item.label!.isNotEmpty) {
      iconButton = Semantics(
        label: item.label,
        selected: isSelected,
        button: true,
        child: isWide
            ? Tooltip(
                message: item.label!,
                waitDuration: const Duration(milliseconds: 500),
                child: iconButton,
              )
            : iconButton,
      );
    }

    return iconButton;
  }
}
