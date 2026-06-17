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
import 'package:bearby/components/tile_button.dart';
import 'package:bearby/components/token_card.dart';
import 'package:bearby/components/wallet_header.dart';
import 'package:bearby/config/web3_constants.dart';
import 'package:bearby/mixins/adaptive_size.dart';
import 'package:bearby/mixins/qrcode.dart';
import 'package:bearby/mixins/status_bar.dart';
import 'package:bearby/mixins/wallet_type.dart';
import 'package:bearby/src/rust/api/token.dart';
import 'package:bearby/src/rust/api/wallet.dart';
import 'package:bearby/src/rust/api/utils.dart';
import 'package:bearby/state/app_state.dart';
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_hasInitialSync) {
      _hasInitialSync = true;
      final appState = Provider.of<AppState>(context, listen: false);
      _refreshData(appState);
    }
  }

  bool _hasZilliqaExtras(AppState appState) =>
      appState.account != null && appState.chain?.slip44 == kZilliqaSlip44;

  Future<void> _refreshData(AppState appState) async {
    if (_isRefreshing) return;

    _isRefreshing = true;

    try {
      await syncBalances(walletIndex: appState.selectedWalletIndex);

      if (_errorMessage != null) {
        setState(() => _errorMessage = null);
      }
    } catch (e) {
      debugPrint("refresh: $e");
      setState(() => _errorMessage = e.toString());
    }

    await appState.syncRates();
    await appState.syncData();

    _isRefreshing = false;
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
    final trimmed = rawData.trim();
    if (trimmed.isEmpty) return;

    final appState = Provider.of<AppState>(context, listen: false);
    final activeChain = appState.chain;

    // Chain-aware parse (EIP-681 style: "chain:address?amount=...&token=...").
    // A plain address with no scheme yields an empty map; we then treat the
    // whole payload as the recipient.
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
      Navigator.of(context).pop();
      _showScanError();
      return;
    }

    try {
      final ok = await isValidAddress(addr: address);
      if (!ok) {
        if (!mounted) return;
        Navigator.of(context).pop();
        _showScanError();
        return;
      }
    } catch (e) {
      debugPrint('address validation error: $e');
      if (!mounted) return;
      Navigator.of(context).pop();
      _showScanError();
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pop();
    _goToSendPage(
      recipient: address,
      amount: amount,
      tokenAddress: tokenAddress,
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = appState.currentTheme;
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);
    final adaptivePaddingCard = AdaptiveSize.getAdaptivePadding(context, 12);
    final iconSizeSmall =
        AdaptiveSize.getAdaptiveIconSize(context, _ICON_SIZE_SMALL_BASE);
    final iconSizeTileButton =
        AdaptiveSize.getAdaptiveIconSize(context, _ICON_SIZE_TILE_BUTTON_BASE);
    final spacing = AdaptiveSize.getAdaptiveSize(context, 12);
    final isIOS = defaultTargetPlatform == TargetPlatform.iOS;
    final l10n = AppLocalizations.of(context)!;

    if (appState.wallet == null) return const SizedBox.shrink();

    final filteredTokens = appState.wallet!.tokens
        .where((t) => t.addrType == appState.account?.addrType)
        .toList();

    final slivers = [
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
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: GlassMessage(
              message: _errorMessage!,
              type: GlassMessageType.error,
              onDismiss: () => setState(() => _errorMessage = null),
            ),
          ),
        ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (appState.account != null)
                Expanded(
                  child: WalletHeader(
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
                ),
            ],
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: adaptivePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TileButton(
                      icon: AppIconView(
                        icon: AppIcon.send,
                        size: iconSizeTileButton,
                        color: theme.primaryPurple,
                      ),
                      title: l10n.homePageSendButton,
                      fillWidth: true,
                      onPressed: () => _goToSendPage(),
                      backgroundColor: theme.cardBackground,
                      textColor: theme.primaryPurple,
                    ),
                  ),
                  SizedBox(width: adaptivePaddingCard),
                  Expanded(
                    child: TileButton(
                      icon: AppIconView(
                        icon: AppIcon.receive,
                        size: iconSizeTileButton,
                        color: theme.primaryPurple,
                      ),
                      title: l10n.homePageReceiveButton,
                      fillWidth: true,
                      onPressed: () => context.push(AppRoutes.receive),
                      backgroundColor: theme.cardBackground,
                      textColor: theme.primaryPurple,
                    ),
                  ),
                ],
              ),
              if (_hasZilliqaExtras(appState)) ...[
                SizedBox(height: adaptivePaddingCard),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      TileButton(
                        icon: AppIconView(
                          icon: AppIcon.anchorSimple,
                          size: iconSizeTileButton,
                          color: theme.primaryPurple,
                        ),
                        title: "Stake",
                        onPressed: () => context.push(AppRoutes.zilStake),
                        backgroundColor: theme.cardBackground,
                        textColor: theme.primaryPurple,
                      ),
                      if (!appState.wallet!.walletType
                          .contains(WalletType.ledger.name)) ...[
                        SizedBox(width: adaptivePaddingCard),
                        TileButton(
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
                          onPressed: () async {
                            final walletIndex = appState.selectedWalletIndex;
                            await zilliqaSwapChain(
                              walletIndex: walletIndex,
                              accountIndex: appState.wallet!.selectedAccount,
                            );
                            await appState.syncData();
                            try {
                              await syncBalances(walletIndex: walletIndex);
                              await appState.syncData();
                            } catch (_) {}
                          },
                          backgroundColor: theme.cardBackground,
                          textColor: theme.primaryPurple,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding:
              EdgeInsets.symmetric(horizontal: adaptivePadding, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  NetworkDownButton(
                    onPressed: () {
                      context.push(AppRoutes.networks,
                          extra: {'popOnSelect': true});
                    },
                    chain: appState.chain!,
                  ),
                  SizedBox(width: spacing),
                  HoverIcon(
                    icon: AppIconState.balanceVisibility(hidden: appState.hideBalance),
                    size: iconSizeSmall,
                    padding: const EdgeInsets.all(0),
                    color: theme.textSecondary.withValues(alpha: 0.5),
                    onTap: () {
                      appState.setHideBalance(!appState.hideBalance);
                    },
                  ),
                  SizedBox(width: spacing),
                  HoverIcon(
                    icon: AppIcon.lockWallet,
                    size: iconSizeSmall,
                    padding: const EdgeInsets.all(0),
                    color: theme.textSecondary.withValues(alpha: 0.5),
                    onTap: () {
                      appState.clearAuthentication();
                    },
                  ),
                ],
              ),
              Row(
                children: [
                  if (appState.wallet != null &&
                      appState.wallet!.tokens.length > 1)
                    HoverIcon(
                      icon: AppIconState.tokenLayout(isTileView: appState.isTileView),
                      size: iconSizeSmall,
                      padding: const EdgeInsets.all(0),
                      color: theme.textSecondary.withValues(alpha: 0.5),
                      onTap: () async {
                        await appState.updateIsTileView(!appState.isTileView);
                      },
                    ),
                  SizedBox(width: spacing),
                  HoverIcon(
                    icon: AppIcon.manage,
                    size: iconSizeSmall,
                    padding: const EdgeInsets.all(0),
                    color: theme.textSecondary.withValues(alpha: 0.5),
                    onTap: () {
                      context.push(AppRoutes.manageTokens);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      if (appState.wallet != null &&
          appState.wallet!.tokens.length > 1 &&
          appState.isTileView)
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: adaptivePadding),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.4,
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
                  showDivider: false,
                  isTileView: true,
                  onTap: () {
                    final originalIndex =
                        appState.wallet!.tokens.indexOf(token);
                    context.push(AppRoutes.send,
                        extra: {'token_index': originalIndex});
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
                showDivider: !isLast,
                onTap: () {
                  final originalIndex = appState.wallet!.tokens.indexOf(token);
                  context.push(AppRoutes.send,
                      extra: {'token_index': originalIndex});
                },
              );
            },
            childCount: filteredTokens.length,
          ),
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

    final screenWidth = MediaQuery.of(context).size.width;
    final maxWidth = screenWidth < 600 ? double.infinity : 600.0;

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
