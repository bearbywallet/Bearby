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
import 'package:zilpay/src/rust/api/token.dart';
import 'package:zilpay/src/rust/api/utils.dart';
import 'package:zilpay/src/rust/api/wallet.dart';
import 'package:zilpay/src/rust/models/ftoken.dart';
import 'package:zilpay/src/rust/models/stake.dart';
import 'package:zilpay/src/rust/models/transactions/request.dart';
import 'package:zilpay/state/app_state.dart';
import 'package:zilpay/theme/app_theme.dart';

enum StakeOperationType {
  stake,
  unstake,
}

void showStakeModal({
  required BuildContext context,
  required FinalOutputInfo stake,
  required StakeOperationType opType,
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
    builder: (context) => StakeModalContent(
      stake: stake,
      opType: opType,
    ),
  ).then((_) => onDismiss?.call());
}

class StakeModalContent extends StatefulWidget {
  final FinalOutputInfo stake;
  final StakeOperationType opType;

  const StakeModalContent({
    super.key,
    required this.stake,
    required this.opType,
  });

  @override
  State<StakeModalContent> createState() => _StakeModalContentState();
}

class _StakeModalContentState extends State<StakeModalContent> {
  final TextEditingController _amountController = TextEditingController();
  final GlobalKey<SmartInputState> _amountInputKey =
      GlobalKey<SmartInputState>();

  late final bool _isStaking;
  BigInt _availableBalance = BigInt.zero;
  int _balanceDecimals = 18;

