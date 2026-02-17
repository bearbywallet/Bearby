import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/load_button.dart';
import 'package:zilpay/mixins/wallet_type.dart';
import 'package:zilpay/src/rust/api/wallet.dart';
import 'package:zilpay/state/app_state.dart';
import '../../components/smart_input.dart';
import 'package:zilpay/l10n/app_localizations.dart';

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
        walletIndex: BigInt.from(widget.state.selectedWallet),
        password:
            _passwordController.text.isEmpty ? null : _passwordController.text,
      );
      await widget.state.syncData();
      widget.state.setSelectedWallet(0);

      if (!mounted) return;
      _btnController.success();
      await Navigator.of(context).pushNamed('/login');
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
      constraints:
          BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.9),
      decoration: BoxDecoration(
        color: theme.cardBackground.withValues(alpha: 0.85),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
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
                    color: Colors.white.withValues(alpha: 0.2),
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
                            style: theme.titleSmall.copyWith(
                              color: theme.danger,
                              shadows: [
                                Shadow(
                                  color:
                                      theme.background.withValues(alpha: 0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.deleteWalletModalWarning,
                            style: theme.bodyText2.copyWith(
                              color: theme.warning,
                              shadows: [
                                Shadow(
                                  color:
                                      theme.background.withValues(alpha: 0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.deleteWalletModalSecretPhraseWarning,
                            style: theme.labelMedium.copyWith(
                              color: theme.danger,
                              shadows: [
                                Shadow(
                                  color:
                                      theme.background.withValues(alpha: 0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
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
                              style: theme.labelMedium.copyWith(
                                color: theme.danger,
                              ),
                            ),
                          ],
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
                                style: theme.titleSmall.copyWith(
                                  color: Colors.white,
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
        ),
      ),
    );
  }
}
