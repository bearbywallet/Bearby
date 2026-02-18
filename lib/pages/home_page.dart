// ignore_for_file: constant_identifier_names

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/glass_message.dart';
import 'package:zilpay/components/hoverd_svg.dart';
import 'package:zilpay/components/linear_refresh_indicator.dart';
import 'package:zilpay/components/net_btn.dart';
import 'package:zilpay/components/tile_button.dart';
import 'package:zilpay/components/token_card.dart';
import 'package:zilpay/components/wallet_header.dart';
import 'package:zilpay/config/web3_constants.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import 'package:zilpay/mixins/status_bar.dart';
import 'package:zilpay/mixins/wallet_type.dart';
import 'package:zilpay/src/rust/api/token.dart';
import 'package:zilpay/src/rust/api/wallet.dart';
import 'package:zilpay/state/app_state.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zilpay/l10n/app_localizations.dart';

const double _ICON_SIZE_SMALL_BASE = 24.0;
const double _ICON_SIZE_TILE_BUTTON_BASE = 25.0;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with StatusBarMixin {
  String? _errorMessage;
  bool _isRefreshing = false;

  Future<void> _refreshData(AppState appState) async {
    if (_isRefreshing) return;

    _isRefreshing = true;

    try {
      await syncBalances(walletIndex: BigInt.from(appState.selectedWallet));

      if (_errorMessage != null) {
        setState(() => _errorMessage = null);
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    }

    await appState.syncRates();
    await appState.syncData();

    _isRefreshing = false;
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
    final iconSizeManage = AdaptiveSize.getAdaptiveIconSize(context, 18);
    final spacing = AdaptiveSize.getAdaptiveSize(context, 12);
    final isIOS = defaultTargetPlatform == TargetPlatform.iOS;
    final l10n = AppLocalizations.of(context)!;

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
                    onSettings: () {
                      Navigator.pushNamed(context, '/settings');
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: adaptivePadding),
          child: Row(
            children: [
              TileButton(
                icon: SvgPicture.asset(
                  "assets/icons/send.svg",
                  width: iconSizeTileButton,
                  height: iconSizeTileButton,
                  colorFilter: ColorFilter.mode(
                    theme.primaryPurple,
                    BlendMode.srcIn,
                  ),
                ),
                title: l10n.homePageSendButton,
                onPressed: () {
                  if (filteredTokens.isNotEmpty) {
                    final originalIndex =
                        appState.wallet!.tokens.indexOf(filteredTokens[0]);
                    Navigator.of(context).pushNamed(
                      '/send',
                      arguments: {'token_index': originalIndex},
                    );
                  }
                },
                backgroundColor: theme.cardBackground,
                textColor: theme.primaryPurple,
              ),
              SizedBox(width: adaptivePaddingCard),
              TileButton(
                icon: SvgPicture.asset(
                  "assets/icons/receive.svg",
                  width: iconSizeTileButton,
                  height: iconSizeTileButton,
                  colorFilter: ColorFilter.mode(
                    theme.primaryPurple,
                    BlendMode.srcIn,
                  ),
                ),
                title: l10n.homePageReceiveButton,
                onPressed: () {
                  Navigator.pushNamed(context, '/receive');
                },
                backgroundColor: theme.cardBackground,
                textColor: theme.primaryPurple,
              ),
              if (appState.account != null &&
                  appState.chain?.slip44 == kZilliqaSlip44) ...[
                SizedBox(width: adaptivePaddingCard),
                TileButton(
                  icon: SvgPicture.asset(
                    "assets/icons/anchor.svg",
                    width: iconSizeTileButton,
                    height: iconSizeTileButton,
                    colorFilter:
                        ColorFilter.mode(theme.primaryPurple, BlendMode.srcIn),
                  ),
                  title: "Stake",
                  onPressed: () async {
                    Navigator.pushNamed(context, '/zil_stake');
                  },
                  backgroundColor: theme.cardBackground,
                  textColor: theme.primaryPurple,
                ),
              ],
              if (appState.account != null &&
                  appState.chain?.slip44 == kZilliqaSlip44 &&
                  !appState.wallet!.walletType
                      .contains(WalletType.ledger.name)) ...[
                SizedBox(width: adaptivePaddingCard),
                TileButton(
                  icon: SvgPicture.asset(
                    appState.account?.addrType == kScillaAddressType
                        ? "assets/icons/scilla.svg"
                        : "assets/icons/solidity.svg",
                    width: iconSizeTileButton,
                    height: iconSizeTileButton,
                    colorFilter:
                        ColorFilter.mode(theme.primaryPurple, BlendMode.srcIn),
                  ),
                  title: appState.account?.addrType == kScillaAddressType
                      ? "Scilla"
                      : "EVM",
                  onPressed: () async {
                    BigInt walletIndex = BigInt.from(appState.selectedWallet);
                    await zilliqaSwapChain(
                      walletIndex: walletIndex,
                      accountIndex: appState.wallet!.selectedAccount,
                    );
                    await appState.syncData();

                    try {
                      await syncBalances(
                        walletIndex: walletIndex,
                      );
                      await appState.syncData();
                    } catch (_) {}
                  },
                  backgroundColor: theme.cardBackground,
                  textColor: theme.primaryPurple,
                ),
              ]
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
                      Navigator.pushNamed(
                        context,
                        '/networks',
                        arguments: {'popOnSelect': true},
                      );
                    },
                    chain: appState.chain!,
                  ),
                  SizedBox(width: spacing),
                  HoverSvgIcon(
                    assetName: appState.hideBalance
                        ? 'assets/icons/close_eye.svg'
                        : 'assets/icons/open_eye.svg',
                    width: iconSizeSmall,
                    height: iconSizeSmall,
                    padding: const EdgeInsets.all(0),
                    color: theme.textSecondary.withValues(alpha: 0.5),
                    onTap: () {
                      appState.setHideBalance(!appState.hideBalance);
                    },
                  ),
                ],
              ),
              Row(
                children: [
                  if (appState.wallet != null &&
                      appState.wallet!.tokens.length > 1)
                    HoverSvgIcon(
                      assetName: appState.isTileView
                          ? 'assets/icons/tiles.svg'
                          : 'assets/icons/lines.svg',
                      width: iconSizeManage,
                      height: iconSizeManage,
                      blendMode: BlendMode.modulate,
                      padding: const EdgeInsets.all(0),
                      color: theme.surface,
                      onTap: () async {
                        await appState.updateIsTileView(!appState.isTileView);
                      },
                    ),
                  SizedBox(width: spacing),
                  HoverSvgIcon(
                    assetName: 'assets/icons/manage.svg',
                    width: iconSizeManage,
                    height: iconSizeManage,
                    blendMode: BlendMode.modulate,
                    padding: const EdgeInsets.all(0),
                    color: theme.surface,
                    onTap: () {
                      Navigator.pushNamed(context, '/manage_tokens');
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
              childAspectRatio: 1.618,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final token = filteredTokens[index];
                final tokenAmountValue = token.balances.isNotEmpty &&
                        token.balances.keys
                            .contains(appState.wallet!.selectedAccount)
                    ? BigInt.tryParse(token
                            .balances[appState.wallet!.selectedAccount]
                            .toString()) ??
                        BigInt.zero
                    : BigInt.zero;

                return TokenCard(
                  ftoken: token,
                  hideBalance: appState.hideBalance,
                  tokenAmount: tokenAmountValue,
                  showDivider: false,
                  isTileView: true,
                  onTap: () {
                    final originalIndex =
                        appState.wallet!.tokens.indexOf(token);
                    Navigator.of(context).pushNamed(
                      '/send',
                      arguments: {'token_index': originalIndex},
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
              final tokenAmountValue = token.balances.isNotEmpty &&
                      token.balances.keys
                          .contains(appState.wallet!.selectedAccount)
                  ? BigInt.tryParse(token
                          .balances[appState.wallet!.selectedAccount]
                          .toString()) ??
                      BigInt.zero
                  : BigInt.zero;

              return TokenCard(
                ftoken: token,
                hideBalance: appState.hideBalance,
                tokenAmount: tokenAmountValue,
                showDivider: !isLast,
                onTap: () {
                  final originalIndex = appState.wallet!.tokens.indexOf(token);
                  Navigator.of(context).pushNamed(
                    '/send',
                    arguments: {'token_index': originalIndex},
                  );
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
