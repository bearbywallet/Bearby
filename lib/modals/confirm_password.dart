import 'dart:async';

import 'package:flutter/material.dart';
import '../../components/load_button.dart';
import '../../components/smart_input.dart';
import '../../theme/app_theme.dart';
import 'package:flutter_svg/svg.dart';
import 'package:zilpay/l10n/app_localizations.dart';

void showConfirmPasswordModal({
  required BuildContext context,
  required AppTheme theme,
  required Future<bool> Function(String password) onConfirm,
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
    builder: (context) => ConfirmPasswordModal(
      theme: theme,
      onConfirm: onConfirm,
    ),
  ).then((_) => onDismiss?.call());
}

class ConfirmPasswordModal extends StatefulWidget {
  final AppTheme theme;
  final Future<bool> Function(String password) onConfirm;

  const ConfirmPasswordModal({
    super.key,
    required this.theme,
    required this.onConfirm,
  });

  @override
  State<ConfirmPasswordModal> createState() => _ConfirmPasswordModalState();
}

class _ConfirmPasswordModalState extends State<ConfirmPasswordModal> {
  final _passwordController = TextEditingController();
  final _passwordInputKey = GlobalKey<SmartInputState>();
  final _btnController = RoundedLoadingButtonController();

  bool _obscurePassword = true;
  String _errorMessage = '';
  static const double _inputHeight = 50.0;

  @override
  void dispose() {
    _passwordController.dispose();
    _btnController.dispose();
    super.dispose();
  }

  bool _validatePassword() {
    if (_passwordController.text.isEmpty) {
      _passwordInputKey.currentState?.shake();
      setState(() {
        _errorMessage =
            AppLocalizations.of(context)!.confirmPasswordModalEmptyError;
      });
      _btnController.reset();
      return false;
    }
    return true;
  }

  Future<void> _handleConfirmPassword(BuildContext context) async {
    setState(() {
      _errorMessage = '';
    });

    _btnController.start();

    if (!_validatePassword()) {
      return;
    }

    try {
      bool success = await widget.onConfirm(_passwordController.text);

      if (success && mounted) {
        _btnController.success();

        Timer(const Duration(milliseconds: 300), () {
          if (mounted) {
            Navigator.pop(context);
          }
        });
      } else if (mounted) {
        setState(() {
          _errorMessage =
              AppLocalizations.of(context)!.confirmPasswordModalIncorrectError;
        });
        _passwordInputKey.currentState?.shake();
        _btnController.error();

        Timer(const Duration(seconds: 1), () {
          if (mounted) {
            _btnController.reset();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage =
              '${AppLocalizations.of(context)!.confirmPasswordModalGenericError} ${e.toString()}';
        });
        _btnController.error();

        Timer(const Duration(seconds: 1), () {
          if (mounted) {
            _btnController.reset();
          }
        });
      }
    }
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
                        l10n.confirmPasswordModalTitle,
                        style: TextStyle(
                          color: widget.theme.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.confirmPasswordModalDescription,
                        style: TextStyle(
                          color: widget.theme.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SmartInput(
                        key: _passwordInputKey,
                        controller: _passwordController,
                        hint: l10n.confirmPasswordModalHint,
                        height: _inputHeight,
                        fontSize: 18,
                        disabled: false,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        obscureText: _obscurePassword,
                        rightIconPath: _obscurePassword
                            ? "assets/icons/close_eye.svg"
                            : "assets/icons/open_eye.svg",
                        onRightIconTap: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                        onChanged: (_) => _errorMessage.isNotEmpty
                            ? setState(() => _errorMessage = '')
                            : null,
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
                        child: RoundedLoadingButton(
                          color: widget.theme.primaryPurple,
                          valueColor: widget.theme.buttonText,
                          controller: _btnController,
                          onPressed: () => _handleConfirmPassword(context),
                          child: Text(
                            l10n.confirmPasswordModalButton,
                            style: TextStyle(
                              color: widget.theme.buttonText,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
