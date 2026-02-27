import 'package:flutter/material.dart';
import '../../components/button.dart';
import '../../components/smart_input.dart';
import '../../theme/app_theme.dart';
import 'package:bearby/l10n/app_localizations.dart';

void showChangePasswordModal({
  required BuildContext context,
  required AppTheme theme,
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
    builder: (context) => ChangePasswordModal(theme: theme),
  ).then((_) => onDismiss?.call());
}

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
  final _confirmPasswordController = TextEditingController();

  final _currentPasswordInputKey = GlobalKey<SmartInputState>();
  final _newPasswordInputKey = GlobalKey<SmartInputState>();
  final _confirmPasswordInputKey = GlobalKey<SmartInputState>();

  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _disabled = false;
  String _errorMessage = '';

  static const double _inputHeight = 50.0;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _validatePasswords() {
    if (_currentPasswordController.text.isEmpty) {
      _currentPasswordInputKey.currentState?.shake();
      setState(() {
        _errorMessage = AppLocalizations.of(context)!
            .changePasswordModalCurrentPasswordEmptyError;
        _disabled = false;
      });
      return false;
    }

    if (_newPasswordController.text.length < 6) {
      _newPasswordInputKey.currentState?.shake();
      setState(() {
        _errorMessage = AppLocalizations.of(context)!
            .changePasswordModalPasswordLengthError;
        _disabled = false;
      });
      return false;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      _confirmPasswordInputKey.currentState?.shake();
      setState(() {
        _errorMessage = AppLocalizations.of(context)!
            .changePasswordModalPasswordsMismatchError;
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

    debugPrint('Change password clicked');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      constraints:
          BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.9),
      decoration: BoxDecoration(
        color: widget.theme.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: widget.theme.modalBorder, width: 2),
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
                color: widget.theme.modalBorder,
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
                        l10n.changePasswordModalTitle,
                        style: widget.theme.titleSmall.copyWith(
                          color: widget.theme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.changePasswordModalDescription,
                        style: widget.theme.bodyText2.copyWith(
                          color: widget.theme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SmartInput(
                        key: _currentPasswordInputKey,
                        controller: _currentPasswordController,
                        hint: l10n.changePasswordModalCurrentPasswordHint,
                        height: _inputHeight,
                        fontSize: 18,
                        disabled: _disabled,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        obscureText: _obscureCurrentPassword,
                        rightIconPath: _obscureCurrentPassword
                            ? "assets/icons/close_eye.svg"
                            : "assets/icons/open_eye.svg",
                        onRightIconTap: () => setState(() =>
                            _obscureCurrentPassword = !_obscureCurrentPassword),
                        onChanged: (_) => _errorMessage.isNotEmpty
                            ? setState(() => _errorMessage = '')
                            : null,
                      ),
                      const SizedBox(height: 16),
                      SmartInput(
                        key: _newPasswordInputKey,
                        controller: _newPasswordController,
                        hint: l10n.changePasswordModalNewPasswordHint,
                        height: _inputHeight,
                        fontSize: 18,
                        disabled: _disabled,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        obscureText: _obscureNewPassword,
                        rightIconPath: _obscureNewPassword
                            ? "assets/icons/close_eye.svg"
                            : "assets/icons/open_eye.svg",
                        onRightIconTap: () => setState(
                            () => _obscureNewPassword = !_obscureNewPassword),
                        onChanged: (_) => _errorMessage.isNotEmpty
                            ? setState(() => _errorMessage = '')
                            : null,
                      ),
                      const SizedBox(height: 16),
                      SmartInput(
                        key: _confirmPasswordInputKey,
                        controller: _confirmPasswordController,
                        hint: l10n.changePasswordModalConfirmPasswordHint,
                        height: _inputHeight,
                        fontSize: 18,
                        disabled: _disabled,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        obscureText: _obscureConfirmPassword,
                        rightIconPath: _obscureConfirmPassword
                            ? "assets/icons/close_eye.svg"
                            : "assets/icons/open_eye.svg",
                        onRightIconTap: () => setState(() =>
                            _obscureConfirmPassword = !_obscureConfirmPassword),
                        onChanged: (_) => _errorMessage.isNotEmpty
                            ? setState(() => _errorMessage = '')
                            : null,
                      ),
                      if (_errorMessage.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage,
                          style: widget.theme.labelMedium.copyWith(
                            color: widget.theme.danger,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: CustomButton(
                          text: l10n.changePasswordModalButton,
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
