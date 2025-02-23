import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/smart_input.dart';
import 'package:zilpay/components/swipe_button.dart';
import 'package:zilpay/services/auth_guard.dart';
import 'package:zilpay/services/biometric_service.dart';
import 'package:zilpay/services/device.dart';
import 'package:zilpay/state/app_state.dart';
import '../../theme/app_theme.dart';

void showSignMessageModal({
  required BuildContext context,
  required String message,
  required String appTitle, // Added appTitle
  required String appIcon, // Added appIcon
  required Function(String) onMessageSigned,
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
      appTitle: appTitle, // Pass appTitle
      appIcon: appIcon, // Pass appIcon
      onMessageSigned: onMessageSigned,
      onDismiss: onDismiss,
    ),
  ).then((_) {
    if (onDismiss != null) {
      onDismiss();
    }
  });
}

class _SignMessageModalContent extends StatefulWidget {
  final String message;
  final String appTitle; // Added appTitle
  final String appIcon; // Added appIcon
  final Function(String) onMessageSigned;
  final VoidCallback? onDismiss;

  const _SignMessageModalContent({
    required this.message,
    required this.appTitle, // Added appTitle
    required this.appIcon, // Added appIcon
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
  final _authService = AuthService();
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

  Future<String?> _signMessage(AppState appState) async {
    final device = DeviceInfoService();
    final identifiers = await device.getDeviceIdentifiers();
    final wallet = appState.wallet!;
    final walletIndex = BigInt.from(appState.selectedWallet);
    final accountIndex = wallet.selectedAccount;

    if (wallet.authType != AuthMethod.none.name) {
      if (!await _authenticate()) return null;
      final session =
          await _authGuard.getSession(sessionKey: wallet.walletAddress);
      // return await signMessage(
      //   walletIndex: walletIndex,
      //   accountIndex: accountIndex,
      //   identifiers: identifiers,
      //   message: widget.message,
      //   sessionCipher: session,
      // );
    } else {
      // return await signMessage(
      //   walletIndex: walletIndex,
      //   accountIndex: accountIndex,
      //   identifiers: identifiers,
      //   message: widget.message,
      //   password: _passwordController.text,
      // );
    }
    return null; // Placeholder until signMessage is implemented
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final theme = appState.currentTheme;

    return Container(
      constraints:
          BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.9),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                color: theme.textSecondary.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.only(
                    bottom: MediaQuery.viewInsetsOf(context).bottom),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Sign Message',
                        style: TextStyle(
                          color: theme.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Review and sign the following message with your wallet.',
                        style: TextStyle(
                          color: theme.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildMessageDisplay(theme),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.danger.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            SvgPicture.asset(
                              'assets/icons/warning.svg',
                              width: 24,
                              height: 24,
                              colorFilter: ColorFilter.mode(
                                  theme.danger, BlendMode.srcIn),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _error!,
                                style: TextStyle(
                                    color: theme.danger, fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (appState.wallet!.authType == AuthMethod.none.name) ...[
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: SmartInput(
                          key: _passwordInputKey,
                          controller: _passwordController,
                          hint: 'Password',
                          fontSize: 18,
                          height: 56,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          focusedBorderColor: theme.primaryPurple,
                          disabled: _loading,
                          obscureText: _obscurePassword,
                          rightIconPath: _obscurePassword
                              ? 'assets/icons/close_eye.svg'
                              : 'assets/icons/open_eye.svg',
                          onRightIconTap: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                          onChanged: (_) => setState(() => _error = null),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SwipeButton(
                        text: _loading ? 'Processing...' : 'Sign Message',
                        disabled: _loading,
                        onSwipeComplete: () async {
                          setState(() => _loading = true);
                          try {
                            final signedMessage = await _signMessage(appState);
                            if (mounted && signedMessage != null) {
                              widget.onMessageSigned(signedMessage);
                              if (mounted) {
                                Navigator.pop(context);
                              }
                            } else if (mounted) {
                              setState(() => _error =
                                  'Authentication failed or signing canceled');
                            }
                          } catch (e) {
                            if (mounted) {
                              setState(
                                  () => _error = 'Failed to sign message: $e');
                            }
                          } finally {
                            if (mounted) {
                              setState(() => _loading = false);
                            }
                          }
                        },
                      ),
                    ),
                    SizedBox(
                        height: MediaQuery.viewInsetsOf(context).bottom > 0
                            ? 16
                            : 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageDisplay(AppTheme theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.background.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.appIcon.isNotEmpty) ...[
            Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.primaryPurple.withValues(alpha: 0.1),
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: Image.network(
                  widget.appIcon,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.message,
                    color: theme.textSecondary,
                    size: 24,
                  ),
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.textSecondary,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
          Text(
            widget.appTitle,
            style: TextStyle(
              color: theme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Message',
            style: TextStyle(
              color: theme.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.message,
            style: TextStyle(
              color: theme.textPrimary,
              fontSize: 16,
            ),
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
