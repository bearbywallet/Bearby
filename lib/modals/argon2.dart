import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/button.dart';
import 'package:zilpay/components/smart_input.dart';
import 'package:zilpay/components/option_list.dart';
import 'package:zilpay/config/argon.dart';
import 'package:zilpay/src/rust/models/settings.dart';
import 'package:zilpay/state/app_state.dart';

void showArgonSettingsModal({
  required BuildContext context,
  required Function(WalletArgonParamsInfo) onParamsSelected,
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
        child: _ArgonSettingsModalContent(
          onParamsSelected: onParamsSelected,
        ),
      );
    },
  );
}

class _ArgonSettingsModalContent extends StatefulWidget {
  final Function(WalletArgonParamsInfo) onParamsSelected;

  const _ArgonSettingsModalContent({
    required this.onParamsSelected,
  });

  @override
  State<_ArgonSettingsModalContent> createState() =>
      _ArgonSettingsModalContentState();
}

class _ArgonSettingsModalContentState
    extends State<_ArgonSettingsModalContent> {
  final TextEditingController _secretController = TextEditingController();
  int selectedParamIndex = 1;

  final List<Map<String, String>> argonDescriptions = [
    {
      'title': 'Low Memory',
      'subtitle': '64KB RAM, 3 iterations',
      'description': 'Minimal memory usage, suitable for low-end devices.',
    },
    {
      'title': 'OWASP Default',
      'subtitle': '6.5MB RAM, 2 iterations',
      'description': 'Recommended by OWASP for general use.',
    },
    {
      'title': 'Secure',
      'subtitle': '256MB RAM, 4 iterations',
      'description': 'High security with increased memory and iterations.',
    },
  ];

  @override
  void dispose() {
    _secretController.dispose();
    super.dispose();
  }

  WalletArgonParamsInfo _getSelectedParams() {
    final secret = _secretController.text;
    switch (selectedParamIndex) {
      case 0:
        return Argon2DefaultParams.lowMemory(secret: secret);
      case 1:
        return Argon2DefaultParams.owaspDefault(secret: secret);
      case 2:
        return Argon2DefaultParams.secure(secret: secret);
      default:
        return Argon2DefaultParams.owaspDefault(secret: secret);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<AppState>(context).currentTheme;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      decoration: BoxDecoration(
        color: theme.cardBackground,
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
              color: theme.textSecondary.withOpacity(0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              physics: const BouncingScrollPhysics(),
              child: OptionsList(
                options: List.generate(
                  argonDescriptions.length,
                  (index) => OptionItem(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          argonDescriptions[index]['title']!,
                          style: TextStyle(
                            color: theme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          argonDescriptions[index]['subtitle']!,
                          style: TextStyle(
                            color: theme.primaryPurple,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          argonDescriptions[index]['description']!,
                          style: TextStyle(
                            color: theme.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    isSelected: selectedParamIndex == index,
                    onSelect: () => setState(() => selectedParamIndex = index),
                  ),
                ),
                unselectedOpacity: 0.5,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SmartInput(
              controller: _secretController,
              hint: 'Enter secret (optional)',
              borderColor: theme.textPrimary,
              focusedBorderColor: theme.primaryPurple,
              height: 48,
              fontSize: 16,
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8 + bottomPadding),
            child: SizedBox(
              width: double.infinity,
              child: CustomButton(
                text: 'Confirm',
                onPressed: () {
                  widget.onParamsSelected(_getSelectedParams());
                  Navigator.pop(context);
                },
                backgroundColor: theme.primaryPurple,
                borderRadius: 30.0,
                height: 50.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
