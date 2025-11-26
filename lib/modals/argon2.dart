import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/button.dart';
import 'package:zilpay/components/smart_input.dart';
import 'package:zilpay/components/option_list.dart';
import 'package:zilpay/config/argon.dart';
import 'package:zilpay/src/rust/models/settings.dart';
import 'package:zilpay/state/app_state.dart';
import 'package:zilpay/l10n/app_localizations.dart';

void showArgonSettingsModal({
  required BuildContext context,
  required Function(WalletArgonParamsInfo) onParamsSelected,
  required WalletArgonParamsInfo argonParams,
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
          argonParams: argonParams,
        ),
      );
    },
  );
}

class _ArgonSettingsModalContent extends StatefulWidget {
  final Function(WalletArgonParamsInfo) onParamsSelected;
  final WalletArgonParamsInfo argonParams;

  const _ArgonSettingsModalContent({
    required this.onParamsSelected,
    required this.argonParams,
  });

  @override
  State<_ArgonSettingsModalContent> createState() =>
      _ArgonSettingsModalContentState();
}

class _ArgonSettingsModalContentState
    extends State<_ArgonSettingsModalContent> {
  final TextEditingController _secretController = TextEditingController();
  bool _obscurePassword = true;

  late int selectedParamIndex;

  @override
  void initState() {
    super.initState();

    selectedParamIndex = _getInitialParamIndex();
    _secretController.text = widget.argonParams.secret;
  }

  int _getInitialParamIndex() {
    if (widget.argonParams ==
        Argon2DefaultParams.lowMemory(secret: widget.argonParams.secret)) {
      return 0;
    } else if (widget.argonParams ==
        Argon2DefaultParams.secure(secret: widget.argonParams.secret)) {
      return 2;
    }
    return 1; // OWASP Default
  }

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
    final localizations = AppLocalizations.of(context)!;

    final List<Map<String, String>> argonDescriptions = [
      {
        'title': localizations.argonSettingsModalContentLowMemoryTitle,
        'subtitle': localizations.argonSettingsModalContentLowMemorySubtitle,
        'description':
            localizations.argonSettingsModalContentLowMemoryDescription,
      },
      {
        'title': localizations.argonSettingsModalContentOwaspTitle,
        'subtitle': localizations.argonSettingsModalContentOwaspSubtitle,
        'description': localizations.argonSettingsModalContentOwaspDescription,
      },
      {
        'title': localizations.argonSettingsModalContentSecureTitle,
        'subtitle': localizations.argonSettingsModalContentSecureSubtitle,
        'description': localizations.argonSettingsModalContentSecureDescription,
      },
    ];

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: theme.modalBorder, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: theme.modalBorder,
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
                          style: theme.labelLarge.copyWith(color: theme.textPrimary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          argonDescriptions[index]['subtitle']!,
                          style: theme.labelMedium.copyWith(color: theme.primaryPurple),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          argonDescriptions[index]['description']!,
                          style: theme.bodyText2.copyWith(color: theme.textSecondary),
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
              obscureText: _obscurePassword,
              rightIconPath: _obscurePassword
                  ? "assets/icons/close_eye.svg"
                  : "assets/icons/open_eye.svg",
              hint: localizations.argonSettingsModalContentSecretHint,
              borderColor: theme.textPrimary,
              focusedBorderColor: theme.primaryPurple,
              height: 48,
              fontSize: 16,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              onRightIconTap: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8 + bottomPadding),
            child: SizedBox(
              width: double.infinity,
              child: CustomButton(
                textColor: theme.buttonText,
                backgroundColor: theme.primaryPurple,
                text: localizations.argonSettingsModalContentConfirmButton,
                onPressed: () {
                  widget.onParamsSelected(_getSelectedParams());
                  Navigator.pop(context);
                },
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
