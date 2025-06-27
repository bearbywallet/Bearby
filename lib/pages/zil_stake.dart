import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/button.dart';
import 'package:zilpay/components/custom_app_bar.dart';
import 'package:zilpay/components/image_cache.dart';
import 'package:zilpay/components/linear_refresh_indicator.dart';
import 'package:zilpay/config/ftokens.dart';
import 'package:zilpay/l10n/app_localizations.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import 'package:zilpay/mixins/amount.dart';
import 'package:zilpay/src/rust/api/stake.dart';
import 'package:zilpay/src/rust/models/stake.dart';
import 'package:zilpay/state/app_state.dart';
import 'package:zilpay/theme/app_theme.dart';

enum SortType { apr, commission, tvl, votePower }

class ZilStakePage extends StatefulWidget {
  const ZilStakePage({super.key});

  @override
  State<ZilStakePage> createState() => _ZilStakePageState();
}

class _ZilStakePageState extends State<ZilStakePage> {
  List<FinalOutputInfo> _stakes = [];
  bool _isLoading = true;
  String? _errorMessage;
  SortType _sortType = SortType.apr;

  @override
  void initState() {
    super.initState();
    _fetchStakes();
  }

  Future<void> _fetchStakes({bool isRefresh = false}) async {
    if (!isRefresh && mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final list = await getStakes(
        walletIndex: BigInt.from(appState.selectedWallet),
        accountIndex: appState.wallet!.selectedAccount,
      );

      if (mounted) {
        setState(() {
          _stakes = list;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _sortStakes() {
    _stakes.sort((a, b) {
      bool aIsAvely = a.name.toLowerCase().contains('avely');
      bool bIsAvely = b.name.toLowerCase().contains('avely');

      if (aIsAvely && !bIsAvely) return -1;
      if (!aIsAvely && bIsAvely) return 1;

      switch (_sortType) {
        case SortType.apr:
          return (b.apr ?? 0).compareTo(a.apr ?? 0);
        case SortType.commission:
          return (a.commission ?? 0).compareTo(b.commission ?? 0);
        case SortType.tvl:
          return (b.tvl ?? BigInt.zero).compareTo(a.tvl ?? BigInt.zero);
        case SortType.votePower:
          return (b.votePower ?? 0).compareTo(a.votePower ?? 0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _sortStakes();
    final appState = Provider.of<AppState>(context);
    final theme = appState.currentTheme;
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);
    final isIOS = defaultTargetPlatform == TargetPlatform.iOS;
    final l10n = AppLocalizations.of(context)!;

    Widget buildContent() {
      if (_isLoading) {
        return _buildSkeletonLoading(theme, adaptivePadding, isIOS);
      }

      if (_errorMessage != null) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Error: $_errorMessage',
              style: TextStyle(color: theme.danger),
              textAlign: TextAlign.center,
            ),
          ),
        );
      }

      if (_stakes.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                'assets/icons/anchor.svg',
                width: 80,
                height: 80,
                colorFilter: ColorFilter.mode(
                  theme.textSecondary.withValues(alpha: 0.3),
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.noStakingPoolsFound,
                style: TextStyle(
                  color: theme.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      }

      return CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          if (isIOS)
            CupertinoSliverRefreshControl(
              onRefresh: () => _fetchStakes(isRefresh: true),
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
          SliverPadding(
            padding: EdgeInsets.symmetric(
              horizontal: adaptivePadding,
              vertical: 8,
            ),
            sliver: SliverToBoxAdapter(
              child: _buildSortButtons(theme, l10n),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              adaptivePadding,
              8,
              adaptivePadding,
              adaptivePadding,
            ),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: StakingPoolCard(stake: _stakes[index]),
                  );
                },
                childCount: _stakes.length,
              ),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: theme.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: adaptivePadding),
              child: CustomAppBar(
                title: l10n.zilStakePageTitle,
                onBackPressed: () => Navigator.pop(context),
              ),
            ),
            Expanded(
              child: isIOS
                  ? buildContent()
                  : RefreshIndicator(
                      onRefresh: () => _fetchStakes(isRefresh: true),
                      color: theme.primaryPurple,
                      backgroundColor: theme.cardBackground,
                      child: buildContent(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonLoading(
      AppTheme theme, double adaptivePadding, bool isIOS) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      slivers: [
        if (isIOS)
          CupertinoSliverRefreshControl(
            onRefresh: () => _fetchStakes(isRefresh: true),
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
        SliverPadding(
          padding: EdgeInsets.symmetric(
            horizontal: adaptivePadding,
            vertical: 8,
          ),
          sliver: SliverToBoxAdapter(
            child: _buildSkeletonSortButtons(theme),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            adaptivePadding,
            8,
            adaptivePadding,
            adaptivePadding,
          ),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildSkeletonStakingPoolCard(theme),
                );
              },
              childCount: 3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSkeletonSortButtons(AppTheme theme) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: List.generate(4, (index) {
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Container(
              width: 80,
              height: 32,
              decoration: BoxDecoration(
                color: theme.textSecondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSkeletonStakingPoolCard(AppTheme theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.textSecondary.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: theme.textSecondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 120,
                            height: 18,
                            decoration: BoxDecoration(
                              color: theme.textSecondary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 60,
                            height: 14,
                            decoration: BoxDecoration(
                              color: theme.textSecondary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(4, (index) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 12,
                          decoration: BoxDecoration(
                            color: theme.textSecondary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 60,
                          height: 16,
                          decoration: BoxDecoration(
                            color: theme.textSecondary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: theme.textSecondary.withValues(alpha: 0.1),
                ),
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: theme.textSecondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: theme.textSecondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortButtons(AppTheme theme, AppLocalizations l10n) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: SortType.values.map((type) {
          final isSelected = _sortType == type;
          String label;
          switch (type) {
            case SortType.apr:
              label = l10n.aprSort;
              break;
            case SortType.commission:
              label = l10n.commissionSort;
              break;
            case SortType.tvl:
              label = l10n.tvlSort;
              break;
            case SortType.votePower:
              label = "VP";
              break;
          }
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: GestureDetector(
              onTap: () {
                if (_sortType != type) {
                  setState(() => _sortType = type);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color:
                      isSelected ? theme.primaryPurple : theme.cardBackground,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? Colors.transparent
                        : theme.textSecondary.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    color: isSelected ? theme.buttonText : theme.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class StakingPoolCard extends StatelessWidget {
  final FinalOutputInfo stake;

  const StakingPoolCard({super.key, required this.stake});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = appState.currentTheme;
    final l10n = AppLocalizations.of(context)!;
    final hasRewards = double.tryParse(stake.rewards.replaceAll(',', ''))! > 0;
    final hasDelegation =
        double.tryParse(stake.delegAmt.replaceAll(',', ''))! > 0;
    final isLP = stake.tokenAddress == zeroEVM;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.textSecondary.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildCardHeader(theme, isLP, l10n),
                const SizedBox(height: 16),
                _buildStatsRow(theme, l10n, appState),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: theme.textSecondary.withValues(alpha: 0.1),
                ),
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (hasRewards)
                  Expanded(
                    child: CustomButton(
                      text: l10n.claimButton(stake.rewards),
                      onPressed: () {},
                      textColor: theme.buttonText,
                      backgroundColor: theme.success,
                      borderRadius: 12,
                      height: 44.0,
                    ),
                  ),
                if (hasRewards) const SizedBox(width: 8),
                Expanded(
                  child: CustomButton(
                    text: hasDelegation ? l10n.unstakeButton : l10n.stakeButton,
                    onPressed: () {},
                    textColor: theme.buttonText,
                    backgroundColor:
                        hasDelegation ? theme.danger : theme.primaryPurple,
                    borderRadius: 12,
                    height: 44.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardHeader(AppTheme theme, bool isLP, AppLocalizations l10n) {
    return Row(
      children: [
        AsyncImage(
          url: stake.url,
          width: 48,
          height: 48,
          fit: BoxFit.contain,
          loadingWidget: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: theme.textSecondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child:
                const Center(child: CupertinoActivityIndicator(radius: 10.0)),
          ),
          errorWidget: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: theme.danger.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.broken_image, color: theme.danger, size: 24),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stake.name,
                style: TextStyle(
                  color: theme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isLP) ...[
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.primaryPurple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    l10n.lpStakingBadge,
                    style: TextStyle(
                      color: theme.primaryPurple,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ]
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(
      AppTheme theme, AppLocalizations l10n, AppState appState) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildStatItem(
            theme,
            "VP",
            '${stake.votePower?.toStringAsFixed(2) ?? 0}%',
            theme.primaryPurple),
        _buildStatItem(
            theme, l10n.aprLabel, '${stake.apr ?? 0}%', theme.success),
        _buildStatItem(theme, l10n.commissionLabel, '${stake.commission ?? 0}%',
            theme.warning),
        _buildStatItem(theme, l10n.tvlLabel, _formatTvl(stake.tvl, appState),
            theme.textPrimary),
      ],
    );
  }

  Widget _buildStatItem(
      AppTheme theme, String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: theme.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _formatTvl(BigInt? tvl, AppState appState) {
    if (tvl == null) return 'N/A';

    String symbol = "ZIL";
    int decimals = 18;
    double rate = 0;

    try {
      final nativeToken = appState.wallet?.tokens
          .firstWhere((t) => t.native && t.addrType == 0);
      if (nativeToken != null) {
        decimals = nativeToken.decimals;
        symbol = nativeToken.symbol;
        rate = nativeToken.rate;
      }
    } catch (_) {}

    final (formattedValue, _) = formatingAmount(
      amount: tvl,
      symbol: symbol,
      decimals: decimals,
      rate: rate,
      appState: appState,
    );

    return formattedValue.split(' ')[0];
  }
}
