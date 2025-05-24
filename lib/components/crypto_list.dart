import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/state/app_state.dart';

class CryptoList extends StatelessWidget {
  final List<CryptoListItem> items;

  const CryptoList({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<AppState>(context).currentTheme;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (context, index) => Divider(
          color: theme.textSecondary.withValues(alpha: 0.2),
          height: 1,
        ),
        itemBuilder: (context, index) {
          return items[index];
        },
      ),
    );
  }
}

class CryptoListItem extends StatelessWidget {
  final String name;
  final String balance;
  final String balanceInUsd;
  final List<Widget> icons;

  const CryptoListItem({
    super.key,
    required this.name,
    required this.balance,
    required this.balanceInUsd,
    required this.icons,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<AppState>(context).currentTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.bodyText1.copyWith(
                    color: theme.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  balanceInUsd,
                  style: theme.bodyText2.copyWith(
                    color: theme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                balance,
                style: theme.bodyText1.copyWith(
                  color: theme.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: icons,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
