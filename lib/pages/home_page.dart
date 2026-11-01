// ignore_for_file: constant_identifier_names

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bearby/components/glass_message.dart';
import 'package:bearby/components/hover_icon.dart';
import 'package:bearby/components/app_icon.dart';
import 'package:bearby/components/linear_refresh_indicator.dart';
import 'package:bearby/components/net_btn.dart';
import 'package:bearby/components/token_card.dart';
import 'package:bearby/components/wallet_header.dart';
import 'package:bearby/config/web3_constants.dart';
import 'package:bearby/mixins/adaptive_size.dart';
import 'package:bearby/mixins/pressable_animation.dart';
import 'package:bearby/mixins/qrcode.dart';
import 'package:bearby/mixins/status_bar.dart';
import 'package:bearby/mixins/wallet_type.dart';
import 'package:bearby/src/rust/api/wallet.dart';
import 'package:bearby/src/rust/api/utils.dart';
import 'package:bearby/state/app_state.dart';
import 'package:bearby/theme/app_theme.dart';
import 'package:bearby/l10n/app_localizations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:bearby/modals/qr_scanner_modal.dart';
import 'package:bearby/router.dart';

const double _ICON_SIZE_SMALL_BASE = 20.0;
const double _ICON_SIZE_TILE_BUTTON_BASE = 22.0;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with StatusBarMixin {
  String? _errorMessage;
  bool _isRefreshing = false;
  bool _hasInitialSync = false;
  bool _isHandlingScan = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_hasInitialSync) {
      _hasInitialSync = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final appState = Provider.of<AppState>(context, listen: false);
        _refreshData(appState);
      });
    }
  }

  bool _hasZilliqaExtras(AppState appState) =>
      appState.account != null && appState.chain?.slip44 == kZilliqaSlip44;

  Future<void> _refreshData(AppState appState) async {
    if (_isRefreshing) return;

    _isRefreshing = true;

    try {
      await appState.refreshBalancesAndRates(
        walletIndex: appState.selectedWalletIndex,
      );

      if (_errorMessage != null && mounted) {
        setState(() => _errorMessage = null);
      }
    } catch (e) {
      debugPrint("refresh: $e");
      if (mounted) {
        setState(() => _errorMessage = e.toString());
      }
    } finally {
      _isRefreshing = false;
    }
  }

  void _goToSendPage({String? recipient, String? amount, String? tokenAddress}) {
    final appState = Provider.of<AppState>(context, listen: false);
    final wallet = appState.wallet;
    if (wallet == null) return;

    final filteredTokens = wallet.tokens
        .where((t) => t.addrType == appState.account?.addrType)
        .toList();
    if (filteredTokens.isEmpty) return;

    final originalIndex = wallet.tokens.indexOf(filteredTokens.first);

    final Map<String, Object> extra = <String, Object>{
      'token_index': originalIndex,
    };
    if (recipient != null) extra['recipient'] = recipient;
    if (amount != null) extra['amount'] = amount;
    if (tokenAddress != null) extra['token_address'] = tokenAddress;

    context.push(AppRoutes.send, extra: extra);
  }

  void _showScanError() {
    final appState = Provider.of<AppState>(context, listen: false);
    final theme = appState.currentTheme;
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;

    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        backgroundColor: theme.cardBackground,
        title: Text(
          l10n.homePageQrScanErrorTitle,
          style: theme.titleMedium.copyWith(color: theme.textPrimary),
        ),
        content: Text(
          l10n.qrCodeUnrecognizedError,
          style: theme.bodyLarge.copyWith(color: theme.danger),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              l10n.homePageQrScanOkButton,
              style: theme.bodyLarge.copyWith(color: theme.primaryPurple),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleQrScanResult(String rawData) async {
    if (_isHandlingScan) return;

    final trimmed = rawData.trim();
    if (trimmed.isEmpty) return;

    _isHandlingScan = true;

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final activeChain = appState.chain;

      final parsed = parseCryptoUrl(trimmed);
      final String? qrChain = parsed['chain'];
      final String address = (parsed['address'] ?? trimmed);
      final String? amount = parsed['amount'];
      final String? tokenAddress = parsed['token'];

      final bool wrongChain = qrChain != null &&
          qrChain.isNotEmpty &&
          activeChain != null &&
          !chainMatches(activeChain, qrChain);

      if (wrongChain) {
        if (!mounted) return;
        _showScanError();
        return;
      }

      try {
        final ok = await isValidAddress(addr: address);
        if (!ok) {
          if (!mounted) return;
          _showScanError();
          return;
        }
      } catch (e) {
        debugPrint('address validation error: $e');
        if (!mounted) return;
        _showScanError();
        return;
      }

      if (!mounted) return;

      _goToSendPage(
        recipient: address,
        amount: amount,
        tokenAddress: tokenAddress,
      );
    } finally {
      _isHandlingScan = false;
    }
  }

  Future<void> _handleZilliqaSwap(AppState appState) async {
    final walletIndex = appState.selectedWalletIndex;
    await zilliqaSwapChain(
      walletIndex: walletIndex,
      accountIndex: appState.wallet!.selectedAccount,
    );
    await appState.syncData();
    try {
      await appState.syncBalancesTracked(
        walletIndex: walletIndex,
      );
      await appState.syncData();
    } catch (_) {}
  }

  Widget _buildTopSection({
    required BuildContext context,
    required AppState appState,
    required AppTheme theme,
    required AppLocalizations l10n,
    required double adaptivePadding,
    required double iconSizeTileButton,
    required bool isWideLayout,
  }) {
    final showZilSwitch = _hasZilliqaExtras(appState) &&
        !appState.wallet!.walletType.contains(WalletType.ledger.name);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        adaptivePadding,
        12,
        adaptivePadding,
        12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (appState.account != null)
            WalletHeader(
              account: appState.account!,
              showCopyAddress: false,
              onSettings: () {
                context.push(AppRoutes.settings);
              },
              onScan: () {
                showQRScannerModal(
                  context: context,
                  onScanned: _handleQrScanResult,
                );
              },
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _HomeActionCard(
                  icon: AppIconView(
                    icon: AppIcon.send,
                    size: iconSizeTileButton,
                    color: theme.primaryPurple,
                  ),
                  title: l10n.homePageSendButton,
                  accentColor: theme.primaryPurple,
                  isHorizontal: isWideLayout,
                  onPressed: () => _goToSendPage(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HomeActionCard(
                  icon: AppIconView(
                    icon: AppIcon.receive,
                    size: iconSizeTileButton,
                    color: theme.primaryPurple,
                  ),
                  title: l10n.homePageReceiveButton,
                  accentColor: theme.primaryPurple,
                  isHorizontal: isWideLayout,
                  onPressed: () => context.push(AppRoutes.receive),
                ),
              ),
              if (showZilSwitch) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: _HomeActionCard(
                    icon: SvgPicture.asset(
                      appState.account?.addrType == kScillaAddressType
                          ? 'assets/icons/scilla.svg'
                          : 'assets/icons/solidity.svg',
                      width: iconSizeTileButton,
                      height: iconSizeTileButton,
                      colorFilter: ColorFilter.mode(
                        theme.primaryPurple,
                        BlendMode.srcIn,
                      ),
                    ),
                    title: appState.account?.addrType == kScillaAddressType
                        ? "Scilla"
                        : "EVM",
                    accentColor: theme.primaryPurple,
                    isHorizontal: isWideLayout,
                    onPressed: () => _handleZilliqaSwap(appState),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlBar({
    required BuildContext context,
    required AppState appState,
    required AppTheme theme,
    required double adaptivePadding,
    required double iconSizeSmall,
  }) {
    final canSwitchView =
        appState.wallet != null && appState.wallet!.tokens.length > 1;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        adaptivePadding,
        2,
        adaptivePadding,
        12,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: NetworkDownButton(
              onPressed: () {
                context.push(
                  AppRoutes.networks,
                  extra: {'popOnSelect': true},
                );
              },
              chain: appState.chain!,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: theme.cardBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: theme.textPrimary.withValues(alpha: 0.08),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                HoverIcon(
                  icon: AppIconState.balanceVisibility(
                    hidden: appState.hideBalance,
                  ),
                  size: iconSizeSmall,
                  padding: const EdgeInsets.all(4),
                  color: appState.hideBalance
                      ? theme.primaryPurple
                      : theme.textSecondary.withValues(alpha: 0.72),
                  onTap: () {
                    appState.setHideBalance(!appState.hideBalance);
                  },
                ),
                const SizedBox(width: 6),
                HoverIcon(
                  icon: AppIcon.lockWallet,
                  size: iconSizeSmall,
                  padding: const EdgeInsets.all(4),
                  color: theme.textSecondary.withValues(alpha: 0.72),
                  onTap: () {
                    appState.clearAuthentication();
                  },
                ),
                if (canSwitchView) ...[
                  Container(
                    width: 1,
                    height: 16,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    color: theme.textPrimary.withValues(alpha: 0.08),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: theme.primaryPurple.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: HoverIcon(
                      icon: AppIconState.tokenLayout(
                        isTileView: appState.isTileView,
                      ),
                      size: iconSizeSmall,
                      padding: const EdgeInsets.all(4),
                      color: theme.primaryPurple,
                      onTap: () async {
                        await appState.updateIsTileView(!appState.isTileView);
                      },
                    ),
                  ),
                ],
                const SizedBox(width: 6),
                HoverIcon(
                  icon: AppIcon.manage,
                  size: iconSizeSmall,
                  padding: const EdgeInsets.all(4),
                  color: theme.textSecondary.withValues(alpha: 0.72),
                  onTap: () {
                    context.push(AppRoutes.manageTokens);
                  },
                ),
              ],
            ),
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
    final iconSizeSmall =
        AdaptiveSize.getAdaptiveIconSize(context, _ICON_SIZE_SMALL_BASE);
    final iconSizeTileButton =
        AdaptiveSize.getAdaptiveIconSize(context, _ICON_SIZE_TILE_BUTTON_BASE);
    final spacing = AdaptiveSize.getAdaptiveSize(context, 12);
    final isIOS = defaultTargetPlatform == TargetPlatform.iOS;
    final l10n = AppLocalizations.of(context)!;

    if (appState.wallet == null) return const SizedBox.shrink();

    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600 && screenWidth < 960;
    final isDesktop = screenWidth >= 960;
    final isWideLayout = screenWidth >= 600;
    final double maxWidth = isDesktop
        ? 920.0
        : isTablet
            ? 760.0
            : double.infinity;

    final filteredTokens = appState.wallet!.tokens
        .where((t) => t.addrType == appState.account?.addrType)
        .toList();

    final slivers = <Widget>[
      if (isIOS)
        CupertinoSliverRefreshControl(
          onRefresh: () => _refreshData(appState),
          builder: (
            BuildContext context,
            RefreshIndicatorMode refreshState,
            double pulledExtent,
            double refreshTriggerPullDistance,
            double refreshIndicatorExtent,
          ) {
            return LinearRefreshIndicator(
              pulledExtent: pulledExtent,
              refreshTriggerPullDistance: refreshTriggerPullDistance,
              refreshIndicatorExtent: refreshIndicatorExtent,
            );
          },
        ),
      if (_errorMessage != null)
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              adaptivePadding,
              12,
              adaptivePadding,
              4,
            ),
            child: GlassMessage(
              message: _errorMessage!,
              type: GlassMessageType.error,
              onDismiss: () => setState(() => _errorMessage = null),
            ),
          ),
        ),
      SliverToBoxAdapter(
        child: _buildTopSection(
          context: context,
          appState: appState,
          theme: theme,
          l10n: l10n,
          adaptivePadding: adaptivePadding,
          iconSizeTileButton: iconSizeTileButton,
          isWideLayout: isWideLayout,
        ),
      ),
      SliverToBoxAdapter(
        child: _buildControlBar(
          context: context,
          appState: appState,
          theme: theme,
          adaptivePadding: adaptivePadding,
          iconSizeSmall: iconSizeSmall,
        ),
      ),
      if (appState.wallet != null &&
          appState.wallet!.tokens.length > 1 &&
          appState.isTileView)
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: adaptivePadding),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: isWideLayout ? 235.0 : 210.0,
              mainAxisExtent: isWideLayout ? 158.0 : 150.0,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final token = filteredTokens[index];
                final tokenAmountValue = BigInt.tryParse(
                        token.balances[appState.accountBalanceKey] ?? '-') ??
                    BigInt.zero;

                return TokenCard(
                  ftoken: token,
                  hideBalance: appState.hideBalance,
                  tokenAmount: tokenAmountValue,
                  isAmountLoading: appState.isSyncingBalances,
                  isRateLoading: appState.isSyncingRates,
                  showDivider: false,
                  isTileView: true,
                  onTap: () {
                    final originalIndex =
                        appState.wallet!.tokens.indexOf(token);
                    context.push(
                      AppRoutes.send,
                      extra: {'token_index': originalIndex},
                    );
                  },
                );
              },
              childCount: filteredTokens.length,
            ),
          ),
        )
      else
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final token = filteredTokens[index];
              final isLast = index == filteredTokens.length - 1;
              final tokenAmountValue = BigInt.tryParse(
                      token.balances[appState.accountBalanceKey] ?? '-') ??
                  BigInt.zero;

              return TokenCard(
                ftoken: token,
                hideBalance: appState.hideBalance,
                tokenAmount: tokenAmountValue,
                isAmountLoading: appState.isSyncingBalances,
                isRateLoading: appState.isSyncingRates,
                showDivider: !isLast,
                onTap: () {
                  final originalIndex = appState.wallet!.tokens.indexOf(token);
                  context.push(
                    AppRoutes.send,
                    extra: {'token_index': originalIndex},
                  );
                },
              );
            },
            childCount: filteredTokens.length,
          ),
        ),
      const SliverToBoxAdapter(
        child: SizedBox(height: 96),
      ),
    ];

    Widget scrollView = CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: slivers,
    );

    if (!isIOS) {
      scrollView = RefreshIndicator(
        onRefresh: () => _refreshData(appState),
        child: scrollView,
      );
    }

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: scrollView,
        ),
      ),
    );
  }
}

