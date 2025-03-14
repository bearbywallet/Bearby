import 'dart:math';
import 'package:flutter/material.dart';
import 'package:zilpay/components/button.dart';
import 'package:zilpay/components/custom_app_bar.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/mnemonic_word_input.dart';
import 'package:zilpay/state/app_state.dart';
import 'package:zilpay/l10n/app_localizations.dart';

List<int> getRandomNumbers(int min, int max, int count) {
  final random = Random();
  Set<int> numbers = {};

  while (numbers.length < count) {
    int randomNumber = min + random.nextInt(max - min);
    numbers.add(randomNumber);
  }

  return numbers.toList();
}

const maxNumbers = 4;

class SecretPhraseVerifyPage extends StatefulWidget {
  const SecretPhraseVerifyPage({
    super.key,
  });

  @override
  State<SecretPhraseVerifyPage> createState() => _VerifyBip39PageState();
}

class _VerifyBip39PageState extends State<SecretPhraseVerifyPage> {
  List<String>? _bip39List;
  List<int> _indexes = [];
  final List<String> _verifyWords =
      List<String>.filled(maxNumbers, '', growable: false);

  void _generateIndexes() {
    if (_bip39List != null && _bip39List!.isNotEmpty) {
      setState(() {
        _indexes = getRandomNumbers(0, _bip39List!.length, maxNumbers);
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments
        as Map<String, List<String>>?;

    if (args == null || args['bip39'] == null || args['bip39']!.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/initial');
      });
    } else {
      setState(() {
        _bip39List = args['bip39'];
        _generateIndexes();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<AppState>(context).currentTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                CustomAppBar(
                  title:
                      AppLocalizations.of(context)!.secretPhraseVerifyPageTitle,
                  onBackPressed: () => Navigator.pop(context),
                  actionWidget: TextButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed('/net_setup',
                          arguments: {'bip39': _bip39List});
                    },
                    child: Text(
                      AppLocalizations.of(context)!
                          .secretPhraseVerifyPageSkipButton,
                      style: TextStyle(
                        color: theme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _bip39List == null
                      ? const Center(child: CircularProgressIndicator())
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(context)!
                                    .secretPhraseVerifyPageSubtitle,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: theme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Expanded(
                                child: ListView.builder(
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: maxNumbers,
                                  itemBuilder: (context, index) {
                                    final wordIndex = _indexes[index];
                                    final displayIndex = wordIndex + 1;

                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8.0),
                                      child: MnemonicWordInput(
                                        index: displayIndex,
                                        word: _verifyWords[index],
                                        isEditable: true,
                                        borderColor: _verifyWords[index] == ''
                                            ? theme.textSecondary
                                            : _bip39List![wordIndex] ==
                                                    _verifyWords[index]
                                                ? Colors.green
                                                : Colors.red,
                                        onChanged: (_, newWord) {
                                          setState(() {
                                            _verifyWords[index] = newWord;
                                          });
                                        },
                                      ),
                                    );
                                  },
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16.0),
                                child: CustomButton(
                                  textColor: theme.buttonText,
                                  backgroundColor: theme.primaryPurple,
                                  text: AppLocalizations.of(context)!
                                      .secretPhraseVerifyPageNextButton,
                                  onPressed: () {
                                    Navigator.of(context).pushNamed(
                                        '/net_setup',
                                        arguments: {'bip39': _bip39List});
                                  },
                                  borderRadius: 30.0,
                                  height: 56.0,
                                  disabled: !isVerified,
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

  bool get isVerified {
    if (_bip39List == null ||
        _indexes.length != maxNumbers ||
        _verifyWords.length != maxNumbers) {
      return false;
    }

    for (int i = 0; i < maxNumbers; i++) {
      int bip39Index = _indexes[i];

      if (bip39Index < 0 || bip39Index >= _bip39List!.length) {
        return false;
      }

      if (_bip39List![bip39Index].trim().toLowerCase() !=
          _verifyWords[i].trim().toLowerCase()) {
        return false;
      }
    }

    return true;
  }
}
