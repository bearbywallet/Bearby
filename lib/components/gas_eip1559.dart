import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/l10n/app_localizations.dart';
import 'package:zilpay/mixins/amount.dart';
import 'package:zilpay/mixins/gas_eip1559.dart';
import 'package:zilpay/src/rust/models/ftoken.dart';
import 'package:zilpay/src/rust/models/gas.dart';
import 'package:zilpay/src/rust/models/provider.dart';
import 'package:zilpay/state/app_state.dart';
import 'package:zilpay/theme/app_theme.dart';

extension GasFeeOptionX on GasFeeOption {
  String title(BuildContext context) {
    switch (this) {
      case GasFeeOption.low:
        return AppLocalizations.of(context)!.gasFeeOptionLow;
      case GasFeeOption.market:
        return AppLocalizations.of(context)!.gasFeeOptionMarket;
      case GasFeeOption.aggressive:
        return AppLocalizations.of(context)!.gasFeeOptionAggressive;
    }
  }

  int get blocksForConfirmation {
    switch (this) {
      case GasFeeOption.low:
        return 10;
      case GasFeeOption.market:
        return 5;
      case GasFeeOption.aggressive:
        return 2;
    }
  }

  String confirmationTime(int timeDiffBlock) {
    int seconds = blocksForConfirmation * timeDiffBlock;
    if (seconds < 60) {
      seconds = seconds == 0 ? 1 : seconds;
      return '~$seconds sec';
    } else {
      int minutes = (seconds / 60).round();
      return '~$minutes min';
    }
  }

  String get icon {
    switch (this) {
      case GasFeeOption.low:
        return '🐥';
      case GasFeeOption.market:
        return '🐼';
      case GasFeeOption.aggressive:
        return '👹';
    }
  }
}

class GasDetails extends StatelessWidget {
  final RequiredTxParamsInfo txParamsInfo;
  final GasFeeOption selectedOption;
  final FTokenInfo token;
  final AppTheme theme;
  final bool disabled;
  final Color? textColor;
  final Color? secondaryColor;

