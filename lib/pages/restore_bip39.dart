import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import 'package:zilpay/components/button.dart';
import 'package:zilpay/components/custom_app_bar.dart';
import 'package:zilpay/components/mnemonic_word_input.dart';
import 'package:zilpay/components/wor_count_selector.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import 'package:zilpay/src/rust/api/methods.dart';
import 'package:zilpay/state/app_state.dart';

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
        lang: 'english',
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

      if (mounted) {
        setState(() {
          _wordsErrorIndexes = adjustedIndexes;
          _validateForm();
        });
      }
    } catch (e) {
      debugPrint('Error checking words: $e');
    }
  }

  void _handleWordChange(int index, String word) {
    final trimmedWord = word.trim().toLowerCase();
    final currentIndex = index - 1;

    if (word.contains(' ')) {
      _handlePhrasePaste(word, currentIndex);
      return;
    }

    _words[currentIndex] = trimmedWord;
    if (_wordsErrorIndexes.contains(currentIndex)) {
      _wordsErrorIndexes.remove(currentIndex);
    }
    _validateForm();

    if (trimmedWord.isNotEmpty) {
      Future.microtask(() => _handleCheckWords());
    }
  }

  void _handlePhrasePaste(String phrase, int startIndex) {
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

    for (var i = 0; i < words.length && (startIndex + i) < targetCount; i++) {
      if (words[i].isNotEmpty) {
        _words[startIndex + i] = words[i].toLowerCase();
      }
    }

    _validateForm();

    if (words.isNotEmpty) {
      Future.microtask(() => _handleCheckWords());
    }
  }

  void _validateForm() {
    final isValid =
        _words.every((word) => word.isNotEmpty) && _wordsErrorIndexes.isEmpty;
    if (isValid != _isFormValid) {
      setState(() {
        _isFormValid = isValid;
      });
    }
  }

  void _handleCountChanged(int newCount, {bool autoAdjust = false}) {
    if (mounted) {
      setState(() {
        _count = newCount;
        final newWords = List<String>.filled(newCount, '');
        for (var i = 0; i < math.min(_words.length, newCount); i++) {
          newWords[i] = _words[i];
        }
        _words = newWords;
        _wordsErrorIndexes = [];
        _validateForm();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);
    final theme = Provider.of<AppState>(context).currentTheme;

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
                                  key: ValueKey('word_$index'),
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
                            onPressed: () {
                              Navigator.of(context).pushNamed('/net_setup',
                                  arguments: {'bip39': _words});
                            },
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
