import 'package:flutter/material.dart';
import '../../components/smart_input.dart';
import '../../components/button.dart';
import '../../theme/app_theme.dart';

void showCustomNetworkModal({
  required BuildContext context,
  required AppTheme theme,
  required Function({
    required String networkName,
    required String rpcUrl,
    required String chainId,
    required String symbol,
    required String explorerUrl,
  }) onSave,
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
        child: _CustomNetworkModalContent(
          theme: theme,
          onSave: onSave,
        ),
      );
    },
  );
}

class _CustomNetworkModalContent extends StatefulWidget {
  final AppTheme theme;
  final Function({
    required String networkName,
    required String rpcUrl,
    required String chainId,
    required String symbol,
    required String explorerUrl,
  }) onSave;

  const _CustomNetworkModalContent({
    required this.theme,
    required this.onSave,
  });

  @override
  State<_CustomNetworkModalContent> createState() =>
      _CustomNetworkModalContentState();
}

class _CustomNetworkModalContentState
    extends State<_CustomNetworkModalContent> {
  final _networkNameController = TextEditingController();
  final _rpcUrlController = TextEditingController();
  final _chainIdController = TextEditingController();
  final _symbolController = TextEditingController();
  final _explorerUrlController = TextEditingController();

  @override
  void dispose() {
    _networkNameController.dispose();
    _rpcUrlController.dispose();
    _chainIdController.dispose();
    _symbolController.dispose();
    _explorerUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      decoration: BoxDecoration(
        color: widget.theme.cardBackground,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: widget.theme.textSecondary.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInputField(
                    controller: _networkNameController,
                    hint: 'Enter network name',
                  ),
                  _buildInputField(
                    controller: _rpcUrlController,
                    hint: 'Add a URL',
                  ),
                  _buildInputField(
                    controller: _chainIdController,
                    hint: 'Enter Chain ID',
                  ),
                  _buildInputField(
                    controller: _symbolController,
                    hint: 'Enter symbol',
                  ),
                  _buildInputField(
                    controller: _explorerUrlController,
                    hint: 'Add a URL',
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8 + bottomPadding),
            child: SizedBox(
              width: double.infinity,
              child: CustomButton(
                text: 'Save',
                onPressed: () {
                  widget.onSave(
                    networkName: _networkNameController.text,
                    rpcUrl: _rpcUrlController.text,
                    chainId: _chainIdController.text,
                    symbol: _symbolController.text,
                    explorerUrl: _explorerUrlController.text,
                  );
                  Navigator.pop(context);
                },
                backgroundColor: widget.theme.primaryPurple,
                borderRadius: 30.0,
                height: 50.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SmartInput(
            controller: controller,
            hint: hint,
            borderColor: widget.theme.textSecondary.withValues(alpha: 0.3),
            focusedBorderColor: widget.theme.primaryPurple,
            height: 48,
            fontSize: 16,
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
        ],
      ),
    );
  }
}
