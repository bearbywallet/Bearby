import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';

class CryptoList extends StatelessWidget {
  final List<CryptoListItem> items;

  const CryptoList({Key? key, required this.items}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (context, index) => Divider(
          color: theme.textSecondary.withOpacity(0.2),
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
    Key? key,
    required this.name,
    required this.balance,
    required this.balanceInUsd,
    required this.icons,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;

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
                  style: TextStyle(
                    color: theme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  balanceInUsd,
                  style: TextStyle(
                    color: theme.textSecondary,
                    fontSize: 14,
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
                style: TextStyle(
                  color: theme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 4),
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
