import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:bearby/components/button.dart';
import 'package:bearby/components/custom_app_bar.dart';
import 'package:bearby/components/glass_message.dart';
import 'package:bearby/components/mnemonic_word_input.dart';
import 'package:bearby/components/wor_count_selector.dart';
import 'package:bearby/l10n/app_localizations.dart';
import 'package:bearby/mixins/adaptive_size.dart';
import 'package:bearby/mixins/chain_route_args.dart';
import 'package:bearby/mixins/status_bar.dart';
import 'package:bearby/router.dart';
import 'package:bearby/src/rust/models/provider.dart';
import 'package:bearby/state/app_state.dart';
import 'package:bearby/theme/app_theme.dart';
import 'package:bearby/utils/bip39_wordlist.dart';

class RestoreSecretPhrasePage extends StatefulWidget {
  const RestoreSecretPhrasePage({super.key});

  @override
  State<RestoreSecretPhrasePage> createState() =>
      _RestoreSecretPhrasePageState();
}

class _RestoreSecretPhrasePageState extends State<RestoreSecretPhrasePage>
    with StatusBarMixin, ChainRouteArgsMixin {
  late List<String> _words;
  List<int> _wordsErrorIndexes = [];
  int _count = 12;
  int? _activeIndex;
  final List<int> _allowedCounts = const [12, 15, 18, 21, 24];

  Bip39Language _detectedLanguage = Bip39Language.english;
  bool _isLanguageDetected = false;
  List<String> _suggestions = const [];

  bool _isChecksumValid = true;
  bool _bypassChecksumValidation = false;
  bool _showChecksumWarning = false;
  bool _allWordsEntered = false;
  NetworkConfigInfo? _chain;

  static final RegExp _whitespaceRegex = RegExp(r'[\s\u3000]+');
  static final RegExp _invalidCharsRegex =
      RegExp(r'[0-9.,!?;:"' "'" r'()\[\]{}<>/\\|`~@#$%^&*_+=]+');

  @override
  void initState() {
    super.initState();
    _words = List.filled(_count, '', growable: true);
    _initWordlists();
  }

  Future<void> _initWordlists() async {
    await Bip39WordlistService.instance.ensureLoaded();
    if (!mounted) return;
    if (_words.any((w) => w.isNotEmpty)) {
      await _handleCheckWords();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    bootstrapChainArg(_chain, (chain) {
      setState(() => _chain = chain);
    });
  }

  String _sanitizeWord(String raw) {
    final cleaned = raw.trim().toLowerCase().replaceAll(_invalidCharsRegex, '');
    return Bip39WordlistService.toNfc(cleaned);
  }

  void _updateSuggestionsForIndex(int? index) {
    if (index == null || index < 0 || index >= _words.length) {
      if (_suggestions.isNotEmpty) {
        setState(() => _suggestions = const []);
      }
      return;
    }

    final current = _words[index];
    final detection = Bip39WordlistService.instance.detectLanguage(
      _words,
      currentDraft: current,
    );

    if (current.isEmpty) {
      setState(() {
        _detectedLanguage = detection.language;
        _isLanguageDetected = detection.isConfident;
        _suggestions = const [];
      });
      return;
    }

    final suggestions = Bip39WordlistService.instance.getSuggestions(
      current,
      preferredLanguage: detection.isConfident ? detection.language : null,
      contextWords: _words,
      limit: 6,
    );

    // Hide suggestions if the typed word is already the single exact match
    final filtered =
        (suggestions.length == 1 && suggestions.first == current)
            ? const <String>[]
            : suggestions;

    setState(() {
      _detectedLanguage = detection.language;
      _isLanguageDetected = detection.isConfident;
      _suggestions = filtered;
    });
  }

  Future<void> _handleCheckWords() async {
    try {
      await Bip39WordlistService.instance.ensureLoaded();
      final nonEmptyWords = _words.where((word) => word.isNotEmpty).toList();
      if (nonEmptyWords.isEmpty) {
        if (mounted) {
          setState(() {
            _wordsErrorIndexes = [];
            _isLanguageDetected = false;
          });
        }
        return;
      }

      final detection = Bip39WordlistService.instance.detectLanguage(_words);
      final invalidIndices = Bip39WordlistService.instance
          .findInvalidWordIndices(_words, language: detection.language);

      if (mounted) {
        setState(() {
          _detectedLanguage = detection.language;
          _isLanguageDetected = detection.isConfident;
          _wordsErrorIndexes = invalidIndices;
        });
        await _validateForm();
      }
    } catch (e) {
      debugPrint("Error checking BIP39 words: $e");
    }
  }

  Future<void> _validateForm() async {
    final allFilled = _words.every((word) => word.trim().isNotEmpty);
    final noWordErrors = _wordsErrorIndexes.isEmpty;

    setState(() {
      _allWordsEntered = allFilled;
    });

    final areAllWordsValid = allFilled && noWordErrors;

    if (areAllWordsValid) {
      if (!_showChecksumWarning) {
        final checksumValid =
            await Bip39WordlistService.instance.validateChecksum(
          _words,
          language: _detectedLanguage,
        );

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

  void _applySuggestion(String word) {
    final idx = _activeIndex;
    if (idx == null || idx < 0 || idx >= _words.length) return;

    final nextIdx = idx + 1 < _count ? idx + 1 : null;
    setState(() {
      _words[idx] = word;
      _wordsErrorIndexes.remove(idx);
      _suggestions = const [];
      _activeIndex = nextIdx;
      _showChecksumWarning = false;
      _bypassChecksumValidation = false;
    });

    Future.microtask(() => _handleCheckWords());
  }

  void _handleWordChange(int index, String word) {
    final currentIndex = index - 1;
    if (word.trim().contains(_whitespaceRegex)) {
      _handlePhrasePaste(word, startIndex: currentIndex);
      return;
    }

    if ((word.endsWith(' ') || word.endsWith('\u3000')) &&
        word.trim().isNotEmpty) {
      final sanitized = _sanitizeWord(word);
      if (sanitized.isNotEmpty) {
        setState(() {
          _words[currentIndex] = sanitized;
          _wordsErrorIndexes.remove(currentIndex);
          _suggestions = const [];
          if (currentIndex + 1 < _count) {
            _activeIndex = currentIndex + 1;
          }
        });
        Future.microtask(() => _handleCheckWords());
        return;
      }
    }

    final trimmedWord = _sanitizeWord(word);
    _words[currentIndex] = trimmedWord;
    _wordsErrorIndexes.remove(currentIndex);

    if (_showChecksumWarning) {
      setState(() {
        _showChecksumWarning = false;
        _bypassChecksumValidation = false;
      });
    }

    _updateSuggestionsForIndex(currentIndex);
    _validateForm();

    if (trimmedWord.isNotEmpty) {
      Future.microtask(() => _handleCheckWords());
    }
  }

  void _handlePhrasePaste(String phrase, {int startIndex = 0}) {
    final words = phrase
        .trim()
        .split(_whitespaceRegex)
        .map(_sanitizeWord)
        .where((word) => word.isNotEmpty)
        .toList();

    if (words.isEmpty) return;

    final isCompletePhrase = _allowedCounts.contains(words.length);
    final effectiveStartIndex = isCompletePhrase ? 0 : startIndex;

    final neededLength = effectiveStartIndex + words.length;
    final targetCount = neededLength > _count
        ? _allowedCounts.firstWhere(
            (count) => count >= neededLength,
            orElse: () => _allowedCounts.last,
          )
        : (isCompletePhrase ? words.length : _count);

    if (targetCount != _count) {
      final resized = List<String>.filled(targetCount, '', growable: true);
      if (!isCompletePhrase) {
        for (int i = 0; i < math.min(_words.length, targetCount); i++) {
          resized[i] = _words[i];
        }
      }
      _count = targetCount;
      _words = resized;
      _wordsErrorIndexes = [];
    }

    for (var i = 0;
        i < words.length && (effectiveStartIndex + i) < _words.length;
        i++) {
      _words[effectiveStartIndex + i] = words[i];
    }

    final detection = Bip39WordlistService.instance.detectLanguage(_words);
    final langData =
        Bip39WordlistService.instance.getLoaded(detection.language);
    if (langData != null && detection.isConfident) {
      for (int i = 0; i < _words.length; i++) {
        if (_words[i].isNotEmpty && langData.containsWord(_words[i])) {
          _words[i] = langData.canonicalWord(_words[i]);
        }
      }
    }

    setState(() {
      _showChecksumWarning = false;
      _bypassChecksumValidation = false;
      _words = List.from(_words);
      _suggestions = const [];
      _detectedLanguage = detection.language;
      _isLanguageDetected = detection.isConfident;
    });

    _validateForm();
    Future.microtask(() => _handleCheckWords());
  }

  void _handleCountChanged(int newCount) {
    if (!mounted) return;

    setState(() {
      _count = newCount;
      final newWords = List<String>.filled(newCount, '', growable: true);
      for (var i = 0; i < math.min(_words.length, newCount); i++) {
        newWords[i] = _words[i];
      }
      _words = newWords;
      _wordsErrorIndexes = [];
      _suggestions = const [];
      _showChecksumWarning = false;
      _bypassChecksumValidation = false;
    });

    _validateForm();
    Future.microtask(() => _handleCheckWords());
  }

  bool get _isButtonEnabled {
    if (!_allWordsEntered) return false;
    if (_wordsErrorIndexes.isNotEmpty) return false;
    if (_isChecksumValid) return true;
    return _bypassChecksumValidation;
  }

  Widget _buildWordGrid(AppTheme theme) {
    const columns = 3;
    final rowCount = (_words.length + columns - 1) ~/ columns;

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: rowCount,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, rowIndex) {
        final startIdx = rowIndex * columns;
        return Row(
          children: List.generate(columns, (colIdx) {
            final wordIndex = startIdx + colIdx;
            if (wordIndex >= _words.length) {
              return const Expanded(child: SizedBox.shrink());
            }
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  left: colIdx == 0 ? 0 : 4,
                  right: colIdx == columns - 1 ? 0 : 4,
                ),
                child: MnemonicWordInput(
                  key: ValueKey('word_$wordIndex'),
                  index: wordIndex + 1,
                  word: _words[wordIndex],
                  isEditable: true,
                  compact: true,
                  obscureWhenUnfocused: false,
                  isActive: _activeIndex == wordIndex,
                  hasError: _wordsErrorIndexes.contains(wordIndex),
                  onFocusIndex: (idx) {
                    setState(() => _activeIndex = idx);
                    _updateSuggestionsForIndex(idx);
                  },
                  onNextRequested: (idx) {
                    if (idx + 1 < _count) {
                      setState(() {
                        _activeIndex = idx + 1;
                        _suggestions = const [];
                      });
                    } else {
                      FocusScope.of(context).unfocus();
                    }
                  },
                  onChanged: _handleWordChange,
                ),
              ),
            );
          }),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);
    final theme = Provider.of<AppState>(context).currentTheme;
    final l10n = AppLocalizations.of(context)!;

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
                CustomAppBar(
                  title: l10n.restoreSecretPhrasePageRestoreButton,
                  onBackPressed: () => context.pop(),
                  actionIcon: _isLanguageDetected
                      ? Text(
                          '${_detectedLanguage.badge} ${_detectedLanguage.shortCode}',
                          style: theme.bodyText2.copyWith(
                            color: theme.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      : null,
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: adaptivePadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        WordCountSelector(
                          wordCounts: _allowedCounts,
                          selectedCount: _count,
                          onCountChanged: _handleCountChanged,
                        ),
                        if (_suggestions.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: SizedBox(
                              height: 30,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                itemCount: _suggestions.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 6),
                                itemBuilder: (context, index) {
                                  final suggestion = _suggestions[index];
                                  return GestureDetector(
                                    key: ValueKey('bip39_suggestion_$index'),
                                    onTap: () => _applySuggestion(suggestion),
                                    behavior: HitTestBehavior.opaque,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 11,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: theme.cardBackground
                                            .withValues(alpha: 0.75),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        suggestion,
                                        style: theme.bodyText2.copyWith(
                                          color: theme.textPrimary,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: _buildWordGrid(theme),
                        ),
                        if (_showChecksumWarning)
                          Padding(
                            padding: const EdgeInsets.only(top: 8, bottom: 4),
                            child: Column(
                              children: [
                                GlassMessage(
                                  message: l10n.checksumValidationFailed,
                                  type: GlassMessageType.warning,
                                  margin: const EdgeInsets.only(bottom: 4),
                                ),
                                Row(
                                  children: [
                                    Checkbox(
                                      value: _bypassChecksumValidation,
                                      onChanged: (value) {
                                        setState(() {
                                          _bypassChecksumValidation =
                                              value ?? false;
                                        });
                                      },
                                      activeColor: theme.warning,
                                    ),
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _bypassChecksumValidation =
                                                !_bypassChecksumValidation;
                                          });
                                        },
                                        child: Text(
                                          l10n.proceedDespiteInvalidChecksum,
                                          style: theme.bodyText2.copyWith(
                                            color: theme.textSecondary,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.only(top: 10, bottom: 16),
                          child: CustomButton(
                            textColor: theme.buttonText,
                            backgroundColor: theme.primaryPurple,
                            text: l10n.restoreSecretPhrasePageRestoreButton,
                            onPressed: () {
                              context.push(AppRoutes.passSetup, extra: {
                                'bip39': _words,
                                'chain': _chain,
                                'ignore_checksum': _bypassChecksumValidation,
                              });
                            },
                            borderRadius: 30,
                            height: 56,
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
