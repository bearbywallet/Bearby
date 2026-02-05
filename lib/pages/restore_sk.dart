import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/button.dart';
import 'package:zilpay/components/custom_app_bar.dart';
import 'package:zilpay/components/hex_key.dart';
import 'package:zilpay/components/smart_input.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import 'package:zilpay/mixins/status_bar.dart';
import 'package:zilpay/modals/backup_confirmation_modal.dart';
import 'package:zilpay/src/rust/models/keypair.dart';
import 'package:zilpay/src/rust/models/provider.dart';
import 'package:zilpay/state/app_state.dart';
import 'package:zilpay/l10n/app_localizations.dart';

class SecretKeyRestorePage extends StatefulWidget {
  const SecretKeyRestorePage({super.key});

  @override
  State<SecretKeyRestorePage> createState() => _SecretKeyRestorePageState();
}

class _SecretKeyRestorePageState extends State<SecretKeyRestorePage>
    with StatusBarMixin {
  final TextEditingController _privateKeyController = TextEditingController();
  String? _errorMessage;
  bool _hasBackup = false;
  bool _isValidating = false;
  KeyPairInfo _keyPair = KeyPairInfo(sk: "", pk: "");
  NetworkConfigInfo? _chain;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final chain = args?['chain'] as NetworkConfigInfo?;

    if (chain == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/net_setup');
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
      final isValidHex = normalized.length == 64 && RegExp(r'^[a-f0-9]+$').hasMatch(normalized);
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
                  onBackPressed: () => Navigator.pop(context),
                  onActionPressed: _handlePaste,
                  actionIcon: SvgPicture.asset(
                    'assets/icons/copy.svg',
                    width: 30,
                    height: 30,
                    colorFilter: ColorFilter.mode(
                      theme.textPrimary,
                      BlendMode.srcIn,
                    ),
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
                                padding: EdgeInsets.symmetric(horizontal: adaptivePadding),
                                child: SmartInput(
                                  controller: _privateKeyController,
                                  hint: l10n.secretKeyRestorePageHint,
                                  onChanged: _validatePrivateKey,
                                  keyboardType: TextInputType.text,
                                  autofocus: true,
                                  leftIconPath: 'assets/icons/key.svg',
                                  rightIconPath: _isValidating
                                      ? 'assets/icons/loading.svg'
                                      : null,
                                  secondaryColor: theme.textSecondary,
                                  backgroundColor: theme.cardBackground,
                                  textColor: theme.textPrimary,
                                  focusedBorderColor: theme.primaryPurple,
                                  height: 64,
                                  fontSize: 16,
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  iconPadding: const EdgeInsets.symmetric(horizontal: 12),
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
                      const SizedBox(height: 8),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: adaptivePadding),
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            splashFactory: NoSplash.splashFactory,
                            highlightColor: Colors.transparent,
                          ),
                          child: CheckboxListTile(
                            title: Text(
                              l10n.secretKeyRestorePageBackupLabel,
                              style: theme.bodyText2.copyWith(
                                color: theme.textSecondary,
                              ),
                            ),
                            value: _hasBackup,
                            onChanged: (value) {
                              if (!_hasBackup) {
                                showBackupConfirmationModal(
                                  context: context,
                                  onConfirmed: (confirmed) {
                                    setState(() {
                                      _hasBackup = confirmed;
                                    });
                                  },
                                );
                              }
                            },
                            controlAffinity: ListTileControlAffinity.leading,
                            activeColor: theme.primaryPurple,
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
                          onPressed: _keyPair.sk.isNotEmpty && _hasBackup
                              ? () {
                                  Navigator.of(context).pushNamed(
                                    '/pass_setup',
                                    arguments: {
                                      'keys': _keyPair,
                                      'chain': _chain,
                                    },
                                  );
                                }
                              : null,
                          borderRadius: 30.0,
                          height: 56.0,
                          disabled: !(_keyPair.sk.isNotEmpty && _hasBackup),
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
