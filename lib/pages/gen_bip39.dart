import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/theme_provider.dart';

class SecretPhraseGeneratorPage extends StatefulWidget {
  @override
  _SecretPhraseGeneratorPageState createState() => _SecretPhraseGeneratorPageState();
}

class _SecretPhraseGeneratorPageState extends State<SecretPhraseGeneratorPage> {
  bool isBackupConfirmed = false;
  String selectedLanguage = 'English';
  int wordCount = 24;
  List<String> words = List.generate(24, (index) => 'word${index + 1}');

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
        title: Text('Secret Phrase Generator', style: TextStyle(color: theme.textPrimary)),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Generate a unique secret phrase to secure your wallet. Write down these words in order and keep them safe.',
              style: TextStyle(color: theme.textSecondary, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  child: Text(selectedLanguage),
                  onPressed: () {
                    // Logic to change language
                  },
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(theme.buttonBackground),
                    foregroundColor: MaterialStateProperty.all(theme.buttonText),
                  ),
                ),
                ElevatedButton(
                  child: Text('$wordCount'),
                  onPressed: () {
                    // Logic to change word count
                  },
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(theme.buttonBackground),
                    foregroundColor: MaterialStateProperty.all(theme.buttonText),
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
            for (int i = 0; i < words.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 30,
                      child: Text(
                        '${i + 1}.',
                        style: TextStyle(color: theme.textSecondary, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text(
                      words[i],
                      style: TextStyle(color: theme.textPrimary, fontSize: 16),
                    ),
                  ],
                ),
              ),
            SizedBox(height: 24),
            Row(
              children: [
                Checkbox(
                  value: isBackupConfirmed,
                  onChanged: (value) {
                    setState(() {
                      isBackupConfirmed = value ?? false;
                    });
                  },
                  fillColor: MaterialStateProperty.all(theme.primaryPurple),
                ),
                Expanded(
                  child: Text(
                    'I have made a backup of my secret phrase',
                    style: TextStyle(color: theme.textPrimary),
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
            ElevatedButton(
              child: Text('Continue'),
              onPressed: isBackupConfirmed ? () {
                // Logic to proceed
              } : null,
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.resolveWith<Color>(
                  (Set<MaterialState> states) {
                    if (states.contains(MaterialState.disabled)) {
                      return theme.buttonBackground.withOpacity(0.5);
                    }
                    return theme.primaryPurple;
                  },
                ),
                foregroundColor: MaterialStateProperty.all(theme.buttonText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
