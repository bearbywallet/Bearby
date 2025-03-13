import 'package:blockies/blockies.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/image_cache.dart';
import 'package:zilpay/mixins/amount.dart';
import 'package:zilpay/mixins/preprocess_url.dart';
import 'package:zilpay/src/rust/models/ftoken.dart';
import 'package:zilpay/state/app_state.dart';

class TokenSelectItem extends StatelessWidget {
  final FTokenInfo ftoken;
  final BigInt balance;
  final VoidCallback onTap;
  final double iconSize;

  const TokenSelectItem({
    super.key,
    required this.ftoken,
    required this.balance,
    required this.onTap,
    this.iconSize = 40.0,
  });

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = appState.currentTheme;
    final (amount, converted) = formatingAmount(
      amount: balance,
      symbol: ftoken.symbol,
      decimals: ftoken.decimals,
      rate: ftoken.rate,
      appState: appState,
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(iconSize / 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(iconSize / 2),
                child: AsyncImage(
                  url: processTokenLogo(
                    token: ftoken,
                    shortName: appState.chain?.shortName ?? "",
                    theme: theme.value,
                  ),
                  width: iconSize,
                  height: iconSize,
                  fit: BoxFit.contain,
                  errorWidget: Blockies(
                    seed: ftoken.addr,
                    color: theme.secondaryPurple,
                    bgColor: theme.primaryPurple,
                    spotColor: theme.background,
                    size: 8,
                  ),
                  loadingWidget: const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ftoken.symbol,
                    style: TextStyle(
                      color: theme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ftoken.name,
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
                  amount,
                  style: TextStyle(
                    color: theme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  converted,
                  style: TextStyle(
                    color: theme.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
