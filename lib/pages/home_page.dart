import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/hoverd_svg.dart';
import 'package:zilpay/components/linear_refresh_indicator.dart';
import 'package:zilpay/components/tile_button.dart';
import 'package:zilpay/components/token_card.dart';
import 'package:zilpay/components/wallet_header.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import 'package:zilpay/src/rust/api/token.dart';
import 'package:zilpay/state/app_state.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zilpay/l10n/app_localizations.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
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
                          Text(
                            l10n.homePageErrorTitle,
                            style: TextStyle(
                              color: theme.buttonText,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: theme.buttonText,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: SvgPicture.asset(
                        'assets/icons/close.svg',
                        width: 24,
                        height: 24,
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
              Expanded(
                child: WalletHeader(
                  account: appState.account!,
                ),
              ),
              HoverSvgIcon(
                assetName: 'assets/icons/gear.svg',
                width: 30,
                height: 30,
                padding: const EdgeInsets.fromLTRB(16, 0, 0, 0),
                color: theme.textSecondary,
                onTap: () {
                  Navigator.pushNamed(context, '/settings');
                },
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
                  width: 24,
                  height: 24,
                  colorFilter: ColorFilter.mode(
                    theme.primaryPurple,
                    BlendMode.srcIn,
                  ),
                ),
                onPressed: () {
                  Navigator.pushNamed(context, '/send');
                },
                backgroundColor: theme.cardBackground,
                textColor: theme.primaryPurple,
              ),
              SizedBox(width: adaptivePaddingCard),
              TileButton(
                icon: SvgPicture.asset(
                  "assets/icons/receive.svg",
                  width: 24,
                  height: 24,
                  colorFilter: ColorFilter.mode(
                    theme.primaryPurple,
                    BlendMode.srcIn,
                  ),
                ),
                onPressed: () {
                  Navigator.pushNamed(context, '/receive');
                },
                backgroundColor: theme.cardBackground,
                textColor: theme.primaryPurple,
              ),
              SizedBox(width: adaptivePaddingCard),
              TileButton(
                icon: SvgPicture.asset(
                  "assets/icons/swap.svg",
                  width: 24,
                  height: 24,
                  colorFilter: ColorFilter.mode(
                    theme.primaryPurple,
                    BlendMode.srcIn,
                  ),
                ),
                disabled: true,
                onPressed: () {},
                backgroundColor: theme.cardBackground,
                textColor: theme.primaryPurple,
              ),
              SizedBox(width: adaptivePaddingCard),
              TileButton(
                icon: SvgPicture.asset(
                  "assets/icons/buy.svg",
                  width: 24,
                  height: 24,
                  colorFilter: ColorFilter.mode(
                    theme.primaryPurple,
                    BlendMode.srcIn,
                  ),
                ),
                disabled: true,
                onPressed: () {},
                backgroundColor: theme.cardBackground,
                textColor: theme.primaryPurple,
              ),
              SizedBox(width: adaptivePaddingCard),
              TileButton(
                icon: SvgPicture.asset(
                  "assets/icons/sell.svg",
                  width: 24,
                  height: 24,
                  colorFilter: ColorFilter.mode(
                    theme.primaryPurple,
                    BlendMode.srcIn,
                  ),
                ),
                onPressed: () {},
                disabled: true,
                backgroundColor: theme.cardBackground,
                textColor: theme.primaryPurple,
              ),
            ],
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding:
              EdgeInsets.symmetric(horizontal: adaptivePadding, vertical: 4),
          child: Row(
            mainAxisAlignment: appState.chain?.testnet == true
                ? MainAxisAlignment.spaceBetween
                : MainAxisAlignment.end,
            children: [
              if (appState.chain?.testnet == true)
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  decoration: BoxDecoration(
                    color: theme.warning,
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                    border: Border.all(color: theme.modalBorder, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      l10n.homePageTestnetLabel,
                      style: TextStyle(
                        color: theme.buttonText,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              HoverSvgIcon(
                assetName: 'assets/icons/manage.svg',
                width: 30,
                height: 30,
                padding: EdgeInsets.fromLTRB(
                    30, adaptivePadding, adaptivePadding, adaptivePadding),
                color: theme.textSecondary,
                onTap: () {
                  Navigator.pushNamed(context, '/manage_tokens');
                },
              ),
            ],
          ),
        ),
      ),
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
