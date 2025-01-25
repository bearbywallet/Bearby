import 'package:flutter/material.dart';
import '../../components/button.dart';
import '../../components/smart_input.dart';
import '../../theme/app_theme.dart';

class ChangePasswordModal extends StatefulWidget {
  final AppTheme theme;

  const ChangePasswordModal({
    super.key,
    required this.theme,
  });

  @override
  State<ChangePasswordModal> createState() => _ChangePasswordModalState();
}

class _ChangePasswordModalState extends State<ChangePasswordModal> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();

  final _currentPasswordInputKey = GlobalKey<SmartInputState>();
  final _newPasswordInputKey = GlobalKey<SmartInputState>();

  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _disabled = false;
  String _errorMessage = '';

  static const double _inputHeight = 50.0;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  bool _validatePasswords() {
    if (_currentPasswordController.text.isEmpty) {
      _currentPasswordInputKey.currentState?.shake();
      setState(() {
        _errorMessage = 'Current password cannot be empty';
        _disabled = false;
      });
      return false;
    }

    if (_newPasswordController.text.length < 6) {
      _newPasswordInputKey.currentState?.shake();
      setState(() {
        _errorMessage = 'Password must be at least 8 characters';
        _disabled = false;
      });
      return false;
    }

    return true;
  }

  void _handleChangePassword(BuildContext context) {
    setState(() {
      _errorMessage = '';
      _disabled = true;
    });

    if (!_validatePasswords()) {
      return;
    }

    // Add password change logic here
    debugPrint('Change password clicked');
    Navigator.pop(context);
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
            margin: const EdgeInsets.only(top: 8, bottom: 16),
            decoration: BoxDecoration(
              color: widget.theme.textSecondary.withValues(alpha: 0.3),
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
                'Change Password',
                style: TextStyle(
                  color: widget.theme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your current password and choose a new password to update your wallet security.',
                style: TextStyle(
                  color: widget.theme.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              SmartInput(
                key: _currentPasswordInputKey,
                controller: _currentPasswordController,
                hint: 'Current Password',
                height: _inputHeight,
                fontSize: 18,
                disabled: _disabled,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                obscureText: _obscureCurrentPassword,
                rightIconPath: _obscureCurrentPassword
                    ? "assets/icons/close_eye.svg"
                    : "assets/icons/open_eye.svg",
                onRightIconTap: () {
                  setState(() {
                    _obscureCurrentPassword = !_obscureCurrentPassword;
                  });
                },
                onChanged: (value) {
                  if (_errorMessage.isNotEmpty) {
                    setState(() {
                      _errorMessage = '';
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              SmartInput(
                key: _newPasswordInputKey,
                controller: _newPasswordController,
                hint: 'New Password',
                height: _inputHeight,
                fontSize: 18,
                disabled: _disabled,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                obscureText: _obscureNewPassword,
                rightIconPath: _obscureNewPassword
                    ? "assets/icons/close_eye.svg"
                    : "assets/icons/open_eye.svg",
                onRightIconTap: () {
                  setState(() {
                    _obscureNewPassword = !_obscureNewPassword;
                  });
                },
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
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: 'Change Password',
                  onPressed: () => _handleChangePassword(context),
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
