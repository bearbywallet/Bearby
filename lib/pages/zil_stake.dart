import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/custom_app_bar.dart';
import 'package:zilpay/components/button.dart';
import 'package:zilpay/components/image_cache.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import 'package:zilpay/state/app_state.dart';

enum StakingType { liquid, regular }

enum SortType { vp, apr, commission, uptime }

class StakingPool {
  final String name;
  final String token;
  final String iconUrl;
  final double vp;
  final double commission;
  final double apr;
  final double minStake;
  final bool isLiquid;
  final String description;
  final double uptime;

  StakingPool({
    required this.name,
    required this.token,
    required this.iconUrl,
    required this.vp,
    required this.commission,
    required this.apr,
    required this.minStake,
    required this.isLiquid,
    required this.description,
    required this.uptime,
  });
}

class ZilStakePage extends StatelessWidget {
  const ZilStakePage({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = appState.currentTheme;
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: theme.background,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: adaptivePadding),
                    child: CustomAppBar(
                      title: '',
                      onBackPressed: () => Navigator.pop(context),
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: adaptivePadding),
                    decoration: BoxDecoration(
                      color: theme.cardBackground,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TabBar(
                      labelColor: theme.textPrimary,
                      unselectedLabelColor: theme.textSecondary,
                      indicatorColor: theme.primaryPurple,
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      indicator: BoxDecoration(
                        color: theme.primaryPurple.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      labelStyle: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      unselectedLabelStyle: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      tabs: const [
                        Tab(text: 'Stake'),
                        Tab(text: 'Unstake'),
                        Tab(text: 'Migrate'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: TabBarView(
                      children: [
                        StakeTab(),
                        _buildComingSoonTab(theme, 'Unstake'),
                        _buildComingSoonTab(theme, 'Migrate'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildComingSoonTab(theme, String feature) {
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
            '$feature Coming Soon',
            style: TextStyle(
              color: theme.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This feature is under development',
            style: TextStyle(
              color: theme.textSecondary,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class StakeTab extends StatefulWidget {
  @override
  _StakeTabState createState() => _StakeTabState();
}

class _StakeTabState extends State<StakeTab> {
  StakingType selectedType = StakingType.liquid;
  SortType currentSort = SortType.vp;

  final List<StakingPool> pools = [
    StakingPool(
      name: 'Luganodes',
      token: 'LNZIL',
      iconUrl: 'https://stake.zilliqa.com/assets/luganodes.png',
      vp: 2.07,
      commission: 10,
      apr: 14.2,
      minStake: 1000,
      isLiquid: true,
      description: 'Liquid staking with instant rewards',
      uptime: 99.8,
    ),
    StakingPool(
      name: 'PlunderSwap',
      token: 'pZIL',
      iconUrl: 'https://stake.zilliqa.com/assets/plunderswap.png',
      vp: 2.04,
      commission: 8,
      apr: 15.1,
      minStake: 500,
      isLiquid: true,
      description: 'DeFi-integrated liquid staking',
      uptime: 99.5,
    ),
    StakingPool(
      name: 'stZIL Protocol',
      token: 'stZIL',
      iconUrl: 'https://stake.zilliqa.com/assets/stzil.png',
      vp: 1.89,
      commission: 8,
      apr: 14.8,
      minStake: 250,
      isLiquid: true,
      description: 'Community-driven liquid staking',
      uptime: 99.9,
    ),
    StakingPool(
      name: 'ZilPool',
      token: 'ZILP',
      iconUrl: 'https://stake.zilliqa.com/assets/zilpool.png',
      vp: 1.95,
      commission: 12,
      apr: 13.5,
      minStake: 100,
      isLiquid: true,
      description: 'Low barrier liquid staking',
      uptime: 99.3,
    ),
    StakingPool(
      name: 'ZilPay Validator',
      token: 'ZIL',
      iconUrl: 'https://stake.zilliqa.com/assets/zilpay.png',
      vp: 3.25,
      commission: 5,
      apr: 16.2,
      minStake: 10000,
      isLiquid: false,
      description: 'Traditional validator staking',
      uptime: 99.95,
    ),
    StakingPool(
      name: 'Moonlet Validator',
      token: 'ZIL',
      iconUrl: 'https://stake.zilliqa.com/assets/moonlet.png',
      vp: 2.85,
      commission: 7,
      apr: 15.8,
      minStake: 10000,
      isLiquid: false,
      description: 'Enterprise-grade validator',
      uptime: 99.7,
    ),
  ];

  Future<void> _onRefresh() async {
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pools updated successfully'),
          backgroundColor: Provider.of<AppState>(context, listen: false)
              .currentTheme
              .success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = appState.currentTheme;
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);

    List<StakingPool> filteredPools = pools
        .where((pool) => pool.isLiquid == (selectedType == StakingType.liquid))
        .toList();

    filteredPools.sort((a, b) {
      switch (currentSort) {
        case SortType.vp:
          return b.vp.compareTo(a.vp);
        case SortType.apr:
          return b.apr.compareTo(a.apr);
        case SortType.commission:
          return a.commission.compareTo(b.commission);
        case SortType.uptime:
          return b.uptime.compareTo(a.uptime);
      }
    });

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: adaptivePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStakingTypeSelector(theme),
          const SizedBox(height: 16),
          _buildSortOptions(theme),
          const SizedBox(height: 16),
          Expanded(
            child: filteredPools.isEmpty
                ? _buildEmptyState(theme)
                : RefreshIndicator(
                    onRefresh: _onRefresh,
                    color: theme.primaryPurple,
                    backgroundColor: theme.cardBackground,
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      itemCount: filteredPools.length,
                      itemBuilder: (context, index) {
                        final pool = filteredPools[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: StakingPoolCard(pool: pool),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStakingTypeSelector(theme) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.textSecondary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => selectedType = StakingType.liquid),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selectedType == StakingType.liquid
                      ? theme.primaryPurple
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      'assets/icons/currency.svg',
                      width: 16,
                      height: 16,
                      colorFilter: ColorFilter.mode(
                        selectedType == StakingType.liquid
                            ? theme.buttonText
                            : theme.textSecondary,
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Liquid Staking',
                      style: TextStyle(
                        color: selectedType == StakingType.liquid
                            ? theme.buttonText
                            : theme.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => selectedType = StakingType.regular),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selectedType == StakingType.regular
                      ? theme.primaryPurple
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      'assets/icons/anchor.svg',
                      width: 16,
                      height: 16,
                      colorFilter: ColorFilter.mode(
                        selectedType == StakingType.regular
                            ? theme.buttonText
                            : theme.textSecondary,
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Regular Staking',
                      style: TextStyle(
                        color: selectedType == StakingType.regular
                            ? theme.buttonText
                            : theme.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortOptions(theme) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: SortType.values.asMap().entries.map((entry) {
          final int index = entry.key;
          final SortType type = entry.value;

          String label;
          switch (type) {
            case SortType.vp:
              label = 'VP';
              break;
            case SortType.apr:
              label = 'APR';
              break;
            case SortType.commission:
              label = 'Commission';
              break;
            case SortType.uptime:
              label = 'Uptime';
              break;
          }

          final bool isSelected = currentSort == type;

          return Padding(
            padding: EdgeInsets.only(
              right: index < SortType.values.length - 1 ? 24 : 0,
            ),
            child: GestureDetector(
              onTap: () => setState(() => currentSort = type),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: isSelected
                    ? BoxDecoration(
                        color: theme.primaryPurple.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: theme.primaryPurple,
                          width: 1,
                        ),
                      )
                    : null,
                child: Text(
                  label,
                  style: TextStyle(
                    color:
                        isSelected ? theme.primaryPurple : theme.textSecondary,
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState(theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'assets/icons/anchor.svg',
            width: 64,
            height: 64,
            colorFilter: ColorFilter.mode(
              theme.textSecondary.withValues(alpha: 0.3),
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No pools available',
            style: TextStyle(
              color: theme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later for new staking opportunities',
            style: TextStyle(
              color: theme.textSecondary,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class StakingPoolCard extends StatelessWidget {
  final StakingPool pool;

  const StakingPoolCard({required this.pool});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = appState.currentTheme;

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
                        color: theme.background,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: AsyncImage(
                        url: pool.iconUrl,
                        width: 48,
                        height: 48,
                        fit: BoxFit.contain,
                        errorWidget: Container(
                          decoration: BoxDecoration(
                            color: theme.primaryPurple.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.account_balance,
                            color: theme.primaryPurple,
                            size: 24,
                          ),
                        ),
                        loadingWidget: Container(
                          decoration: BoxDecoration(
                            color: theme.textSecondary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  pool.name,
                                  style: TextStyle(
                                    color: theme.textPrimary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: pool.isLiquid
                                      ? theme.success.withValues(alpha: 0.1)
                                      : theme.primaryPurple
                                          .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  pool.token,
                                  style: TextStyle(
                                    color: pool.isLiquid
                                        ? theme.success
                                        : theme.primaryPurple,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            pool.description,
                            style: TextStyle(
                              color: theme.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        theme,
                        'VP',
                        '${pool.vp.toStringAsFixed(2)}%',
                        theme.primaryPurple,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        theme,
                        'APR',
                        '${pool.apr.toStringAsFixed(1)}%',
                        theme.success,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        theme,
                        'Commission',
                        '${pool.commission.toStringAsFixed(0)}%',
                        theme.textSecondary,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        theme,
                        'Uptime',
                        '${pool.uptime.toStringAsFixed(1)}%',
                        theme.textSecondary,
                      ),
                    ),
                  ],
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
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Min. Stake',
                        style: TextStyle(
                          color: theme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '${_formatAmount(pool.minStake)} ZIL',
                        style: TextStyle(
                          color: theme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                CustomButton(
                  text: 'Stake',
                  onPressed: () {
                    //
                  },
                  textColor: theme.buttonText,
                  backgroundColor: theme.primaryPurple,
                  borderRadius: 25.0,
                  height: 44.0,
                  width: 80.0,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(theme, String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: theme.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(0);
  }
}
