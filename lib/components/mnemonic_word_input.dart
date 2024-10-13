import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import '../theme/theme_provider.dart';

class MnemonicWordInput extends StatelessWidget {
  final int index;
  final String word;
  final bool isEditable;
  final Color? borderColor;
  final double opacity;

  const MnemonicWordInput({
    super.key,
    required this.index,
    required this.word,
    this.opacity = 1,
    this.isEditable = false,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: theme.cardBackground.withOpacity(opacity),
        borderRadius: BorderRadius.circular(16),
        border: borderColor != null
            ? Border.all(color: borderColor!, width: 1)
            : null,
      ),
      child: Row(
        children: [
          Text(
            '$index',
            style: TextStyle(color: theme.textSecondary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: TextEditingController(text: word),
              style: TextStyle(color: theme.textPrimary),
              enabled: isEditable,
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
