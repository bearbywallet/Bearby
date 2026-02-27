import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:bearby/components/custom_app_bar.dart';
import 'package:bearby/components/linear_refresh_indicator.dart';
import 'package:bearby/components/stakeing_card.dart';
import 'package:bearby/l10n/app_localizations.dart';
import 'package:bearby/mixins/adaptive_size.dart';
import 'package:bearby/mixins/status_bar.dart';
import 'package:bearby/src/rust/api/stake.dart';
import 'package:bearby/src/rust/models/stake.dart';
import 'package:bearby/state/app_state.dart';
import 'package:bearby/theme/app_theme.dart';

class ZilStakePage extends StatefulWidget {
  const ZilStakePage({super.key});

  @override
  State<ZilStakePage> createState() => _ZilStakePageState();
}

class _ZilStakePageState extends State<ZilStakePage> with StatusBarMixin {
  List<FinalOutputInfo> _stakes = [];
  bool _isLoading = true;
  String? _errorMessage;

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
      final list = await _fetchStakesForAccount(appState);

      if (mounted) {
        setState(() {
          _stakes = list;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<List<FinalOutputInfo>> _fetchStakesForAccount(
      AppState appState) async {
    final walletIndex = BigInt.from(appState.selectedWallet);
    final accountIndex = appState.wallet!.selectedAccount;

    if (appState.account?.addrType == 0) {
      return fetchScillaStake(
        walletIndex: walletIndex,
        accountIndex: accountIndex,
      );
    }
    return fetchEvmStake(
      walletIndex: walletIndex,
      accountIndex: accountIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.read<AppState>().currentTheme;
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: _buildAppBar(theme),
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
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: _buildBody(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(AppTheme theme) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      automaticallyImplyLeading: false,
      toolbarHeight: 0,
      systemOverlayStyle: getSystemUiOverlayStyle(context),
    );
  }

  Widget _buildBody() {
    final isIOS = defaultTargetPlatform == TargetPlatform.iOS;

    if (isIOS) {
      return _buildIosBody();
    }
    return _buildAndroidBody();
  }

  Widget _buildIosBody() {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      slivers: [
        CupertinoSliverRefreshControl(
          onRefresh: () => _fetchStakes(isRefresh: true),
          builder: _buildRefreshIndicator,
        ),
        _buildContentSliver(),
      ],
    );
  }

  Widget _buildAndroidBody() {
    final theme = context.read<AppState>().currentTheme;

    return RefreshIndicator(
      onRefresh: () => _fetchStakes(isRefresh: true),
      color: theme.primaryPurple,
      backgroundColor: theme.cardBackground,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [_buildContentSliver()],
      ),
    );
  }

  Widget _buildRefreshIndicator(
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
  }

  Widget _buildContentSliver() {
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);

    if (_isLoading) {
      return _StakingSkeletonSliver(adaptivePadding: adaptivePadding);
    }

    if (_errorMessage != null) {
      return _ErrorSliver(
        errorMessage: _errorMessage!,
        adaptivePadding: adaptivePadding,
      );
    }

    if (_stakes.isEmpty) {
      return const _EmptySliver();
    }

    return _StakingListSliver(
      stakes: _stakes,
      adaptivePadding: adaptivePadding,
    );
  }
}

class _StakingListSliver extends StatelessWidget {
  final List<FinalOutputInfo> stakes;
  final double adaptivePadding;

  const _StakingListSliver({
    required this.stakes,
    required this.adaptivePadding,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        adaptivePadding,
        8,
        adaptivePadding,
        adaptivePadding,
      ),
      sliver: SliverList.builder(
        itemCount: stakes.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: StakingPoolCard(stake: stakes[index]),
          );
        },
      ),
    );
  }
}

class _StakingSkeletonSliver extends StatelessWidget {
  final double adaptivePadding;

  const _StakingSkeletonSliver({required this.adaptivePadding});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        adaptivePadding,
        8,
        adaptivePadding,
        adaptivePadding,
      ),
      sliver: SliverList.builder(
        itemCount: 3,
        itemBuilder: (context, index) {
          return const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: _StakingCardSkeleton(),
          );
        },
      ),
    );
  }
}

class _StakingCardSkeleton extends StatelessWidget {
  const _StakingCardSkeleton();

  @override
  Widget build(BuildContext context) {
    final theme = context.read<AppState>().currentTheme;

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
                _buildHeaderSkeleton(theme),
                const SizedBox(height: 16),
                _buildStatsSkeleton(theme),
              ],
            ),
          ),
          _buildActionsSkeleton(theme),
        ],
      ),
    );
  }

  Widget _buildHeaderSkeleton(AppTheme theme) {
    return Row(
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
    );
  }

  Widget _buildStatsSkeleton(AppTheme theme) {
    return Row(
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
    );
  }

  Widget _buildActionsSkeleton(AppTheme theme) {
    return Container(
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
    );
  }
}

class _ErrorSliver extends StatelessWidget {
  final String errorMessage;
  final double adaptivePadding;

  const _ErrorSliver({
    required this.errorMessage,
    required this.adaptivePadding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.read<AppState>().currentTheme;

    return SliverFillRemaining(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(adaptivePadding),
          child: Text(
            'Error: $errorMessage',
            style: theme.bodyText2.copyWith(color: theme.danger),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _EmptySliver extends StatelessWidget {
  const _EmptySliver();

  @override
  Widget build(BuildContext context) {
    final theme = context.read<AppState>().currentTheme;
    final l10n = AppLocalizations.of(context)!;

    return SliverFillRemaining(
      child: Center(
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
              textAlign: TextAlign.center,
              style: theme.titleLarge.copyWith(
                color: theme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
