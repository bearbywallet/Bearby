import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/config/ftokens.dart';
import 'package:zilpay/mixins/gas_eip1559.dart';
import 'package:zilpay/src/rust/api/utils.dart';
import 'package:zilpay/src/rust/models/ftoken.dart';
import 'package:zilpay/src/rust/models/gas.dart';
import 'package:zilpay/src/rust/models/provider.dart';
import 'package:zilpay/state/app_state.dart';
import 'package:zilpay/theme/app_theme.dart';

extension GasFeeOptionX on GasFeeOption {
  String get title {
    switch (this) {
      case GasFeeOption.low:
        return 'Low';
      case GasFeeOption.market:
        return 'Market';
      case GasFeeOption.aggressive:
        return 'Aggressive';
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
    final seconds = blocksForConfirmation * timeDiffBlock;
    if (seconds < 60) {
      return '~$seconds sec';
    } else {
      final minutes = (seconds / 60).round();
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

  String get description {
    switch (this) {
      case GasFeeOption.low:
        return 'Slower but cheaper';
      case GasFeeOption.market:
        return 'Recommended';
      case GasFeeOption.aggressive:
        return 'Faster but expensive';
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
                  'Estimated Gas:',
                  '${txParamsInfo.txEstimateGas}',
                  effectiveTextColor,
                  effectiveSecondaryColor,
                ),
              _buildDetailRow(
                'Gas Price:',
                formatGasPriceDetail(
                  calculateGasPrice(selectedOption, txParamsInfo.gasPrice),
                  token,
                ),
                effectiveTextColor,
                effectiveSecondaryColor,
              ),
              if (txParamsInfo.feeHistory.baseFee != BigInt.zero)
                _buildDetailRow(
                  'Base Fee:',
                  formatGasPriceDetail(
                    txParamsInfo.feeHistory.baseFee,
                    token,
                  ),
                  effectiveTextColor,
                  effectiveSecondaryColor,
                ),
              if (txParamsInfo.feeHistory.priorityFee != BigInt.zero)
                _buildDetailRow(
                  'Priority Fee:',
                  formatGasPriceDetail(
                    calculateMaxPriorityFee(
                      selectedOption,
                      txParamsInfo.feeHistory.priorityFee,
                    ),
                    token,
                  ),
                  effectiveTextColor,
                  effectiveSecondaryColor,
                ),
              if (txParamsInfo.feeHistory.baseFee != BigInt.zero &&
                  txParamsInfo.feeHistory.priorityFee != BigInt.zero)
                _buildDetailRow(
                  'Max Fee:',
                  formatGasPriceDetail(
                    calculateFeeForOption(
                      selectedOption,
                      txParamsInfo.feeHistory.baseFee,
                      txParamsInfo.feeHistory.priorityFee,
                    ),
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
      String label, String value, Color textColor, Color secondaryColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: secondaryColor.withValues(alpha: disabled ? 0.5 : 1.0),
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: textColor.withValues(alpha: disabled ? 0.5 : 1.0),
              fontSize: 12,
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
  final Function(BigInt maxPriorityFee) onChangeMaxPriorityFee;
  final Function(BigInt gasPrice) onChangeGasPrice;
  final bool disabled;
  final int timeDiffBlock;
  final Color? primaryColor;
  final Color? textColor;
  final Color? secondaryColor;

  const GasEIP1559({
    super.key,
    required this.txParamsInfo,
    required this.onChangeMaxPriorityFee,
    required this.onChangeGasPrice,
    required this.timeDiffBlock,
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
  GasFeeOption _selected = GasFeeOption.market;

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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        BigInt maxPriorityFee = calculateMaxPriorityFee(
          _selected,
          widget.txParamsInfo.feeHistory.priorityFee,
        );
        BigInt gasPrice = calculateGasPrice(
          _selected,
          widget.txParamsInfo.gasPrice,
        );
        widget.onChangeMaxPriorityFee(maxPriorityFee);
        widget.onChangeGasPrice(gasPrice);
      });
    }
  }

  void _handleOptionTap(GasFeeOption option) {
    if (widget.disabled) return;

    if (_selected == option) {
      setState(() {
        _isExpanded = !_isExpanded;
        _isExpanded ? _expandController.forward() : _expandController.reverse();
      });
      return;
    }

    setState(() {
      _selected = option;
      _isExpanded = false;
      _expandController.reverse();
    });

    final maxPriorityFee = calculateMaxPriorityFee(
      option,
      widget.txParamsInfo.feeHistory.priorityFee,
    );
    widget.onChangeMaxPriorityFee(maxPriorityFee);
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

    final isSelected = _selected == option;
    final confirmationTime = option.confirmationTime(widget.timeDiffBlock);

    final totalGasFee = calculateTotalGasCost(
      option,
      widget.txParamsInfo.feeHistory.baseFee,
      widget.txParamsInfo.feeHistory.priorityFee,
      widget.txParamsInfo.txEstimateGas,
      widget.txParamsInfo.gasPrice,
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
            label: '${option.title} gas fee option',
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
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              option.title,
                              style: TextStyle(
                                color: effectiveTextColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              confirmationTime,
                              style: TextStyle(
                                color: effectiveSecondaryColor,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '≈ ${intlNumberFormating(
                                  value: totalGasFee.toString(),
                                  decimals: token.decimals,
                                  localeStr: appState.state.locale,
                                  symbolStr: token.symbol,
                                  threshold: baseThreshold,
                                  compact: appState.state.abbreviatedNumber,
                                )}',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: TextStyle(
                                  color: optionTextColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                option.description,
                                style: TextStyle(
                                  color: effectiveSecondaryColor,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (isSelected)
                      SizeTransition(
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
    final appState = Provider.of<AppState>(context);
    final theme = appState.currentTheme;
    final chain = appState.chain!;
    final token = appState.wallet!.tokens
        .firstWhere((t) => t.addrType == appState.account?.addrType);

    // Get the option-specific colors, using custom colors or falling back to theme
    final warningColor = theme.warning;
    final textColor = widget.textColor ?? theme.textPrimary;
    final dangerColor = theme.danger;

    return Column(
      children: [
        if (_isExpanded || _selected == GasFeeOption.low)
          _buildGasOption(
            option: GasFeeOption.low,
            optionTextColor: warningColor,
            appState: appState,
            chain: chain,
            token: token,
          ),
        if (_isExpanded || _selected == GasFeeOption.market)
          _buildGasOption(
            option: GasFeeOption.market,
            optionTextColor: textColor,
            appState: appState,
            chain: chain,
            token: token,
          ),
        if (_isExpanded || _selected == GasFeeOption.aggressive)
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
