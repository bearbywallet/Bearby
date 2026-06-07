import 'package:bearby/components/app_icon.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bearby/components/glass_message.dart';
import 'package:bearby/components/load_button.dart';
import 'package:bearby/mixins/wallet_type.dart';
import 'package:bearby/src/rust/api/wallet.dart';
import 'package:bearby/state/app_state.dart';
import '../../components/smart_input.dart';
import 'package:bearby/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:bearby/router.dart';

void showDeleteWalletModal({
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
    builder: (context) => DeleteWalletModal(
      state: state,
    ),
  ).then((_) => onDismiss?.call());
}

class DeleteWalletModal extends StatefulWidget {
  final AppState state;

  const DeleteWalletModal({
    super.key,
    required this.state,
  });

  @override
  State<DeleteWalletModal> createState() => _DeleteWalletModalState();
}

class _DeleteWalletModalState extends State<DeleteWalletModal> {
  final _passwordController = TextEditingController();
  final _passwordInputKey = GlobalKey<SmartInputState>();
  final _btnController = RoundedLoadingButtonController();

  bool _obscurePassword = true;
  bool _isDisabled = false;
  String _errorMessage = '';

  static const double _inputHeight = 50.0;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
  }

  Future<void> _handleDeleteWallet(AppState appState) async {
    _btnController.start();

    try {
      setState(() {
        _errorMessage = '';
        _isDisabled = true;
      });

      await deleteWallet(
        walletIndex: widget.state.selectedWalletIndex,
        password:
            _passwordController.text.isEmpty ? null : _passwordController.text,
      );
      await widget.state.syncData();
      widget.state.setSelectedWallet(0);

      if (!mounted) return;
      _btnController.success();
      context.go(AppRoutes.login);
    } catch (e) {
      debugPrint("error: $e");
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isDisabled = false;
        });
      }
      _btnController.error();
      await Future.delayed(const Duration(seconds: 1));
      _btnController.reset();
    } finally {
      await widget.state.syncData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final theme = widget.state.currentTheme;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: theme.modalBorder, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
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
                        l10n.deleteWalletModalTitle,
                        style: TextStyle(
                          color: theme.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'SFRounded',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.danger.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.danger, width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.deleteWalletModalWarning,
                              style: TextStyle(
                                color: theme.warning,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'SFRounded',
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.deleteWalletModalSecretPhraseWarning,
                              style: TextStyle(
                                color: theme.danger,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'SFRounded',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (appState.wallet?.walletType
                              .contains(WalletType.ledger.name) ==
                          false)
                        SmartInput(
                          key: _passwordInputKey,
                          controller: _passwordController,
                          hint: l10n.deleteWalletModalPasswordHint,
                          height: _inputHeight,
                          fontSize: 18,
                          disabled: _isDisabled,
                          padding:
                              const EdgeInsets.symmetric(horizontal: 20),
                          obscureText: _obscurePassword,
                          rightIcon: AppIconState.passwordVisibility(obscured: _obscurePassword),
                          onRightIconTap: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                          onChanged: (_) => _errorMessage.isNotEmpty
                              ? setState(() => _errorMessage = '')
                              : null,
                        ),
                      if (_errorMessage.isNotEmpty)
                        GlassMessage(
                          message: _errorMessage,
                          type: GlassMessageType.error,
                          margin: const EdgeInsets.only(top: 8),
                        ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: RoundedLoadingButton(
                          color: theme.danger,
                          valueColor: Colors.white,
                          onPressed: () => _handleDeleteWallet(appState),
                          controller: _btnController,
                          child: Text(
                            l10n.deleteWalletModalSubmit,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'SFRounded',
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