  const GasDetails({
    super.key,
    required this.txParamsInfo,
    required this.selectedOption,
    required this.token,
    required this.theme,
    required this.disabled,
    this.textColor,
    this.secondaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveTextColor = textColor ?? theme.textPrimary;
    final effectiveSecondaryColor = secondaryColor ?? theme.textSecondary;

    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.background,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              if (txParamsInfo.txEstimateGas != BigInt.zero)
                _buildDetailRow(
                  AppLocalizations.of(context)!.gasDetailsEstimatedGas,
                  '${txParamsInfo.txEstimateGas}',
                  effectiveTextColor,
                  effectiveSecondaryColor,
                ),
              _buildDetailRow(
                AppLocalizations.of(context)!.gasDetailsGasPrice,
                formatGasPriceDetail(
                  calculateGasPrice(selectedOption, txParamsInfo.gasPrice),
                  token,
                ),
                effectiveTextColor,
                effectiveSecondaryColor,
              ),
              if (txParamsInfo.feeHistory.baseFee != BigInt.zero)
                _buildDetailRow(
                  AppLocalizations.of(context)!.gasDetailsBaseFee,
                  formatGasPriceDetail(
                    txParamsInfo.feeHistory.baseFee,
                    token,
                  ),
                  effectiveTextColor,
                  effectiveSecondaryColor,
                ),
              if (txParamsInfo.maxPriorityFee != BigInt.zero)
                _buildDetailRow(
                  AppLocalizations.of(context)!.gasDetailsPriorityFee,
                  formatGasPriceDetail(
                    txParamsInfo.maxPriorityFee,
                    token,
                  ),
                  effectiveTextColor,
                  effectiveSecondaryColor,
                ),
              if (txParamsInfo.feeHistory.baseFee != BigInt.zero &&
                  txParamsInfo.maxPriorityFee != BigInt.zero)
                _buildDetailRow(
                  AppLocalizations.of(context)!.gasDetailsMaxFee,
                  formatGasPriceDetail(
                    txParamsInfo.feeHistory.baseFee +
                        txParamsInfo.maxPriorityFee,
                    token,
                  ),
                  effectiveTextColor,
                  effectiveSecondaryColor,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    Color textColor,
    Color secondaryColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.caption.copyWith(
              color: secondaryColor.withValues(alpha: disabled ? 0.5 : 1.0),
            ),
          ),
          Text(
            value,
            style: theme.caption.copyWith(
              color: textColor.withValues(alpha: disabled ? 0.5 : 1.0),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class GasEIP1559 extends StatefulWidget {
  final RequiredTxParamsInfo txParamsInfo;
  final Function(GasFeeOption option, BigInt selectedValue) onGasOptionChanged;
  final bool disabled;
  final int timeDiffBlock;
  final bool isBitcoin;
  final Color? primaryColor;
  final Color? textColor;
  final Color? secondaryColor;

  const GasEIP1559({
    super.key,
    required this.txParamsInfo,
    required this.onGasOptionChanged,
    required this.timeDiffBlock,
    this.isBitcoin = false,
    this.disabled = false,
    this.primaryColor,
    this.textColor,
    this.secondaryColor,
  });

  @override
  State<GasEIP1559> createState() => _GasEIP1559State();
}

class _GasEIP1559State extends State<GasEIP1559> with TickerProviderStateMixin {
  late final AnimationController _expandController;
  late final Animation<double> _expandAnimation;
  bool _isExpanded = false;
  GasFeeOption _selectedOption = GasFeeOption.market;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOut,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSelectedOption();
    });
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(GasEIP1559 oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.txParamsInfo != widget.txParamsInfo) {
      final current = widget.txParamsInfo.current;
      final slow = widget.txParamsInfo.slow;
      final market = widget.txParamsInfo.market;
      final fast = widget.txParamsInfo.fast;

      GasFeeOption? detectedOption;
      if (current == slow) {
        detectedOption = GasFeeOption.low;
      } else if (current == market) {
        detectedOption = GasFeeOption.market;
      } else if (current == fast) {
        detectedOption = GasFeeOption.aggressive;
      }

      if (detectedOption != null && _selectedOption != detectedOption) {
        setState(() {
          _selectedOption = detectedOption!;
        });
      }
    }
  }

  void _initializeSelectedOption() {
    final appState = Provider.of<AppState>(context, listen: false);
    _selectedOption = appState.selectedGasOption;
  }

  BigInt _getValueForOption(GasFeeOption option) {
    switch (option) {
      case GasFeeOption.low:
        return BigInt.parse(widget.txParamsInfo.slow);
      case GasFeeOption.market:
        return BigInt.parse(widget.txParamsInfo.market);
      case GasFeeOption.aggressive:
        return BigInt.parse(widget.txParamsInfo.fast);
    }
  }

  BigInt _calculateDisplayFee(GasFeeOption option) {
    final gasPriceForOption = _getValueForOption(option);

    if (gasPriceForOption == BigInt.zero) {
      return BigInt.zero;
    }

    if (widget.isBitcoin) {
      return gasPriceForOption;
    }

    final gasLimit = widget.txParamsInfo.txEstimateGas;
    if (gasLimit == BigInt.zero) {
      return BigInt.zero;
    }

    return gasLimit * gasPriceForOption;
  }

  void _handleOptionTap(GasFeeOption option) {
    if (widget.disabled) return;

    if (_selectedOption == option) {
      setState(() {
        _isExpanded = !_isExpanded;
        _isExpanded ? _expandController.forward() : _expandController.reverse();
      });
      return;
    }

    setState(() {
      _selectedOption = option;
      _isExpanded = false;
      _expandController.reverse();
    });

    final appState = Provider.of<AppState>(context, listen: false);
    appState.setSelectedGasOption(option);

    final selectedValue = _getValueForOption(option);
    widget.onGasOptionChanged(option, selectedValue);
  }

  Widget _buildGasOption({
    required GasFeeOption option,
    required Color optionTextColor,
    required AppState appState,
    required NetworkConfigInfo chain,
    required FTokenInfo token,
  }) {
    final theme = appState.currentTheme;
    final effectivePrimaryColor = widget.primaryColor ?? theme.primaryPurple;
    final effectiveTextColor = widget.textColor ?? theme.textPrimary;
    final effectiveSecondaryColor =
        widget.secondaryColor ?? theme.textSecondary;

    final isSelected = _selectedOption == option;
    final confirmationTime = option.confirmationTime(widget.timeDiffBlock);

    final totalGasFee = _calculateDisplayFee(option);
    final (normalizedGasFee, convertedGasFee) = formatingAmount(
      amount: totalGasFee,
      symbol: token.symbol,
      decimals: token.decimals,
      rate: token.rate,
      appState: appState,
    );

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(
        begin: 0.95,
        end: isSelected ? 1.0 : 0.95,
      ),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutQuart,
      builder: (context, value, child) => Transform.scale(
        scale: value,
        child: Opacity(
          opacity: widget.disabled ? 0.5 : 1.0,
          child: Semantics(
            button: true,
            label: '${option.title(context)} gas fee option',
            child: GestureDetector(
              onTap: widget.disabled ? null : () => _handleOptionTap(option),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? effectivePrimaryColor.withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(
                          option.icon,
                          style: theme.bodyText1,
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              option.title(context),
                              style: theme.bodyText1.copyWith(
                                color: effectiveTextColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              confirmationTime,
                              style: theme.caption.copyWith(
                                color: effectiveSecondaryColor,
                              ),
                            ),
                          ],
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '≈ $normalizedGasFee',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: theme.bodyText1.copyWith(
                                  color: optionTextColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                convertedGasFee,
                                style: theme.caption.copyWith(
                                  color: effectiveSecondaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (isSelected)
                      SizeTransition(
                        key: ValueKey('gas_details_$option'),
                        sizeFactor: _expandAnimation,
                        child: GasDetails(
                          txParamsInfo: widget.txParamsInfo,
                          selectedOption: option,
                          token: token,
                          theme: theme,
                          disabled: widget.disabled,
                          textColor: effectiveTextColor,
                          secondaryColor: effectiveSecondaryColor,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final theme = appState.currentTheme;
    final chain = appState.chain!;
    final token = appState.wallet!.tokens
        .firstWhere((t) => t.addrType == appState.account?.addrType);

    final warningColor = theme.warning;
    final textColor = widget.textColor ?? theme.textPrimary;
    final dangerColor = theme.danger;

    return Column(
      children: [
        if (_isExpanded || _selectedOption == GasFeeOption.low)
          _buildGasOption(
            option: GasFeeOption.low,
            optionTextColor: warningColor,
            appState: appState,
            chain: chain,
            token: token,
          ),
        if (_isExpanded || _selectedOption == GasFeeOption.market)
          _buildGasOption(
            option: GasFeeOption.market,
            optionTextColor: textColor,
            appState: appState,
            chain: chain,
            token: token,
          ),
        if (_isExpanded || _selectedOption == GasFeeOption.aggressive)
          _buildGasOption(
            option: GasFeeOption.aggressive,
            optionTextColor: dangerColor,
            appState: appState,
            chain: chain,
            token: token,
          ),
      ],
    );
  }
}
