import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/button.dart';
import 'package:zilpay/components/smart_input.dart';
import 'package:zilpay/components/option_list.dart';
import 'package:zilpay/config/argon.dart';
import 'package:zilpay/src/rust/models/settings.dart';
import 'package:zilpay/state/app_state.dart';
import 'package:zilpay/l10n/app_localizations.dart';

void showEncryptionSettingsModal({
  required BuildContext context,
  required int selectedCipherIndex,
  required WalletArgonParamsInfo argonParams,
  required Function(int cipherIndex, WalletArgonParamsInfo argonParams)
      onSettingsChanged,
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
        child: _EncryptionSettingsModalContent(
          selectedCipherIndex: selectedCipherIndex,
          argonParams: argonParams,
          onSettingsChanged: onSettingsChanged,
        ),
      );
    },
  );
}

class _EncryptionSettingsModalContent extends StatefulWidget {
  final int selectedCipherIndex;
  final WalletArgonParamsInfo argonParams;
  final Function(int cipherIndex, WalletArgonParamsInfo argonParams)
      onSettingsChanged;

  const _EncryptionSettingsModalContent({
    required this.selectedCipherIndex,
    required this.argonParams,
    required this.onSettingsChanged,
  });

  @override
  State<_EncryptionSettingsModalContent> createState() =>
      _EncryptionSettingsModalContentState();
}

class _EncryptionSettingsModalContentState
    extends State<_EncryptionSettingsModalContent> {
  final TextEditingController _secretController = TextEditingController();
  bool _obscurePassword = true;
  bool _showAdvanced = false;

  late int _selectedCipherIndex;
  late int _selectedArgonIndex;

  @override
  void initState() {
    super.initState();
    _selectedCipherIndex = widget.selectedCipherIndex;
    _selectedArgonIndex = _getInitialArgonIndex();
    _secretController.text = widget.argonParams.secret;
  }

  int _getInitialArgonIndex() {
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

  WalletArgonParamsInfo _getSelectedArgonParams() {
    final secret = _secretController.text;
    switch (_selectedArgonIndex) {
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
    final l10n = AppLocalizations.of(context)!;

    final List<Map<String, String>> cipherDescriptions = [
      {
        'title': l10n.cipherSettingsPageStandardTitle,
        'subtitle': l10n.cipherSettingsPageStandardSubtitle,
        'description': l10n.cipherSettingsPageStandardDescription,
      },
      {
        'title': l10n.cipherSettingsPageHybridTitle,
        'subtitle': l10n.cipherSettingsPageHybridSubtitle,
        'description': l10n.cipherSettingsPageHybridDescription,
      },
      {
        'title': l10n.cipherSettingsPageQuantumTitle,
        'subtitle': l10n.cipherSettingsPageQuantumSubtitle,
        'description': l10n.cipherSettingsPageQuantumDescription,
      },
    ];

    final List<Map<String, String>> argonDescriptions = [
      {
        'title': l10n.argonSettingsModalContentLowMemoryTitle,
        'subtitle': l10n.argonSettingsModalContentLowMemorySubtitle,
        'description': l10n.argonSettingsModalContentLowMemoryDescription,
      },
      {
        'title': l10n.argonSettingsModalContentOwaspTitle,
        'subtitle': l10n.argonSettingsModalContentOwaspSubtitle,
        'description': l10n.argonSettingsModalContentOwaspDescription,
      },
      {
        'title': l10n.argonSettingsModalContentSecureTitle,
        'subtitle': l10n.argonSettingsModalContentSecureSubtitle,
        'description': l10n.argonSettingsModalContentSecureDescription,
      },
    ];

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              l10n.cipherSettingsPageTitle,
              style: theme.titleLarge.copyWith(color: theme.textPrimary),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OptionsList(
                    options: List.generate(
                      cipherDescriptions.length,
                      (index) => OptionItem(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cipherDescriptions[index]['title']!,
                              style: theme.labelLarge
                                  .copyWith(color: theme.textPrimary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              cipherDescriptions[index]['subtitle']!,
                              style: theme.bodyText2
                                  .copyWith(color: theme.primaryPurple),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              cipherDescriptions[index]['description']!,
                              style: theme.bodyText2
                                  .copyWith(color: theme.textSecondary),
                            ),
                          ],
                        ),
                        isSelected: _selectedCipherIndex == index,
                        onSelect: () =>
                            setState(() => _selectedCipherIndex = index),
                      ),
                    ),
                    unselectedOpacity: 0.5,
                  ),
                  if (_selectedCipherIndex == 2)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        l10n.cipherSettingsPageQuantumWarning,
                        style: theme.bodyText2.copyWith(
                          color: theme.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () => setState(() => _showAdvanced = !_showAdvanced),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        l10n.cipherSettingsPageAdvancedButton,
                        style: theme.bodyLarge
                            .copyWith(color: theme.primaryPurple),
                      ),
                    ),
                  ),
                  AnimatedCrossFade(
                    firstChild: const SizedBox.shrink(),
                    secondChild: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          l10n.argonSettingsModalContentSecretHint,
                          style:
                              theme.bodyText2.copyWith(color: theme.textPrimary),
                        ),
                        const SizedBox(height: 8),
                        OptionsList(
                          options: List.generate(
                            argonDescriptions.length,
                            (index) => OptionItem(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    argonDescriptions[index]['title']!,
                                    style: theme.labelLarge
                                        .copyWith(color: theme.textPrimary),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    argonDescriptions[index]['subtitle']!,
                                    style: theme.labelMedium
                                        .copyWith(color: theme.primaryPurple),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    argonDescriptions[index]['description']!,
                                    style: theme.bodyText2
                                        .copyWith(color: theme.textSecondary),
                                  ),
                                ],
                              ),
                              isSelected: _selectedArgonIndex == index,
                              onSelect: () =>
                                  setState(() => _selectedArgonIndex = index),
                            ),
                          ),
                          unselectedOpacity: 0.5,
                        ),
                        const SizedBox(height: 16),
                        SmartInput(
                          controller: _secretController,
                          obscureText: _obscurePassword,
                          rightIconPath: _obscurePassword
                              ? "assets/icons/close_eye.svg"
                              : "assets/icons/open_eye.svg",
                          hint: l10n.argonSettingsModalContentSecretHint,
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
                      ],
                    ),
                    crossFadeState: _showAdvanced
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 200),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8 + bottomPadding),
            child: SizedBox(
              width: double.infinity,
              child: CustomButton(
                textColor: theme.buttonText,
                backgroundColor: theme.primaryPurple,
                text: l10n.cipherSettingsPageConfirmButton,
                onPressed: () {
                  widget.onSettingsChanged(
                    _selectedCipherIndex,
                    _getSelectedArgonParams(),
                  );
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
