import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';

class OptionItem {
  final String title;
  final bool isSelected;
  final VoidCallback onSelect;

  OptionItem({
    required this.title,
    required this.isSelected,
    required this.onSelect,
  });
}

class OptionsList extends StatelessWidget {
  final List<OptionItem> options;
  final double unselectedOpacity;

  const OptionsList({
    super.key,
    required this.options,
    this.unselectedOpacity = 0.5,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;
    bool hasSelectedOption = options.any((option) => option.isSelected);

    return Column(
      children: options
          .map((option) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: hasSelectedOption && !option.isSelected
                      ? unselectedOpacity
                      : 1.0,
                  child: GestureDetector(
                    onTap: option.onSelect,
                    child: TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 300),
                      tween:
                          Tween(begin: 0.0, end: option.isSelected ? 1.0 : 0.0),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 16),
                          decoration: BoxDecoration(
                            color: theme.cardBackground,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Color.lerp(
                                theme.cardBackground,
                                theme.primaryPurple,
                                value * 0.5,
                              )!,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  option.title,
                                  style: TextStyle(
                                    color: theme.textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: option.isSelected
                                        ? theme.primaryPurple
                                        : theme.textSecondary,
                                    width: 2,
                                  ),
                                ),
                                child: Center(
                                  child: AnimatedScale(
                                    duration: const Duration(milliseconds: 200),
                                    scale: option.isSelected ? 1.0 : 0.0,
                                    child: Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: theme.primaryPurple,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ))
          .toList(),
    );
  }
}
