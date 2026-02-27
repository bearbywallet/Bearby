import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:bearby/components/button.dart';
import 'package:bearby/components/detail_group_card.dart';
import 'package:bearby/components/detail_item_group_card.dart';
import 'package:bearby/components/hoverd_svg.dart';
import 'package:bearby/components/smart_input.dart';
import 'package:bearby/l10n/app_localizations.dart';
import 'package:bearby/src/rust/api/utils.dart';
import 'package:bearby/src/rust/models/gas.dart';
import 'package:bearby/state/app_state.dart';
import 'package:bearby/theme/app_theme.dart';

class EditGasDialog extends StatefulWidget {
  final RequiredTxParamsInfo txParamsInfo;
  final BigInt initialGasPrice;
  final BigInt initialMaxPriorityFee;
  final BigInt initialGasLimit;
  final BigInt initialNonce;
  final String? data;
  final Function(
          BigInt gasPrice, BigInt maxPriorityFee, BigInt gasLimit, BigInt nonce)
      onSave;

  final Color? primaryColor;
  final Color? textColor;
  final Color? secondaryColor;

  const EditGasDialog({
    super.key,
    required this.txParamsInfo,
    required this.initialGasPrice,
    required this.initialMaxPriorityFee,
    required this.initialGasLimit,
    required this.initialNonce,
    required this.onSave,
    this.primaryColor,
    this.textColor,
    this.secondaryColor,
    this.data,
  });

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

  String _normalizeDecimalInput(String value) {
    String normalized = value.replaceAll(',', '.');
    final parts = normalized.split('.');
    if (parts.length > 2) {
      final integerPart = parts.sublist(0, parts.length - 1).join('');
      final decimalPart = parts.last;
      normalized = '$integerPart.$decimalPart';
    }
    return normalized.trim();
  }

  void _handleSave() {
    try {
      final normalizedGasPrice = _normalizeDecimalInput(_gasPriceController.text);
      final normalizedGasLimit = _normalizeDecimalInput(_gasLimitController.text);
      final normalizedNonce = _normalizeDecimalInput(_nonceController.text);

      final gasPriceWei =
          BigInt.parse(toWei(value: normalizedGasPrice, decimals: 9).$1);
      final gasLimit = BigInt.parse(normalizedGasLimit.split('.').first);
      final nonce = BigInt.parse(normalizedNonce.split('.').first);

      BigInt maxPriorityFeeWei;
      if (!_isLegacy) {
        final normalizedMaxPriorityFee = _normalizeDecimalInput(_maxPriorityFeeController.text);
        maxPriorityFeeWei = BigInt.parse(
            toWei(value: normalizedMaxPriorityFee, decimals: 9).$1);
      } else {
        maxPriorityFeeWei = BigInt.zero;
      }

      final l10n = AppLocalizations.of(context)!;
      if (gasPriceWei < BigInt.zero ||
          maxPriorityFeeWei < BigInt.zero ||
          gasLimit <= BigInt.zero ||
          nonce < BigInt.zero) {
        throw ArgumentError(l10n.editGasDialogInvalidGasValues);
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
      final theme = Provider.of<AppState>(context, listen: false).currentTheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString(),
            style: theme.bodyText2.copyWith(color: Colors.white),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final theme = appState.currentTheme;
    final l10n = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: screenWidth > 600 ? 500 : 600),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.background,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.modalBorder, width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(l10n, theme),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildGasSettings(l10n, theme),
                      const SizedBox(height: 16),
                      _buildTransactionDetails(l10n, theme),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildActionButton(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n, AppTheme theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            l10n.editGasDialogTitle,
            style: theme.headline2.copyWith(color: theme.textPrimary),
          ),
          HoverSvgIcon(
            assetName: 'assets/icons/close.svg',
            onTap: () => Navigator.of(context).pop(),
            width: 20,
            height: 20,
            color: theme.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildGasSettings(AppLocalizations l10n, AppTheme theme) {
    return DetailGroupCard(
      title: 'Advanced Gas settings',
      theme: theme,
      contentPadding: const EdgeInsets.only(top: 16, left: 12, right: 12),
      children: [
        _buildInputField(
          label: l10n.editGasDialogGasPrice,
          controller: _gasPriceController,
          suffix: 'Gwei',
          theme: theme,
        ),
        if (!_isLegacy)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: _buildInputField(
              label: l10n.editGasDialogMaxPriorityFee,
              controller: _maxPriorityFeeController,
              suffix: 'Gwei',
              theme: theme,
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: _buildInputField(
            label: l10n.editGasDialogGasLimit,
            controller: _gasLimitController,
            isIntegerInput: true,
            theme: theme,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: _buildInputField(
            label: l10n.transactionDetailsModal_nonce,
            controller: _nonceController,
            isIntegerInput: true,
            theme: theme,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionDetails(AppLocalizations l10n, AppTheme theme) {
    return DetailGroupCard(
      title: l10n.transactionDetailsModal_transaction,
      theme: theme,
      children: [
        if (widget.data != null)
          DetailItem(
            label: 'Data',
            theme: theme,
            valueWidget: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    widget.data!,
                    style: theme.bodyText2.copyWith(color: theme.textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _buildCopyButton(widget.data!),
              ],
            ),
          ),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _buildActionButton(AppTheme theme) {
    return CustomButton(
      text: 'Update settings',
      onPressed: _handleSave,
      backgroundColor: widget.primaryColor ?? theme.primaryPurple,
      textColor: theme.buttonText,
      height: 52,
      borderRadius: 12,
    );
  }

  Widget _buildCopyButton(String textToCopy) {
    final theme = Provider.of<AppState>(context).currentTheme;
    return HoverSvgIcon(
      assetName: 'assets/icons/copy.svg',
      onTap: () {
        Clipboard.setData(ClipboardData(text: textToCopy));
      },
      width: 18,
      height: 18,
      color: theme.primaryPurple,
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required AppTheme theme,
    String? suffix,
    bool isIntegerInput = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: theme.bodyText2.copyWith(color: theme.textSecondary),
          ),
        ),
        SmartInput(
          height: 52,
          controller: controller,
          keyboardType: isIntegerInput
              ? TextInputType.number
              : const TextInputType.numberWithOptions(decimal: true),
          backgroundColor: theme.cardBackground,
          borderColor: theme.modalBorder.withValues(alpha: 0.5),
          textColor: theme.textPrimary,
          secondaryColor: theme.textSecondary,
        ),
      ],
    );
  }
}
