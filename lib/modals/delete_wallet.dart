import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:zilpay/components/load_button.dart';
import 'package:zilpay/services/device.dart';
import 'package:zilpay/src/rust/api/wallet.dart';
import 'package:zilpay/state/app_state.dart';
import '../../components/smart_input.dart';

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

  Future<void> _handleDeleteWallet() async {
    if (_passwordController.text.isEmpty) return;

    _btnController.start();

    try {
      setState(() {
        _errorMessage = '';
        _isDisabled = true;
      });

      final device = DeviceInfoService();
      final identifiers = await device.getDeviceIdentifiers();

      await deleteWallet(
        walletIndex: BigInt.from(widget.state.selectedWallet),
        identifiers: identifiers,
        password: _passwordController.text,
      );
      await widget.state.syncData();
      if (!mounted) return;
      _btnController.success();
      await Navigator.of(context).pushNamed('/login');
    } catch (e) {
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
                        'Delete Wallet',
                        style: TextStyle(
                          color: theme.danger,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Warning: This action cannot be undone. Your wallet can only be recovered using your secret phrase. If you don\'t have access to it, you will permanently lose all funds associated with this account.',
                        style: TextStyle(
                          color: theme.warning,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Please make sure you have access to your secret phrase before proceeding.',
                        style: TextStyle(
                          color: theme.danger,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SmartInput(
                        key: _passwordInputKey,
                        controller: _passwordController,
                        hint: 'Enter Password',
                        height: _inputHeight,
                        fontSize: 18,
                        disabled: _isDisabled,
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
                            color: theme.danger,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: RoundedLoadingButton(
                          color: theme.danger,
                          onPressed: _handleDeleteWallet,
                          controller: _btnController,
                          successIcon: SvgPicture.asset(
                            'assets/icons/ok.svg',
                            width: 24,
                            height: 24,
                            colorFilter: ColorFilter.mode(
                                theme.textPrimary, BlendMode.srcIn),
                          ),
                          child: Text(
                            'Submit',
                            style: TextStyle(
                              color: theme.textPrimary,
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
