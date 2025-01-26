import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/mixins/gas_eip1559.dart';
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

  String get confirmationTime {
    switch (this) {
      case GasFeeOption.low:
        return '~3-5 min';
      case GasFeeOption.market:
        return '~30-60 sec';
      case GasFeeOption.aggressive:
        return '~10-15 sec';
    }
  }
}

class GasEIP1559 extends StatefulWidget {
  final GasInfo gasInfo;
  final Function(BigInt maxPriorityFee) onChange;

  const GasEIP1559({
    super.key,
    required this.gasInfo,
    required this.onChange,
  });

  @override
  State<GasEIP1559> createState() => _GasEIP1559State();
}

class _GasEIP1559State extends State<GasEIP1559> with TickerProviderStateMixin {
  late final AnimationController _expandController;
  late final Animation<double> _expandAnimation;
  bool _isExpanded = false;
  GasFeeOption _selected = GasFeeOption.market;

  // Мемоизация часто используемых значений
  late final BigInt _initialMaxPriorityFee;

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

    _validateFees();
    _initialMaxPriorityFee = calculateMaxPriorityFee(
      _selected,
      widget.gasInfo.feeHistory.priorityFee,
    );
    widget.onChange(_initialMaxPriorityFee);
  }

  void _validateFees() {
    assert(
        widget.gasInfo.feeHistory.maxFee >= widget.gasInfo.feeHistory.baseFee,
        'Max fee must be greater than base fee');
    assert(
        widget.gasInfo.feeHistory.maxFee >=
            widget.gasInfo.feeHistory.priorityFee,
        'Max fee must be greater than priority fee');
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  void _handleOptionTap(GasFeeOption option) {
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
      widget.gasInfo.feeHistory.priorityFee,
    );
    widget.onChange(maxPriorityFee);
  }

  Widget _buildGasDetails(AppTheme theme, FTokenInfo token) {
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
              _buildDetailRow(
                'Estimated Gas:',
                '${widget.gasInfo.txEstimateGas}',
                theme,
              ),
              _buildDetailRow(
                'Base Fee:',
                formatGasPriceDetail(
                  widget.gasInfo.feeHistory.baseFee,
                  token,
                ),
                theme,
              ),
              _buildDetailRow(
                'Priority Fee:',
                formatGasPriceDetail(
                  calculateMaxPriorityFee(
                    _selected,
                    widget.gasInfo.feeHistory.priorityFee,
                  ),
                  token,
                ),
                theme,
              ),
              _buildDetailRow(
                'Max Fee:',
                formatGasPriceDetail(
                  calculateFeeForOption(
                    _selected,
                    widget.gasInfo.feeHistory.baseFee,
                    widget.gasInfo.feeHistory.priorityFee,
                  ),
                  token,
                ),
                theme,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, AppTheme theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: theme.textSecondary,
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: theme.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGasOption({
    required GasFeeOption option,
    required Color textColor,
    required AppState appState,
    required NetworkConfigInfo chain,
    required FTokenInfo token,
  }) {
    final theme = appState.currentTheme;
    final isSelected = _selected == option;

    final totalGasFee = calculateTotalGasCost(
      option,
      widget.gasInfo.feeHistory.baseFee,
      widget.gasInfo.feeHistory.priorityFee,
      widget.gasInfo.txEstimateGas,
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
        child: GestureDetector(
          onTap: () => _handleOptionTap(option),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.primaryPurple.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(option.icon, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            option.title,
                            style: TextStyle(
                              color: theme.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            option.confirmationTime,
                            style: TextStyle(
                              color: theme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          formatGasPrice(
                              totalGasFee, token.decimals, token.symbol),
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          option.description,
                          style: TextStyle(
                            color: theme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (isSelected)
                  SizeTransition(
                    sizeFactor: _expandAnimation,
                    child: _buildGasDetails(theme, token),
                  ),
              ],
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
    final token = appState.wallet!.tokens.first;

    return Column(
      children: [
        if (_isExpanded || _selected == GasFeeOption.low)
          _buildGasOption(
            option: GasFeeOption.low,
            textColor: theme.warning,
            appState: appState,
            chain: chain,
            token: token,
          ),
        if (_isExpanded || _selected == GasFeeOption.market)
          _buildGasOption(
            option: GasFeeOption.market,
            textColor: theme.textPrimary,
            appState: appState,
            chain: chain,
            token: token,
          ),
        if (_isExpanded || _selected == GasFeeOption.aggressive)
          _buildGasOption(
            option: GasFeeOption.aggressive,
            textColor: theme.danger,
            appState: appState,
            chain: chain,
            token: token,
          ),
      ],
    );
  }
}
