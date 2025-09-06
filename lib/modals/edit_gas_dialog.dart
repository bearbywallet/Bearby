import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/button.dart';
import 'package:zilpay/l10n/app_localizations.dart';
import 'package:zilpay/src/rust/api/utils.dart';
import 'package:zilpay/src/rust/models/gas.dart';
import 'package:zilpay/state/app_state.dart';
import 'package:zilpay/theme/app_theme.dart';

class EditGasDialog extends StatefulWidget {
  final RequiredTxParamsInfo txParamsInfo;
  final BigInt initialGasPrice;
  final BigInt initialMaxPriorityFee;
  final BigInt initialGasLimit;
  final BigInt initialNonce;
  final Function(
          BigInt gasPrice, BigInt maxPriorityFee, BigInt gasLimit, BigInt nonce)
      onSave;
  final Color? primaryColor;
  final Color? textColor;
  final Color? secondaryColor;

  const EditGasDialog({
    Key? key,
    required this.txParamsInfo,
    required this.initialGasPrice,
    required this.initialMaxPriorityFee,
    required this.initialGasLimit,
    required this.initialNonce,
    required this.onSave,
    this.primaryColor,
    this.textColor,
    this.secondaryColor,
  }) : super(key: key);

  @override
  State<EditGasDialog> createState() => _EditGasDialogState();
}

class _EditGasDialogState extends State<EditGasDialog> {
  late TextEditingController _gasPriceController;
  late TextEditingController _maxPriorityFeeController;
  late TextEditingController _gasLimitController;
  late TextEditingController _nonceController;
  late bool _isLegacy;

  @override
  void initState() {
    super.initState();
    _isLegacy = widget.txParamsInfo.feeHistory.baseFee == BigInt.zero;

    _gasPriceController = TextEditingController(
      text: fromWei(value: widget.initialGasPrice.toString(), decimals: 9),
    );
    _maxPriorityFeeController = TextEditingController(
      text:
          fromWei(value: widget.initialMaxPriorityFee.toString(), decimals: 9),
    );
    _gasLimitController = TextEditingController(
      text: widget.initialGasLimit.toString(),
    );
    _nonceController = TextEditingController(
      text: widget.initialNonce.toString(),
    );
  }

  @override
  void dispose() {
    _gasPriceController.dispose();
    _maxPriorityFeeController.dispose();
    _gasLimitController.dispose();
    _nonceController.dispose();
    super.dispose();
  }

  void _handleSave() {
    try {
      final (gasPriceWeiStr, _) =
          toWei(value: _gasPriceController.text, decimals: 9);
      final gasPriceWei = BigInt.parse(gasPriceWeiStr);

      final gasLimit = BigInt.parse(_gasLimitController.text);
      final nonce = BigInt.parse(_nonceController.text);

      BigInt maxPriorityFeeWei;
      if (!_isLegacy) {
        final (maxPriorityFeeWeiStr, _) =
            toWei(value: _maxPriorityFeeController.text, decimals: 9);
        maxPriorityFeeWei = BigInt.parse(maxPriorityFeeWeiStr);
      } else {
        maxPriorityFeeWei = BigInt.zero;
      }

      if (gasPriceWei < BigInt.zero ||
          maxPriorityFeeWei < BigInt.zero ||
          gasLimit <= BigInt.zero ||
          nonce < BigInt.zero) {
        throw ArgumentError(
            "Gas values cannot be negative or zero (for limit)");
      }
      if (!_isLegacy && maxPriorityFeeWei > gasPriceWei) {
        throw ArgumentError(
            "Max Priority Fee cannot be greater than Gas Price");
      }

      widget.onSave(
        gasPriceWei,
        maxPriorityFeeWei,
        gasLimit,
        nonce,
      );
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.editGasDialogInvalidGasValues,
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = appState.currentTheme;
    final l10n = AppLocalizations.of(context)!;

    final effectivePrimaryColor = widget.primaryColor ?? theme.primaryPurple;
    final effectiveTextColor = widget.textColor ?? theme.textPrimary;
    final effectiveSecondaryColor =
        widget.secondaryColor ?? theme.textSecondary;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.modalBorder, width: 1),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.editGasDialogTitle,
                    style: TextStyle(
                      color: effectiveTextColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  InkWell(
                    splashFactory: NoSplash.splashFactory,
                    highlightColor: Colors.transparent,
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      child: SvgPicture.asset(
                        'assets/icons/close.svg',
                        width: 18,
                        height: 18,
                        colorFilter: ColorFilter.mode(
                          effectiveTextColor,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildInputField(
                label: l10n.editGasDialogGasPrice,
                controller: _gasPriceController,
                hint: '0.0',
                suffix: 'Gwei',
                effectiveTextColor: effectiveTextColor,
                effectiveSecondaryColor: effectiveSecondaryColor,
                theme: theme,
              ),
              const SizedBox(height: 12),
              if (!_isLegacy)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInputField(
                      label: l10n.editGasDialogMaxPriorityFee,
                      controller: _maxPriorityFeeController,
                      hint: '0.0',
                      suffix: 'Gwei',
                      effectiveTextColor: effectiveTextColor,
                      effectiveSecondaryColor: effectiveSecondaryColor,
                      theme: theme,
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              _buildInputField(
                label: l10n.editGasDialogGasLimit,
                controller: _gasLimitController,
                hint: '21000',
                effectiveTextColor: effectiveTextColor,
                effectiveSecondaryColor: effectiveSecondaryColor,
                theme: theme,
                readOnly: false,
                isIntegerInput: true,
              ),
              const SizedBox(height: 12),
              _buildInputField(
                label: l10n.transactionDetailsModal_nonce,
                controller: _nonceController,
                hint: '0',
                effectiveTextColor: effectiveTextColor,
                effectiveSecondaryColor: effectiveSecondaryColor,
                theme: theme,
                readOnly: false,
                isIntegerInput: true,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: l10n.editGasDialogCancel,
                      onPressed: () => Navigator.of(context).pop(),
                      backgroundColor: theme.background,
                      textColor: effectiveTextColor,
                      height: 48,
                      borderRadius: 8,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomButton(
                      text: l10n.editGasDialogSave,
                      onPressed: _handleSave,
                      backgroundColor: effectivePrimaryColor,
                      textColor: theme.buttonText,
                      height: 48,
                      borderRadius: 8,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hint,
    String? suffix,
    required Color effectiveTextColor,
    required Color effectiveSecondaryColor,
    required AppTheme theme,
    bool readOnly = false,
    bool isIntegerInput = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: effectiveSecondaryColor,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: readOnly
                ? theme.background.withValues(alpha: 0.5)
                : theme.background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.modalBorder),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  readOnly: readOnly,
                  keyboardType: isIntegerInput
                      ? TextInputType.number
                      : const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(
                    color: effectiveTextColor,
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(
                      color: effectiveSecondaryColor.withValues(alpha: 0.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    border: InputBorder.none,
                  ),
                ),
              ),
              if (suffix != null)
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Text(
                    suffix,
                    style: TextStyle(
                      color: effectiveSecondaryColor,
                      fontSize: 14,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
