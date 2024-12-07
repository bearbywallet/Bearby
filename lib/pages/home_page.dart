import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/hoverd_svg.dart';
import 'package:zilpay/components/linear_refresh_indicator.dart';
import 'package:zilpay/components/tile_button.dart';
import 'package:zilpay/components/token_card.dart';
import 'package:zilpay/components/wallet_header.dart';

import 'package:zilpay/mixins/adaptive_size.dart';
import 'package:zilpay/mixins/icon.dart';
import 'package:zilpay/modals/manage_tokens.dart';
import 'package:zilpay/src/rust/api/backend.dart';
import 'package:zilpay/state/app_state.dart';
import '../theme/theme_provider.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = Provider.of<AppState>(context, listen: false);

      if (appState.wallet == null || appState.account == null) {
        Navigator.of(context).pop();
        return;
      }

      _refreshData(appState);
    });
  }

  Future<void> _refreshData(AppState appState) async {
    try {
      BigInt index = BigInt.from(appState.selectedWallet);
      await syncBalances(walletIndex: index);
      await appState.syncData();
      setState(() {});
    } catch (e) {
      debugPrint("error sync balance: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = Provider.of<ThemeProvider>(context).currentTheme;
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);
    final adaptivePaddingCard = AdaptiveSize.getAdaptivePadding(context, 12);

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              CupertinoSliverRefreshControl(
                onRefresh: () async {
                  await _refreshData(appState);
                },
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
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: WalletHeader(
                              walletName: appState.account!.name,
                              walletAddress: appState.account!.addr,
                              primaryPurple: theme.primaryPurple,
                              background: theme.background,
                              textPrimary: theme.textPrimary,
                            ),
                          ),
                          HoverSvgIcon(
                            assetName: 'assets/icons/gear.svg',
                            width: 30,
                            height: 30,
                            padding: EdgeInsets.fromLTRB(16, 0, 0, 0),
                            color: theme.textSecondary,
                            onTap: () {
                              Navigator.pushNamed(context, '/settings');
                            },
                          ),
                        ],
                      ),
                    ),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding:
                          EdgeInsets.symmetric(horizontal: adaptivePadding),
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
                            onPressed: () {},
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
                            onPressed: () {},
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
                            backgroundColor: theme.cardBackground,
                            textColor: theme.primaryPurple,
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: adaptivePadding, vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          HoverSvgIcon(
                            assetName: 'assets/icons/manage.svg',
                            width: 30,
                            height: 30,
                            padding: EdgeInsets.fromLTRB(30, adaptivePadding,
                                adaptivePadding, adaptivePadding),
                            color: theme.textSecondary,
                            onTap: () {
                              showManageTokensModal(
                                context: context,
                                onAddToken: () {
                                  debugPrint('Add new token');
                                },
                                onTokenToggle: (String symbol) async {
                                  debugPrint("symbol $symbol");
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(adaptivePadding),
                      child: Column(
                        children: appState.wallet!.tokens
                            .asMap()
                            .entries
                            .map((entry) {
                          final token = entry.value;
                          final isLast =
                              entry.key == appState.wallet!.tokens.length - 1;
                          final account = appState.account!;
                          String tokenAmountValue =
                              token.balances[account.addr] ?? "0";
                          double tokenAmount = 0;

                          try {
                            tokenAmount = double.parse(tokenAmountValue);
                            double divisor = pow(10, token.decimals).toDouble();
                            tokenAmount = tokenAmount / divisor;
                          } catch (e) {
                            ///
                          }

                          return TokenCard(
                            tokenAmount: tokenAmount,
                            tokenAddr: token.addr,
                            convertAmount: 0,
                            tokenName: token.name,
                            tokenSymbol: token.symbol,
                            showDivider: !isLast,
                            iconUrl: viewIcon(token.addr, "Light"),
                            onTap: () => {print("tap token ${token.name}")},
                          );
                        }).toList(),
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
