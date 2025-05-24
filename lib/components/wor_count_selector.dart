import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/state/app_state.dart';

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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        height: 48,
        decoration: BoxDecoration(
          color: theme.cardBackground,
          borderRadius: BorderRadius.circular(8),
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
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: FractionallySizedBox(
                widthFactor: 1 / wordCounts.length,
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.primaryPurple,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            Row(
              children: List.generate(
                wordCounts.length,
                (index) => Expanded(
                  child: GestureDetector(
                    onTap: () => onCountChanged(wordCounts[index]),
                    behavior: HitTestBehavior.opaque,
                    child: Center(
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 300),
                        style: theme.subtitle1.copyWith(
                          fontSize: 18, // subtitle1 is 20, adjusting
                          color: selectedCount == wordCounts[index]
                              ? Colors.white
                              : theme.textSecondary,
                          fontWeight: selectedCount == wordCounts[index]
                              ? FontWeight.bold
                              : FontWeight.normal, // subtitle1 is w500 by default
                        ),
                        child: Text(wordCounts[index].toString()),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
