import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/src/rust/api/book.dart';
import 'package:zilpay/state/app_state.dart';
import '../../components/button.dart';
import '../../components/smart_input.dart';
import 'package:zilpay/l10n/app_localizations.dart';

void showAddContactModal({
  required BuildContext context,
  required AppState state,
  VoidCallback? onDismiss,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    enableDrag: true,
    isDismissible: true,
    useSafeArea: true,
    barrierColor: Colors.black54,
    builder: (context) => AddAddressModal(
      state: state,
    ),
  ).then((_) => onDismiss?.call());
}

class AddAddressModal extends StatefulWidget {
  final AppState state;

  const AddAddressModal({
    super.key,
    required this.state,
  });

  @override
  State<AddAddressModal> createState() => _AddAddressModalState();
}

class _AddAddressModalState extends State<AddAddressModal> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _nameInputKey = GlobalKey<SmartInputState>();
  final _addressInputKey = GlobalKey<SmartInputState>();

  bool _isDisabled = false;
  String _errorMessage = '';

  static const double _inputHeight = 50.0;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  bool _validateInputs() {
    if (_nameController.text.isEmpty) {
      _nameInputKey.currentState?.shake();
      setState(() {
        _errorMessage =
            AppLocalizations.of(context)!.addAddressModalNameEmptyError;
        _isDisabled = false;
      });
      return false;
    }
    if (_addressController.text.isEmpty) {
      _addressInputKey.currentState?.shake();
      setState(() {
        _errorMessage =
            AppLocalizations.of(context)!.addAddressModalAddressEmptyError;
        _isDisabled = false;
      });
      return false;
    }
    return true;
  }

  Future<void> _handleAddAddress(AppState appState) async {
    setState(() {
      _errorMessage = '';
      _isDisabled = true;
    });

    if (!_validateInputs() || appState.chain == null) return;

    try {
      await addNewBookAddress(
        name: _nameController.text,
        addr: _addressController.text,
        net: BigInt.zero,
        slip44: appState.chain!.slip44,
      );
      await widget.state.syncBook();
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isDisabled = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = widget.state.currentTheme;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      constraints:
          BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.9),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: theme.modalBorder, width: 2),
      ),
      child: SafeArea(
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
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.only(
                    bottom: MediaQuery.viewInsetsOf(context).bottom),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.addAddressModalTitle,
                        style: theme.subtitle2.copyWith(color: theme.textPrimary),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.addAddressModalDescription,
                        style: theme.bodyText2.copyWith(color: theme.textSecondary),
                      ),
                      const SizedBox(height: 24),
                      SmartInput(
                        key: _nameInputKey,
                        controller: _nameController,
                        hint: l10n.addAddressModalNameHint,
                        height: _inputHeight,
                        fontSize: 18,
                        disabled: _isDisabled,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        onChanged: (_) {
                          if (_errorMessage.isNotEmpty) {
                            setState(() => _errorMessage = '');
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      SmartInput(
                        key: _addressInputKey,
                        controller: _addressController,
                        hint: l10n.addAddressModalAddressHint,
                        height: _inputHeight,
                        fontSize: 18,
                        disabled: _isDisabled,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        onChanged: (_) {
                          if (_errorMessage.isNotEmpty) {
                            setState(() => _errorMessage = '');
                          }
                        },
                      ),
                      if (_errorMessage.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage,
                          style: theme.labelMedium.copyWith(color: theme.danger),
                        ),
                      ],
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: CustomButton(
                          text: l10n.addAddressModalButton,
                          onPressed: () => _handleAddAddress(appState),
                          textColor: theme.buttonText,
                          backgroundColor: theme.primaryPurple,
                          height: 48,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
