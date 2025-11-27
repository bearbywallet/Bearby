import 'package:zilpay/components/jazzicon.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/image_cache.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import 'package:zilpay/mixins/amount.dart';
import 'package:zilpay/mixins/pressable_animation.dart';
import 'package:zilpay/mixins/preprocess_url.dart';
import 'package:zilpay/src/rust/models/ftoken.dart';
import 'package:zilpay/state/app_state.dart';

class TokenCard extends StatefulWidget {
  final FTokenInfo ftoken;
  final BigInt tokenAmount;
  final bool showDivider;
  final VoidCallback? onTap;
  final bool hideBalance;
  final bool isTileView;

  const TokenCard({
    super.key,
    required this.tokenAmount,
    required this.ftoken,
    this.showDivider = true,
    this.onTap,
    this.hideBalance = false,
    this.isTileView = false,
  });

  @override
  State<TokenCard> createState() => _TokenCardState();
}

class _TokenCardState extends State<TokenCard>
    with SingleTickerProviderStateMixin, PressableAnimationMixin {
  @override
  void initState() {
    super.initState();
    initPressAnimation();
  }

  @override
  void dispose() {
    disposePressAnimation();
    super.dispose();
  }

  Widget _buildIcon(AppState state, double iconSize) {
    final theme = state.currentTheme;
    FTokenInfo token = FTokenInfo(
      name: widget.ftoken.name,
      symbol: widget.ftoken.symbol,
      decimals: widget.ftoken.decimals,
      addr: widget.ftoken.addr,
      addrType: widget.ftoken.addrType,
      balances: {},
      rate: 0,
      default_: widget.ftoken.default_,
      native: widget.ftoken.native,
      chainHash: widget.ftoken.chainHash,
      logo: widget.ftoken.logo ?? state.wallet?.tokens.first.logo,
    );

    return Container(
      width: iconSize,
      height: iconSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
            color: theme.primaryPurple.withValues(alpha: 0.1), width: 2),
      ),
      child: ClipOval(
        child: AsyncImage(
          url: processTokenLogo(
            token: token,
            shortName: state.chain?.shortName ?? '',
            theme: theme.value,
          ),
          width: iconSize,
          height: iconSize,
          fit: BoxFit.contain,
          errorWidget: Jazzicon(
            seed: widget.ftoken.addr,
            diameter: iconSize,
          ),
          loadingWidget:
              const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      ),
    );
  }

  String maskBalance() {
    return "*******";
  }

  Widget _buildTileLayout(AppState appState, String displayAmount, String displayConverted) {
    final theme = appState.currentTheme;
    final iconSize = AdaptiveSize.getAdaptiveIconSize(context, 28);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.max,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  widget.ftoken.name,
                  style: theme.bodyText2.copyWith(
                    color: theme.textPrimary.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 8),
              _buildIcon(appState, iconSize),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  displayAmount,
                  style: theme.subtitle1.copyWith(
                    color: theme.textPrimary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                ),
              ),
              const SizedBox(height: 2),
              if (appState.wallet?.settings.currencyConvert != null)
                Text(
                  displayConverted,
                  style: theme.caption.copyWith(color: theme.textSecondary),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildListLayout(AppState appState, String displayAmount, String displayConverted, double adaptivePadding) {
    final theme = appState.currentTheme;
    final iconSize = AdaptiveSize.getAdaptiveIconSize(context, 32);

    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: adaptivePadding, vertical: adaptivePadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${widget.ftoken.name} (${widget.ftoken.symbol})',
                  style: theme.bodyText1.copyWith(
                    color: theme.textPrimary.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 8),
                Text(
                  displayAmount,
                  style: theme.subtitle1.copyWith(
                    color: theme.textPrimary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 4),
                if (appState.wallet?.settings.currencyConvert != null)
                  Text(
                    displayConverted,
                    style: theme.bodyText2.copyWith(color: theme.textSecondary),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: theme.textPrimary.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: _buildIcon(appState, iconSize),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = appState.currentTheme;
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);
    final (amount, converted) = formatingAmount(
      amount: widget.tokenAmount,
      symbol: widget.ftoken.symbol,
      decimals: widget.ftoken.decimals,
      rate: widget.ftoken.rate,
      appState: appState,
    );
    final displayAmount = widget.hideBalance ? maskBalance() : amount;
    final displayConverted = widget.hideBalance ? maskBalance() : converted;

    Widget content = widget.isTileView
        ? _buildTileLayout(appState, displayAmount, displayConverted)
        : _buildListLayout(appState, displayAmount, displayConverted, adaptivePadding);

    Widget gestureWidget = buildPressable(
      onTap: widget.onTap,
      enableHover: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
        ),
        child: content,
      ),
    );

    if (widget.isTileView) {
      return gestureWidget;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        gestureWidget,
        if (widget.showDivider)
          Container(
              height: 1, color: theme.textPrimary.withValues(alpha: 0.1)),
      ],
    );
  }
}
