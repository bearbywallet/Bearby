import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/button.dart';
import 'package:zilpay/components/detail_group_card.dart';
import 'package:zilpay/components/detail_item_group_card.dart';
import 'package:zilpay/components/hoverd_svg.dart';
import 'package:zilpay/components/smart_input.dart';
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

  final String _solidityCodeExample =
      'function proofEncap(uint32 time, uint64 mileage, bytes32 blockHash) internal pure returns (uint256)';
  final String _dataExample = '0x03...EBC5';

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
      final gasPriceWei =
          BigInt.parse(toWei(value: _gasPriceController.text, decimals: 9).$1);
      final gasLimit = BigInt.parse(_gasLimitController.text);
      final nonce = BigInt.parse(_nonceController.text);

      BigInt maxPriorityFeeWei;
      if (!_isLegacy) {
        maxPriorityFeeWei = BigInt.parse(
            toWei(value: _maxPriorityFeeController.text, decimals: 9).$1);
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString(),
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
                      _buildSolidityView(theme),
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

  Widget _buildSolidityView(AppTheme theme) {
    return DetailGroupCard(
      title: 'Solidity',
      theme: theme,
      headerTrailing: _buildCopyButton(_solidityCodeExample),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.textSecondary.withValues(alpha: 0.2),
            ),
          ),
          child: RichText(
            text: TextSpan(
              style: theme.bodyText2.copyWith(
                fontFamily: 'Courier',
                color: theme.textPrimary,
              ),
              children: _buildHighlightedCode(),
            ),
          ),
        ),
      ],
    );
  }

  List<TextSpan> _buildHighlightedCode() {
    final theme = Provider.of<AppState>(context, listen: false).currentTheme;
    final keywordStyle =
        TextStyle(color: theme.secondaryPurple, fontWeight: FontWeight.bold);
    final typeStyle = TextStyle(color: theme.warning);
    final nameStyle = TextStyle(color: theme.textPrimary);
    final punctuationStyle = TextStyle(color: theme.textSecondary);

    return [
      TextSpan(text: 'function ', style: keywordStyle),
      TextSpan(text: 'proofEncap', style: nameStyle),
      TextSpan(text: '(', style: punctuationStyle),
      TextSpan(text: 'uint32', style: typeStyle),
      TextSpan(text: ' time, ', style: nameStyle),
      TextSpan(text: 'uint64', style: typeStyle),
      TextSpan(text: ' mileage, ', style: nameStyle),
      TextSpan(text: 'bytes32', style: typeStyle),
      TextSpan(text: ' blockHash', style: nameStyle),
      TextSpan(text: ') ', style: punctuationStyle),
      TextSpan(text: 'internal pure returns ', style: keywordStyle),
      TextSpan(text: '(', style: punctuationStyle),
      TextSpan(text: 'uint256', style: typeStyle),
      TextSpan(text: ')', style: punctuationStyle),
    ];
  }

  Widget _buildTransactionDetails(AppLocalizations l10n, AppTheme theme) {
    return DetailGroupCard(
      title: l10n.transactionDetailsModal_transaction,
      theme: theme,
      children: [
        DetailItem(label: 'Function', value: 'Transfer', theme: theme),
        const SizedBox(height: 8),
        DetailItem(
          label: 'To',
          theme: theme,
          valueWidget: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.danger.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Account 1',
              style: theme.caption.copyWith(
                color: theme.danger,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        DetailItem(label: 'Value', value: '100000', theme: theme),
        const SizedBox(height: 8),
        DetailItem(
          label: 'Data',
          theme: theme,
          valueWidget: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  _dataExample,
                  style: theme.bodyText2.copyWith(color: theme.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              _buildCopyButton(_dataExample),
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
