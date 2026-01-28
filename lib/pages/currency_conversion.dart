import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/button_item.dart';
import 'package:zilpay/components/smart_input.dart';
import 'package:zilpay/l10n/app_localizations.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import 'package:zilpay/mixins/status_bar.dart';
import 'package:zilpay/src/rust/api/settings.dart';
import 'package:zilpay/src/rust/api/utils.dart';
import 'package:zilpay/state/app_state.dart';
import 'package:zilpay/modals/list_selector.dart';
import '../theme/app_theme.dart';
import '../components/custom_app_bar.dart';

class CurrencyConversionPage extends StatefulWidget {
  const CurrencyConversionPage({super.key});

  @override
  State<CurrencyConversionPage> createState() => _CurrencyConversionPageState();
}

class _CurrencyConversionPageState extends State<CurrencyConversionPage>
    with StatusBarMixin {
  late List<Currency> _currencies = [];
  late List<Currency> _filteredCurrencies = [];
  final TextEditingController _searchController = TextEditingController();
  String selectedCurrency = 'btc';
  int selectedEngine = 0;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final state = Provider.of<AppState>(context, listen: false);
      final currenciesTickets = await getCurrenciesTickets();
      final availableCodes = currenciesTickets.map((p) => p.$1).toSet();

      final orderedList = _getOrderedCurrencies()
          .where((c) => availableCodes.contains(c.code))
          .toList();

      final codeToRate = {
        for (final pair in currenciesTickets) pair.$1: pair.$2
      };

      final currenciesList = orderedList.map((c) {
        final rate = codeToRate[c.code] ?? '';
        return Currency(c.code, "${c.name} $rate");
      }).toList();

      setState(() {
        _currencies = currenciesList;
        _filteredCurrencies = currenciesList;
      });

      if (state.wallet?.settings.currencyConvert != null) {
        setState(() {
          selectedCurrency = state.wallet!.settings.currencyConvert;
        });
      }

      setState(() {
        selectedEngine = state.wallet?.settings.ratesApiOptions ?? 0;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterCurrencies(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCurrencies = _currencies;
      } else {
        _filteredCurrencies = _currencies.where((currency) {
          return currency.name.toLowerCase().contains(query.toLowerCase()) ||
              currency.code.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

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
    "DOGE": "Dogecoin",
    "GOLD": "Gold",
    "SILVER": "Silver"
  };

  List<Currency> _getOrderedCurrencies() =>
      _currencyNames.entries.map((e) => Currency(e.key, e.value)).toList();

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final theme = appState.currentTheme;
    final bool isRateFetchEnabled =
        appState.wallet!.settings.ratesApiOptions != 0;
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);

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
                  padding: EdgeInsets.symmetric(horizontal: adaptivePadding),
                  child: CustomAppBar(
                    title:
                        AppLocalizations.of(context)!.currencyConversionTitle,
                    onBackPressed: () => Navigator.pop(context),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: adaptivePadding),
                    child: Column(
                      children: [
                        _buildEngineBlock(theme, appState),
                        const SizedBox(height: 16),
                        _buildCurrenciesBlock(
                            theme, appState, isRateFetchEnabled),
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

  Widget _buildEngineBlock(AppTheme theme, AppState appState) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: _buildEngineInfo(theme, appState),
    );
  }

  Widget _buildCurrenciesBlock(
      AppTheme theme, AppState appState, bool isRateFetchEnabled) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardBackground,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Opacity(
          opacity: isRateFetchEnabled ? 1.0 : 0.5,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: AbsorbPointer(
              absorbing: !isRateFetchEnabled,
              child: Column(
                children: [
                  SmartInput(
                    controller: _searchController,
                    hint: AppLocalizations.of(context)!
                        .currencyConversionSearchHint,
                    leftIconPath: 'assets/icons/search.svg',
                    rightIconPath: "assets/icons/close.svg",
                    onChanged: (value) {
                      _filterCurrencies(value);
                    },
                    onRightIconTap: () {
                      _searchController.text = "";
                      _filterCurrencies("");
                    },
                    onSubmitted: (value) {},
                    borderColor: theme.textPrimary,
                    focusedBorderColor: theme.primaryPurple,
                    height: 48,
                    fontSize: 16,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    autofocus: false,
                    keyboardType: TextInputType.text,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: _filteredCurrencies.length,
                      itemBuilder: (context, index) {
                        final currency = _filteredCurrencies[index];
                        final isSelected = currency.code.toLowerCase() ==
                            selectedCurrency.toLowerCase();

                        return _buildCurrencyItem(
                          theme,
                          currency,
                          isSelected,
                          onTap: () async {
                            setState(() {
                              selectedCurrency = currency.code;
                            });

                            await setRateFetcher(
                              walletIndex: BigInt.from(appState.selectedWallet),
                              currency: selectedCurrency,
                            );

                            await appState.syncRates(force: true);
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
      ),
    );
  }

  Widget _buildEngineInfo(AppTheme theme, AppState appState) {
    return ButtonItem(
      theme: theme,
      title: AppLocalizations.of(context)!.currencyConversionEngineTitle,
      iconPath: 'assets/icons/currency.svg',
      description:
          AppLocalizations.of(context)!.currencyConversionEngineDescription,
      subtitleText: _getEngineName(selectedEngine),
      onTap: () {
        _showEngineSelector(appState);
      },
    );
  }

  String _getEngineName(int engineIndex) {
    final l10n = AppLocalizations.of(context)!;
    switch (engineIndex) {
      case 0:
        return l10n.currencyConversionEngineNone;
      case 1:
        return l10n.currencyConversionEngineCryptoCompare;
      case 2:
        return l10n.currencyConversionEngineCoingecko;
      default:
        return l10n.currencyConversionEngineNone;
    }
  }

  List<ListItem> _getEnginesList() {
    final l10n = AppLocalizations.of(context)!;
    return [
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
    ];
  }

  void _showEngineSelector(AppState appState) {
    showListSelectorModal(
      context: context,
      title:
          AppLocalizations.of(context)!.currencyConversionEngineSelectorTitle,
      items: _getEnginesList(),
      selectedIndex: selectedEngine,
      onItemSelected: (index) async {
        setState(() {
          selectedEngine = index;
        });

        await setRateEngine(
          walletIndex: BigInt.from(appState.selectedWallet),
          engineCode: index,
        );

        await appState.syncData();
      },
    );
  }

  Widget _buildCurrencyItem(
    AppTheme theme,
    Currency currency,
    bool isSelected, {
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: theme.textSecondary.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 80,
              child: Text(
                currency.code.toUpperCase(),
                style: theme.labelLarge.copyWith(
                  color: theme.textPrimary,
                ),
              ),
            ),
            Expanded(
              child: Text(
                currency.name,
                style: theme.bodyLarge.copyWith(
                  color: theme.textSecondary,
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
      ),
    );
  }
}

class Currency {
  final String code;
  final String name;

  Currency(this.code, this.name);
}
