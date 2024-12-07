import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';
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
  bool isRateFetchEnabled = false;

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;

    return Scaffold(
      backgroundColor: theme.background,
      body: SafeArea(
        child: Column(
          children: [
            CustomAppBar(
              title: 'Primary Currency',
              onBackPressed: () => Navigator.pop(context),
            ),
            _buildRateFetchOption(theme),
            Expanded(
              child: Opacity(
                opacity: isRateFetchEnabled ? 1.0 : 0.5,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: AbsorbPointer(
                    absorbing: !isRateFetchEnabled,
                    child: ListView.builder(
                      itemCount: currencies.length,
                      itemBuilder: (context, index) {
                        final currency = currencies[index];
                        final isSelected = currency.code == selectedCurrency;

                        return _buildCurrencyItem(
                          theme,
                          currency,
                          isSelected,
                          onTap: () {
                            setState(() {
                              selectedCurrency = currency.code;
                            });
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
    );
  }

  Widget _buildRateFetchOption(AppTheme theme) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(16),
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
                value: isRateFetchEnabled,
                onChanged: (value) {
                  setState(() {
                    isRateFetchEnabled = value;
                  });
                },
                activeColor: theme.primaryPurple,
                activeTrackColor: theme.primaryPurple.withOpacity(0.5),
              ),
            ],
          ),
          SizedBox(height: 8),
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
