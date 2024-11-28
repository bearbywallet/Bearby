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

    if (_appState.wallet == null) {
      Navigator.of(context).pop();
    }

    _refreshData();
  }

  Future<void> _refreshData() async {
    try {
      BigInt index = BigInt.from(_appState.selectedWallet);
      await syncBalances(walletIndex: index);
      await _appState.syncData();
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
                                  width: 32,
                                  height: 32,
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
                                      seed: _appState.wallet!
                                          .walletAddress, // TODO: replace it with account.
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
                                      _appState.wallet!.walletName,
                                      style: TextStyle(
                                        color: theme.textPrimary,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    CopyAddressButton(
                                      address: _appState.wallet!.walletAddress,
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
                            color: theme.textPrimary,
                            onTap: () {
                              print('Settings tapped');
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
                        children: [
                          TokenCard(
                            tokenAmount: 5437854356.654674,
                            tokenAddr:
                                "0x5ab3e1128c6f2ed0f62efc4e26d93f82ef50134e",
                            convertAmount: 100000,
                            tokenName: "Zilliqa",
                            tokenSymbol: "ZIL",
                            onTap: () => {},
                            iconUrl:
                                "https://cryptologos.cc/logos/zilliqa-zil-logo.png",
                          ),
                          TokenCard(
                            tokenAmount: 549,
                            tokenAddr:
                                "0x7c8a02b6fcbd46aa10d8e9b6f9d947d45a2d784a",
                            convertAmount: 549,
                            tokenName: "ZilPay USD",
                            tokenSymbol: "ZPUSD",
                            iconUrl:
                                "https://cryptologos.cc/logos/usd-coin-usdc-logo.png",
                          ),
                          TokenCard(
                            tokenAmount: 1.5,
                            tokenAddr:
                                "0x28f8a18f3a64dc5eeb02fd4627234d6c99c0f154",
                            convertAmount: 2000000,
                            tokenName: "Bitcoin",
                            tokenSymbol: "BTC",
                            iconUrl:
                                "https://cryptologos.cc/logos/bitcoin-btc-logo.png?v=002",
                          ),
                          TokenCard(
                            convertAmount: 100,
                            tokenAddr:
                                "0x4df7b47293424586f109c51fa127a8ec3219847d",
                            tokenAmount: 0.5,
                            tokenName: "GRIN coin",
                            tokenSymbol: "GRIN",
                            iconUrl:
                                "https://cryptologos.cc/logos/gridcoin-grc-logo.png?v=002",
                          ),
                          TokenCard(
                            tokenAmount: 0.5,
                            tokenAddr:
                                "0x91e3d4bf3e27e98502d79d5c63c96e038ee8cd44",
                            convertAmount: 100,
                            tokenName: "GogeCoin",
                            tokenSymbol: "DOGE",
                            showDivider: false,
                            iconUrl:
                                "https://cryptologos.cc/logos/dogecoin-doge-logo.png?v=002",
                          ),
                          TokenCard(
                            tokenAmount: 0.5,
                            convertAmount: 100,
                            tokenAddr:
                                "0x91e34bf3e27898502d70d5c63c96e038ee8cd44",
                            tokenName: "None",
                            tokenSymbol: "None",
                            showDivider: false,
                            iconUrl:
                                "https://cryptologos.cc/logos/dogecoin-gfdjkghfdjk-logo.png?v=002",
                          ),
                        ],
                      ),
                    ),
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
