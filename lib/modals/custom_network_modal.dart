import 'package:flutter/material.dart';
import '../../components/smart_input.dart';
import '../../components/button.dart';
import '../../theme/app_theme.dart';

class CustomNetworkModal extends StatefulWidget {
  final AppTheme theme;
  final String initialUrl;
  final String initialChainId;
  final Function({required String url, required String chainId}) onSave;

  const CustomNetworkModal({
    super.key,
    required this.theme,
    required this.initialUrl,
    required this.initialChainId,
    required this.onSave,
  });

  @override
  State<CustomNetworkModal> createState() => _CustomNetworkModalState();
}

class _CustomNetworkModalState extends State<CustomNetworkModal> {
  late final TextEditingController _urlController;
  late final TextEditingController _chainIdController;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: widget.initialUrl);
    _chainIdController = TextEditingController(text: widget.initialChainId);
  }

  @override
  void dispose() {
    _urlController.dispose();
    _chainIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Configure Custom Network',
            style: TextStyle(
              color: widget.theme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          SmartInput(
            controller: _urlController,
            hint: 'Node URL',
            borderColor: widget.theme.textSecondary.withOpacity(0.3),
            focusedBorderColor: widget.theme.primaryPurple,
            height: 48,
            fontSize: 16,
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          const SizedBox(height: 16),
          SmartInput(
            controller: _chainIdController,
            hint: 'Chain ID',
            borderColor: widget.theme.textSecondary.withOpacity(0.3),
            focusedBorderColor: widget.theme.primaryPurple,
            height: 48,
            fontSize: 16,
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: 'Save',
              onPressed: () {
                widget.onSave(
                  url: _urlController.text,
                  chainId: _chainIdController.text,
                );
                Navigator.pop(context);
              },
              backgroundColor: widget.theme.primaryPurple,
              textColor: widget.theme.textPrimary,
              height: 48,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