  @override
  void initState() {
    super.initState();
    _isStaking = widget.opType == StakeOperationType.stake;
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

      if (token == null) {
        throw Exception(
            "Native token not found for stake type ${widget.stake.tag}");
      }
      _balanceDecimals = token.decimals;

      if (_isStaking) {
        final selectedAccount = appState.wallet?.selectedAccount ?? BigInt.zero;
        _availableBalance =
            BigInt.tryParse(token.balances[selectedAccount] ?? '0') ??
                BigInt.zero;
      } else {
        _availableBalance =
            BigInt.tryParse(widget.stake.delegAmt) ?? BigInt.zero;
      }
    } catch (e) {
      debugPrint('Error loading balance: $e');
      _availableBalance = BigInt.zero;
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _setPercentageAmount(double percentage) {
    final amount =
        (_availableBalance * BigInt.from((percentage * 100).round())) ~/
            BigInt.from(100);

    final formattedAmount = fromWei(
      value: amount.toString(),
      decimals: _balanceDecimals,
    );

    _amountController.text = formattedAmount;
    _amountController.selection = TextSelection.fromPosition(
        TextPosition(offset: _amountController.text.length));
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
          onTap: () => FocusScope.of(context).unfocus(),
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
                        const SizedBox(height: 12),
                        _buildAdditionalInfo(theme, l10n),
                        const SizedBox(height: 20),
                        _buildAmountInput(theme, l10n),
                        const SizedBox(height: 16),
                        _buildPercentageButtons(theme),
                        const SizedBox(height: 24),
                        _buildActionButton(appState, l10n),
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
                padding: const EdgeInsets.all(14),
                child: SvgPicture.asset(
                  'assets/icons/zil.svg',
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
                    color: widget.stake.tag == 'scilla'
                        ? theme.success
                        : theme.primaryPurple,
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

  Widget _buildAdditionalInfo(AppTheme theme, AppLocalizations l10n) {
    String unbondingPeriodText;

    if (widget.stake.unbondingPeriod != null &&
        widget.stake.unbondingPeriod! > BigInt.zero) {
      final periodInBlocks = widget.stake.unbondingPeriod!;
      final seconds = (periodInBlocks.toDouble() * 1.5).round();
      final duration = Duration(seconds: seconds);
      final formattedDuration = _formatDuration(duration, l10n);
      unbondingPeriodText = '${periodInBlocks.toString()} ($formattedDuration)';
    } else {
      unbondingPeriodText = widget.stake.unbondingPeriod?.toString() ?? 'N/A';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(
          color: theme.textSecondary.withValues(alpha: 0.1),
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildInfoRow(
            theme,
            l10n.unbondingPeriod,
            unbondingPeriodText,
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            theme,
            l10n.currentBlock,
            widget.stake.currentBlock?.toString() ?? 'N/A',
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            theme,
            l10n.version,
            widget.stake.version ?? 'N/A',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(AppTheme theme, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: theme.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: theme.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
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
          _isStaking ? l10n.stakeButton : l10n.unstakeButton,
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

  Widget _buildActionButton(AppState appState, AppLocalizations l10n) {
    final theme = appState.currentTheme;

    return SizedBox(
      width: double.infinity,
      child: CustomButton(
        text: _isStaking ? l10n.stakeButton : l10n.unstakeButton,
        onPressed: () => _onConfirm(appState),
        backgroundColor: theme.primaryPurple,
        textColor: theme.buttonText,
        height: 56,
        borderRadius: 16,
      ),
    );
  }

  Future<void> _onConfirm(AppState appState) async {
    TransactionRequestInfo tx;

    try {
      final walletIndex = BigInt.from(appState.selectedWallet);
      final accountIndex = appState.wallet!.selectedAccount;
      final nativeToken = appState.wallet?.tokens.firstWhere((t) => t.native);

      if (nativeToken == null) {
        throw Exception("Native token not found.");
      }

      final (amount, _) = toWei(
        value: _amountController.text,
        decimals: _balanceDecimals,
      );

      if (widget.stake.tag == 'evm') {
        if (appState.account!.addrType == 0) {
          await zilliqaSwapChain(
            walletIndex: walletIndex,
            accountIndex: accountIndex,
          );
        }

        if (_isStaking) {
          print(widget.stake.token?.chainHash);
          tx = await buildTxEvmStakeRequest(
            walletIndex: walletIndex,
            accountIndex: accountIndex,
            stake: widget.stake,
            amount: amount,
          );

          if (widget.stake.token != null &&
              !appState.wallet!.tokens.any((token) =>
                  token.addr.toLowerCase() ==
                  widget.stake.address.toLowerCase())) {
            final newToken = FTokenInfo(
              name: widget.stake.token!.name,
              symbol: widget.stake.token!.symbol,
              decimals: widget.stake.token!.decimals,
              addr: widget.stake.token!.addr,
              addrType: widget.stake.token!.addrType,
              logo: widget.stake.token!.logo,
              balances: {},
              rate: 0,
              default_: false,
              native: false,
              chainHash: appState.chain!.chainHash,
            );
            await addFtoken(
              meta: newToken,
              walletIndex: BigInt.from(appState.selectedWallet),
            );
            await appState.syncData();
          }
        } else {
          tx = await buildTxEvmUnstakeRequest(
            walletIndex: walletIndex,
            accountIndex: accountIndex,
            stake: widget.stake,
            amountToUnstake: amount,
          );
        }
      } else {
        throw Exception("Invalid operation type: ${widget.stake.tag}");
      }

      if (!mounted) return;
      showConfirmTransactionModal(
        context: context,
        tx: tx,
        to: widget.stake.address,
        token: nativeToken,
        amount: "0",
        onConfirm: (_) {
          Navigator.of(context).pop();
          Navigator.of(context).pushNamed('/', arguments: {
            'selectedIndex': 1,
          });
        },
      );
    } catch (err) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: appState.currentTheme.cardBackground,
          title: Text(
            "Error",
            style: TextStyle(color: appState.currentTheme.textPrimary),
          ),
          content: Text(
            err.toString(),
            style: TextStyle(color: appState.currentTheme.danger),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                "OK",
                style: TextStyle(color: appState.currentTheme.primaryPurple),
              ),
            )
          ],
        ),
      );
    }
  }

  String _formatDuration(Duration duration, AppLocalizations l10n) {
    final days = duration.inDays;
    final hours = duration.inHours.remainder(24);
    final minutes = duration.inMinutes.remainder(60);

    final List<String> parts = [];
    if (days > 0) {
      parts.add('${days}${l10n.durationDay}');
    }
    if (hours > 0) {
      parts.add('${hours}${l10n.durationHour}');
    }
    if (minutes > 0) {
      parts.add('${minutes}${l10n.durationMinute}');
    }

    if (parts.isEmpty && duration.inSeconds > 0) {
      return l10n.durationLessThanAMinute;
    }

    if (parts.isEmpty) {
      return l10n.durationNotAvailable;
    }

    return '~${parts.take(2).join(' ')}';
  }
}
