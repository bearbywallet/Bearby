import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/smart_input.dart';
import 'package:zilpay/src/rust/models/transactions/evm.dart';
import 'package:zilpay/state/app_state.dart';
import '../theme/app_theme.dart' as theme;

void showSignParamsModal({
  required BuildContext context,
  required List<TransactionRequestEVM> transactions,
  required Function(List<TransactionRequestEVM>) onConfirm,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    enableDrag: true,
    isDismissible: true,
    useSafeArea: true,
    barrierColor: Colors.black54,
    builder: (BuildContext context) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _SignParamsModalContent(
          transactions: transactions,
          onConfirm: onConfirm,
        ),
      );
    },
  );
}

class _SignParamsModalContent extends StatefulWidget {
  final List<TransactionRequestEVM> transactions;
  final Function(List<TransactionRequestEVM>) onConfirm;

  const _SignParamsModalContent({
    required this.transactions,
    required this.onConfirm,
  });

  @override
  State<_SignParamsModalContent> createState() =>
      _SignParamsModalContentState();
}

class _SignParamsModalContentState extends State<_SignParamsModalContent> {
  late List<TransactionRequestEVM> _transactions;
  int _currentTxIndex = 0;
  bool _showHexData = false;

  final TextEditingController _gasLimitController = TextEditingController();
  final TextEditingController _gasPriceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _transactions = List.from(widget.transactions);
    _updateControllers();
  }

  void _updateControllers() {
    final tx = _transactions[_currentTxIndex];
    _gasLimitController.text = tx.gasLimit?.toString() ?? '';
    _gasPriceController.text = tx.gasPrice?.toString() ?? '';
  }

  void _updateTransaction({
    required TransactionRequestEVM currentTx,
    BigInt? newGasLimit,
    BigInt? newGasPrice,
  }) {
    setState(() {
      _transactions[_currentTxIndex] = TransactionRequestEVM(
        nonce: currentTx.nonce,
        from: currentTx.from,
        to: currentTx.to,
        value: currentTx.value,
        gasLimit: newGasLimit ?? currentTx.gasLimit,
        data: currentTx.data,
        maxFeePerGas: currentTx.maxFeePerGas,
        maxPriorityFeePerGas: currentTx.maxPriorityFeePerGas,
        gasPrice: newGasPrice ?? currentTx.gasPrice,
        chainId: currentTx.chainId,
        accessList: currentTx.accessList,
        blobVersionedHashes: currentTx.blobVersionedHashes,
        maxFeePerBlobGas: currentTx.maxFeePerBlobGas,
      );
    });
  }

  @override
  void dispose() {
    _gasLimitController.dispose();
    _gasPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<AppState>(context).currentTheme;
    final currentTx = _transactions[_currentTxIndex];

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(theme),
          if (widget.transactions.length > 1)
            _buildTransactionPagination(theme),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildAddressSection(theme, 'From', currentTx.from),
                _buildAddressSection(theme, 'To', currentTx.to),
                _buildValueSection(theme, currentTx),
                _buildGasSection(theme, currentTx),
                _buildDataSection(theme, currentTx),
                _buildAdditionalInfo(theme, currentTx),
              ],
            ),
          ),
          _buildBottomButtons(theme),
        ],
      ),
    );
  }

  Widget _buildHeader(theme.AppTheme theme) {
    return Column(
      children: [
        Container(
          width: 36,
          height: 4,
          margin: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: theme.textSecondary.withOpacity(0.5),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Confirm Transaction',
            style: TextStyle(
              color: theme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTransactionPagination(theme.AppTheme theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          widget.transactions.length,
          (index) => GestureDetector(
            onTap: () {
              setState(() {
                _currentTxIndex = index;
                _updateControllers();
              });
            },
            child: Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentTxIndex == index
                    ? theme.primaryPurple
                    : theme.textSecondary.withOpacity(0.3),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddressSection(
      theme.AppTheme theme, String title, String? address) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: theme.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.background,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  address ?? 'Not specified',
                  style: TextStyle(
                    color: theme.textPrimary,
                    fontSize: 16,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.copy, color: theme.textSecondary),
                onPressed: () {
                  if (address != null) {
                    Clipboard.setData(ClipboardData(text: address));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Address copied')),
                    );
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildValueSection(theme.AppTheme theme, TransactionRequestEVM tx) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Value',
          style: TextStyle(
            color: theme.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.background,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            tx.value ?? '0',
            style: TextStyle(
              color: theme.textPrimary,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildGasSection(
      theme.AppTheme theme, TransactionRequestEVM currentTx) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gas Parameters',
          style: TextStyle(
            color: theme.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: SmartInput(
                controller: _gasLimitController,
                hint: 'Gas Limit',
                onChanged: (value) {
                  try {
                    _updateTransaction(
                      currentTx: currentTx,
                      newGasLimit: BigInt.parse(value),
                    );
                  } catch (_) {}
                },
                borderColor: theme.textPrimary,
                focusedBorderColor: theme.primaryPurple,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SmartInput(
                controller: _gasPriceController,
                hint: 'Gas Price',
                onChanged: (value) {
                  try {
                    _updateTransaction(
                      currentTx: currentTx,
                      newGasPrice: BigInt.parse(value),
                    );
                  } catch (_) {}
                },
                borderColor: theme.textPrimary,
                focusedBorderColor: theme.primaryPurple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDataSection(theme.AppTheme theme, TransactionRequestEVM tx) {
    if (tx.data == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Data',
              style: TextStyle(
                color: theme.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() => _showHexData = !_showHexData);
              },
              child: Text(
                _showHexData ? 'Hide Hex' : 'Show Hex',
                style: TextStyle(
                  color: theme.primaryPurple,
                ),
              ),
            ),
          ],
        ),
        if (_showHexData) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '0x${tx.data!.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join()}',
              style: TextStyle(
                color: theme.textPrimary,
                fontSize: 14,
                fontFamily: 'MonoSpace',
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildAdditionalInfo(theme.AppTheme theme, TransactionRequestEVM tx) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (tx.chainId != null)
          _buildInfoRow(theme, 'Chain ID', tx.chainId.toString()),
        if (tx.nonce != null)
          _buildInfoRow(theme, 'Nonce', tx.nonce.toString()),
        if (tx.maxFeePerGas != null)
          _buildInfoRow(theme, 'Max Fee Per Gas', tx.maxFeePerGas.toString()),
        if (tx.maxPriorityFeePerGas != null)
          _buildInfoRow(
            theme,
            'Max Priority Fee Per Gas',
            tx.maxPriorityFeePerGas.toString(),
          ),
      ],
    );
  }

  Widget _buildInfoRow(theme.AppTheme theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: theme.textSecondary,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: theme.textPrimary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons(theme.AppTheme theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(
                  theme.background,
                ),
                padding: MaterialStateProperty.all(
                  const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: theme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextButton(
              onPressed: () {
                widget.onConfirm(_transactions);
                Navigator.pop(context);
              },
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(
                  theme.primaryPurple,
                ),
                padding: MaterialStateProperty.all(
                  const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              child: const Text(
                'Confirm',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
