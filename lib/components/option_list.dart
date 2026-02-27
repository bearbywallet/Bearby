import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bearby/state/app_state.dart';

class OptionItem {
  final Widget child;
  final bool isSelected;
  final VoidCallback onSelect;

  OptionItem({
    required this.child,
    required this.isSelected,
    required this.onSelect,
  });
}

class OptionsList extends StatelessWidget {
  final List<OptionItem> options;
  final double unselectedOpacity;
  final bool disabled;
  final double disabledOpacity;

  const OptionsList({
    super.key,
    required this.options,
    this.unselectedOpacity = 0.5,
    this.disabled = false,
    this.disabledOpacity = 0.5,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<AppState>(context).currentTheme;
    final hasSelectedOption = options.any((option) => option.isSelected);

    return Column(
      children: options
          .asMap()
          .entries
          .map((entry) => _OptionItemWidget(
                key: ValueKey(entry.key),
                option: entry.value,
                theme: theme,
                disabled: disabled,
                disabledOpacity: disabledOpacity,
                unselectedOpacity: unselectedOpacity,
                hasSelectedOption: hasSelectedOption,
              ))
          .toList(),
    );
  }
}

class _OptionItemWidget extends StatefulWidget {
  final OptionItem option;
  final dynamic theme;
  final bool disabled;
  final double disabledOpacity;
  final double unselectedOpacity;
  final bool hasSelectedOption;

  const _OptionItemWidget({
    super.key,
    required this.option,
    required this.theme,
    required this.disabled,
    required this.disabledOpacity,
    required this.unselectedOpacity,
    required this.hasSelectedOption,
  });

  @override
  State<_OptionItemWidget> createState() => _OptionItemWidgetState();
}

class _OptionItemWidgetState extends State<_OptionItemWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: widget.disabled
            ? widget.disabledOpacity
            : widget.hasSelectedOption && !widget.option.isSelected
                ? widget.unselectedOpacity
                : 1.0,
        child: MouseRegion(
          onEnter:
              widget.disabled ? null : (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          cursor: widget.disabled
              ? SystemMouseCursors.basic
              : SystemMouseCursors.click,
          child: GestureDetector(
            onTap: widget.disabled ? null : widget.option.onSelect,
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 300),
              tween:
                  Tween(begin: 0.0, end: widget.option.isSelected ? 1.0 : 0.0),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return AnimatedScale(
                  scale: _isHovered && !widget.disabled ? 1.02 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Color.lerp(
                          widget.theme.modalBorder,
                          widget.disabled
                              ? widget.theme.textSecondary
                              : widget.theme.primaryPurple,
                          value,
                        )!,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: widget.option.child,
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: widget.option.isSelected
                                  ? widget.disabled
                                      ? widget.theme.textSecondary
                                      : widget.theme.primaryPurple
                                  : widget.theme.modalBorder,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: AnimatedScale(
                              duration: const Duration(milliseconds: 200),
                              scale: widget.option.isSelected ? 1.0 : 0.0,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: widget.disabled
                                      ? widget.theme.textSecondary
                                      : widget.theme.primaryPurple,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
