import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/button.dart';
import 'package:zilpay/components/image_cache.dart';
import 'package:zilpay/l10n/app_localizations.dart';
import 'package:zilpay/mixins/amount.dart';
import 'package:zilpay/mixins/preprocess_url.dart';
import 'package:zilpay/modals/stake_modal.dart';
import 'package:zilpay/modals/transfer.dart';
import 'package:zilpay/src/rust/api/stake.dart';
import 'package:zilpay/src/rust/api/wallet.dart';
import 'package:zilpay/src/rust/models/stake.dart';
import 'package:zilpay/src/rust/models/transactions/request.dart';
import 'package:zilpay/state/app_state.dart';
import 'package:zilpay/theme/app_theme.dart';

class StakingPoolCard extends StatelessWidget {
  final FinalOutputInfo stake;

  const StakingPoolCard({super.key, required this.stake});

  bool get isLiquidStaking => stake.token != null;
  bool get isScilla => stake.tag == "scilla";
  bool get isOldAvely => stake.tag == 'avely';

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = appState.currentTheme;
    final l10n = AppLocalizations.of(context)!;
    final hasRewards = (int.tryParse(stake.rewards) ?? 0) > 0;
    final hasDelegation = (double.tryParse(stake.delegAmt) ?? 0) > 0;
    final showStakingInfo = hasRewards || hasDelegation;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.textSecondary.withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildCardHeader(theme, l10n),
                if (showStakingInfo) ...[
                  const SizedBox(height: 20),
                  _buildUserStakingInfo(theme, l10n, appState),
                  const SizedBox(height: 16),
                  _buildStatsRow(theme, l10n, appState),
                  if (isLiquidStaking) ...[
                    const SizedBox(height: 16),
                    _buildLiquidStakingInfo(theme, l10n, appState),
                  ],
                  if (hasRewards && !isLiquidStaking) ...[
                    const SizedBox(height: 16),
                    _buildClaimRewardsButton(context, theme, l10n, appState),
                  ],
                ] else ...[
                  const SizedBox(height: 16),
                  _buildStatsRow(theme, l10n, appState),
                ],
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: theme.textSecondary.withValues(alpha: 0.08),
                ),
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: _buildActionButtons(context, appState, l10n, hasDelegation),
          ),
        ],
      ),
    );
  }

  Widget _buildCardHeader(AppTheme theme, AppLocalizations l10n) {
    String urlTemplate =
        "https://raw.githubusercontent.com/zilpay/zilpay-cdn/refs/heads/main/stakeing/zilliqa/icons/%{address}%/%{dark,light}%.webp";
    final replacements = <String, String>{
      'address': stake.address.toLowerCase(),
    };

    return Row(
      children: [
        Stack(
          children: [
            AsyncImage(
              url: processUrlTemplate(
                template: urlTemplate,
                theme: theme.value,
                replacements: replacements,
              ),
              width: 56,
              height: 56,
              fit: BoxFit.contain,
              loadingWidget: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: theme.textSecondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: CupertinoActivityIndicator(radius: 12.0),
                ),
              ),
              errorWidget: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: theme.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SvgPicture.asset(
                  'assets/icons/zil.svg',
                  width: 28,
                  height: 28,
                  colorFilter: ColorFilter.mode(theme.warning, BlendMode.srcIn),
                ),
              ),
            ),
            Positioned(
              bottom: -2,
              right: -2,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: theme.cardBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.textSecondary.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: SvgPicture.asset(
                  isScilla || isOldAvely
                      ? 'assets/icons/scilla.svg'
                      : 'assets/icons/solidity.svg',
                  width: 16,
                  height: 16,
                  colorFilter: ColorFilter.mode(
                    theme.textPrimary,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      stake.name,
                      style: TextStyle(
                        color: theme.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: stake.tag == 'scilla'
                          ? theme.success.withValues(alpha: 0.1)
                          : theme.primaryPurple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      stake.tag.toUpperCase(),
                      style: TextStyle(
                        color: theme.primaryPurple,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if (isLiquidStaking) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: theme.primaryPurple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'LP',
                        style: TextStyle(
                          color: theme.primaryPurple,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUserStakingInfo(
    AppTheme theme,
    AppLocalizations l10n,
    AppState appState,
  ) {
    final hasRewards = (int.tryParse(stake.rewards) ?? 0) > 0;
    final hasDelegation = (int.tryParse(stake.delegAmt) ?? 0) > 0;

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.primaryPurple.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.primaryPurple.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: theme.primaryPurple.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SvgPicture.asset(
                        isLiquidStaking
                            ? 'assets/icons/piggy.svg'
                            : 'assets/icons/wallet.svg',
                        width: 16,
                        height: 16,
                        colorFilter: ColorFilter.mode(
                            theme.primaryPurple, BlendMode.srcIn),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isLiquidStaking
                            ? stake.token?.symbol ?? ""
                            : l10n.stakedAmount,
                        style: TextStyle(
                          color: theme.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildAmountDisplay(
                  theme,
                  isLiquidStaking
                      ? _formatTokenAmount(stake.delegAmt, appState,
                          isLSTToken: true)
                      : _formatTokenAmount(stake.delegAmt, appState),
                  hasDelegation ? theme.primaryPurple : theme.textSecondary,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isLiquidStaking
                  ? theme.primaryPurple.withValues(alpha: 0.06)
                  : hasRewards
                      ? theme.success.withValues(alpha: 0.06)
                      : theme.textSecondary.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isLiquidStaking
                    ? theme.primaryPurple.withValues(alpha: 0.1)
                    : hasRewards
                        ? theme.success.withValues(alpha: 0.1)
                        : theme.textSecondary.withValues(alpha: 0.08),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isLiquidStaking
                            ? theme.primaryPurple.withValues(alpha: 0.1)
                            : hasRewards
                                ? theme.success.withValues(alpha: 0.1)
                                : theme.textSecondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SvgPicture.asset(
                        'assets/icons/trophy.svg',
                        width: 16,
                        height: 16,
                        colorFilter: ColorFilter.mode(
                          isLiquidStaking
                              ? theme.primaryPurple
                              : hasRewards
                                  ? theme.success
                                  : theme.textSecondary,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isLiquidStaking
                            ? 'Yield ${stake.token?.symbol ?? ""}'
                            : l10n.rewardsAvailable,
                        style: TextStyle(
                          color: theme.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildAmountDisplay(
                  theme,
                  isLiquidStaking
                      ? _calculateLSTValue(appState)
                      : _formatTokenAmount(stake.rewards, appState),
                  isLiquidStaking
                      ? theme.primaryPurple
                      : hasRewards
                          ? theme.success
                          : theme.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLiquidStakingInfo(
    AppTheme theme,
    AppLocalizations l10n,
    AppState appState,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.primaryPurple.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.primaryPurple.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.primaryPurple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SvgPicture.asset(
                  'assets/icons/currency.svg',
                  width: 20,
                  height: 20,
                  colorFilter:
                      ColorFilter.mode(theme.primaryPurple, BlendMode.srcIn),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stake.token?.symbol ?? "",
                      style: TextStyle(
                        color: theme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatLSTPrice(appState),
                      style: TextStyle(
                        color: theme.primaryPurple,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Yield via Price',
                    style: TextStyle(
                      color: theme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Auto-compounding',
                    style: TextStyle(
                      color: theme.success,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmountDisplay(
    AppTheme theme,
    (String, String) values,
    Color valueColor,
  ) {
    final primaryValue = values.$1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          primaryValue,
          style: TextStyle(
            color: valueColor,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(
      AppTheme theme, AppLocalizations l10n, AppState appState) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: theme.textSecondary.withValues(alpha: 0.08),
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatItem(
            theme,
            "VP",
            stake.votePower == null || stake.votePower == 0
                ? 'N/A'
                : '${stake.votePower?.toStringAsFixed(1)}%',
            stake.votePower == null || stake.votePower == 0
                ? theme.textSecondary
                : theme.primaryPurple,
          ),
          _buildStatItem(
            theme,
            isLiquidStaking ? 'APR' : l10n.aprLabel,
            stake.apr == null || stake.apr == 0
                ? 'N/A'
                : '${stake.apr?.toStringAsFixed(1)}%',
            stake.apr == null || stake.apr == 0
                ? theme.textSecondary
                : theme.success,
          ),
          _buildStatItem(
            theme,
            l10n.commissionLabel,
            stake.commission == null || stake.commission == 0
                ? 'N/A'
                : '${stake.commission?.toStringAsFixed(1)}%',
            stake.commission == null || stake.commission == 0
                ? theme.textSecondary
                : theme.warning,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      AppTheme theme, String label, String value, Color valueColor) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: theme.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildClaimRewardsButton(
    BuildContext context,
    AppTheme theme,
    AppLocalizations l10n,
    AppState appState,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.success.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.success.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: SvgPicture.asset(
              'assets/icons/trophy.svg',
              width: 20,
              height: 20,
              colorFilter: ColorFilter.mode(theme.success, BlendMode.srcIn),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Available Rewards",
                  style: TextStyle(
                    color: theme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTokenAmount(stake.rewards, appState).$1,
                  style: TextStyle(
                    color: theme.success,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          CustomButton(
            text: l10n.claimButton,
            onPressed: () => _claimRewards(context, appState),
            textColor: theme.buttonText,
            backgroundColor: theme.success,
            borderRadius: 12,
            height: 40.0,
            width: 80,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    AppState appState,
    AppLocalizations l10n,
    bool hasDelegation,
  ) {
    final theme = appState.currentTheme;

    if (isScilla && !hasDelegation) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        if (!isOldAvely && !isScilla && hasDelegation && !isLiquidStaking) ...[
          Expanded(
            child: CustomButton(
              text: "Reinvest",
              onPressed: () => _reinvest(context, appState),
              textColor: theme.buttonText,
              backgroundColor: theme.primaryPurple,
              borderRadius: 16,
              height: 48.0,
            ),
          ),
          const SizedBox(width: 12),
        ],
        if (!isOldAvely && !isScilla) ...[
          Expanded(
            child: CustomButton(
              text: l10n.stakeButton,
              onPressed: () => _stake(context),
              textColor: theme.buttonText,
              backgroundColor: theme.primaryPurple,
              borderRadius: 16,
              height: 48.0,
            ),
          ),
          if (hasDelegation) const SizedBox(width: 12),
        ],
        if (hasDelegation) ...[
          Expanded(
            child: CustomButton(
              text: l10n.unstakeButton,
              onPressed: () => _initUnstake(context, appState),
              textColor: theme.buttonText,
              backgroundColor: theme.danger,
              borderRadius: 16,
              height: 48.0,
            ),
          ),
        ],
      ],
    );
  }

  (String, String) _formatTokenAmount(
    String amount,
    AppState appState, {
    bool isLSTToken = false,
  }) {
    final parsedAmount = BigInt.tryParse(amount) ?? BigInt.zero;

    if (isLSTToken && stake.token != null) {
      final token = stake.token!;
      final (formattedValue, converted) = formatingAmount(
        amount: parsedAmount,
        symbol: token.symbol,
        decimals: token.decimals,
        rate: token.rate,
        appState: appState,
        compact: true,
      );
      return (formattedValue, converted);
    } else {
      final nativeToken = appState.wallet?.tokens.firstWhere(
        (t) => t.native,
      );

      if (stake.token != null) {
        final (formattedValue, converted) = formatingAmount(
          amount: parsedAmount,
          symbol: stake.token!.symbol,
          decimals: stake.token!.decimals,
          rate: 0.0,
          appState: appState,
          compact: true,
        );
        return (formattedValue, converted);
      } else if (nativeToken != null) {
        int decimals = stake.tag == 'scilla' ? 12 : 18;

        final (formattedValue, converted) = formatingAmount(
          amount: parsedAmount,
          symbol: nativeToken.symbol,
          decimals: decimals,
          rate: 0,
          appState: appState,
          compact: true,
        );
        return (formattedValue, converted);
      }
    }

    return ("0", "0");
  }

  (String, String) _calculateLSTValue(AppState appState) {
    if (stake.token == null) return ("0", "0");

    final lstAmount = BigInt.tryParse(stake.delegAmt) ?? BigInt.zero;
    final lstPrice = stake.price ?? 1.0;
    final token = stake.token!;

    final lstAmountDouble =
        lstAmount.toDouble() / BigInt.from(10).pow(token.decimals).toDouble();
    final totalValueDouble = lstAmountDouble * lstPrice;

    final nativeToken = appState.wallet?.tokens.firstWhere(
      (t) => t.native,
    );

    if (nativeToken != null) {
      final totalValue = BigInt.from((totalValueDouble *
              BigInt.from(10).pow(nativeToken.decimals).toDouble())
          .toInt());

      final (formattedValue, converted) = formatingAmount(
        amount: totalValue,
        symbol: nativeToken.symbol,
        decimals: nativeToken.decimals,
        rate: nativeToken.rate,
        appState: appState,
      );
      return (formattedValue, converted);
    } else {
      final totalValue = BigInt.from((totalValueDouble * 1e18).toInt());
      final (formattedValue, converted) = formatingAmount(
        amount: totalValue,
        symbol: "ZIL",
        decimals: 18,
        rate: 0,
        appState: appState,
      );
      return (formattedValue, converted);
    }
  }

  String _formatLSTPrice(AppState appState) {
    final price = stake.price ?? 1.0;
    final nativeToken = appState.wallet?.tokens.firstWhere(
      (t) => t.native,
    );

    final symbol = nativeToken?.symbol ?? "ZIL";

    if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(2)}K $symbol';
    } else if (price >= 1) {
      return '${price.toStringAsFixed(4)} $symbol';
    } else {
      return '${price.toStringAsFixed(6)} $symbol';
    }
  }

  Future<void> _initUnstake(BuildContext context, AppState appState) async {
    try {
      final nativeToken = appState.wallet?.tokens.firstWhere(
        (t) => t.native,
        orElse: () => throw Exception('Native token not found'),
      );
      final walletIndex = BigInt.from(appState.selectedWallet);
      final accountIndex = appState.wallet!.selectedAccount;
      TransactionRequestInfo tx;

      if ((stake.tag == 'scilla' || stake.tag == 'avely') &&
          appState.account!.addrType == 1) {
        await zilliqaSwapChain(
          walletIndex: walletIndex,
          accountIndex: accountIndex,
        );
      } else if (stake.tag == 'evm' && appState.account!.addrType == 0) {
        await zilliqaSwapChain(
          walletIndex: walletIndex,
          accountIndex: accountIndex,
        );
      }

      if (stake.tag == 'scilla') {
        tx = await buildTxScillaInitUnstake(
          walletIndex: walletIndex,
          accountIndex: accountIndex,
          stake: stake,
        );
      } else if (stake.tag == 'avely') {
        tx = await buildTxScillaWithdrawStakeAvely(
          walletIndex: walletIndex,
          accountIndex: accountIndex,
          stake: stake,
        );
      } else if (stake.tag == 'evm') {
        tx = await buildTxEvmUnstakeRequest(
          walletIndex: walletIndex,
          accountIndex: accountIndex,
          stake: stake,
          amountToUnstake: stake.delegAmt,
        );
      } else {
        throw "invalid tx type";
      }

      showConfirmTransactionModal(
        context: context,
        tx: tx,
        to: stake.address,
        token: nativeToken!,
        amount: "0",
        onConfirm: (_) {
          Navigator.of(context).pushNamed('/', arguments: {
            'selectedIndex': 1,
          });
        },
      );
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: appState.currentTheme.cardBackground,
          title: Text(
            "Error",
            style: TextStyle(color: appState.currentTheme.textPrimary),
          ),
          content: Text(
            e.toString(),
            style: TextStyle(color: appState.currentTheme.danger),
          ),
          actions: [],
        ),
      );
    }
  }

  void _stake(BuildContext context) {
    showStakeModal(
      context: context,
      stake: stake,
    );
  }

  void _reinvest(BuildContext context, AppState appState) {}

  Future<void> _claimRewards(BuildContext context, AppState appState) async {
    try {
      final nativeToken = appState.wallet?.tokens.firstWhere(
        (t) => t.native,
        orElse: () => throw Exception('Native token not found'),
      );
      final walletIndex = BigInt.from(appState.selectedWallet);
      final accountIndex = appState.wallet!.selectedAccount;
      TransactionRequestInfo tx;

      if (stake.tag == 'scilla' && appState.account!.addrType == 1) {
        await zilliqaSwapChain(
          walletIndex: walletIndex,
          accountIndex: accountIndex,
        );
      } else if (stake.tag == 'evm' && appState.account!.addrType == 0) {
        await zilliqaSwapChain(
          walletIndex: walletIndex,
          accountIndex: accountIndex,
        );
      }

      if (stake.tag == 'scilla') {
        tx = await buildClaimScillaStakingRewardsTx(
          walletIndex: walletIndex,
          accountIndex: accountIndex,
          stake: stake,
        );
      } else if (stake.tag == 'evm') {
        tx = await buildTxClaimRewardRequest(
          walletIndex: walletIndex,
          accountIndex: accountIndex,
          stake: stake,
        );
      } else {
        throw "Invlid stake type";
      }

      showConfirmTransactionModal(
        context: context,
        tx: tx,
        to: stake.address,
        token: stake.token ?? nativeToken!,
        amount: "0",
        onConfirm: (_) {
          Navigator.of(context).pushNamed('/', arguments: {
            'selectedIndex': 1,
          });
        },
      );
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: appState.currentTheme.cardBackground,
          title: Text(
            "Error",
            style: TextStyle(color: appState.currentTheme.textPrimary),
          ),
          content: Text(
            e.toString(),
            style: TextStyle(color: appState.currentTheme.danger),
          ),
          actions: [],
        ),
      );
    }
  }
}
