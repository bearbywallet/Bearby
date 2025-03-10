import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/button_item.dart';
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

class _CurrencyConversionPageState extends State<CurrencyConversionPage> {
  late List<Currency> _currencies = [];
  String selectedCurrency = 'btc';
  int selectedEngine = 0;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final state = Provider.of<AppState>(context, listen: false);
      final currenciesTickets = await getCurrenciesTickets();

      setState(() {
        _currencies = currenciesTickets
            .map((pair) =>
                Currency(pair.$1, "${_getCurrencyName(pair.$1)} ${pair.$2}"))
            .toList();
      });

      if (state.wallet?.settings.currencyConvert != null) {
        setState(() {
          selectedCurrency = state.wallet!.settings.currencyConvert!;
        });
      }

      setState(() {
        selectedEngine = state.wallet?.settings.ratesApiOptions ?? 0;
      });
    });
  }

  String _getCurrencyName(String symbol) {
    final Map<String, String> currencyNames = {
      "BTC": "Bitcoin",
      "BRL": "Brazilian Real",
      "RUB": "Russian Ruble",
      "INR": "Indian Rupee",
      "CNY": "Chinese Yuan",
      "ZAR": "South African Rand",
      "EGP": "Egyptian Pound",
      "ETB": "Ethiopian Birr",
      "IRR": "Iranian Rial",
      "SAR": "Saudi Riyal",
      "AED": "United Arab Emirates Dirham",
      "USD": "United States Dollar",
      "EUR": "Euro",
      "JPY": "Japanese Yen",
      "GBP": "British Pound",
      "KRW": "South Korean Won",
      "CHF": "Swiss Franc",
      "AUD": "Australian Dollar",
      "CAD": "Canadian Dollar",
      "MXN": "Mexican Peso",
      "ETH": "Ethereum",
      "LTC": "Litecoin",
      "XRP": "Ripple",
      "BCH": "Bitcoin Cash",
      "ADA": "Cardano",
      "DOT": "Polkadot",
      "SOL": "Solana",
      "USDT": "Tether",
      "DOGE": "Dogecoin",
      "GOLD": "Gold",
      "SILVER": "Silver"
    };

    return currencyNames[symbol] ?? symbol;
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final theme = state.currentTheme;
    final bool isRateFetchEnabled =
        state.wallet!.settings.currencyConvert != null;

    return Scaffold(
      backgroundColor: theme.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                CustomAppBar(
                  title: 'Primary Currency',
                  onBackPressed: () => Navigator.pop(context),
                ),
                _buildEngineInfo(theme, state),
                Expanded(
                  child: Opacity(
                    opacity: isRateFetchEnabled ? 1.0 : 0.5,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: AbsorbPointer(
                        absorbing: !isRateFetchEnabled,
                        child: ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          itemCount: _currencies.length,
                          itemBuilder: (context, index) {
                            final currency = _currencies[index];
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
                                  walletIndex:
                                      BigInt.from(state.selectedWallet),
                                  currency: selectedCurrency,
                                );

                                await state.syncData();
                              },
                            );
                          },
                        ),
                      ),
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

  Widget _buildEngineInfo(AppTheme theme, AppState appState) {
    final engineText = selectedEngine == 0 ? 'None' : 'Coingecko';

    return ButtonItem(
      theme: theme,
      title: 'Currency Engine',
      iconPath: 'assets/icons/currency.svg',
      description: 'Engine for fetching currency rates',
      subtitleText: engineText,
      onTap: () {
        _showEngineSelector(appState);
      },
    );
  }

  void _showEngineSelector(AppState appState) {
    final engines = [
      ListItem(title: 'None', subtitle: 'No engine selected'),
      ListItem(title: 'Coingecko', subtitle: 'Fetch rates from Coingecko'),
    ];

    showListSelectorModal(
      context: context,
      title: 'Select Currency Engine',
      items: engines,
      selectedIndex: selectedEngine,
      onItemSelected: (index) async {
        setState(() {
          selectedEngine = index;
        });

        // await setCurrencyEngine(
        //   walletIndex: BigInt.from(appState.selectedWallet),
        //   engine: index,
        // );

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
              width: 60,
              child: Text(
                currency.code.toUpperCase(),
                style: TextStyle(
                  color: theme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: Text(
                currency.name,
                style: TextStyle(
                  color: theme.textSecondary,
                  fontSize: 16,
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
