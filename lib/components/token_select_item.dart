import 'package:bearby/components/jazzicon.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bearby/components/image_cache.dart';
import 'package:bearby/mixins/amount.dart';
import 'package:bearby/mixins/preprocess_url.dart';
import 'package:bearby/src/rust/models/ftoken.dart';
import 'package:bearby/state/app_state.dart';

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
    final appState = Provider.of<AppState>(context, listen: false);
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
                  errorWidget: Jazzicon(
                    seed: ftoken.addr,
                    diameter: iconSize,
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
                    style: theme.bodyText1.copyWith(
                      color: theme.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ftoken.name,
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
                  amount,
                  style: theme.bodyText1.copyWith(
                    color: theme.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  converted,
                  style: theme.bodyText2.copyWith(
                    color: theme.textSecondary,
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
