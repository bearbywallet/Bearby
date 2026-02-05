import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import 'package:zilpay/components/button.dart';
import 'package:zilpay/components/custom_app_bar.dart';
import 'package:zilpay/components/mnemonic_word_input.dart';
import 'package:zilpay/components/wor_count_selector.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import 'package:zilpay/mixins/status_bar.dart';
import 'package:zilpay/src/rust/api/methods.dart';
import 'package:zilpay/src/rust/api/utils.dart';
import 'package:zilpay/src/rust/models/provider.dart';
import 'package:zilpay/state/app_state.dart';
import 'package:zilpay/l10n/app_localizations.dart';

class RestoreSecretPhrasePage extends StatefulWidget {
  const RestoreSecretPhrasePage({super.key});

  @override
  State<RestoreSecretPhrasePage> createState() =>
      _RestoreSecretPhrasePageState();
}

class _RestoreSecretPhrasePageState extends State<RestoreSecretPhrasePage>
    with StatusBarMixin {
  late List<String> _words;
  List<int> _wordsErrorIndexes = [];
  int _count = 12;
  final List<int> _allowedCounts = const [12, 15, 18, 21, 24];
  bool _isChecksumValid = true;
  bool _bypassChecksumValidation = false;
  bool _showChecksumWarning = false;
  bool _allWordsEntered = false;
  NetworkConfigInfo? _chain;

  @override
  void initState() {
    super.initState();
    _words = List.filled(_count, '');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final chain = args?['chain'] as NetworkConfigInfo?;

    if (chain == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/net_setup');
      });
    } else if (_chain == null) {
      setState(() {
        _chain = chain;
      });
    }
  }

  Future<void> _handleCheckWords() async {
    try {
      final nonEmptyWords = _words.where((word) => word.isNotEmpty).toList();
      if (nonEmptyWords.isEmpty) return;

      List<int> errorIndexes = (await checkNotExistsBip39Words(
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

  Future<void> _validateForm() async {
    bool areAllWordsValid =
        _words.every((word) => word.isNotEmpty) && _wordsErrorIndexes.isEmpty;

    setState(() {
      _allWordsEntered = areAllWordsValid;
    });

    if (areAllWordsValid) {
      if (!_showChecksumWarning) {
        String phrase = _words.join(' ');
        bool checksumValid = await bip39ChecksumValid(words: phrase);

        if (mounted) {
          setState(() {
            _isChecksumValid = checksumValid;
            _showChecksumWarning = !checksumValid;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _showChecksumWarning = false;
          _bypassChecksumValidation = false;
        });
      }
    }
  }

  void _handleWordChange(int index, String word) {
    if (word.trim().contains(' ')) {
      _handlePhrasePaste(word, startIndex: index - 1);
      return;
    }

    final trimmedWord =
        word.trim().toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
    final currentIndex = index - 1;

    _words[currentIndex] = trimmedWord;
    if (_wordsErrorIndexes.contains(currentIndex)) {
      _wordsErrorIndexes.remove(currentIndex);
    }

    if (_showChecksumWarning) {
      setState(() {
        _showChecksumWarning = false;
        _bypassChecksumValidation = false;
      });
    }

    _validateForm();

    if (trimmedWord.isNotEmpty) {
      Future.microtask(() => _handleCheckWords());
    }
  }

  void _handlePhrasePaste(String phrase, {int startIndex = 0}) {
    final words = phrase
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .map((word) => word.toLowerCase().replaceAll(RegExp(r'[^a-z]'), ''))
        .where((word) => word.isNotEmpty)
        .toList();

    if (words.isEmpty) return;

    int targetCount = _allowedCounts.firstWhere(
      (count) => count >= (startIndex + words.length),
      orElse: () => _allowedCounts.last,
    );

    if (targetCount != _count) {
      setState(() {
        _count = targetCount;
        final newWords = List<String>.filled(targetCount, '');
        for (var i = 0; i < math.min(_words.length, targetCount); i++) {
          newWords[i] = _words[i];
        }
        _words = newWords;
        _wordsErrorIndexes = [];
      });
    }

    for (var i = 0; i < words.length && (startIndex + i) < _words.length; i++) {
      _words[startIndex + i] = words[i];
    }

    setState(() {
      _showChecksumWarning = false;
      _bypassChecksumValidation = false;
      _words = List.from(_words);
    });

    _validateForm();

    if (words.isNotEmpty) {
      Future.microtask(() => _handleCheckWords());
    }
  }

  void _handleCountChanged(int newCount) {
    if (mounted) {
      setState(() {
        _count = newCount;
        final newWords = List<String>.filled(newCount, '');
        for (var i = 0; i < math.min(_words.length, newCount); i++) {
          newWords[i] = _words[i];
        }
        _words = newWords;
        _wordsErrorIndexes = [];
        _showChecksumWarning = false;
        _bypassChecksumValidation = false;
        _allWordsEntered = false;
      });

      _validateForm();
    }
  }

  Widget _buildChecksumWarning() {
    if (!_showChecksumWarning) return const SizedBox.shrink();

    final theme = Provider.of<AppState>(context).currentTheme;

    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.danger.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.danger),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.checksumValidationFailed,
            style: theme.bodyText2.copyWith(
              color: theme.danger,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            children: [
              Checkbox(
                value: _bypassChecksumValidation,
                onChanged: (value) {
                  setState(() {
                    _bypassChecksumValidation = value ?? false;
                  });
                },
                activeColor: theme.primaryPurple,
              ),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.proceedDespiteInvalidChecksum,
                  style: theme.bodyText2.copyWith(
                    color: theme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool get _isButtonEnabled {
    if (!_allWordsEntered) return false;
    if (_isChecksumValid) return true;
    return _bypassChecksumValidation;
  }

  @override
  Widget build(BuildContext context) {
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);
    final theme = Provider.of<AppState>(context).currentTheme;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        toolbarHeight: 0,
        systemOverlayStyle: getSystemUiOverlayStyle(context),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: adaptivePadding),
                  child: CustomAppBar(
                    title: AppLocalizations.of(context)!
                        .restoreSecretPhrasePageTitle,
                    onBackPressed: () => Navigator.pop(context),
                  ),
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
                                  word: _words.elementAtOrNull(index) ?? '',
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
                        _buildChecksumWarning(),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: CustomButton(
                            textColor: theme.buttonText,
                            backgroundColor: theme.primaryPurple,
                            text: AppLocalizations.of(context)!
                                .restoreSecretPhrasePageRestoreButton,
                            onPressed: () {
                              Navigator.of(context).pushNamed(
                                '/pass_setup',
                                arguments: {
                                  'bip39': _words,
                                  'chain': _chain,
                                  'ignore_checksum': _bypassChecksumValidation,
                                },
                              );
                            },
                            borderRadius: 30.0,
                            height: 56.0,
                            disabled: !_isButtonEnabled,
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
