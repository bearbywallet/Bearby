import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/mixins/wallet_type.dart';
import 'package:zilpay/state/app_state.dart';
import '../../components/button.dart';
import '../../theme/app_theme.dart';

class SecretRecoveryModal extends StatelessWidget {
  final AppTheme theme;

  const SecretRecoveryModal({
    super.key,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final walletType = appState.wallet!.walletType;

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
              color: theme.textSecondary.withValues(alpha: 0.3),
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
              if (walletType.contains(WalletType.SecretPhrase.name)) ...[
                _buildOption(
                  title: 'Reveal Secret Recovery Phrase',
                  description: 'If you ever change browsers or move computers, '
                      'you will need this Secret Recovery Phrase to access '
                      'your accounts. Save them somewhere safe and secret.',
                  onPressed: () => _onRevealPhrase(context),
                  buttonText: 'Reveal',
                ),
                const SizedBox(height: 24)
              ],
              if (walletType.contains(WalletType.SecretKey.name) ||
                  walletType.contains(WalletType.SecretPhrase.name)) ...[
                _buildOption(
                  title: 'Show Private Keys',
                  description:
                      'Warning: Never disclose this key. Anyone with your '
                      'private keys can steal any assets held in your account.',
                  onPressed: () => _onShowPrivateKeys(context),
                  buttonText: 'Export',
                ),
                const SizedBox(height: 16),
              ]
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOption({
    required String title,
    required String description,
    required VoidCallback onPressed,
    required String buttonText,
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
}
