import 'dart:math';

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
import 'package:zilpay/utils/stake_formatters.dart';

class StakingPoolCard extends StatelessWidget {
  final FinalOutputInfo stake;

  const StakingPoolCard({super.key, required this.stake});

  bool get isLiquidStaking => stake.token != null;
  bool get isScilla => stake.tag == "scilla";
  bool get isEVM => stake.tag == 'evm';

  @override
  Widget build(BuildContext context) {
    return Selector<AppState, AppTheme>(
      selector: (_, state) => state.currentTheme,
      builder: (context, theme, _) {
        final l10n = AppLocalizations.of(context)!;
        final hasRewards = _hasPositiveValue(stake.rewards);
        final hasDelegation = _hasPositiveValue(stake.delegAmt);
        final hasClaimAmount = _hasPositiveValue(stake.claimableAmount);
        final showStakingInfo = hasRewards || hasDelegation || hasClaimAmount;
        final hasPendingWithdrawals = stake.pendingWithdrawals.isNotEmpty;

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
                    _CardHeader(stake: stake, theme: theme, l10n: l10n),
                    if (hasPendingWithdrawals) ...[
                      const SizedBox(height: 20),
                      _PendingWithdrawalsSection(
                        stake: stake,
                        theme: theme,
                        l10n: l10n,
                      ),
                    ],
                    if (showStakingInfo) ...[
                      const SizedBox(height: 20),
                      _UserStakingInfo(
                        stake: stake,
                        theme: theme,
                        l10n: l10n,
                      ),
                      const SizedBox(height: 16),
                      _StatsRow(stake: stake, theme: theme, l10n: l10n),
                      if (isLiquidStaking) ...[
                        const SizedBox(height: 16),
                        _LiquidStakingInfo(stake: stake, theme: theme),
                      ],
                      if (hasRewards) ...[
                        const SizedBox(height: 16),
                        _ClaimRewardsButton(
                          stake: stake,
                          theme: theme,
                          l10n: l10n,
                        ),
                      ],
                    ] else ...[
                      const SizedBox(height: 16),
                      _StatsRow(stake: stake, theme: theme, l10n: l10n),
                    ],
                  ],
                ),
              ),
              _ActionButtons(
                stake: stake,
                theme: theme,
                l10n: l10n,
                hasDelegation: hasDelegation,
              ),
            ],
          ),
        );
      },
    );
  }

  static bool _hasPositiveValue(String value) {
    return (BigInt.tryParse(value) ?? BigInt.zero) > BigInt.zero;
  }
}

class _CardHeader extends StatelessWidget {
  final FinalOutputInfo stake;
  final AppTheme theme;
  final AppLocalizations l10n;

  const _CardHeader({
    required this.stake,
    required this.theme,
    required this.l10n,
  });

  static const String urlTemplate =
      "https://raw.githubusercontent.com/zilpay/zilpay-cdn/refs/heads/main/stakeing/zilliqa/icons/%{address}%/%{dark,light}%.webp";

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _PoolIcon(stake: stake, theme: theme),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            stake.name,
            style: theme.subtitle1.copyWith(
              color: theme.textPrimary,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _PoolIcon extends StatelessWidget {
  final FinalOutputInfo stake;
  final AppTheme theme;

  const _PoolIcon({required this.stake, required this.theme});

  @override
  Widget build(BuildContext context) {
    final replacements = {'address': stake.address.toLowerCase()};

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AsyncImage(
        url: processUrlTemplate(
          template: _CardHeader.urlTemplate,
          theme: theme.value,
          replacements: replacements,
        ),
        width: 56,
        height: 56,
        fit: BoxFit.contain,
        loadingWidget: _LoadingIcon(theme: theme),
        errorWidget: _ErrorIcon(theme: theme),
      ),
    );
  }
}

class _LoadingIcon extends StatelessWidget {
  final AppTheme theme;

  const _LoadingIcon({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: theme.textSecondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: CupertinoActivityIndicator(radius: 12),
      ),
    );
  }
}

class _ErrorIcon extends StatelessWidget {
  final AppTheme theme;

