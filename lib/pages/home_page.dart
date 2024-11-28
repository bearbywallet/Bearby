import 'dart:math';

import 'package:blockies/blockies.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/copy_content.dart';
import 'package:zilpay/components/hoverd_svg.dart';
import 'package:zilpay/components/linear_refresh_indicator.dart';
import 'package:zilpay/components/tile_button.dart';
import 'package:zilpay/components/token_card.dart';

import 'package:zilpay/mixins/adaptive_size.dart';
import 'package:zilpay/mixins/colors.dart';
import 'package:zilpay/mixins/icon.dart';
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
  late AppState _appState;

  @override
  void initState() {
    super.initState();

    _appState = Provider.of<AppState>(context, listen: false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_appState.wallet == null || _appState.account == null) {
        Navigator.of(context).pop();
        return;
      }

      _refreshData();
    });
  }

  Future<void> _refreshData() async {
    try {
      BigInt index = BigInt.from(_appState.selectedWallet);
      await syncBalances(walletIndex: index);
      await _appState.syncData();
      setState(() {});
    } catch (e) {
      print("error sync balance: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
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
                onRefresh: _refreshData,
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color:
                                          theme.primaryPurple.withOpacity(0.1),
                                      width: 2,
                                    ),
                                  ),
                                  child: ClipOval(
                                    child: Blockies(
                                      seed: _appState.account!.addr,
                                      color: getWalletColor(0),
                                      bgColor: theme.primaryPurple,
                                      spotColor: theme.background,
                                      size: 8,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Text(
                                      _appState.account!.name,
                                      style: TextStyle(
                                        color: theme.textPrimary,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    CopyAddressButton(
                                      address: _appState.account!.addr,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          HoverSvgIcon(
                            assetName: 'assets/icons/gear.svg',
                            width: 30,
                            height: 30,
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
                          horizontal: adaptivePadding, vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          HoverSvgIcon(
                            assetName: 'assets/icons/manage.svg',
                            width: 30,
                            height: 30,
                            color: theme.textSecondary,
                            onTap: () {
                              print('tokens manage');
                            },
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(adaptivePadding),
                      child: Column(
                        children: _appState.wallet!.tokens
                            .asMap()
                            .entries
                            .map((entry) {
                          final token = entry.value;
                          final isLast =
                              entry.key == _appState.wallet!.tokens.length - 1;
                          final account = _appState.account!;
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
                            convertAmount: 0, // add the loading rates.
                            tokenName: token.name,
                            tokenSymbol: token.symbol,
                            showDivider: !isLast,
                            iconUrl: viewIcon(token.addr, "Dark"),
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
