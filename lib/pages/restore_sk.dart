import 'package:bearby/components/app_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:provider/provider.dart';
import 'package:bearby/components/button.dart';
import 'package:bearby/components/custom_app_bar.dart';
import 'package:bearby/components/hex_key.dart';
import 'package:bearby/components/smart_input.dart';
import 'package:bearby/mixins/adaptive_size.dart';
import 'package:bearby/mixins/status_bar.dart';
import 'package:bearby/src/rust/models/keypair.dart';
import 'package:bearby/src/rust/models/provider.dart';
import 'package:bearby/state/app_state.dart';
import 'package:bearby/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:bearby/router.dart';

class SecretKeyRestorePage extends StatefulWidget {
  const SecretKeyRestorePage({super.key});

  @override
  State<SecretKeyRestorePage> createState() => _SecretKeyRestorePageState();
}

class _SecretKeyRestorePageState extends State<SecretKeyRestorePage>
    with StatusBarMixin {
  final TextEditingController _privateKeyController = TextEditingController();
  String? _errorMessage;
  bool _isValidating = false;
  KeyPairInfo _keyPair = KeyPairInfo(sk: "", pk: "");
  NetworkConfigInfo? _chain;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = GoRouterState.of(context).extra as Map<String, dynamic>?;
    final chain = args?['chain'] as NetworkConfigInfo?;

    if (chain == null && _chain == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.pushReplacement(AppRoutes.netSetup);
      });
    } else if (_chain == null) {
      setState(() {
        _chain = chain;
      });
    }
  }

  @override
  void dispose() {
    _privateKeyController.dispose();
    super.dispose();
  }

  String _normalizeInput(String input) {
    final trimmed = input.trim();
    if (trimmed.startsWith('0x') || trimmed.startsWith('0X')) {
      return trimmed.substring(2).toLowerCase();
    }
    return trimmed;
  }

  Future<void> _handlePaste() async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    if (clipboardData?.text != null) {
      final normalizedText = _normalizeInput(clipboardData!.text!);
      _privateKeyController.text = normalizedText;
      _validatePrivateKey(normalizedText);
    }
  }

  void _validatePrivateKey(String input) async {
    final l10n = AppLocalizations.of(context)!;
    final normalized = _normalizeInput(input);

    setState(() {
      _isValidating = true;
      _errorMessage = null;
      _keyPair = KeyPairInfo(sk: "", pk: "");
    });

    if (normalized.isEmpty) {
      setState(() => _isValidating = false);
      return;
    }

    try {
      final isValidHex = normalized.length == 64 &&
          RegExp(r'^[a-f0-9]+$').hasMatch(normalized);
      final isPossibleWif = normalized.length == 51 || normalized.length == 52;

      if (!isValidHex && !isPossibleWif) {
        throw Exception('Invalid format');
      }

      setState(() {
        _keyPair = KeyPairInfo(sk: normalized, pk: "");
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = l10n.secretKeyRestorePageInvalidFormat;
        _keyPair = KeyPairInfo(sk: "", pk: "");
      });
    } finally {
      setState(() => _isValidating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);
    final theme = Provider.of<AppState>(context).currentTheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        toolbarHeight: 0,
        systemOverlayStyle: getSystemUiOverlayStyle(context),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                CustomAppBar(
                  title: l10n.secretKeyRestorePageTitle,
                  onBackPressed: () => context.pop(),
                  onActionPressed: _handlePaste,
                  actionIcon: AppIconView(
                    icon: AppIcon.copy,
                    size: 30,
                    color: theme.textPrimary,
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            children: [
                              Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: adaptivePadding),
                                child: SmartInput(
                                  controller: _privateKeyController,
                                  hint: l10n.secretKeyRestorePageHint,
                                  onChanged: _validatePrivateKey,
                                  keyboardType: TextInputType.text,
                                  autofocus: true,
                                  leftIcon: AppIcon.key,
                                  rightIcon: AppIconState.loading(isLoading: _isValidating),
                                  secondaryColor: theme.textSecondary,
                                  backgroundColor: theme.cardBackground,
                                  textColor: theme.textPrimary,
                                  focusedBorderColor: theme.primaryPurple,
                                  height: 64,
                                  fontSize: 16,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  iconPadding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                ),
                              ),
                              if (_errorMessage != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    _errorMessage!,
                                    style: theme.bodyText2.copyWith(
                                      color: theme.danger,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 16),
                              HexKeyDisplay(
                                hexKey: _keyPair.sk.isNotEmpty
                                    ? _keyPair.sk
                                    : '0000000000000000000000000000000000000000000000000000000000000000',
                                title: l10n.secretKeyRestorePageKeyTitle,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: EdgeInsets.only(
                          left: adaptivePadding,
                          right: adaptivePadding,
                          bottom: 16,
                        ),
                        child: CustomButton(
                          textColor: theme.buttonText,
                          backgroundColor: theme.primaryPurple,
                          text: l10n.secretKeyRestorePageNextButton,
                          onPressed: _keyPair.sk.isNotEmpty
                              ? () {
                                  context.push(AppRoutes.passSetup, extra: {
                                    'keys': _keyPair,
                                    'chain': _chain,
                                  });
                                }
                              : null,
                          borderRadius: 30.0,
                          height: 56.0,
                          disabled: !_keyPair.sk.isNotEmpty,
                        ),
                      ),
                    ],
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
