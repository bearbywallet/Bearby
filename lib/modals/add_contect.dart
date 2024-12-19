import 'package:flutter/material.dart';
import 'package:zilpay/src/rust/api/book.dart';
import 'package:zilpay/state/app_state.dart';
import '../../components/button.dart';
import '../../components/smart_input.dart';
import '../../theme/app_theme.dart';

class AddAddressModal extends StatefulWidget {
  final AppTheme theme;
  final AppState state;

  const AddAddressModal({
    super.key,
    required this.theme,
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

  bool _disabled = false;
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
        _disabled = false;
      });
      return false;
    }

    if (_addressController.text.isEmpty) {
      _addressInputKey.currentState?.shake();
      setState(() {
        _errorMessage = 'Address cannot be empty';
        _disabled = false;
      });
      return false;
    }

    return true;
  }

  Future<void> _handleAddAddress(BuildContext context) async {
    setState(() {
      _errorMessage = '';
      _disabled = true;
    });

    if (!_validateInputs()) {
      return;
    }

    try {
      await addNewBookAddress(
        name: _nameController.text,
        addr: _addressController.text,
        net: BigInt.zero, // Detect network from wallet
      );
      await widget.state.syncBook();

      Navigator.pop(
        context,
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _disabled = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 32,
            height: 4,
            margin: const EdgeInsets.only(top: 16, bottom: 16),
            decoration: BoxDecoration(
              color: widget.theme.textSecondary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            0,
            16,
            MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add Contact',
                style: TextStyle(
                  color: widget.theme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter the contact name and wallet address to add to your address book.',
                style: TextStyle(
                  color: widget.theme.textSecondary,
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
                disabled: _disabled,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                onChanged: (value) {
                  if (_errorMessage.isNotEmpty) {
                    setState(() {
                      _errorMessage = '';
                    });
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
                disabled: _disabled,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                onChanged: (value) {
                  if (_errorMessage.isNotEmpty) {
                    setState(() {
                      _errorMessage = '';
                    });
                  }
                },
              ),
              if (_errorMessage.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  _errorMessage,
                  style: TextStyle(
                    color: widget.theme.danger,
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
                  onPressed: () => _handleAddAddress(context),
                  backgroundColor: widget.theme.primaryPurple,
                  textColor: widget.theme.textPrimary,
                  height: 48,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }
}
