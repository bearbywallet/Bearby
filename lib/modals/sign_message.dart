import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/smart_input.dart';
import 'package:zilpay/components/swipe_button.dart';
import 'package:zilpay/services/auth_guard.dart';
import 'package:zilpay/services/biometric_service.dart';
import 'package:zilpay/services/device.dart';
import 'package:zilpay/src/rust/api/transaction.dart';
import 'package:zilpay/src/rust/models/connection.dart';
import 'package:zilpay/state/app_state.dart';
import '../../theme/app_theme.dart';

void showSignMessageModal({
  required BuildContext context,
  required String message,
  required String appTitle,
  required String appIcon,
  ColorsInfo? colors,
  required Function(String, String) onMessageSigned,
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
    builder: (context) => _SignMessageModalContent(
      message: message,
      appTitle: appTitle,
      appIcon: appIcon,
      colors: colors,
      onMessageSigned: onMessageSigned,
      onDismiss: onDismiss,
    ),
  ).then((_) => onDismiss?.call());
}

class _SignMessageModalContent extends StatefulWidget {
  final String message;
  final String appTitle;
  final String appIcon;
  final ColorsInfo? colors;
  final Function(String, String) onMessageSigned;
  final VoidCallback? onDismiss;

  const _SignMessageModalContent({
    required this.message,
    required this.appTitle,
    required this.appIcon,
    this.colors,
    required this.onMessageSigned,
    this.onDismiss,
  });

  @override
  State<_SignMessageModalContent> createState() =>
      _SignMessageModalContentState();
}

class _SignMessageModalContentState extends State<_SignMessageModalContent> {
  final _passwordController = TextEditingController();
  final _passwordInputKey = GlobalKey<SmartInputState>();
  late final AuthService _authService = AuthService();
  late final AuthGuard _authGuard;

  bool _loading = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _authGuard = context.read<AuthGuard>();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<bool> _authenticate() async => _authService.authenticate(
        allowPinCode: true,
        reason: 'Please authenticate to sign the message',
      );

  Future<void> _signMessage(AppState appState) async {
    try {
      final device = DeviceInfoService();
      final identifiers = await device.getDeviceIdentifiers();
      final wallet = appState.wallet!;
      final walletIndex = BigInt.from(appState.selectedWallet);
      final accountIndex = wallet.selectedAccount;
      String? session;

      if (wallet.authType != AuthMethod.none.name) {
        if (!await _authenticate()) return;
        session = await _authGuard.getSession(sessionKey: wallet.walletAddress);
      }

      final (pubkey, sig) = await signMessage(
        walletIndex: walletIndex,
        accountIndex: accountIndex,
        identifiers: identifiers,
        message: widget.message,
        password: _passwordController.text.isNotEmpty
            ? _passwordController.text
            : null,
        sessionCipher: session,
        passphrase: "",
      );

      widget.onMessageSigned(pubkey, sig);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _error = 'Failed to sign message: $e');
    }
  }

  void _handleSignMessage(AppState appState) async {
    setState(() => _loading = true);
    await _signMessage(appState);
    if (mounted) setState(() => _loading = false);
  }

  Color? _parseColor(String? colorString) {
    if (colorString == null) return null;
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xff')));
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final theme = appState.currentTheme;

    final backgroundColor =
        _parseColor(widget.colors?.background) ?? theme.cardBackground;
    final primaryColor =
        _parseColor(widget.colors?.primary) ?? theme.primaryPurple;
    final secondaryColor =
        _parseColor(widget.colors?.secondary) ?? theme.textSecondary;
    final textColor = _parseColor(widget.colors?.text) ?? theme.textPrimary;

    return Container(
      constraints:
          BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.9),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildDragHandle(secondaryColor),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildHeader(textColor, secondaryColor),
                  _buildMessageDisplay(primaryColor, textColor, secondaryColor),
                  if (_error != null) _buildError(theme),
                  if (appState.wallet!.authType == AuthMethod.none.name)
                    _buildPasswordInput(primaryColor, textColor),
                  _buildSignButton(appState, primaryColor, textColor),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDragHandle(Color secondaryColor) => Container(
        width: 36,
        height: 4,
        margin: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: secondaryColor.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(2),
        ),
      );

  Widget _buildHeader(Color textColor, Color secondaryColor) => Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Sign Message',
            style: TextStyle(
              color: textColor,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Review and sign the following message with your wallet.',
            style: TextStyle(color: secondaryColor, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
        ],
      );

  Widget _buildMessageDisplay(
          Color primaryColor, Color textColor, Color secondaryColor) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: secondaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (widget.appIcon.isNotEmpty)
              _buildAppIcon(primaryColor, secondaryColor),
            Text(
              widget.appTitle,
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Message',
              style: TextStyle(
                color: secondaryColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxHeight: 100),
              child: SingleChildScrollView(
                child: Text(
                  widget.message,
                  style: TextStyle(color: textColor, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildAppIcon(Color primaryColor, Color secondaryColor) => Container(
        width: 40,
        height: 40,
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border:
              Border.all(color: primaryColor.withValues(alpha: 0.1), width: 2),
        ),
        child: ClipOval(
          child: Image.network(
            widget.appIcon,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Icon(
              Icons.message,
              color: secondaryColor,
              size: 24,
            ),
            loadingBuilder: (context, child, loadingProgress) =>
                loadingProgress == null
                    ? child
                    : CircularProgressIndicator(
                        strokeWidth: 2, color: secondaryColor),
          ),
        ),
      );

  Widget _buildError(AppTheme theme) => Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.danger.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                'assets/icons/warning.svg',
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(theme.danger, BlendMode.srcIn),
              ),
              const SizedBox(width: 8),
              Text(
                _error!,
                style: TextStyle(color: theme.danger, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );

  Widget _buildPasswordInput(Color primaryColor, Color textColor) => Padding(
        padding: const EdgeInsets.only(top: 16),
        child: SmartInput(
          key: _passwordInputKey,
          controller: _passwordController,
          hint: 'Password',
          fontSize: 18,
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          focusedBorderColor: primaryColor,
          disabled: _loading,
          obscureText: _obscurePassword,
          rightIconPath: _obscurePassword
              ? 'assets/icons/close_eye.svg'
              : 'assets/icons/open_eye.svg',
          onRightIconTap: () =>
              setState(() => _obscurePassword = !_obscurePassword),
          onChanged: (_) => setState(() => _error = null),
        ),
      );

  Widget _buildSignButton(
          AppState appState, Color primaryColor, Color textColor) =>
      Padding(
        padding: EdgeInsets.only(
          top: 16,
          bottom: MediaQuery.viewInsetsOf(context).bottom > 0 ? 16 : 32,
        ),
        child: Center(
          child: SwipeButton(
            text: _loading ? 'Processing...' : 'Sign Message',
            disabled: _loading,
            backgroundColor: primaryColor,
            textColor: textColor,
            onSwipeComplete: () async => _handleSignMessage(appState),
          ),
        ),
      );
}
