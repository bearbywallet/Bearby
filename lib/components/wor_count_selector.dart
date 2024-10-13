import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';

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
    final theme = Provider.of<ThemeProvider>(context).currentTheme;

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
                        style: TextStyle(
                          fontSize: 18,
                          color: selectedCount == wordCounts[index]
                              ? Colors.white
                              : theme.textSecondary,
                          fontWeight: selectedCount == wordCounts[index]
                              ? FontWeight.bold
                              : FontWeight.normal,
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
