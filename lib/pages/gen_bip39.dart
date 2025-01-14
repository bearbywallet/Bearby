import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/button.dart';
import 'package:zilpay/components/custom_app_bar.dart';
import 'package:zilpay/components/mnemonic_word_input.dart';
import 'package:zilpay/components/wor_count_selector.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import 'package:zilpay/modals/backup_confirmation_modal.dart';
import 'package:zilpay/src/rust/api/methods.dart';
import 'package:zilpay/state/app_state.dart';

class SecretPhraseGeneratorPage extends StatefulWidget {
  const SecretPhraseGeneratorPage({
    super.key,
  });

  @override
  State<SecretPhraseGeneratorPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<SecretPhraseGeneratorPage> {
  List<String> _mnemonicWords = [];
  var _count = 12;
  bool _hasBackupWords = false;
  // final String _selectedLanguage = 'English';

  @override
  void initState() {
    super.initState();
    _regenerateMnemonicWords();
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
                  title: 'New Wallet',
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
                                  opacity: 0.5,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        Theme(
                          data: Theme.of(context).copyWith(
                            splashFactory: NoSplash.splashFactory,
                            highlightColor: Colors.transparent,
                          ),
                          child: CheckboxListTile(
                            title: Text(
                              'I have backup words',
                              style: TextStyle(color: theme.textSecondary),
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
                            controlAffinity: ListTileControlAffinity.leading,
                            activeColor: theme.primaryPurple,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: CustomButton(
                            text: 'Next',
                            onPressed: () {
                              Navigator.of(context).pushNamed('/verify_bip39',
                                  arguments: {'bip39': _mnemonicWords});
                            },
                            backgroundColor: theme.primaryPurple,
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

  void _regenerateMnemonicWords() async {
    String words = await genBip39Words(count: _count);

    setState(() {
      _mnemonicWords = words.split(" ");
      _hasBackupWords = false;
    });
  }
}
