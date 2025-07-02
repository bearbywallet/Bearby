import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/button.dart';
import 'package:zilpay/components/image_cache.dart';
import 'package:zilpay/components/smart_input.dart';
import 'package:zilpay/l10n/app_localizations.dart';
import 'package:zilpay/mixins/preprocess_url.dart';
import 'package:zilpay/modals/transfer.dart';
import 'package:zilpay/src/rust/api/stake.dart';
import 'package:zilpay/src/rust/api/utils.dart';
import 'package:zilpay/src/rust/api/wallet.dart';
import 'package:zilpay/src/rust/models/stake.dart';
import 'package:zilpay/src/rust/models/transactions/request.dart';
import 'package:zilpay/state/app_state.dart';
import 'package:zilpay/theme/app_theme.dart';

void showStakeModal({
  required BuildContext context,
  required FinalOutputInfo stake,
  VoidCallback? onDismiss,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    enableDrag: true,
    isDismissible: true,
    useSafeArea: true,
    barrierColor: Colors.black54,
    builder: (context) => StakeModalContent(stake: stake),
  ).then((_) => onDismiss?.call());
}

class StakeModalContent extends StatefulWidget {
  final FinalOutputInfo stake;

  const StakeModalContent({
    super.key,
    required this.stake,
  });

  @override
  State<StakeModalContent> createState() => _StakeModalContentState();
}

class _StakeModalContentState extends State<StakeModalContent> {
  final TextEditingController _amountController = TextEditingController();
  final GlobalKey<SmartInputState> _amountInputKey =
      GlobalKey<SmartInputState>();

