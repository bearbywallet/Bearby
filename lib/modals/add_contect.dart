import 'package:flutter/material.dart';
import 'package:zilpay/src/rust/api/book.dart';
import 'package:zilpay/state/app_state.dart';
import '../../components/button.dart';
import '../../components/smart_input.dart';

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
        _errorMessage = 'Name cannot be empty';
        _isDisabled = false;
      });
      return false;
    }
    if (_addressController.text.isEmpty) {
      _addressInputKey.currentState?.shake();
      setState(() {
        _errorMessage = 'Address cannot be empty';
        _isDisabled = false;
      });
      return false;
    }
    return true;
  }

  Future<void> _handleAddAddress() async {
    setState(() {
      _errorMessage = '';
      _isDisabled = true;
    });

    if (!_validateInputs()) return;

    try {
      await addNewBookAddress(
        name: _nameController.text,
        addr: _addressController.text,
        net: BigInt.zero,
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
    final theme = widget.state.currentTheme;

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
                        'Add Contact',
                        style: TextStyle(
                          color: theme.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Enter the contact name and wallet address to add to your address book.',
                        style: TextStyle(
                          color: theme.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SmartInput(
                        key: _nameInputKey,
                        controller: _nameController,
                        hint: 'Name',
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
                        hint: 'Wallet Address',
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
                          style: TextStyle(
                            color: theme.danger,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: CustomButton(
                          text: 'Add Contact',
                          onPressed: _handleAddAddress,
                          backgroundColor: theme.primaryPurple,
                          textColor: theme.textPrimary,
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
