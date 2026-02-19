import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/mixins/status_bar.dart';
import 'package:zilpay/src/rust/api/settings.dart';
import 'package:zilpay/state/app_state.dart';
import 'package:zilpay/components/custom_app_bar.dart';
import 'package:zilpay/l10n/app_localizations.dart';

class Language {
  final String code;
  final String name;
  final String localName;

  const Language(this.code, this.name, this.localName);
}

class LanguagePage extends StatefulWidget {
  const LanguagePage({super.key});

  @override
  State<LanguagePage> createState() => _LanguagePageState();
}

class _LanguagePageState extends State<LanguagePage> with StatusBarMixin {
  static const List<Language> _languages = [
    Language('system', 'System', ''),
    Language('ru', 'Russian', 'Русский'),
    Language('ko', 'Korean', '한국어'),
    Language('en', 'English', 'English'),
    Language('ja', 'Japanese', '日本語'),
    Language('zh', 'Chinese', '中文'),
  ];

  String _selectedLanguage = 'system';

  @override
  void initState() {
    super.initState();
    final appState = Provider.of<AppState>(context, listen: false);
    _selectedLanguage = appState.state.locale ?? 'system';
  }

  Future<void> _onLanguageSelected(Language language) async {
    await setDefaultLocale(locale: language.code);
    if (!mounted) return;
    setState(() => _selectedLanguage = language.code);
    await Provider.of<AppState>(context, listen: false).syncData();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final theme = appState.currentTheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: theme.background,
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
                    title: l10n.languagePageTitle,
                    onBackPressed: () => Navigator.pop(context),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: _languages.length,
                    itemBuilder: (context, index) => _LanguageItem(
                      language: _languages[index],
                      isSelected: _languages[index].code == _selectedLanguage,
                      onTap: () => _onLanguageSelected(_languages[index]),
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

class _LanguageItem extends StatefulWidget {
  final Language language;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageItem({
    required this.language,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_LanguageItem> createState() => _LanguageItemState();
}

class _LanguageItemState extends State<_LanguageItem> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<AppState>(context).currentTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: _isPressed
                    ? theme.primaryPurple.withValues(alpha: 0.15)
                    : theme.cardBackground.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: widget.isSelected
                      ? theme.primaryPurple.withValues(alpha: 0.4)
                      : theme.modalBorder,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.language.name,
                          style: theme.bodyLarge.copyWith(
                            color: theme.textPrimary,
                          ),
                        ),
                        if (widget.language.localName.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            widget.language.localName,
                            style: theme.bodyText2.copyWith(
                              color: theme.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: widget.isSelected ? 1.0 : 0.0,
                    child: SvgPicture.asset(
                      'assets/icons/ok.svg',
                      width: 20,
                      height: 20,
                      colorFilter: ColorFilter.mode(
                        theme.primaryPurple,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
