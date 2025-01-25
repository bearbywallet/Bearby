import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/load_button.dart';
import 'package:zilpay/services/device.dart';
import 'package:zilpay/src/rust/api/wallet.dart';
import 'package:zilpay/state/app_state.dart';
import '../../components/smart_input.dart';

class DeleteWalletModal extends StatefulWidget {
  const DeleteWalletModal({
    super.key,
  });

  @override
  State<DeleteWalletModal> createState() => _DeleteWalletModalState();
}

class _DeleteWalletModalState extends State<DeleteWalletModal> {
  final _passwordController = TextEditingController();
  final _passwordInputKey = GlobalKey<SmartInputState>();
  final _btnController = RoundedLoadingButtonController();

  bool _obscurePassword = true;
  bool _disabled = false;
  String _errorMessage = '';

  static const double _inputHeight = 50.0;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _handleDeleteWallet(AppState state) async {
    if (_passwordController.text.isEmpty) {
      return;
    }

    _btnController.start();

    try {
      setState(() {
        _errorMessage = "";
        _disabled = true;
      });

      final device = DeviceInfoService();
      final identifiers = await device.getDeviceIdentifiers();

      await deleteWallet(
        walletIndex: BigInt.from(state.selectedWallet),
        identifiers: identifiers,
        password: _passwordController.text,
      );
      await state.syncData();
      _btnController.success();
      if (!mounted) return;
      await Navigator.of(context).pushNamed(
        '/login',
      );
    } catch (e) {
      setState(() {
        _errorMessage = "$e";
        _disabled = false;
      });
      _btnController.error();
      await Future.delayed(const Duration(seconds: 1));
      _btnController.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = appState.currentTheme;

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
                disabled: _disabled,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                obscureText: _obscurePassword,
                rightIconPath: _obscurePassword
                    ? "assets/icons/close_eye.svg"
                    : "assets/icons/open_eye.svg",
                onRightIconTap: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
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
                  onPressed: () => _handleDeleteWallet(appState),
                  controller: _btnController,
                  successIcon: SvgPicture.asset(
                    'assets/icons/ok.svg',
                    width: 24,
                    height: 24,
                    colorFilter: ColorFilter.mode(
                      theme.textPrimary,
                      BlendMode.srcIn,
                    ),
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
      ],
    );
  }
}
