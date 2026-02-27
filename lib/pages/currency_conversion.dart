import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:bearby/components/custom_app_bar.dart';
import 'package:bearby/components/smart_input.dart';
import 'package:bearby/l10n/app_localizations.dart';
import 'package:bearby/mixins/adaptive_size.dart';
import 'package:bearby/mixins/status_bar.dart';
import 'package:bearby/src/rust/api/settings.dart';
import 'package:bearby/src/rust/api/utils.dart';
import 'package:bearby/state/app_state.dart';
import 'package:bearby/modals/list_selector.dart';
import 'package:bearby/theme/app_theme.dart';

class CurrencyConversionPage extends StatefulWidget {
  const CurrencyConversionPage({super.key});

  @override
  State<CurrencyConversionPage> createState() => _CurrencyConversionPageState();
}

class _CurrencyConversionPageState extends State<CurrencyConversionPage>
    with StatusBarMixin {
  List<Currency> _currencies = [];
  List<Currency> _filteredCurrencies = [];
  final TextEditingController _searchController = TextEditingController();
  String _selectedCurrency = 'btc';
  int _selectedEngine = 0;

  static const Map<String, String> _currencyNames = {
    "BTC": "Bitcoin",
    "RUB": "Russian Ruble",
    "BRL": "Brazilian Real",
    "AED": "United Arab Emirates Dirham",
    "INR": "Indian Rupee",
    "CNY": "Chinese Yuan",
    "KRW": "South Korean Won",
    "JPY": "Japanese Yen",
    "ZAR": "South African Rand",
    "EGP": "Egyptian Pound",
    "ETB": "Ethiopian Birr",
    "IRR": "Iranian Rial",
    "SAR": "Saudi Riyal",
    "USD": "United States Dollar",
    "EUR": "Euro",
    "GBP": "British Pound",
    "CHF": "Swiss Franc",
    "AUD": "Australian Dollar",
    "CAD": "Canadian Dollar",
    "MXN": "Mexican Peso",
    "XAUT": "Gold",
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final state = Provider.of<AppState>(context, listen: false);
    final currenciesTickets = await getCurrenciesTickets();
    final availableCodes = currenciesTickets.map((p) => p.$1).toSet();
    final codeToRate = {for (final pair in currenciesTickets) pair.$1: pair.$2};

    final currenciesList = _currencyNames.entries
        .where((e) => availableCodes.contains(e.key))
        .map((e) => Currency(e.key, "${e.value} ${codeToRate[e.key] ?? ''}"))
        .toList();

    setState(() {
      _currencies = currenciesList;
      _filteredCurrencies = currenciesList;
      _selectedCurrency = state.wallet?.settings.currencyConvert ?? 'btc';
      _selectedEngine = state.wallet?.settings.ratesApiOptions ?? 0;
    });
  }

  void _filterCurrencies(String query) {
    setState(() {
      _filteredCurrencies = query.isEmpty
          ? _currencies
          : _currencies
              .where((c) =>
                  c.name.toLowerCase().contains(query.toLowerCase()) ||
                  c.code.toLowerCase().contains(query.toLowerCase()))
              .toList();
    });
  }

  Future<void> _selectCurrency(Currency currency) async {
    final appState = Provider.of<AppState>(context, listen: false);
    setState(() => _selectedCurrency = currency.code);

    await setRateFetcher(
      walletIndex: BigInt.from(appState.selectedWallet),
      currency: currency.code,
    );
    await appState.syncRates(force: true);
    await appState.syncData();
  }

  Future<void> _selectEngine(int index) async {
    final appState = Provider.of<AppState>(context, listen: false);
    setState(() => _selectedEngine = index);

    await setRateEngine(
      walletIndex: BigInt.from(appState.selectedWallet),
      engineCode: index,
    );
    await appState.syncData();
  }

  void _showEngineSelector() {
    final l10n = AppLocalizations.of(context)!;
    showListSelectorModal(
      context: context,
      title: l10n.currencyConversionEngineSelectorTitle,
      items: [
        ListItem(
          title: l10n.currencyConversionEngineNone,
          subtitle: l10n.currencyConversionEngineNoneSubtitle,
        ),
        ListItem(
          title: l10n.currencyConversionEngineCryptoCompare,
          subtitle: l10n.currencyConversionEngineCryptoCompareSubtitle,
        ),
        ListItem(
          title: l10n.currencyConversionEngineCoingecko,
          subtitle: l10n.currencyConversionEngineCoingeckoSubtitle,
        ),
      ],
      selectedIndex: _selectedEngine,
      onItemSelected: _selectEngine,
    );
  }

  String _getEngineName(int index) {
    final l10n = AppLocalizations.of(context)!;
    return switch (index) {
      1 => l10n.currencyConversionEngineCryptoCompare,
      2 => l10n.currencyConversionEngineCoingecko,
      _ => l10n.currencyConversionEngineNone,
    };
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final theme = appState.currentTheme;
    final isRateEnabled = appState.wallet!.settings.ratesApiOptions != 0;
    final padding = AdaptiveSize.getAdaptivePadding(context, 16);

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
                  padding: EdgeInsets.symmetric(horizontal: padding),
                  child: CustomAppBar(
                    title:
                        AppLocalizations.of(context)!.currencyConversionTitle,
                    onBackPressed: () => Navigator.pop(context),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: padding),
                    child: Column(
                      children: [
                        _GlassCard(
                          child: _EngineTile(
                            theme: theme,
                            title: AppLocalizations.of(context)!
                                .currencyConversionEngineTitle,
                            subtitle: _getEngineName(_selectedEngine),
                            onTap: _showEngineSelector,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: _GlassCard(
                            opacity: isRateEnabled ? 1.0 : 0.5,
                            child: AbsorbPointer(
                              absorbing: !isRateEnabled,
                              child: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        16, 16, 16, 8),
                                    child: SmartInput(
                                      controller: _searchController,
                                      hint: AppLocalizations.of(context)!
                                          .currencyConversionSearchHint,
                                      leftIconPath: 'assets/icons/search.svg',
                                      rightIconPath: 'assets/icons/close.svg',
                                      onChanged: _filterCurrencies,
                                      onRightIconTap: () {
                                        _searchController.clear();
                                        _filterCurrencies('');
                                      },
                                      onSubmitted: (_) {},
                                      borderColor: theme.textPrimary,
                                      focusedBorderColor: theme.primaryPurple,
                                      height: 44,
                                      fontSize: 15,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12),
                                      autofocus: false,
                                      keyboardType: TextInputType.text,
                                    ),
                                  ),
                                  Expanded(
                                    child: ListView.builder(
                                      physics: const BouncingScrollPhysics(),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16),
                                      itemCount: _filteredCurrencies.length,
                                      itemBuilder: (context, index) {
                                        final currency =
                                            _filteredCurrencies[index];
                                        final isSelected =
                                            currency.code.toLowerCase() ==
                                                _selectedCurrency.toLowerCase();
                                        return _CurrencyTile(
                                          theme: theme,
                                          currency: currency,
                                          isSelected: isSelected,
                                          onTap: () =>
                                              _selectCurrency(currency),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
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

class _GlassCard extends StatelessWidget {
  final Widget child;
  final double opacity;

  const _GlassCard({required this.child, this.opacity = 1.0});

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<AppState>(context).currentTheme;

    return Opacity(
      opacity: opacity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: theme.cardBackground.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.textSecondary.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _EngineTile extends StatelessWidget {
  final AppTheme theme;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _EngineTile({
    required this.theme,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              SvgPicture.asset(
                'assets/icons/currency.svg',
                width: 22,
                height: 22,
                colorFilter:
                    ColorFilter.mode(theme.primaryPurple, BlendMode.srcIn),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style:
                            theme.bodyLarge.copyWith(color: theme.textPrimary)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: theme.labelMedium
                            .copyWith(color: theme.primaryPurple)),
                  ],
                ),
              ),
              SvgPicture.asset(
                'assets/icons/chevron_right.svg',
                width: 20,
                height: 20,
                colorFilter:
                    ColorFilter.mode(theme.textSecondary, BlendMode.srcIn),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CurrencyTile extends StatelessWidget {
  final AppTheme theme;
  final Currency currency;
  final bool isSelected;
  final VoidCallback onTap;

  const _CurrencyTile({
    required this.theme,
    required this.currency,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: theme.textSecondary.withValues(alpha: 0.08),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 64,
                child: Text(
                  currency.code.toUpperCase(),
                  style: theme.labelLarge.copyWith(
                    color: isSelected ? theme.primaryPurple : theme.textPrimary,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  currency.name,
                  style: theme.bodyText2.copyWith(color: theme.textSecondary),
                ),
              ),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: isSelected ? 1.0 : 0.0,
                child: SvgPicture.asset(
                  'assets/icons/ok.svg',
                  width: 20,
                  height: 20,
                  colorFilter:
                      ColorFilter.mode(theme.primaryPurple, BlendMode.srcIn),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Currency {
  final String code;
  final String name;

  Currency(this.code, this.name);
}
