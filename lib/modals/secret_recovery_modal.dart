import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/mixins/wallet_type.dart';
import 'package:zilpay/state/app_state.dart';
import '../../components/button.dart';
import '../../theme/app_theme.dart';
import 'package:zilpay/l10n/app_localizations.dart';

void showSecretRecoveryModal({
  required BuildContext context,
  required AppTheme theme,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    enableDrag: true,
    isDismissible: true,
    useSafeArea: true,
    barrierColor: Colors.black54,
    builder: (context) => _SecretRecoveryModal(theme: theme),
  );
}

class _SecretRecoveryModal extends StatelessWidget {
  final AppTheme theme;

  const _SecretRecoveryModal({required this.theme});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        decoration: BoxDecoration(
          color: theme.cardBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: theme.modalBorder, width: 2),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _buildDragHandle(),
                const SizedBox(height: 16),
                _buildContent(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDragHandle() {
    return Center(
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: theme.modalBorder,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        final walletType = appState.wallet!.walletType;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (walletType.contains(WalletType.SecretPhrase.name)) ...[
              _buildOption(
                context: context,
                title: AppLocalizations.of(context)!
                    .secretRecoveryModalRevealPhraseTitle,
                description: AppLocalizations.of(context)!
                    .secretRecoveryModalRevealPhraseDescription,
                buttonText: AppLocalizations.of(context)!
                    .secretRecoveryModalRevealPhraseButton,
                onPressed: () => _onRevealPhrase(context),
              ),
              const SizedBox(height: 24),
            ],
            if (walletType.contains(WalletType.SecretKey.name) ||
                walletType.contains(WalletType.SecretPhrase.name)) ...[
              _buildOption(
                context: context,
                title: AppLocalizations.of(context)!
                    .secretRecoveryModalShowKeysTitle,
                description: AppLocalizations.of(context)!
                    .secretRecoveryModalShowKeysDescription,
                buttonText: AppLocalizations.of(context)!
                    .secretRecoveryModalShowKeysButton,
                onPressed: () => _onShowPrivateKeys(context),
              ),
              const SizedBox(height: 24),
              _buildOption(
                context: context,
                title: AppLocalizations.of(context)!
                    .secretRecoveryModalKeystoreBackupTitle,
                description: AppLocalizations.of(context)!
                    .secretRecoveryModalKeystoreBackupDescription,
                buttonText: AppLocalizations.of(context)!
                    .secretRecoveryModalKeystoreBackupButton,
                onPressed: () => _onCreateKeystoreBackup(context),
              ),
              const SizedBox(height: 16),
            ],
          ],
        );
      },
    );
  }

  Widget _buildOption({
    required BuildContext context,
    required String title,
    required String description,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: theme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: TextStyle(
            color: theme.textSecondary,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: CustomButton(
            text: buttonText,
            onPressed: onPressed,
            backgroundColor: Colors.red.withValues(alpha: 0.1),
            textColor: Colors.red,
            height: 48,
          ),
        ),
      ],
    );
  }

  void _onRevealPhrase(BuildContext context) {
    Navigator.of(context).pushNamed('/reveal_bip39');
  }

  void _onShowPrivateKeys(BuildContext context) {
    Navigator.of(context).pushNamed('/reveal_sk');
  }

  void _onCreateKeystoreBackup(BuildContext context) {
    Navigator.of(context).pushNamed('/keystore_backup');
  }
}
