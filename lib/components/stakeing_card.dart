import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/button.dart';
import 'package:zilpay/components/image_cache.dart';
import 'package:zilpay/config/ftokens.dart';
import 'package:zilpay/l10n/app_localizations.dart';
import 'package:zilpay/mixins/amount.dart';
import 'package:zilpay/src/rust/models/stake.dart';
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
    final hasRewards = double.tryParse(stake.rewards.replaceAll(',', ''))! > 0;
    final hasDelegation =
        double.tryParse(stake.delegAmt.replaceAll(',', ''))! > 0;
    final isLP = stake.tokenAddress == zeroEVM;

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
            child: _buildActionButtons(theme, l10n, hasRewards, hasDelegation),
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
                child: Icon(Icons.broken_image, color: theme.danger, size: 28),
              ),
            ),
            // SVG иконка в зависимости от tag
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
                      ? "assets/icons/scilla.svg"
                      : "assets/icons/solidity.svg",
                  width: 16,
                  height: 16,
                  colorFilter: ColorFilter.mode(
                    stake.tag == 'scilla' ? theme.success : theme.primaryPurple,
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
                        color: stake.tag == 'scilla'
                            ? theme.success
                            : theme.primaryPurple,
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
    final hasRewards = double.tryParse(stake.rewards.replaceAll(',', ''))! > 0;
    final hasDelegation =
        double.tryParse(stake.delegAmt.replaceAll(',', ''))! > 0;

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
              Icons.account_balance_wallet_outlined,
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
              Icons.stars_outlined,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserStatItem(AppTheme theme, String label, String value,
      Color valueColor, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: valueColor,
        ),
        const SizedBox(height: 8),
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
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 16,
            fontWeight: FontWeight.w700,
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
            '${stake.votePower?.toStringAsFixed(1) ?? 0}%',
            theme.primaryPurple,
          ),
          _buildStatItem(
            theme,
            l10n.aprLabel,
            '${stake.apr?.toStringAsFixed(1) ?? 0}%',
            theme.success,
          ),
          _buildStatItem(
            theme,
            l10n.commissionLabel,
            '${stake.commission?.toStringAsFixed(1) ?? 0}%',
            theme.warning,
          ),
          _buildStatItem(
            theme,
            l10n.tvlLabel,
            _formatTvl(stake.tvl, appState),
            theme.textPrimary,
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

  Widget _buildActionButtons(AppTheme theme, AppLocalizations l10n,
      bool hasRewards, bool hasDelegation) {
    return Row(
      children: [
        if (hasRewards) ...[
          Expanded(
            child: CustomButton(
              text: l10n.claimButton(stake.rewards),
              onPressed: () {},
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
            onPressed: () {},
            textColor: theme.buttonText,
            backgroundColor: hasDelegation ? theme.danger : theme.primaryPurple,
            borderRadius: 16,
            height: 48.0,
          ),
        ),
      ],
    );
  }

  String _formatAmount(String amount, AppState appState) {
    final parsedAmount = double.tryParse(amount.replaceAll(',', '')) ?? 0.0;
    if (parsedAmount == 0) return '0';

    String symbol = "ZIL";
    int decimals = 18;

    try {
      final nativeToken = appState.wallet?.tokens
          .firstWhere((t) => t.native && t.addrType == 0);
      if (nativeToken != null) {
        symbol = nativeToken.symbol;
        decimals = nativeToken.decimals;
      }
    } catch (_) {}

    // Конвертируем в BigInt для форматирования
    final bigIntAmount = BigInt.from(parsedAmount * 1e18);

    final (formattedValue, _) = formatingAmount(
      amount: bigIntAmount,
      symbol: symbol,
      decimals: decimals,
      rate: 0,
      appState: appState,
    );

    return formattedValue.split(' ')[0];
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
