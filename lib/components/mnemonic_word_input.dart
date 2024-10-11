import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import '../theme/theme_provider.dart';

class MnemonicWordInput extends StatelessWidget {
  final int index;
  final String word;
  final bool isEditable;

  const MnemonicWordInput({
    super.key,
    required this.index,
    required this.word,
    this.isEditable = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(
            '$index',
            style: const TextStyle(color: Colors.black),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: TextEditingController(text: word),
              style: TextStyle(color: theme.textSecondary),
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
