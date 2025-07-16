import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/custom_app_bar.dart';
import 'package:zilpay/components/linear_refresh_indicator.dart';
import 'package:zilpay/components/stakeing_card.dart';
import 'package:zilpay/l10n/app_localizations.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
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
      List<FinalOutputInfo> list = [];

      if (appState.account?.addrType == 0) {
        list = await fetchScillaStake(
          walletIndex: BigInt.from(appState.selectedWallet),
          accountIndex: appState.wallet!.selectedAccount,
        );
      } else {
        list = await fetchEvmStake(
          walletIndex: BigInt.from(appState.selectedWallet),
          accountIndex: appState.wallet!.selectedAccount,
        );
      }

      if (mounted) {
        setState(() {
          _stakes = list;
          _errorMessage = null;
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

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = appState.currentTheme;
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);
    final isIOS = defaultTargetPlatform == TargetPlatform.iOS;
    final l10n = AppLocalizations.of(context)!;

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
              child: isIOS ? _buildIosBody() : _buildAndroidBody(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIosBody() {
    return _buildContent();
  }

  Widget _buildAndroidBody() {
    final theme = Provider.of<AppState>(context, listen: false).currentTheme;
    return RefreshIndicator(
      onRefresh: () => _fetchStakes(isRefresh: true),
      color: theme.primaryPurple,
      backgroundColor: theme.cardBackground,
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return _buildSkeletonLoading();
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_stakes.isEmpty) {
      return _buildEmptyState();
    }

    return _buildStakeList();
  }

  Widget _buildStakeList() {
    final theme = Provider.of<AppState>(context).currentTheme;
    final l10n = AppLocalizations.of(context)!;
    final isIOS = defaultTargetPlatform == TargetPlatform.iOS;
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);

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

  Widget _buildErrorState() {
    final theme = Provider.of<AppState>(context, listen: false).currentTheme;
    final isIOS = defaultTargetPlatform == TargetPlatform.iOS;
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      slivers: [
        if (isIOS)
          CupertinoSliverRefreshControl(
            onRefresh: () => _fetchStakes(isRefresh: true),
          ),
        SliverFillRemaining(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(adaptivePadding),
              child: Text(
                'Error: $_errorMessage',
                style: TextStyle(color: theme.danger),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    final theme = Provider.of<AppState>(context).currentTheme;
    final l10n = AppLocalizations.of(context)!;
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

  Widget _buildSkeletonLoading() {
    final theme = Provider.of<AppState>(context, listen: false).currentTheme;
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);
    final isIOS = defaultTargetPlatform == TargetPlatform.iOS;

    return CustomScrollView(
      physics: const NeverScrollableScrollPhysics(),
      slivers: [
        if (isIOS)
          CupertinoSliverRefreshControl(
            onRefresh: () => _fetchStakes(isRefresh: true),
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
