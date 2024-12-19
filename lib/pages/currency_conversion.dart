import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/src/rust/api/settings.dart';
import 'package:zilpay/state/app_state.dart';
import '../theme/app_theme.dart';
import '../components/custom_app_bar.dart';

class CurrencyConversionPage extends StatefulWidget {
  const CurrencyConversionPage({super.key});

  @override
  State<CurrencyConversionPage> createState() => _CurrencyConversionPageState();
}

class _CurrencyConversionPageState extends State<CurrencyConversionPage> {
  final List<Currency> currencies = [
    Currency('RUB', 'Russian Ruble'),
    Currency('EUR', 'Euro'),
    Currency('IDR', 'Indonesian Rupiah'),
    Currency('USD', 'United States Dollar'),
    Currency('UAH', 'Ukrainian hryvnia'),
    Currency('UZS', 'Uzbekistani sum'),
    Currency('INR', 'Indian Rupee'),
    Currency('GBP', 'Great Britain Pound'),
    Currency('AED', 'United Arab Emirates Dirham'),
    Currency('CNY', 'China Yuan'),
    Currency('BYN', 'Belarusian Ruble'),
    Currency('BRL', 'Brazilian Real'),
  ];

  String selectedCurrency = 'RUB';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = Provider.of<AppState>(context, listen: false);
      if (state.wallet?.currencyConvert != null) {
        setState(() {
          selectedCurrency = state.wallet!.currencyConvert!;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final theme = state.currentTheme;
    final bool isRateFetchEnabled = state.wallet!.currencyConvert != null;

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
                    title: 'Primary Currency',
                    onBackPressed: () => Navigator.pop(context),
                  ),
                ),
                _buildRateFetchOption(state),
                Expanded(
                  child: Opacity(
                    opacity: isRateFetchEnabled ? 1.0 : 0.5,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: AbsorbPointer(
                        absorbing: !isRateFetchEnabled,
                        child: ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          itemCount: currencies.length,
                          itemBuilder: (context, index) {
                            final currency = currencies[index];
                            final isSelected =
                                currency.code == selectedCurrency;

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

  Widget _buildRateFetchOption(AppState state) {
    final theme = state.currentTheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Enable rate fetcher',
                style: TextStyle(
                  color: theme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Switch(
                value: state.wallet!.currencyConvert != null,
                onChanged: (value) async {
                  await setRateFetcher(
                    walletIndex: BigInt.from(state.selectedWallet),
                    currency: value ? selectedCurrency : null,
                  );

                  await state.syncData();
                },
                activeColor: theme.primaryPurple,
                activeTrackColor: theme.primaryPurple.withOpacity(0.5),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'The wallet will fetch rates and makes request to ZilPay server',
            style: TextStyle(
              color: theme.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
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
              color: theme.textSecondary.withOpacity(0.1),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 60,
              child: Text(
                currency.code,
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
