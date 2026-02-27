import 'dart:math';
import 'package:flutter/material.dart';
import 'package:bearby/components/button.dart';
import 'package:bearby/components/custom_app_bar.dart';
import 'package:provider/provider.dart';
import 'package:bearby/components/mnemonic_word_input.dart';
import 'package:bearby/mixins/status_bar.dart';
import 'package:bearby/src/rust/models/provider.dart';
import 'package:bearby/state/app_state.dart';
import 'package:bearby/l10n/app_localizations.dart';

const _maxNumbers = 4;

List<int> _getRandomNumbers(int min, int max, int count) {
  final random = Random();
  final numbers = <int>{};

  while (numbers.length < count) {
    numbers.add(min + random.nextInt(max - min));
  }

  return numbers.toList();
}

class SecretPhraseVerifyPage extends StatefulWidget {
  const SecretPhraseVerifyPage({super.key});

  @override
  State<SecretPhraseVerifyPage> createState() => _VerifyBip39PageState();
}

class _VerifyBip39PageState extends State<SecretPhraseVerifyPage>
    with StatusBarMixin {
  List<String>? _bip39List;
  NetworkConfigInfo? _chain;
  List<int> _indexes = [];
  final List<String> _verifyWords =
      List.filled(_maxNumbers, '', growable: false);

  void _generateIndexes({bool useSetState = true}) {
    if (_bip39List == null || _bip39List!.isEmpty) return;

    final newIndexes = _getRandomNumbers(0, _bip39List!.length, _maxNumbers);
    if (useSetState) {
      setState(() => _indexes = newIndexes);
    } else {
      _indexes = newIndexes;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final bip39 = args?['bip39'] as List<String>?;
    final chain = args?['chain'] as NetworkConfigInfo?;

    if (bip39 == null || bip39.isEmpty || chain == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/net_setup');
      });
    } else if (_bip39List == null) {
      setState(() {
        _bip39List = bip39;
        _chain = chain;
        _generateIndexes(useSetState: false);
      });
    }
  }

  MnemonicValidation _getValidation(int index) {
    if (_bip39List == null || _verifyWords[index].isEmpty) {
      return MnemonicValidation.none;
    }

    final wordIndex = _indexes[index];
    final isCorrect = _bip39List![wordIndex].toLowerCase() ==
        _verifyWords[index].toLowerCase();

    return isCorrect ? MnemonicValidation.valid : MnemonicValidation.invalid;
  }

  bool get _isVerified {
    if (_bip39List == null || _indexes.length != _maxNumbers) return false;

    for (int i = 0; i < _maxNumbers; i++) {
      final bip39Index = _indexes[i];
      if (bip39Index < 0 || bip39Index >= _bip39List!.length) return false;

      if (_bip39List![bip39Index].toLowerCase() !=
          _verifyWords[i].toLowerCase()) {
        return false;
      }
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
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
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: CustomAppBar(
                    title: AppLocalizations.of(context)!
                        .secretPhraseVerifyPageTitle,
                    onBackPressed: () => Navigator.pop(context),
                  ),
                ),
                Expanded(
                  child: _bip39List == null || _indexes.isEmpty
                      ? Center(
                          child: CircularProgressIndicator(
                              color: theme.primaryPurple))
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              Text(
                                AppLocalizations.of(context)!
                                    .secretPhraseVerifyPageSubtitle,
                                style: theme.titleLarge,
                              ),
                              const SizedBox(height: 16),
                              Expanded(
                                child: ListView.builder(
                                  padding: const EdgeInsets.all(12),
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: _maxNumbers,
                                  itemBuilder: (context, index) {
                                    final wordIndex = _indexes[index];

                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 6),
                                      child: MnemonicWordInput(
                                        key: ValueKey('verify_$index'),
                                        index: wordIndex + 1,
                                        word: _verifyWords[index],
                                        isEditable: true,
                                        validation: _getValidation(index),
                                        onChanged: (_, newWord) {
                                          setState(() =>
                                              _verifyWords[index] = newWord);
                                        },
                                      ),
                                    );
                                  },
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                child: CustomButton(
                                  textColor: theme.buttonText,
                                  backgroundColor: theme.primaryPurple,
                                  text: AppLocalizations.of(context)!
                                      .secretPhraseVerifyPageNextButton,
                                  onPressed: () {
                                    Navigator.of(context).pushReplacementNamed(
                                      '/pass_setup',
                                      arguments: {
                                        'bip39': _bip39List,
                                        'chain': _chain,
                                      },
                                    );
                                  },
                                  borderRadius: 30,
                                  height: 56,
                                  disabled: !_isVerified,
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
