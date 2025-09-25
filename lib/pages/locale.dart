import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/src/rust/api/settings.dart';
import 'package:zilpay/state/app_state.dart';
import '../theme/app_theme.dart';
import '../components/custom_app_bar.dart';
import 'package:zilpay/l10n/app_localizations.dart';

class Language {
  final String code;
  final String name;
  final String localName;

  Language(this.code, this.name, this.localName);
}

class LanguagePage extends StatefulWidget {
  const LanguagePage({super.key});

  @override
  State<LanguagePage> createState() => _LanguagePageState();
}

class _LanguagePageState extends State<LanguagePage> {
  final List<Language> languages = [];

  String selectedLanguage = 'system';
  bool vibrateEnabled = true;

  @override
  void initState() {
    super.initState();
    final appState = Provider.of<AppState>(context, listen: false);

    if (appState.state.locale != null) {
      setState(() {
        selectedLanguage = appState.state.locale!;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = appState.currentTheme;
    final l10n = AppLocalizations.of(context)!;

    languages.clear();
    languages.addAll([
      Language('system', 'System', ""),
      Language('ru', 'Russian', "Русский"),
      Language('ko', 'Korean', "한국어"),
      Language('en', 'English', "English"),
      Language('ja', 'Japanese', "日本語"),
      Language('zh', 'Chinese', "中文"),
    ]);

    return Scaffold(
      backgroundColor: theme.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: CustomAppBar(
                    title: l10n.languagePageTitle,
                    onBackPressed: () => Navigator.pop(context),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: languages.length,
                    itemBuilder: (context, index) {
                      final language = languages[index];
                      final isSelected = language.code == selectedLanguage;
                      final isLastItem = index == languages.length - 1;

                      return _buildLanguageItem(
                        theme,
                        language,
                        isSelected,
                        isLastItem,
                        onTap: () async {
                          await setDefaultLocale(locale: language.code);
                          setState(() {
                            selectedLanguage = language.code;
                          });

                          await appState.syncData();
                        },
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
  }

  Widget _buildLanguageItem(
    AppTheme theme,
    Language language,
    bool isSelected,
    bool isLastItem, {
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: !isLastItem
              ? Border(
                  bottom: BorderSide(
                    color: theme.textSecondary.withValues(alpha: 0.1),
                    width: 1,
                  ),
                )
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              language.name,
              style: TextStyle(
                color: theme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    language.localName,
                    style: TextStyle(
                      color: theme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
                SizedBox(
                  width: 24,
                  height: 24,
                  child: isSelected
                      ? SvgPicture.asset(
                          'assets/icons/ok.svg',
                          colorFilter: ColorFilter.mode(
                            theme.primaryPurple,
                            BlendMode.srcIn,
                          ),
                        )
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
