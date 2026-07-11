import 'package:bearby/components/token_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:bearby/mixins/amount.dart';
import 'package:bearby/src/rust/models/ftoken.dart';
import 'package:bearby/state/app_state.dart';

class TokenSelectItem extends StatelessWidget {
  final FTokenInfo ftoken;
  final BigInt balance;
  final VoidCallback onTap;
  final double iconSize;

  /// Optional small chain icon overlaid on the bottom-right of the token avatar.
  final Widget? networkBadge;

  /// Optional SVG asset paths for exchange providers, rendered next to the symbol.
  final List<String> providerIcons;

  const TokenSelectItem({
    super.key,
    required this.ftoken,
    required this.balance,
    required this.onTap,
    this.iconSize = 40.0,
    this.networkBadge,
    this.providerIcons = const [],
  });

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final theme = appState.currentTheme;
    final badge = networkBadge;
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
            SizedBox(
              width: iconSize,
              height: iconSize,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  TokenAvatar(
                    token: ftoken,
                    size: iconSize,
                    appState: appState,
                    showNetworkBadge: false,
                    showBorder: false,
                    fit: BoxFit.contain,
                  ),
                  if (badge != null)
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: badge,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          ftoken.symbol,
                          style: theme.bodyText1.copyWith(
                            color: theme.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      for (final icon in providerIcons) ...[
                        const SizedBox(width: 6),
                        SvgPicture.asset(
                          icon,
                          width: 16,
                          height: 16,
                          fit: BoxFit.contain,
                        ),
                      ],
                    ],
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
