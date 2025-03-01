import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:zilpay/components/biometric_switch.dart';
import 'package:zilpay/components/counter.dart';
import 'package:zilpay/components/load_button.dart';
import 'package:zilpay/components/smart_input.dart';
import 'package:zilpay/services/biometric_service.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/state/app_state.dart';

class LedgerConnectDialog extends StatefulWidget {
  final String? walletName;
  final AuthMethod biometricType;
  final VoidCallback? onClose;
  final Future<void> Function(int, String, bool)? onConnect;

  const LedgerConnectDialog({
    super.key,
    this.onClose,
    this.onConnect,
    this.biometricType = AuthMethod.none,
    this.walletName = 'Ledger',
  });

  @override
  State<LedgerConnectDialog> createState() => _LedgerConnectDialog();
}

class _LedgerConnectDialog extends State<LedgerConnectDialog> {
  final _btnController = RoundedLoadingButtonController();
  final _walletNameController = TextEditingController();

  int _index = 0;
  bool _loading = false;
  bool _useBiometric = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _walletNameController.text = widget.walletName!;
  }

  Future<void> _onConnect() async {
    if (_walletNameController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Wallet name cannot be empty');
      return;
    }

    if (_walletNameController.text.length > 24) {
      setState(() => _errorMessage = 'Wallet name is too long');
      return;
    }

    if (widget.onConnect != null) {
      try {
        setState(() {
          _loading = true;
          _errorMessage = '';
        });
        _btnController.start();

        await widget.onConnect!(
            _index, _walletNameController.text, _useBiometric);

        _btnController.success();
        await Future.delayed(const Duration(milliseconds: 300));
      } catch (e) {
        setState(() => _errorMessage = e.toString());
        _btnController.error();
        await Future.delayed(const Duration(milliseconds: 500));
      } finally {
        if (mounted) {
          setState(() => _loading = false);
          _btnController.reset();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<AppState>(context).currentTheme;
    final viewInsets = MediaQuery.of(context).viewInsets;
    final screenHeight = MediaQuery.of(context).size.height;
    final maxHeight = screenHeight - (screenHeight * 0.1);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 20),
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: Wrap(
        children: [
          Container(
            constraints: BoxConstraints(
              maxHeight: maxHeight,
            ),
            decoration: BoxDecoration(
              color: theme.background,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[600],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 16),
                        SmartInput(
                          controller: _walletNameController,
                          hint: "Wallet Name",
                          fontSize: 18,
                          height: 50,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          focusedBorderColor: theme.primaryPurple,
                          disabled: _loading,
                          onChanged: (value) {
                            if (_errorMessage.isNotEmpty) {
                              setState(() => _errorMessage = '');
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
                            textAlign: TextAlign.center,
                          ),
                        ],
                        const SizedBox(height: 16),
                        Counter(
                          iconSize: 32,
                          iconColor: theme.textPrimary,
                          animationDuration: const Duration(milliseconds: 300),
                          numberStyle: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: theme.textPrimary,
                          ),
                          initialValue: 0,
                          disabled: _loading,
                          onChanged: !_loading
                              ? (value) {
                                  setState(() {
                                    _index = value;
                                  });
                                }
                              : null,
                        ),
                        const SizedBox(height: 16),
                        SwitchWithIcon(
                          biometricType: widget.biometricType,
                          value: _useBiometric,
                          disabled: _loading,
                          onChanged: (value) {
                            setState(() => _useBiometric = value);
                          },
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: RoundedLoadingButton(
                            controller: _btnController,
                            onPressed: _onConnect,
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
                              'Connect',
                              style: TextStyle(
                                color: theme.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