  BigInt _availableBalance = BigInt.zero;
  int _balanceDecimals = 12;

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _loadBalance() {
    final appState = Provider.of<AppState>(context, listen: false);

    try {
      final token = appState.wallet?.tokens.firstWhere(
        (t) => t.native && t.addrType == (widget.stake.tag == 'scilla' ? 0 : 1),
      );

      if (token != null) {
        final selectedAccount = appState.wallet?.selectedAccount ?? BigInt.zero;
        _availableBalance =
            BigInt.tryParse(token.balances[selectedAccount] ?? '0') ??
                BigInt.zero;
        _balanceDecimals = token.decimals;
      }
    } catch (e) {
      debugPrint('Error loading balance: $e');
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _setPercentageAmount(double percentage) {
    final amount =
        (_availableBalance * BigInt.from((percentage * 100).toInt())) ~/
            BigInt.from(100);

    final formattedAmount = fromWei(
      value: amount.toString(),
      decimals: _balanceDecimals,
    );

    _amountController.text = formattedAmount;
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = appState.currentTheme;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: theme.modalBorder, width: 2),
      ),
      child: SafeArea(
        child: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          behavior: HitTestBehavior.translucent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: theme.modalBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      0,
                      16,
                      16 + MediaQuery.of(context).viewInsets.bottom,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(theme, l10n),
                        const SizedBox(height: 20),
                        _buildStakeInfo(theme, l10n),
                        const SizedBox(height: 20),
                        _buildAmountInput(theme, l10n),
                        const SizedBox(height: 16),
                        _buildPercentageButtons(theme),
                        const SizedBox(height: 16),
                        _buildStakeButton(appState, l10n),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppTheme theme, AppLocalizations l10n) {
    String urlTemplate =
        "https://raw.githubusercontent.com/zilpay/zilpay-cdn/refs/heads/main/stakeing/zilliqa/icons/%{address}%/%{dark,light}%.webp";
    final replacements = <String, String>{
      'address': widget.stake.address.toLowerCase(),
    };

    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.primaryPurple.withValues(alpha: 0.2),
              width: 2,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: AsyncImage(
              url: processUrlTemplate(
                template: urlTemplate,
                theme: theme.value,
                replacements: replacements,
              ),
              width: 56,
              height: 56,
              fit: BoxFit.contain,
              errorWidget: Container(
                color: theme.danger.withValues(alpha: 0.1),
                child: SvgPicture.asset(
                  'assets/icons/zil.svg',
                  width: 28,
                  height: 28,
                  colorFilter: ColorFilter.mode(theme.warning, BlendMode.srcIn),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.stake.name,
                style: TextStyle(
                  color: theme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.stake.tag == 'scilla'
                      ? theme.success.withValues(alpha: 0.1)
                      : theme.primaryPurple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.stake.tag.toUpperCase(),
                  style: TextStyle(
                    color: theme.primaryPurple,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStakeInfo(AppTheme theme, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: theme.textSecondary.withValues(alpha: 0.1),
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatItem(
            theme,
            "APR",
            widget.stake.apr == null || widget.stake.apr == 0
                ? 'N/A'
                : '${widget.stake.apr?.toStringAsFixed(1)}%',
            widget.stake.apr == null || widget.stake.apr == 0
                ? theme.textSecondary
                : theme.success,
          ),
          _buildStatItem(
            theme,
            l10n.commissionLabel,
            widget.stake.commission == null || widget.stake.commission == 0
                ? 'N/A'
                : '${widget.stake.commission?.toStringAsFixed(1)}%',
            widget.stake.commission == null || widget.stake.commission == 0
                ? theme.textSecondary
                : theme.warning,
          ),
          _buildStatItem(
            theme,
            "VP",
            widget.stake.votePower == null || widget.stake.votePower == 0
                ? 'N/A'
                : '${widget.stake.votePower?.toStringAsFixed(1)}%',
            widget.stake.votePower == null || widget.stake.votePower == 0
                ? theme.textSecondary
                : theme.primaryPurple,
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
              fontSize: 12,
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

  Widget _buildAmountInput(AppTheme theme, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.stakeButton,
          style: TextStyle(
            color: theme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        SmartInput(
          key: _amountInputKey,
          controller: _amountController,
          hint: '0.0',
          height: 56,
          fontSize: 18,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          borderColor: theme.textSecondary.withValues(alpha: 0.3),
          focusedBorderColor: theme.primaryPurple,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          rightIconPath: "assets/icons/zil.svg",
        ),
      ],
    );
  }

  Widget _buildPercentageButtons(AppTheme theme) {
    final percentages = [0.25, 0.50, 0.75, 1.0];
    final labels = ['25%', '50%', '75%', 'MAX'];

    return Row(
      children: percentages.asMap().entries.map((entry) {
        final index = entry.key;
        final percentage = entry.value;
        final label = labels[index];

        return Expanded(
          child: Padding(
            padding:
                EdgeInsets.only(right: index < percentages.length - 1 ? 8 : 0),
            child: GestureDetector(
              onTap: () => _setPercentageAmount(percentage),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: theme.primaryPurple.withValues(alpha: 0.3),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: theme.primaryPurple,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStakeButton(AppState appState, AppLocalizations l10n) {
    final theme = appState.currentTheme;

    return SizedBox(
      width: double.infinity,
      child: CustomButton(
        text: l10n.stakeButton,
        onPressed: () async {
          TransactionRequestInfo tx;

          try {
            final walletIndex = BigInt.from(appState.selectedWallet);
            final accountIndex = appState.wallet!.selectedAccount;

            if (widget.stake.tag == 'evm' && appState.account!.addrType == 0) {
              await zilliqaSwapChain(
                walletIndex: walletIndex,
                accountIndex: accountIndex,
              );
            }

            final nativeToken =
                appState.wallet?.tokens.firstWhere((t) => t.native);

            final (amount, _) = toWei(
              value: _amountController.text,
              decimals: nativeToken!.decimals,
            );

            if (widget.stake.tag == 'evm') {
              tx = await buildTxEvmStakeRequest(
                walletIndex: walletIndex,
                accountIndex: accountIndex,
                stake: widget.stake,
                amount: amount,
              );
            } else {
              throw "Invlid stake type";
            }

            if (!mounted) return;
            showConfirmTransactionModal(
              context: context,
              tx: tx,
              to: widget.stake.address,
              token: nativeToken,
              amount: _amountController.text,
              onConfirm: (_) {
                Navigator.of(context).pushNamed('/', arguments: {
                  'selectedIndex': 1,
                });
              },
            );
          } catch (err) {
            if (!mounted) return;

            String errorMessage = err.toString();

            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: appState.currentTheme.cardBackground,
                title: Text(
                  "Error",
                  style: TextStyle(color: appState.currentTheme.textPrimary),
                ),
                content: Text(
                  errorMessage,
                  style: TextStyle(color: appState.currentTheme.danger),
                ),
                actions: [],
              ),
            );
          }
        },
        backgroundColor: theme.primaryPurple,
        textColor: theme.buttonText,
        height: 56,
        borderRadius: 16,
      ),
    );
  }
}
