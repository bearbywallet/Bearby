import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:bearby/components/button.dart';
import 'package:bearby/components/custom_app_bar.dart';
import 'package:bearby/components/mnemonic_word_input.dart';
import 'package:bearby/components/tile_button.dart';
import 'package:bearby/components/wor_count_selector.dart';
import 'package:bearby/mixins/adaptive_size.dart';
import 'package:bearby/mixins/status_bar.dart';
import 'package:bearby/modals/backup_confirmation_modal.dart';
import 'package:bearby/src/rust/api/methods.dart';
import 'package:bearby/src/rust/models/provider.dart';
import 'package:bearby/state/app_state.dart';
import 'package:bearby/l10n/app_localizations.dart';

class SecretPhraseGeneratorPage extends StatefulWidget {
  const SecretPhraseGeneratorPage({
    super.key,
  });

  @override
  State<SecretPhraseGeneratorPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<SecretPhraseGeneratorPage>
    with StatusBarMixin {
  List<String> _mnemonicWords = [];
  var _count = 12;
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

  @override
  void dispose() {
    super.dispose();
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
                  onBackPressed: () => Navigator.pop(context),
                  actionIcon: SvgPicture.asset(
                    'assets/icons/reload.svg',
                    width: 30,
                    height: 30,
                    colorFilter: ColorFilter.mode(
                      theme.textPrimary,
                      BlendMode.srcIn,
                    ),
                  ),
                  onActionPressed: _regenerateMnemonicWords,
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: adaptivePadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        WordCountSelector(
                          wordCounts: const [12, 15, 18, 21, 24],
                          selectedCount: _count,
                          onCountChanged: (newCount) {
                            setState(() {
                              _count = newCount;
                              _regenerateMnemonicWords();
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            itemCount: _mnemonicWords.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8.0),
                                child: MnemonicWordInput(
                                  index: index + 1,
                                  word: _mnemonicWords[index],
                                  isEditable: false,
                                  opacity: 1.0,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Theme(
                                data: Theme.of(context).copyWith(
                                  splashFactory: NoSplash.splashFactory,
                                  highlightColor: Colors.transparent,
                                ),
                                child: CheckboxListTile(
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
                            TileButton(
                              icon: SvgPicture.asset(
                                _isCopied
                                    ? "assets/icons/check.svg"
                                    : "assets/icons/copy.svg",
                                width: 24,
                                height: 24,
                                colorFilter: ColorFilter.mode(
                                  theme.primaryPurple,
                                  BlendMode.srcIn,
                                ),
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
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: CustomButton(
                            textColor: theme.buttonText,
                            backgroundColor: theme.primaryPurple,
                            text: l10n.secretPhraseGeneratorPageNextButton,
                            onPressed: () {
                              Navigator.of(context).pushReplacementNamed(
                                '/verify_bip39',
                                arguments: {
                                  'bip39': _mnemonicWords,
                                  'chain': _chain,
                                },
                              );
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

  Future<void> _handleCopy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
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

  void _regenerateMnemonicWords() async {
    String words = await genBip39Words(count: _count);

    setState(() {
      _mnemonicWords = words.split(" ");
      _hasBackupWords = false;
      _isCopied = false;
    });
  }
}
