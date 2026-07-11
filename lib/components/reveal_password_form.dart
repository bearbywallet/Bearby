import 'package:flutter/material.dart';
import 'package:bearby/components/app_icon.dart';
import 'package:bearby/components/load_button.dart';
import 'package:bearby/components/smart_input.dart';
import 'package:bearby/theme/app_theme.dart';

/// Shared password gate used by secret-key and seed-phrase reveal screens.
class RevealPasswordForm extends StatelessWidget {
  final TextEditingController controller;
  final RoundedLoadingButtonController btnController;
  final AppTheme theme;
  final String passwordHint;
  final String submitLabel;
  final bool obscurePassword;
  final bool hasError;
  final String? errorMessage;
  final VoidCallback onToggleObscure;
  final VoidCallback onSubmit;

  const RevealPasswordForm({
    super.key,
    required this.controller,
    required this.btnController,
    required this.theme,
    required this.passwordHint,
    required this.submitLabel,
    required this.obscurePassword,
    required this.hasError,
    required this.errorMessage,
    required this.onToggleObscure,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SmartInput(
          controller: controller,
          hint: passwordHint,
          fontSize: 18,
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          focusedBorderColor: theme.primaryPurple,
          obscureText: obscurePassword,
          onSubmitted: (_) => onSubmit(),
          rightIcon:
              AppIconState.passwordVisibility(obscured: obscurePassword),
          onRightIconTap: onToggleObscure,
        ),
        if (hasError && errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              errorMessage ?? '',
              style: theme.bodyText2.copyWith(color: theme.danger),
            ),
          ),
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: RoundedLoadingButton(
            color: theme.primaryPurple,
            valueColor: theme.buttonText,
            controller: btnController,
            onPressed: onSubmit,
            child: Text(
              submitLabel,
              style: theme.titleSmall.copyWith(color: theme.buttonText),
            ),
          ),
        ),
      ],
    );
  }
}
