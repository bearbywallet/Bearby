import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/src/rust/models/ftoken.dart';
import 'package:zilpay/src/rust/models/gas.dart';
import 'package:zilpay/src/rust/models/provider.dart';
import 'package:zilpay/state/app_state.dart';

enum GasFeeOption { low, market, aggressive }

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
        return '🐢';
      case GasFeeOption.market:
        return '🐉';
      case GasFeeOption.aggressive:
        return '👹';
    }
  }
}

class GasEIP1559 extends StatefulWidget {
  final GasInfo gasInfo;
  final Function(GasFeeOption type) onSelect;
  final GasFeeOption selected;

  const GasEIP1559({
    super.key,
    required this.gasInfo,
    required this.onSelect,
    this.selected = GasFeeOption.market,
  });

  @override
  State<GasEIP1559> createState() => _GasEIP1559State();
}

class _GasEIP1559State extends State<GasEIP1559>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isExpanded = false;
  late GasFeeOption _lastSelected;

  @override
  void initState() {
    super.initState();
    _lastSelected = widget.selected;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildGasOption({
    required GasFeeOption option,
    required BigInt fee,
    required Color textColor,
    required AppState appState,
    required NetworkConfigInfo chain,
    required FTokenInfo token,
  }) {
    final theme = appState.currentTheme;
    final isSelected = widget.selected == option;
    final value = fee / BigInt.from(10).pow(token.decimals);

    return GestureDetector(
      onTap: () {
        if (widget.selected == option) {
          setState(() {
            _isExpanded = !_isExpanded;
            if (_isExpanded) {
              _controller.forward();
            } else {
              _controller.reverse();
            }
          });
        } else {
          _lastSelected = option;
          widget.onSelect(option);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.primaryPurple.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
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
                ],
              ),
            ),
            Text(
              '${value.toStringAsFixed(5)} ${token.symbol}',
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = appState.currentTheme;
    final selectedOption = _isExpanded ? widget.selected : _lastSelected;
    final chain = appState.chain!;
    final token = appState.wallet!.tokens.first;

    return Column(
      children: [
        if (_isExpanded || selectedOption == GasFeeOption.low)
          _buildGasOption(
            option: GasFeeOption.low,
            fee: widget.gasInfo.feeHistory.baseFee,
            textColor: theme.warning,
            appState: appState,
            chain: chain,
            token: token,
          ),
        if (_isExpanded || selectedOption == GasFeeOption.market)
          _buildGasOption(
            option: GasFeeOption.market,
            fee: widget.gasInfo.feeHistory.maxFee,
            textColor: theme.success,
            appState: appState,
            chain: chain,
            token: token,
          ),
        if (_isExpanded || selectedOption == GasFeeOption.aggressive)
          _buildGasOption(
            option: GasFeeOption.aggressive,
            fee: widget.gasInfo.feeHistory.priorityFee +
                widget.gasInfo.feeHistory.maxFee,
            textColor: theme.danger,
            appState: appState,
            chain: chain,
            token: token,
          ),
      ],
    );
  }
}
