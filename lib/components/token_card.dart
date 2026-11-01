import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bearby/components/shimmer_text.dart';
import 'package:bearby/components/token_avatar.dart';
import 'package:bearby/mixins/adaptive_size.dart';
import 'package:bearby/mixins/amount.dart';
import 'package:bearby/mixins/pressable_animation.dart';
import 'package:bearby/src/rust/models/ftoken.dart';
import 'package:bearby/state/app_state.dart';
import 'package:bearby/theme/app_theme.dart';

class TokenCard extends StatefulWidget {
  final FTokenInfo ftoken;
  final BigInt tokenAmount;
  final bool showDivider;
  final VoidCallback? onTap;
  final bool hideBalance;
  final bool isTileView;
  final bool isAmountLoading;
  final bool isRateLoading;

  const TokenCard({
    super.key,
    required this.tokenAmount,
    required this.ftoken,
    this.showDivider = true,
    this.onTap,
    this.hideBalance = false,
    this.isTileView = false,
    this.isAmountLoading = false,
    this.isRateLoading = false,
  });

  @override
  State<TokenCard> createState() => _TokenCardState();
}

class _TokenCardState extends State<TokenCard>
    with SingleTickerProviderStateMixin, PressableAnimationMixin {
  static const List<Color> _fallbackPalette = [
    Color(0xFF7C5CFF),
    Color(0xFF00D1B2),
    Color(0xFFFF8A4C),
    Color(0xFF3B82F6),
    Color(0xFFEC4899),
    Color(0xFF10B981),
  ];

  @override
  void initState() {
    super.initState();
    initPressAnimation(
      duration: const Duration(milliseconds: 130),
      scaleEnd: 0.97,
    );
  }

  @override
  void dispose() {
    disposePressAnimation();
    super.dispose();
  }

  Color _resolveAccentColor(AppTheme theme) {
    final sym = widget.ftoken.symbol.toUpperCase().trim();
    Color base;
    switch (sym) {
      case 'BTC':
      case 'WBTC':
        base = const Color(0xFFF7931A);
        break;
      case 'ETH':
      case 'WETH':
        base = const Color(0xFF627EEA);
        break;
      case 'ZIL':
      case 'WZIL':
      case 'STZIL':
        base = const Color(0xFF29CCC4);
        break;
      case 'USDT':
        base = const Color(0xFF26A17B);
        break;
      case 'USDC':
        base = const Color(0xFF2775CA);
        break;
      case 'BNB':
        base = const Color(0xFFF3BA2F);
        break;
      case 'TRX':
        base = const Color(0xFFFF2E4C);
        break;
      case 'XAUT':
        base = const Color(0xFFD4AF37);
        break;
      case 'MATIC':
      case 'POL':
        base = const Color(0xFF8247E5);
        break;
      default:
        final hash = sym.codeUnits.fold<int>(0, (acc, c) => acc * 31 + c);
        base = _fallbackPalette[hash.abs() % _fallbackPalette.length];
    }
    return Color.lerp(base, theme.primaryPurple, 0.25) ?? theme.primaryPurple;
  }

  String? _resolveUnitPrice(AppState appState) {
    if (appState.wallet?.settings.currencyConvert == null ||
        widget.ftoken.rate <= 0) {
      return null;
    }
    final safeDecimals = widget.ftoken.decimals.clamp(0, 30);
    final oneToken = BigInt.from(10).pow(safeDecimals);
    final (_, unitConverted) = formatingAmount(
      amount: oneToken,
      symbol: '',
      decimals: safeDecimals,
      rate: widget.ftoken.rate,
      appState: appState,
      compact: true,
    );
    if (unitConverted == '0' || unitConverted == '—') return null;
    return unitConverted;
  }

  Widget _buildIcon(AppState state, double iconSize, Color accent) {
    return TokenAvatar(
      token: widget.ftoken,
      size: iconSize,
      appState: state,
      showNetworkBadge: false,
      borderColor: accent.withValues(alpha: 0.22),
      borderWidth: 1.5,
      fit: BoxFit.contain,
    );
  }

  Widget _buildAvatarPedestal(
    AppState state,
    Color accent, {
    required double avatarSize,
    required double boxSize,
    required double radius,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: boxSize,
      height: boxSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: RadialGradient(
          colors: [
            accent.withValues(alpha: isHovered ? 0.28 : 0.18),
            accent.withValues(alpha: 0.04),
          ],
          radius: 0.85,
        ),
        border: Border.all(
          color: accent.withValues(alpha: isHovered ? 0.45 : 0.22),
          width: 1,
        ),
      ),
      alignment: Alignment.center,
      child: _buildIcon(state, avatarSize, accent),
    );
  }

  String maskBalance() {
    return "••••••";
  }

  Widget _amountText(
    AppTheme theme,
    String value,
    TextStyle style, {
    required bool loading,
    required bool useSecondaryColor,
  }) {
    if (!loading) {
      return Text(
        value,
        style: style,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      );
    }

    final Color textColor =
        useSecondaryColor ? theme.textSecondary : theme.textPrimary;

    return ShimmerText(
      text: value,
      style: style,
      baseColor: textColor.withValues(alpha: 0.35),
      highlightColor: textColor,
    );
  }

  Widget _buildTileLayout(
    AppState appState,
    String displayAmount,
    String displayConverted,
  ) {
    final theme = appState.currentTheme;
    final accent = _resolveAccentColor(theme);
    final hasCurrency = appState.wallet?.settings.currencyConvert != null;
    final hasBalance = widget.tokenAmount > BigInt.zero;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(
                theme.cardBackground,
                accent,
                isHovered ? 0.16 : 0.08,
              )!,
              theme.cardBackground,
            ],
          ),
          border: Border.all(
            color: isHovered
                ? accent.withValues(alpha: 0.52)
                : theme.textPrimary.withValues(alpha: 0.08),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isHovered ? 0.16 : 0.07),
              blurRadius: isHovered ? 14 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: -30,
              right: -26,
              child: IgnorePointer(
                child: Container(
                  width: 105,
                  height: 105,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        accent.withValues(alpha: isHovered ? 0.24 : 0.14),
                        accent.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -26,
              right: -18,
              child: IgnorePointer(
                child: Container(
                  width: 78,
                  height: 78,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: accent.withValues(alpha: 0.06),
                      width: 9,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildAvatarPedestal(
                        appState,
                        accent,
                        avatarSize: 28,
                        boxSize: 38,
                        radius: 12,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          widget.ftoken.symbol,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.bodyText2.copyWith(
                            color: theme.textPrimary.withValues(alpha: 0.85),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    widget.ftoken.name,
                    style: theme.caption.copyWith(
                      color: theme.textSecondary.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 3),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: _amountText(
                      theme,
                      displayAmount,
                      theme.bodyText1.copyWith(
                        color: theme.textPrimary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                      loading: widget.isAmountLoading,
                      useSecondaryColor: false,
                    ),
                  ),
                  if (hasCurrency) ...[
                    const SizedBox(height: 3),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: _amountText(
                        theme,
                        displayConverted,
                        theme.caption.copyWith(
                          color: hasBalance
                              ? theme.textPrimary.withValues(alpha: 0.88)
                              : theme.textSecondary.withValues(alpha: 0.72),
                          fontWeight: FontWeight.w600,
                        ),
                        loading: widget.isRateLoading,
                        useSecondaryColor: true,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListLayout(
    AppState appState,
    String displayAmount,
    String displayConverted,
  ) {
    final theme = appState.currentTheme;
    final accent = _resolveAccentColor(theme);
    final hasCurrency = appState.wallet?.settings.currencyConvert != null;
    final unitPrice = _resolveUnitPrice(appState);
    final hasBalance = widget.tokenAmount > BigInt.zero;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color.lerp(
              theme.cardBackground,
              accent,
              isHovered ? 0.13 : 0.05,
            )!,
            theme.cardBackground,
          ],
        ),
        border: Border.all(
          color: isHovered
              ? accent.withValues(alpha: 0.48)
              : theme.textPrimary.withValues(alpha: 0.07),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isHovered ? 0.14 : 0.05),
            blurRadius: isHovered ? 12 : 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildAvatarPedestal(
            appState,
            accent,
            avatarSize: 32,
            boxSize: 44,
            radius: 14,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        widget.ftoken.name,
                        style: theme.bodyText1.copyWith(
                          color: theme.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.ftoken.symbol,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.caption.copyWith(
                        color: accent.withValues(alpha: 0.95),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  unitPrice != null
                      ? '1 ${widget.ftoken.symbol} ≈ $unitPrice'
                      : (widget.ftoken.native
                          ? '${widget.ftoken.symbol} • Native'
                          : widget.ftoken.symbol),
                  style: theme.caption.copyWith(
                    color: theme.textSecondary.withValues(alpha: 0.78),
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 185),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: _amountText(
                    theme,
                    displayAmount,
                    theme.bodyText1.copyWith(
                      color: theme.textPrimary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                    loading: widget.isAmountLoading,
                    useSecondaryColor: false,
                  ),
                ),
              ),
              if (hasCurrency) ...[
                const SizedBox(height: 4),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 185),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: _amountText(
                      theme,
                      displayConverted,
                      theme.caption.copyWith(
                        color: hasBalance
                            ? theme.textPrimary.withValues(alpha: 0.88)
                            : theme.textSecondary.withValues(alpha: 0.72),
                        fontWeight: FontWeight.w600,
                      ),
                      loading: widget.isRateLoading,
                      useSecondaryColor: true,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);
    final (rawAmount, converted) = formatingAmount(
      amount: widget.tokenAmount,
      symbol: '',
      decimals: widget.ftoken.decimals,
      rate: widget.ftoken.rate,
      appState: appState,
    );
    final formattedAmount = '${rawAmount.trim()} ${widget.ftoken.symbol}';
    final displayAmount = widget.hideBalance ? maskBalance() : formattedAmount;
    final displayConverted = widget.hideBalance ? maskBalance() : converted;

    final Widget content = widget.isTileView
        ? _buildTileLayout(appState, displayAmount, displayConverted)
        : _buildListLayout(appState, displayAmount, displayConverted);

    final Widget gestureWidget = buildPressable(
      onTap: widget.onTap,
      enableHover: true,
      child: content,
    );

    if (widget.isTileView) {
      return gestureWidget;
    }

    return Padding(
      padding: EdgeInsets.only(
        left: adaptivePadding,
        right: adaptivePadding,
        bottom: widget.showDivider ? 10 : 4,
      ),
      child: gestureWidget,
    );
  }
}
