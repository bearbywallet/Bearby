import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zilpay/components/mnemonic_word_input.dart';
import 'package:zilpay/src/rust/api/simple.dart';
import '../theme/theme_provider.dart';

class SecretPhraseGeneratorPage extends StatefulWidget {
  const SecretPhraseGeneratorPage({super.key});

  @override
  _SeedPhraseGeneratorPageState createState() =>
      _SeedPhraseGeneratorPageState();
}

class _SeedPhraseGeneratorPageState extends State<SecretPhraseGeneratorPage> {
  List<String> _mnemonicWords = [];
  final _count = 12;
  bool _hasBackupWords = false;

  @override
  void initState() {
    super.initState();
    _regenerateMnemonicWords();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: SvgPicture.asset(
            'assets/icons/back.svg',
            width: 24,
            height: 24,
            color: theme.secondaryPurple,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: IconButton(
              icon: SvgPicture.asset(
                'assets/icons/reload.svg',
                width: 30,
                height: 30,
                color: theme.textPrimary,
              ),
              onPressed: _regenerateMnemonicWords,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Create Account',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                      decoration: BoxDecoration(
                        color: theme.cardBackground,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('12',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C2C2E),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('English',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Create seed phrase',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              const Text(
                'Write down or copy the phrase, or save it safely',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: _mnemonicWords.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: MnemonicWordInput(
                        index: index + 1,
                        word: _mnemonicWords[index],
                        isEditable: false,
                      ),
                    );
                  },
                ),
              ),
              Row(
                children: [
                  Checkbox(
                    value: _hasBackupWords,
                    onChanged: (bool? value) {
                      setState(() {
                        _hasBackupWords = value ?? false;
                      });
                    },
                  ),
                  const Text(
                    'I have backup words',
                    style: TextStyle(color: Colors.purple),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  child: const Text('Next'),
                  onPressed: _hasBackupWords ? _onNextPressed : null,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: theme.secondaryPurple,
                    // onPrimary: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _regenerateMnemonicWords() async {
    String words = await genBip39Words(count: _count);

    setState(() {
      _mnemonicWords = words.split(" ");
      ;
    });
  }

  void _onNextPressed() {
    print('Next button pressed');
  }
}