class _HomeActionCard extends StatefulWidget {
  final Widget icon;
  final String title;
  final Color accentColor;
  final bool isHorizontal;
  final VoidCallback onPressed;

  const _HomeActionCard({
    required this.icon,
    required this.title,
    required this.accentColor,
    required this.isHorizontal,
    required this.onPressed,
  });

  @override
  State<_HomeActionCard> createState() => _HomeActionCardState();
}

class _HomeActionCardState extends State<_HomeActionCard>
    with SingleTickerProviderStateMixin, PressableAnimationMixin {
  @override
  void initState() {
    super.initState();
    initPressAnimation(
      duration: const Duration(milliseconds: 120),
      scaleEnd: 0.96,
      opacityEnd: 0.9,
    );
  }

  @override
  void dispose() {
    disposePressAnimation();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final theme = appState.currentTheme;

    final titleWidget = Text(
      widget.title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: widget.isHorizontal ? TextAlign.start : TextAlign.center,
      style: theme.bodyText2.copyWith(
        color: theme.textPrimary,
        fontWeight: FontWeight.w600,
      ),
    );

    return buildPressable(
      onTap: widget.onPressed,
      enableHover: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: widget.isHorizontal ? 16 : 12,
          vertical: widget.isHorizontal ? 14 : 14,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(
                theme.cardBackground,
                widget.accentColor,
                isHovered ? 0.14 : 0.06,
              )!,
              theme.cardBackground,
            ],
          ),
          border: Border.all(
            color: isHovered
                ? widget.accentColor.withValues(alpha: 0.48)
                : theme.textPrimary.withValues(alpha: 0.08),
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
        child: widget.isHorizontal
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  widget.icon,
                  const SizedBox(width: 10),
                  Flexible(child: titleWidget),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  widget.icon,
                  const SizedBox(height: 8),
                  titleWidget,
                ],
              ),
      ),
    );
  }
}
