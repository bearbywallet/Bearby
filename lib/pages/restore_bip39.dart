import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import 'package:zilpay/components/button.dart';
import 'package:zilpay/components/custom_app_bar.dart';
import 'package:zilpay/components/mnemonic_word_input.dart';
import 'package:zilpay/components/wor_count_selector.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import '../theme/theme_provider.dart';

class RestoreSecretPhrasePage extends StatefulWidget {
  const RestoreSecretPhrasePage({
    super.key,
  });

  @override
  State<RestoreSecretPhrasePage> createState() =>
      _RestoreSecretPhrasePageState();
}

class _RestoreSecretPhrasePageState extends State<RestoreSecretPhrasePage> {
  late List<String> _words;
  bool _isFormValid = false;
  int _filledWordsCount = 0;
  int _count = 12;
  final List<int> _allowedCounts = const [12, 15, 18, 21, 24];

  @override
  void initState() {
    super.initState();
    _words = List.filled(_count, '');
  }

  void _handleWordChange(int index, String word) {
    // Check if the input contains spaces (potential phrase paste)
    if (word.contains(' ')) {
      _handlePhrasePaste(word, index - 1);
      return;
    }

    setState(() {
      final trimmedWord = word.trim().toLowerCase();
      _words[index - 1] = trimmedWord;
      _updateWordsCount();
      _validateForm();
    });
  }

  void _handlePhrasePaste(String phrase, int startIndex) {
    final words =
        phrase.trim().split(RegExp(r'\s+')); // Split by any whitespace

    // Find the appropriate word count based on pasted words length
    int targetCount = _count;
    for (int allowedCount in _allowedCounts) {
      if (words.length <= allowedCount) {
        targetCount = allowedCount;
        break;
      }
    }

    // If count needs to change, update it first
    if (targetCount != _count) {
      _handleCountChanged(targetCount, autoAdjust: true);
    }

    setState(() {
      // Fill words starting from the paste location
      for (var i = 0; i < words.length && (startIndex + i) < targetCount; i++) {
        if (words[i].isNotEmpty) {
          _words[startIndex + i] = words[i].toLowerCase();
        }
      }

      _updateWordsCount();
      _validateForm();
    });
  }

  void _updateWordsCount() {
    setState(() {
      _filledWordsCount = _words.where((word) => word.isNotEmpty).length;
    });
  }

  void _validateForm() {
    setState(() {
      _isFormValid = _words.every((word) => word.isNotEmpty);
    });
  }

  void _handleCountChanged(int newCount, {bool autoAdjust = false}) {
    setState(() {
      _count = newCount;
      // Preserve existing words when possible
      final newWords = List<String>.filled(newCount, '');
      for (var i = 0; i < math.min(_words.length, newCount); i++) {
        newWords[i] = _words[i];
      }
      _words = newWords;
      _updateWordsCount();
      _validateForm();
    });
  }

  @override
  Widget build(BuildContext context) {
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);
    final theme = Provider.of<ThemeProvider>(context).currentTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                CustomAppBar(
                  title: 'Restore Wallet',
                  onBackPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: adaptivePadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        WordCountSelector(
                          wordCounts: _allowedCounts,
                          selectedCount: _count,
                          onCountChanged: (count) => _handleCountChanged(count),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            itemCount: _count,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8.0),
                                child: MnemonicWordInput(
                                  index: index + 1,
                                  word: _words[index],
                                  isEditable: true,
                                  onChanged: _handleWordChange,
                                  borderColor: theme.buttonText,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: CustomButton(
                            text: 'Restore',
                            onPressed: () {},
                            backgroundColor: theme.primaryPurple,
                            borderRadius: 30.0,
                            height: 56.0,
                            disabled: !_isFormValid,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