  const _ErrorIcon({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}


class _PendingWithdrawalsSection extends StatelessWidget {
  final FinalOutputInfo stake;
  final AppTheme theme;
  final AppLocalizations l10n;

  const _PendingWithdrawalsSection({
    required this.stake,
    required this.theme,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.warning.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.warning.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PendingWithdrawalsHeader(
            count: stake.pendingWithdrawals.length,
            theme: theme,
            l10n: l10n,
          ),
          const SizedBox(height: 16),
          ...stake.pendingWithdrawals.asMap().entries.map(
                (entry) => Padding(
                  padding: EdgeInsets.only(
                    bottom: entry.key < stake.pendingWithdrawals.length - 1
                        ? 12
                        : 0,
                  ),
                  child: _PendingWithdrawalItem(
                    stake: stake,
                    item: entry.value,
                    theme: theme,
                    l10n: l10n,
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _PendingWithdrawalsHeader extends StatelessWidget {
  final int count;
  final AppTheme theme;
  final AppLocalizations l10n;

  const _PendingWithdrawalsHeader({
    required this.count,
    required this.theme,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: theme.warning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: SvgPicture.asset(
            'assets/icons/clock.svg',
            width: 16,
            height: 16,
            colorFilter: ColorFilter.mode(theme.warning, BlendMode.srcIn),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            l10n.pendingWithdrawals,
            style: theme.labelMedium.copyWith(
              color: theme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: theme.warning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: theme.labelSmall.copyWith(
              color: theme.warning,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class _PendingWithdrawalItem extends StatelessWidget {
  final FinalOutputInfo stake;
  final PendingWithdrawalInfo item;
  final AppTheme theme;
  final AppLocalizations l10n;

  const _PendingWithdrawalItem({
    required this.stake,
    required this.item,
    required this.theme,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();
    final currentBlock = stake.currentBlock ?? BigInt.zero;
    final withdrawalBlock = item.withdrawalBlock;
    final blocksRemaining = withdrawalBlock > currentBlock
        ? withdrawalBlock - currentBlock
        : BigInt.zero;
    final isClaimable = item.claimable || blocksRemaining == BigInt.zero;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isClaimable
              ? theme.success.withValues(alpha: 0.2)
              : theme.textSecondary.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.amount,
                      style: theme.labelSmall.copyWith(
                        color: theme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _TokenAmount(
                      amount: item.amount,
                      appState: appState,
                      style: theme.bodyLarge.copyWith(
                        color: theme.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              if (isClaimable)
                CustomButton(
                  text: l10n.claimButton,
                  onPressed: () => _claimWithdrawal(context, appState, item),
                  backgroundColor: theme.success,
                  textColor: theme.buttonText,
                  height: 36,
                  width: 80,
                  borderRadius: 12,
                ),
            ],
          ),
          if (!isClaimable && blocksRemaining > BigInt.zero) ...[
            const SizedBox(height: 12),
            _WithdrawalProgress(
              blocksRemaining: blocksRemaining,
              avgBlockTimeMs: stake.avgBlockTimeMs ?? BigInt.from(45000),
              theme: theme,
              l10n: l10n,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _claimWithdrawal(
    BuildContext context,
    AppState appState,
    PendingWithdrawalInfo item,
  ) async {
    try {
      final walletIndex = BigInt.from(appState.selectedWallet);
      final accountIndex = appState.wallet!.selectedAccount;
      final nativeToken = appState.wallet?.tokens.firstWhere(
        (t) => t.native,
        orElse: () => throw Exception('Native token not found'),
      );

      await _ensureCorrectChain(appState, walletIndex, accountIndex);

      if (!context.mounted) return;

      final tx = await _buildClaimTx(walletIndex, accountIndex);

      if (!context.mounted) return;

      showConfirmTransactionModal(
        context: context,
        tx: tx,
        to: stake.address,
        token: nativeToken!,
        amount: "0",
        onConfirm: (_) => _navigateToHistory(context),
      );
    } catch (e) {
      _showErrorDialog(context, appState, e);
    }
  }

  Future<void> _ensureCorrectChain(
    AppState appState,
    BigInt walletIndex,
    BigInt accountIndex,
  ) async {
    final isScilla = stake.tag == "scilla";
    final isEVM = stake.tag == 'evm';
    final addrType = appState.account?.addrType;

    if ((isScilla && addrType == 1) || (isEVM && addrType == 0)) {
      await zilliqaSwapChain(
        walletIndex: walletIndex,
        accountIndex: accountIndex,
      );
    }
  }

  Future<TransactionRequestInfo> _buildClaimTx(
    BigInt walletIndex,
    BigInt accountIndex,
  ) async {
    final isScilla = stake.tag == "scilla";

    if (isScilla) {
      return buildTxScillaCompleteWithdrawal(
        walletIndex: walletIndex,
        accountIndex: accountIndex,
        stake: stake,
      );
    }
    return buildTxClaimUnstakeRequest(
      walletIndex: walletIndex,
      accountIndex: accountIndex,
      stake: stake,
    );
  }

  void _navigateToHistory(BuildContext context) {
    Navigator.of(context).pushReplacementNamed('/', arguments: {
      'selectedIndex': 1,
    });
  }

  void _showErrorDialog(BuildContext context, AppState appState, Object e) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: appState.currentTheme.cardBackground,
        title: Text(
          "Error",
          style: appState.currentTheme.bodyLarge
              .copyWith(color: appState.currentTheme.textPrimary),
        ),
        content: Text(
          e.toString(),
          style: appState.currentTheme.bodyLarge
              .copyWith(color: appState.currentTheme.danger),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              "OK",
              style: appState.currentTheme.bodyLarge
                  .copyWith(color: appState.currentTheme.primaryPurple),
            ),
          ),
        ],
      ),
    );
  }
}

class _WithdrawalProgress extends StatelessWidget {
  final BigInt blocksRemaining;
  final BigInt avgBlockTimeMs;
  final AppTheme theme;
  final AppLocalizations l10n;

  const _WithdrawalProgress({
    required this.blocksRemaining,
    required this.avgBlockTimeMs,
    required this.theme,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final blockTimeSeconds = avgBlockTimeMs.toInt() / 1000;
    final totalSeconds = (blocksRemaining.toDouble() * blockTimeSeconds).round();
    final duration = Duration(seconds: totalSeconds);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${l10n.claimableIn} ${_formatDuration(duration)}',
          style: theme.labelSmall.copyWith(
            color: theme.warning,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: 0,
            backgroundColor: theme.textSecondary.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(theme.warning),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    }
    return '${duration.inSeconds}s';
  }
}

class _UserStakingInfo extends StatelessWidget {
  final FinalOutputInfo stake;
  final AppTheme theme;
  final AppLocalizations l10n;

  const _UserStakingInfo({
    required this.stake,
    required this.theme,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();
    final hasClaimableAmount =
        (BigInt.tryParse(stake.claimableAmount) ?? BigInt.zero) > BigInt.zero;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.primaryPurple.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.primaryPurple.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          _DelegatedAmountDisplay(
            stake: stake,
            theme: theme,
            l10n: l10n,
            appState: appState,
          ),
          if (hasClaimableAmount) ...[
            const SizedBox(height: 12),
            _ClaimableAmountCard(
              stake: stake,
              theme: theme,
              l10n: l10n,
              appState: appState,
            ),
          ],
        ],
      ),
    );
  }
}

class _DelegatedAmountDisplay extends StatelessWidget {
  final FinalOutputInfo stake;
  final AppTheme theme;
  final AppLocalizations l10n;
  final AppState appState;

  const _DelegatedAmountDisplay({
    required this.stake,
    required this.theme,
    required this.l10n,
    required this.appState,
  });

  @override
  Widget build(BuildContext context) {
    final delegatedAmountZil = _calculateDelegatedAmountInZil();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: theme.primaryPurple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: SvgPicture.asset(
                'assets/icons/piggy.svg',
                width: 14,
                height: 14,
                colorFilter: ColorFilter.mode(theme.primaryPurple, BlendMode.srcIn),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'Delegated',
              style: theme.labelSmall.copyWith(
                color: theme.textSecondary,
                fontSize: 10,
              ),
            ),
          ],
        ),
        Text(
          delegatedAmountZil,
          style: theme.bodyText2.copyWith(
            color: theme.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  String _calculateDelegatedAmountInZil() {
    final delegAmt = BigInt.tryParse(stake.delegAmt) ?? BigInt.zero;
    if (delegAmt == BigInt.zero) return '0 ZIL';

    final nativeToken = appState.wallet?.tokens.firstWhere((t) => t.native);
    final nativeSymbol = nativeToken?.symbol ?? 'ZIL';
    final nativeDecimals = nativeToken?.decimals ?? 18;

    if (stake.token != null) {
      final lstPrice = stake.token!.rate;
      final lstDecimals = stake.token!.decimals;
      final lstAmountDouble = delegAmt.toDouble() / pow(10, lstDecimals);
      final zilBackedDouble = lstAmountDouble * lstPrice;
      final zilBackedBigInt = BigInt.from(zilBackedDouble * pow(10, nativeDecimals));

      final (formatted, _) = formatingAmount(
        amount: zilBackedBigInt,
        symbol: nativeSymbol,
        decimals: nativeDecimals,
        rate: 0,
        appState: appState,
        compact: true,
      );
      return formatted;
    }

    final isScilla = stake.tag == "scilla";
    final decimals = isScilla ? 12 : nativeDecimals;

    final (formatted, _) = formatingAmount(
      amount: delegAmt,
      symbol: nativeSymbol,
      decimals: decimals,
      rate: 0,
      appState: appState,
      compact: true,
    );
    return formatted;
  }
}


class _ClaimableAmountCard extends StatelessWidget {
  final FinalOutputInfo stake;
  final AppTheme theme;
  final AppLocalizations l10n;
  final AppState appState;

  const _ClaimableAmountCard({
    required this.stake,
    required this.theme,
    required this.l10n,
    required this.appState,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.warning.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: theme.warning.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: SvgPicture.asset(
              'assets/icons/trophy.svg',
              width: 12,
              height: 12,
              colorFilter: ColorFilter.mode(theme.warning, BlendMode.srcIn),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Claimable',
                  style: theme.caption.copyWith(
                    color: theme.textSecondary,
                    fontSize: 9,
                  ),
                ),
                const SizedBox(height: 2),
                _TokenAmount(
                  amount: stake.claimableAmount,
                  appState: appState,
                  isLSTToken: true,
                  style: theme.bodyText2.copyWith(
                    color: theme.warning,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          CustomButton(
            text: l10n.claimButton,
            onPressed: () => _claimClaimableAmount(context, appState),
            backgroundColor: theme.warning,
            textColor: theme.buttonText,
            height: 28,
            width: 55,
            borderRadius: 8,
          ),
        ],
      ),
    );
  }

  Future<void> _claimClaimableAmount(
      BuildContext context, AppState appState) async {
    try {
      final walletIndex = BigInt.from(appState.selectedWallet);
      final accountIndex = appState.wallet!.selectedAccount;
      final nativeToken = appState.wallet?.tokens.firstWhere(
        (t) => t.native,
        orElse: () => throw Exception('Native token not found'),
      );

      if (stake.tag == 'evm' && appState.account!.addrType == 0) {
        await zilliqaSwapChain(
          walletIndex: walletIndex,
          accountIndex: accountIndex,
        );
      }

      final tx = await buildTxClaimUnstakeRequest(
        walletIndex: walletIndex,
        accountIndex: accountIndex,
        stake: stake,
      );

      if (!context.mounted) return;

      showConfirmTransactionModal(
        context: context,
        tx: tx,
        to: stake.address,
        token: stake.token ?? nativeToken!,
        amount: "0",
        onConfirm: (_) {
          Navigator.of(context).pushReplacementNamed('/', arguments: {
            'selectedIndex': 1,
          });
        },
      );
    } catch (e) {
      _showErrorDialog(context, appState, e);
    }
  }

  void _showErrorDialog(BuildContext context, AppState appState, Object e) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: appState.currentTheme.cardBackground,
        title: Text(
          "Error",
          style: appState.currentTheme.bodyLarge
              .copyWith(color: appState.currentTheme.textPrimary),
        ),
        content: Text(
          e.toString(),
          style: appState.currentTheme.bodyLarge
              .copyWith(color: appState.currentTheme.danger),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              "OK",
              style: appState.currentTheme.bodyLarge
                  .copyWith(color: appState.currentTheme.primaryPurple),
            ),
          ),
        ],
      ),
    );
  }
}

class _LiquidStakingInfo extends StatelessWidget {
  final FinalOutputInfo stake;
  final AppTheme theme;

  const _LiquidStakingInfo({required this.stake, required this.theme});

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();
    final hasGrowth = stake.lstPriceChangePercent != null;
    final growthColor = (stake.lstPriceChangePercent ?? 0) >= 0
        ? theme.success
        : theme.danger;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.primaryPurple.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.primaryPurple.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: theme.primaryPurple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: AsyncImage(
              url: processTokenLogo(
                token: stake.token!,
                shortName: appState.chain?.shortName ?? '',
                theme: theme.value,
              ),
              width: 20,
              height: 20,
              fit: BoxFit.contain,
              errorWidget: SvgPicture.asset(
                'assets/icons/warning.svg',
                width: 20,
                height: 20,
              ),
              loadingWidget: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${stake.token?.symbol ?? ""} Price",
                      style: theme.labelSmall.copyWith(
                        color: theme.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                    if (hasGrowth)
                      Text(
                        StakeFormatters.formatLstPriceChange(
                          stake.lstPriceChangePercent,
                        ),
                        style: theme.labelSmall.copyWith(
                          color: growthColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _formatLSTPrice(stake: stake, appState: appState),
                  style: theme.bodyText2.copyWith(
                    color: theme.primaryPurple,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatLSTPrice({
    required FinalOutputInfo stake,
    required AppState appState,
  }) {
    final price = stake.token?.rate ?? 1.0;
    final nativeToken = appState.wallet?.tokens.firstWhere((t) => t.native);
    final symbol = nativeToken?.symbol ?? "ZIL";

    if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(2)}K $symbol';
    } else if (price >= 1) {
      return '${price.toStringAsFixed(4)} $symbol';
    }
    return '${price.toStringAsFixed(6)} $symbol';
  }
}

class _StatsRow extends StatelessWidget {
  final FinalOutputInfo stake;
  final AppTheme theme;
  final AppLocalizations l10n;

  const _StatsRow({
    required this.stake,
    required this.theme,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final hasUnbonding = stake.unbondingPeriodSeconds != null &&
                         stake.unbondingPeriodSeconds! > BigInt.zero;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(
          color: theme.textSecondary.withValues(alpha: 0.08),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _CompactStatItem(
              label: "APR",
              value: StakeFormatters.formatApr(stake.apr),
              color: _getAprColor(stake.apr),
              theme: theme,
            ),
          ),
          Expanded(
            child: _CompactStatItem(
              label: l10n.commissionLabel,
              value: StakeFormatters.formatCommission(stake.commission),
              color: _getCommissionColor(stake.commission),
              theme: theme,
            ),
          ),
          if (hasUnbonding)
            Expanded(
              child: _CompactStatItem(
                label: "Unbonding",
                value: StakeFormatters.formatUnbondingPeriodCompact(
                  stake.unbondingPeriodSeconds,
                  l10n,
                ),
                color: theme.textSecondary,
                theme: theme,
              ),
            ),
        ],
      ),
    );
  }

  Color _getAprColor(double? apr) {
    if (apr == null || apr == 0) return theme.textSecondary;
    return theme.success;
  }

  Color _getCommissionColor(double? commission) {
    if (commission == null || commission == 0) return theme.textSecondary;
    return theme.warning;
  }
}

class _CompactStatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final AppTheme theme;

  const _CompactStatItem({
    required this.label,
    required this.value,
    required this.color,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.caption.copyWith(
            color: theme.textSecondary,
            fontSize: 9,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          value,
          style: theme.bodyText2.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}


class _ClaimRewardsButton extends StatelessWidget {
  final FinalOutputInfo stake;
  final AppTheme theme;
  final AppLocalizations l10n;

  const _ClaimRewardsButton({
    required this.stake,
    required this.theme,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();

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
                  l10n.rewardsAvailable,
                  style: theme.labelSmall.copyWith(
                    color: theme.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                _TokenAmount(
                  amount: stake.rewards,
                  appState: appState,
                  style: theme.bodyText2.copyWith(
                    color: theme.success,
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
            height: 40,
            width: 80,
          ),
        ],
      ),
    );
  }

  Future<void> _claimRewards(BuildContext context, AppState appState) async {
    try {
      final walletIndex = BigInt.from(appState.selectedWallet);
      final accountIndex = appState.wallet!.selectedAccount;
      final nativeToken = appState.wallet?.tokens.firstWhere(
        (t) => t.native,
        orElse: () => throw Exception('Native token not found'),
      );

      await _ensureCorrectChain(appState, walletIndex, accountIndex);

      if (!context.mounted) return;

      final tx = await _buildClaimRewardsTx(walletIndex, accountIndex);

      if (!context.mounted) return;

      showConfirmTransactionModal(
        context: context,
        tx: tx,
        to: stake.address,
        token: stake.token ?? nativeToken!,
        amount: "0",
        onConfirm: (_) => _navigateToHistory(context),
      );
    } catch (e) {
      _showErrorDialog(context, appState, e);
    }
  }

  Future<void> _ensureCorrectChain(
    AppState appState,
    BigInt walletIndex,
    BigInt accountIndex,
  ) async {
    final isScilla = stake.tag == "scilla";
    final isEVM = stake.tag == 'evm';
    final addrType = appState.account?.addrType;

    if ((isScilla && addrType == 1) || (isEVM && addrType == 0)) {
      await zilliqaSwapChain(
        walletIndex: walletIndex,
        accountIndex: accountIndex,
      );
    }
  }

  Future<TransactionRequestInfo> _buildClaimRewardsTx(
    BigInt walletIndex,
    BigInt accountIndex,
  ) async {
    final isScilla = stake.tag == "scilla";

    if (isScilla) {
      return buildClaimScillaStakingRewardsTx(
        walletIndex: walletIndex,
        accountIndex: accountIndex,
        stake: stake,
      );
    }
    return buildTxClaimRewardRequest(
      walletIndex: walletIndex,
      accountIndex: accountIndex,
      stake: stake,
    );
  }

  void _navigateToHistory(BuildContext context) {
    Navigator.of(context).pushReplacementNamed('/', arguments: {
      'selectedIndex': 1,
    });
  }

  void _showErrorDialog(BuildContext context, AppState appState, Object e) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: appState.currentTheme.cardBackground,
        title: Text(
          "Error",
          style: appState.currentTheme.bodyLarge
              .copyWith(color: appState.currentTheme.textPrimary),
        ),
        content: Text(
          e.toString(),
          style: appState.currentTheme.bodyLarge
              .copyWith(color: appState.currentTheme.danger),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              "OK",
              style: appState.currentTheme.bodyLarge
                  .copyWith(color: appState.currentTheme.primaryPurple),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final FinalOutputInfo stake;
  final AppTheme theme;
  final AppLocalizations l10n;
  final bool hasDelegation;

  const _ActionButtons({
    required this.stake,
    required this.theme,
    required this.l10n,
    required this.hasDelegation,
  });

  @override
  Widget build(BuildContext context) {
    final isScilla = stake.tag == "scilla";

    if (isScilla && !hasDelegation) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: theme.textSecondary.withValues(alpha: 0.08),
          ),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          if (!isScilla) ...[
            Expanded(
              child: CustomButton(
                text: l10n.stakeButton,
                onPressed: () => _stake(context),
                textColor: theme.buttonText,
                backgroundColor: theme.primaryPurple,
                borderRadius: 16,
                height: 48,
              ),
            ),
            if (hasDelegation) const SizedBox(width: 12),
          ],
          if (hasDelegation) ...[
            Expanded(
              child: CustomButton(
                text: l10n.unstakeButton,
                onPressed: () => _initUnstake(context),
                textColor: theme.buttonText,
                backgroundColor: theme.danger,
                borderRadius: 16,
                height: 48,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _stake(BuildContext context) {
    showStakeModal(
      opType: StakeOperationType.stake,
      context: context,
      stake: stake,
    );
  }

  Future<void> _initUnstake(BuildContext context) async {
    final appState = context.read<AppState>();

    try {
      final nativeToken = appState.wallet?.tokens.firstWhere(
        (t) => t.native,
        orElse: () => throw Exception('Native token not found'),
      );
      final walletIndex = BigInt.from(appState.selectedWallet);
      final accountIndex = appState.wallet!.selectedAccount;

      await _ensureCorrectChain(appState, walletIndex, accountIndex);

      if (!context.mounted) return;

      final isEVM = stake.tag == 'evm';

      if (isEVM) {
        showStakeModal(
          opType: StakeOperationType.unstake,
          context: context,
          stake: stake,
        );
        return;
      }

      final tx = await buildTxScillaInitUnstake(
        walletIndex: walletIndex,
        accountIndex: accountIndex,
        stake: stake,
      );

      if (!context.mounted) return;

      showConfirmTransactionModal(
        context: context,
        tx: tx,
        to: stake.address,
        token: nativeToken!,
        amount: "0",
        onConfirm: (_) => _navigateToHistory(context),
      );
    } catch (e) {
      _showErrorDialog(context, appState, e);
    }
  }

  Future<void> _ensureCorrectChain(
    AppState appState,
    BigInt walletIndex,
    BigInt accountIndex,
  ) async {
    final isScilla = stake.tag == "scilla";
    final isEVM = stake.tag == 'evm';
    final addrType = appState.account?.addrType;

    if ((isScilla && addrType == 1) || (isEVM && addrType == 0)) {
      await zilliqaSwapChain(
        walletIndex: walletIndex,
        accountIndex: accountIndex,
      );
    }
  }

  void _navigateToHistory(BuildContext context) {
    Navigator.of(context).pushReplacementNamed('/', arguments: {
      'selectedIndex': 1,
    });
  }

  void _showErrorDialog(BuildContext context, AppState appState, Object e) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: appState.currentTheme.cardBackground,
        title: Text(
          "Error",
          style: appState.currentTheme.bodyLarge
              .copyWith(color: appState.currentTheme.textPrimary),
        ),
        content: Text(
          e.toString(),
          style: appState.currentTheme.bodyLarge
              .copyWith(color: appState.currentTheme.danger),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              "OK",
              style: appState.currentTheme.bodyLarge
                  .copyWith(color: appState.currentTheme.primaryPurple),
            ),
          ),
        ],
      ),
    );
  }
}

class _TokenAmount extends StatelessWidget {
  final String amount;
  final AppState appState;
  final TextStyle style;
  final bool isLSTToken;

  const _TokenAmount({
    required this.amount,
    required this.appState,
    required this.style,
    this.isLSTToken = false,
  });

  @override
  Widget build(BuildContext context) {
    final formatted = _formatAmount();
    return Text(formatted.$1, style: style);
  }

  (String, String) _formatAmount() {
    final parsedAmount = BigInt.tryParse(amount) ?? BigInt.zero;

    if (isLSTToken) {
      return _formatLSTAmount(parsedAmount);
    }
    return _formatNativeAmount(parsedAmount);
  }

  (String, String) _formatLSTAmount(BigInt parsedAmount) {
    final token = appState.wallet?.tokens.firstWhere(
      (t) => t.addr == stake?.token?.addr,
      orElse: () => appState.wallet!.tokens.first,
    );

    return formatingAmount(
      amount: parsedAmount,
      symbol: token?.symbol ?? 'ZIL',
      decimals: token?.decimals ?? 18,
      rate: token?.rate ?? 0.0,
      appState: appState,
      compact: true,
    );
  }

  (String, String) _formatNativeAmount(BigInt parsedAmount) {
    final nativeToken = appState.wallet?.tokens.firstWhere((t) => t.native);

    if (nativeToken == null) return ("0", "0");

    return formatingAmount(
      amount: parsedAmount,
      symbol: nativeToken.symbol,
      decimals: nativeToken.decimals,
      rate: 0,
      appState: appState,
      compact: true,
    );
  }

  FinalOutputInfo? get stake {
    final element = context?.findAncestorWidgetOfExactType<StakingPoolCard>();
    return element?.stake;
  }

  BuildContext? get context {
    return null;
  }
}
