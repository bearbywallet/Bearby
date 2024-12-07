import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import 'package:zilpay/components/button.dart';
import 'package:zilpay/components/custom_app_bar.dart';
import 'package:zilpay/components/mnemonic_word_input.dart';
import 'package:zilpay/components/wor_count_selector.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import 'package:zilpay/src/rust/api/methods.dart';
import '../theme/theme_provider.dart';

class RestoreSecretPhrasePage extends StatefulWidget {
  const RestoreSecretPhrasePage({super.key});

  @override
  State<RestoreSecretPhrasePage> createState() =>
      _RestoreSecretPhrasePageState();
}

class _RestoreSecretPhrasePageState extends State<RestoreSecretPhrasePage> {
  late List<String> _words;
  List<int> _wordsErrorIndexes = [];
  bool _isFormValid = false;
  int _count = 12;
  final List<int> _allowedCounts = const [12, 15, 18, 21, 24];

  @override
  void initState() {
    super.initState();
    _words = List.filled(_count, '');
  }

  Future<void> _handleCheckWords() async {
    try {
      final nonEmptyWords = _words.where((word) => word.isNotEmpty).toList();
      if (nonEmptyWords.isEmpty) return;

      final List<int> errorIndexes = (await checkNotExistsBip39Words(
        words: nonEmptyWords,
        lang: 'english', // TODO: add lang chose
      ))
          .map((e) => e.toInt())
          .toList();

      final List<int> adjustedIndexes = [];
      var currentIndex = 0;

      for (int i = 0; i < _words.length; i++) {
        if (_words[i].isNotEmpty) {
          if (errorIndexes.contains(currentIndex)) {
            adjustedIndexes.add(i);
          }
          currentIndex++;
        }
      }

      setState(() {
        _wordsErrorIndexes = adjustedIndexes;
        _validateForm();
      });
    } catch (e) {
      debugPrint('Error checking words: $e');
    }
  }

  void _handleWordChange(int index, String word) async {
    // Remove only the current index from errors if it exists
    setState(() {
      if (_wordsErrorIndexes.contains(index - 1)) {
        _wordsErrorIndexes.remove(index - 1);
      }
    });

    if (word.contains(' ')) {
      _handlePhrasePaste(word, index - 1);
      return;
    }

    setState(() {
      final trimmedWord = word.trim().toLowerCase();
      _words[index - 1] = trimmedWord;
      _validateForm();
    });

    if (word.trim().isNotEmpty) {
      await _handleCheckWords();
    }

    // Check if all words are filled to validate the entire phrase
    if (_words.every((word) => word.isNotEmpty)) {
      await _handleCheckWords();
    }
  }

  void _handlePhrasePaste(String phrase, int startIndex) async {
    setState(() {
      _wordsErrorIndexes = [];
    });

    final words = phrase.trim().split(RegExp(r'\s+'));

    int targetCount = _count;
    for (int allowedCount in _allowedCounts) {
      if (words.length <= allowedCount) {
        targetCount = allowedCount;
        break;
      }
    }

    if (targetCount != _count) {
      _handleCountChanged(targetCount, autoAdjust: true);
    }

    setState(() {
      for (var i = 0; i < words.length && (startIndex + i) < targetCount; i++) {
        if (words[i].isNotEmpty) {
          _words[startIndex + i] = words[i].toLowerCase();
        }
      }
      _validateForm();
    });

    if (words.isNotEmpty) {
      await _handleCheckWords();
    }
  }

  void _validateForm() {
    setState(() {
      _isFormValid =
          _words.every((word) => word.isNotEmpty) && _wordsErrorIndexes.isEmpty;
    });
  }

  void _handleCountChanged(int newCount, {bool autoAdjust = false}) {
    setState(() {
      _count = newCount;
      _wordsErrorIndexes = [];

      final newWords = List<String>.filled(newCount, '');
      for (var i = 0; i < math.min(_words.length, newCount); i++) {
        newWords[i] = _words[i];
      }
      _words = newWords;
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
                                  hasError: _wordsErrorIndexes.contains(index),
                                  errorBorderColor: theme.danger,
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
