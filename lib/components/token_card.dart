import 'package:zilpay/components/jazzicon.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/image_cache.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import 'package:zilpay/mixins/amount.dart';
import 'package:zilpay/mixins/preprocess_url.dart';
import 'package:zilpay/src/rust/models/ftoken.dart';
import 'package:zilpay/state/app_state.dart';

class TokenCard extends StatefulWidget {
  final FTokenInfo ftoken;
  final BigInt tokenAmount;
  final bool showDivider;
  final VoidCallback? onTap;
  final bool hideBalance;

  const TokenCard({
    super.key,
    required this.tokenAmount,
    required this.ftoken,
    this.showDivider = true,
    this.onTap,
    this.hideBalance = false,
  });

  @override
  State<TokenCard> createState() => _TokenCardState();
}

class _TokenCardState extends State<TokenCard>
    with SingleTickerProviderStateMixin {
  bool isHovered = false;
  bool isPressed = false;

  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _animation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildIcon(AppState state) {
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
      width: 32,
      height: 32,
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
          width: 32,
          height: 32,
          fit: BoxFit.contain,
          errorWidget: Jazzicon(
            seed: widget.ftoken.addr,
            diameter: 32,
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

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MouseRegion(
            onEnter: (_) => setState(() => isHovered = true),
            onExit: (_) => setState(() => isHovered = false),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (_) {
                setState(() => isPressed = true);
                _controller.forward();
              },
              onTapUp: (_) {
                setState(() => isPressed = false);
                _controller.reverse();
              },
              onTapCancel: () {
                setState(() => isPressed = false);
                _controller.reverse();
              },
              onTap: widget.onTap,
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) =>
                    Transform.scale(scale: _animation.value, child: child),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
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
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  return Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          widget.ftoken.name,
                                          style: theme.bodyText1.copyWith(
                                            color: theme.textPrimary
                                                .withValues(alpha: 0.7),
                                            fontWeight: FontWeight.w500,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '(${widget.ftoken.symbol})',
                                        style: theme.caption.copyWith(
                                          color: theme.textSecondary
                                              .withValues(alpha: 0.5),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      displayAmount,
                                      style: theme.subtitle1.copyWith(
                                        color: theme.textPrimary,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.5,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              if (appState.wallet?.settings.currencyConvert !=
                                  null)
                                Text(
                                  displayConverted,
                                  style: theme.bodyText2
                                      .copyWith(color: theme.textSecondary),
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
                          child: _buildIcon(Provider.of<AppState>(context)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (widget.showDivider)
            Container(
                height: 1, color: theme.textPrimary.withValues(alpha: 0.1)),
        ],
      ),
    );
  }
}
