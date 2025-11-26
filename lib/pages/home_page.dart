// ignore_for_file: constant_identifier_names

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/hoverd_svg.dart';
import 'package:zilpay/components/linear_refresh_indicator.dart';
import 'package:zilpay/components/net_btn.dart';
import 'package:zilpay/components/tile_button.dart';
import 'package:zilpay/components/token_card.dart';
import 'package:zilpay/components/wallet_header.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import 'package:zilpay/mixins/status_bar.dart';
import 'package:zilpay/mixins/wallet_type.dart';
import 'package:zilpay/src/rust/api/token.dart';
import 'package:zilpay/src/rust/api/wallet.dart';
import 'package:zilpay/state/app_state.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zilpay/l10n/app_localizations.dart';

const double ICON_SIZE_SMALL = 24.0;
const double ICON_SIZE_MEDIUM = 32.0;
const double ICON_SIZE_TILE_BUTTON = 25.0;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with TickerProviderStateMixin, StatusBarMixin {
  bool _isFirstLoad = true;
  String? _errorMessage;
  late AnimationController _animationController;
  late Animation<double> _heightAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _heightAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isFirstLoad) {
        _isFirstLoad = false;
        final appState = Provider.of<AppState>(context, listen: false);
        _refreshData(appState);
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _refreshData(AppState appState) async {
    BigInt index = BigInt.from(appState.selectedWallet);

    try {
      await syncBalances(walletIndex: index);
      if (_errorMessage != null) {
        setState(() {
          _errorMessage = null;
        });
        _animationController.reverse();
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
      _animationController.forward();
    }

    await appState.syncRates();
    await appState.syncData();
  }

  void _dismissError() {
    _animationController.reverse().then((_) {
      setState(() {
        _errorMessage = null;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = appState.currentTheme;
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);
    final adaptivePaddingCard = AdaptiveSize.getAdaptivePadding(context, 12);
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
          child: SizeTransition(
            axisAlignment: -1,
            sizeFactor: _heightAnimation,
            child: FadeTransition(
              opacity: _opacityAnimation,
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: theme.danger,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.homePageErrorTitle,
                              style: theme.subtitle1.copyWith(
                                color: theme.buttonText,
                              )),
                          const SizedBox(height: 4),
                          Text(
                            _errorMessage!,
                            style: theme.bodyLarge.copyWith(
                              color: theme.buttonText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: SvgPicture.asset(
                        'assets/icons/close.svg',
                        width: ICON_SIZE_SMALL,
                        height: ICON_SIZE_SMALL,
                        colorFilter: ColorFilter.mode(
                          theme.buttonText,
                          BlendMode.srcIn,
                        ),
                      ),
                      onPressed: _dismissError,
                    ),
                  ],
                ),
              ),
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
                  "assets/icons/receive.svg",
                  width: ICON_SIZE_TILE_BUTTON,
                  height: ICON_SIZE_TILE_BUTTON,
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
                  appState.chain?.slip44 == 313) ...[
                SizedBox(width: adaptivePaddingCard),
                TileButton(
                  icon: SvgPicture.asset(
                    "assets/icons/anchor.svg",
                    width: ICON_SIZE_TILE_BUTTON,
                    height: ICON_SIZE_TILE_BUTTON,
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
                  appState.chain?.slip44 == 313 &&
                  !appState.wallet!.walletType
                      .contains(WalletType.ledger.name)) ...[
                SizedBox(width: adaptivePaddingCard),
                TileButton(
                  icon: SvgPicture.asset(
                    appState.account?.addrType == 0
                        ? "assets/icons/scilla.svg"
                        : "assets/icons/solidity.svg",
                    width: ICON_SIZE_TILE_BUTTON,
                    height: ICON_SIZE_TILE_BUTTON,
                    colorFilter:
                        ColorFilter.mode(theme.primaryPurple, BlendMode.srcIn),
                  ),
                  title: appState.account?.addrType == 0 ? "Scilla" : "EVM",
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
                      Navigator.pushNamed(context, '/networks');
                    },
                    chain: appState.chain!,
                  ),
                  const SizedBox(width: 12),
                  HoverSvgIcon(
                    assetName: appState.hideBalance
                        ? 'assets/icons/close_eye.svg'
                        : 'assets/icons/open_eye.svg',
                    width: ICON_SIZE_SMALL,
                    height: ICON_SIZE_SMALL,
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
                      width: 18,
                      height: 18,
                      blendMode: BlendMode.modulate,
                      padding: const EdgeInsets.all(0),
                      color: theme.surface,
                      onTap: () async {
                        await appState.updateIsTileView(!appState.isTileView);
                      },
                    ),
                  const SizedBox(width: 12),
                  HoverSvgIcon(
                    assetName: 'assets/icons/manage.svg',
                    width: 18,
                    height: 18,
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
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.618,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
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

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: scrollView,
        ),
      ),
    );
  }
}
