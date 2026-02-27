import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bearby/state/app_state.dart';

class WordCountSelector extends StatelessWidget {
  final List<int> wordCounts;
  final int selectedCount;
  final Function(int) onCountChanged;

  const WordCountSelector({
    super.key,
    required this.wordCounts,
    required this.selectedCount,
    required this.onCountChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<AppState>(context).currentTheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: theme.cardBackground.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: theme.modalBorder.withValues(alpha: 0.5), width: 1),
          ),
          child: Stack(
            children: [
              AnimatedAlign(
                alignment: Alignment(
                  -1 +
                      2 *
                          (wordCounts.indexOf(selectedCount) /
                              (wordCounts.length - 1)),
                  0,
                ),
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                child: FractionallySizedBox(
                  widthFactor: 1 / wordCounts.length,
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: theme.primaryPurple,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              Row(
                children: wordCounts.map((count) {
                  final isSelected = count == selectedCount;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onCountChanged(count),
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: theme.labelMedium.copyWith(
                            color: isSelected
                                ? theme.buttonText
                                : theme.textSecondary,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w500,
                          ),
                          child: Text(count.toString()),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
