import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:bearby/components/app_icon.dart';
import 'package:bearby/components/button.dart';
import 'package:bearby/components/custom_app_bar.dart';
import 'package:bearby/components/mnemonic_word_input.dart';
import 'package:bearby/components/modal_drag_handle.dart';
import 'package:bearby/components/tile_button.dart';
import 'package:bearby/components/wor_count_selector.dart';
import 'package:bearby/l10n/app_localizations.dart';
import 'package:bearby/mixins/adaptive_size.dart';
import 'package:bearby/mixins/chain_route_args.dart';
import 'package:bearby/mixins/status_bar.dart';
import 'package:bearby/modals/backup_confirmation_modal.dart';
import 'package:bearby/router.dart';
import 'package:bearby/src/rust/models/provider.dart';
import 'package:bearby/state/app_state.dart';
import 'package:bearby/theme/app_theme.dart';
import 'package:bearby/utils/bip39_wordlist.dart';

class SecretPhraseGeneratorPage extends StatefulWidget {
  const SecretPhraseGeneratorPage({
    super.key,
  });

  @override
  State<SecretPhraseGeneratorPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<SecretPhraseGeneratorPage>
    with StatusBarMixin, ChainRouteArgsMixin {
  List<String> _mnemonicWords = [];
  int _count = 24;
  Bip39Language _selectedLanguage = Bip39Language.english;
  bool _hasBackupWords = false;
  bool _isCopied = false;
  NetworkConfigInfo? _chain;

  @override
  void initState() {
    super.initState();
    _regenerateMnemonicWords();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    bootstrapChainArg(_chain, (chain) {
      setState(() {
        _chain = chain;
      });
    });
  }

  Future<void> _regenerateMnemonicWords() async {
    final words = await Bip39WordlistService.instance.generateWords(
      count: _count,
      language: _selectedLanguage,
    );

    if (!mounted) return;
    setState(() {
      _mnemonicWords = words;
      _hasBackupWords = false;
      _isCopied = false;
    });
  }

  Future<void> _handleCopy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    setState(() {
      _isCopied = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isCopied = false;
        });
      }
    });
  }

  void _showLanguagePicker(AppTheme theme) {
    showModalBottomSheet<Bip39Language>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(sheetContext).size.height * 0.68,
              ),
              decoration: BoxDecoration(
                color: theme.cardBackground.withValues(alpha: 0.94),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(
                  top: BorderSide(
                    color: theme.modalBorder.withValues(alpha: 0.6),
                    width: 1,
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 10),
                    ModalDragHandle(theme: theme),
                    Flexible(
                      child: GridView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                        physics: const BouncingScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 2.9,
                        ),
                        itemCount: Bip39Language.values.length,
                        itemBuilder: (context, index) {
                          final lang = Bip39Language.values[index];
                          final isSelected = lang == _selectedLanguage;
                          return GestureDetector(
                            onTap: () => Navigator.of(sheetContext).pop(lang),
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? theme.primaryPurple.withValues(alpha: 0.16)
                                    : theme.background.withValues(alpha: 0.45),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? theme.primaryPurple
                                      : Colors.transparent,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    lang.badge,
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      lang.nativeName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.bodyText2.copyWith(
                                        color: theme.textPrimary,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ).then((chosen) {
      if (chosen != null && chosen != _selectedLanguage) {
        setState(() {
          _selectedLanguage = chosen;
        });
        _regenerateMnemonicWords();
      }
    });
  }

  Widget _buildMatrixGrid(AppTheme theme) {
    const columns = 3;
    final rowCount = (_mnemonicWords.length + columns - 1) ~/ columns;

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
            if (wordIndex >= _mnemonicWords.length) {
              return const Expanded(child: SizedBox.shrink());
            }
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  left: colIdx == 0 ? 0 : 4,
                  right: colIdx == columns - 1 ? 0 : 4,
                ),
                child: MnemonicWordInput(
                  key: ValueKey('gen_word_$wordIndex'),
                  index: wordIndex + 1,
                  word: _mnemonicWords[wordIndex],
                  isEditable: false,
                  compact: true,
                  opacity: 1.0,
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
                  title: l10n.secretPhraseGeneratorPageTitle,
                  onBackPressed: () => context.pop(),
                  actionIcon: AppIconView(
                    icon: AppIcon.reload,
                    size: 26,
                    color: theme.textPrimary,
                  ),
                  onActionPressed: _regenerateMnemonicWords,
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: adaptivePadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: WordCountSelector(
                                wordCounts: const [12, 15, 18, 21, 24],
                                selectedCount: _count,
                                onCountChanged: (newCount) {
                                  setState(() {
                                    _count = newCount;
                                  });
                                  _regenerateMnemonicWords();
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              key: const ValueKey('bip39_lang_selector'),
                              onTap: () => _showLanguagePicker(theme),
                              behavior: HitTestBehavior.opaque,
                              child: Container(
                                height: 48,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.cardBackground
                                      .withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _selectedLanguage.badge,
                                      style: const TextStyle(fontSize: 15),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _selectedLanguage.shortCode,
                                      style: theme.labelMedium.copyWith(
                                        color: theme.textPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: _buildMatrixGrid(theme),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: Material(
                                color: Colors.transparent,
                                child: Theme(
                                  data: Theme.of(context).copyWith(
                                    splashFactory: NoSplash.splashFactory,
                                    highlightColor: Colors.transparent,
                                  ),
                                  child: CheckboxListTile(
                                    contentPadding: EdgeInsets.zero,
                                    dense: true,
                                    checkboxShape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    title: Text(
                                      l10n.secretPhraseGeneratorPageBackupCheckbox,
                                      style: theme.bodyText2
                                          .copyWith(color: theme.textSecondary),
                                    ),
                                    value: _hasBackupWords,
                                    onChanged: (_) {
                                      if (!_hasBackupWords) {
                                        showBackupConfirmationModal(
                                          context: context,
                                          onConfirmed: (confirmed) {
                                            setState(() {
                                              _hasBackupWords = confirmed;
                                            });
                                          },
                                        );
                                      }
                                    },
                                    controlAffinity:
                                        ListTileControlAffinity.leading,
                                    activeColor: theme.primaryPurple,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            TileButton(
                              icon: AppIconView(
                                icon: _isCopied ? AppIcon.check : AppIcon.copy,
                                size: 22,
                                color: _isCopied
                                    ? theme.success
                                    : theme.primaryPurple,
                              ),
                              disabled: false,
                              onPressed: () async {
                                await _handleCopy(_mnemonicWords.join(" "));
                              },
                              backgroundColor: theme.cardBackground,
                              textColor: theme.primaryPurple,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: CustomButton(
                            textColor: theme.buttonText,
                            backgroundColor: theme.primaryPurple,
                            text: l10n.secretPhraseGeneratorPageNextButton,
                            onPressed: () {
                              context.pushReplacement(AppRoutes.verifyBip39,
                                  extra: {
                                    'bip39': _mnemonicWords,
                                    'chain': _chain,
                                  });
                            },
                            borderRadius: 30.0,
                            height: 56.0,
                            disabled: !_hasBackupWords,
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
