import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/button.dart';
import 'package:zilpay/components/image_cache.dart';
import 'package:zilpay/config/ftokens.dart';
import 'package:zilpay/l10n/app_localizations.dart';
import 'package:zilpay/mixins/amount.dart';
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

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = appState.currentTheme;
    final l10n = AppLocalizations.of(context)!;
    final hasRewards = (double.tryParse(stake.rewards) ?? 0) > 0;
    final hasDelegation = (double.tryParse(stake.delegAmt) ?? 0) > 0;
    final isLP = stake.tokenAddress == null || stake.tokenAddress == zeroEVM;

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
                _buildCardHeader(theme, isLP, l10n),
                const SizedBox(height: 20),
                _buildUserStakingInfo(theme, l10n, appState),
                const SizedBox(height: 16),
                _buildStatsRow(theme, l10n, appState),
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
            child: _buildActionButtons(
                context, appState, l10n, hasRewards, hasDelegation),
          ),
        ],
      ),
    );
  }

  Widget _buildCardHeader(AppTheme theme, bool isLP, AppLocalizations l10n) {
    return Row(
      children: [
        Stack(
          children: [
            AsyncImage(
              url: stake.url,
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
                  stake.tag == 'scilla'
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
              if (isLP) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: theme.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    l10n.lpStakingBadge,
                    style: TextStyle(
                      color: theme.warning,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
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
      AppTheme theme, AppLocalizations l10n, AppState appState) {
    final hasRewards = (int.tryParse(stake.rewards) ?? 0) > 0;
    final hasDelegation = (int.tryParse(stake.delegAmt) ?? 0) > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.textSecondary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildUserStatItem(
              theme,
              l10n.stakedAmount,
              _formatAmount(stake.delegAmt, appState),
              hasDelegation ? theme.primaryPurple : theme.textSecondary,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: theme.textSecondary.withValues(alpha: 0.1),
          ),
          Expanded(
            child: _buildUserStatItem(
              theme,
              l10n.rewardsAvailable,
              _formatAmount(stake.rewards, appState),
              hasRewards ? theme.success : theme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserStatItem(
    AppTheme theme,
    String label,
    (String, String) values,
    Color valueColor,
  ) {
    final primaryValue = values.$1;
    final btcValue = values.$2;

    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: theme.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: primaryValue,
                style: TextStyle(
                  color: valueColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (btcValue.isNotEmpty)
                TextSpan(
                  text: '\n$btcValue',
                  style: TextStyle(
                    color: theme.textSecondary,
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          textAlign: TextAlign.center,
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
            l10n.aprLabel,
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
          _buildStatItem(
            theme,
            l10n.tvlLabel,
            stake.tvl == null ? 'N/A' : _formatTvl(stake.tvl, appState),
            stake.tvl == null ? theme.textSecondary : theme.textPrimary,
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

  Widget _buildActionButtons(
    BuildContext context,
    AppState appState,
    AppLocalizations l10n,
    bool hasRewards,
    bool hasDelegation,
  ) {
    final theme = appState.currentTheme;

    return Row(
      children: [
        if (hasRewards) ...[
          Expanded(
            child: CustomButton(
              text: l10n.claimButton,
              onPressed: () => _claimRewards(context, appState),
              textColor: theme.buttonText,
              backgroundColor: theme.success,
              borderRadius: 16,
              height: 48.0,
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: CustomButton(
            text: hasDelegation ? l10n.unstakeButton : l10n.stakeButton,
            onPressed: () => hasDelegation
                ? _initUnstake(context, appState)
                : _stake(context),
            textColor: theme.buttonText,
            backgroundColor: hasDelegation ? theme.danger : theme.primaryPurple,
            borderRadius: 16,
            height: 48.0,
          ),
        ),
      ],
    );
  }

  (String, String) _formatAmount(String amount, AppState appState) {
    final parsedAmount = BigInt.tryParse(amount) ?? BigInt.zero;

    String symbol = "ZIL";
    int decimals = stake.tag == 'scilla' ? 12 : 18;
    double rate = appState.wallet?.tokens.first.rate ?? 0;

    final (formattedValue, converted) = formatingAmount(
      amount: parsedAmount,
      symbol: symbol,
      decimals: decimals,
      rate: rate,
      appState: appState,
    );

    return (formattedValue, converted);
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
    return;
  }

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
}
