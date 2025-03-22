import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/button.dart';
import 'package:zilpay/components/custom_app_bar.dart';
import 'package:zilpay/components/hex_key.dart';
import 'package:zilpay/components/tile_button.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import 'package:zilpay/modals/backup_confirmation_modal.dart';
import 'package:zilpay/src/rust/api/methods.dart';
import 'package:zilpay/src/rust/models/keypair.dart';
import 'package:zilpay/state/app_state.dart';
import 'package:zilpay/l10n/app_localizations.dart';

class SecretKeyGeneratorPage extends StatefulWidget {
  const SecretKeyGeneratorPage({super.key});

  @override
  State<SecretKeyGeneratorPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<SecretKeyGeneratorPage> {
  KeyPairInfo _keyPair = KeyPairInfo(sk: "", pk: "");
  bool _hasBackupWords = false;
  bool isCopied = false;

  @override
  void initState() {
    super.initState();
    _regenerateKeys();
  }

  Future<void> _regenerateKeys() async {
    KeyPairInfo keyPair = await genKeypair();
    setState(() {
      _hasBackupWords = false;
      _keyPair = keyPair;
    });
  }

  @override
  Widget build(BuildContext context) {
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);
    final theme = Provider.of<AppState>(context).currentTheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            CustomAppBar(
              title: l10n.secretKeyGeneratorPageTitle,
              onBackPressed: () => Navigator.pop(context),
              actionIcon: SvgPicture.asset(
                'assets/icons/reload.svg',
                width: 30,
                height: 30,
                colorFilter: ColorFilter.mode(
                  theme.textPrimary,
                  BlendMode.srcIn,
                ),
              ),
              onActionPressed: _regenerateKeys,
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: adaptivePadding),
                child: Column(
                  children: [
                    Expanded(
                      flex: 4,
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            HexKeyDisplay(
                              hexKey: _keyPair.sk,
                              title: l10n.secretKeyGeneratorPagePrivateKey,
                            ),
                            const SizedBox(height: 16),
                            HexKeyDisplay(
                              hexKey: _keyPair.pk,
                              title: l10n.secretKeyGeneratorPagePublicKey,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.3,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            constraints: const BoxConstraints(maxWidth: 480),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Theme(
                                        data: Theme.of(context).copyWith(
                                          splashFactory: NoSplash.splashFactory,
                                          highlightColor: Colors.transparent,
                                        ),
                                        child: CheckboxListTile(
                                          title: Text(
                                            l10n.secretKeyGeneratorPageBackupCheckbox,
                                            style: TextStyle(
                                              color: theme.textSecondary,
                                            ),
                                          ),
                                          value: _hasBackupWords,
                                          onChanged: (_) {
                                            if (!_hasBackupWords) {
                                              showBackupConfirmationModal(
                                                context: context,
                                                onConfirmed: (confirmed) {
                                                  setState(() {
                                                    _hasBackupWords = confirmed;
                                                  });
                                                },
                                              );
                                            }
                                          },
                                          controlAffinity:
                                              ListTileControlAffinity.leading,
                                          activeColor: theme.primaryPurple,
                                        ),
                                      ),
                                    ),
                                    TileButton(
                                      icon: SvgPicture.asset(
                                        isCopied
                                            ? "assets/icons/check.svg"
                                            : "assets/icons/copy.svg",
                                        width: 24,
                                        height: 24,
                                        colorFilter: ColorFilter.mode(
                                          theme.primaryPurple,
                                          BlendMode.srcIn,
                                        ),
                                      ),
                                      disabled: false,
                                      onPressed: () async {
                                        await _handleCopy(_keyPair.sk);
                                      },
                                      backgroundColor: theme.cardBackground,
                                      textColor: theme.primaryPurple,
                                    ),
                                  ],
                                ),
                                const SizedBox(
                                  height: 16,
                                ),
                                CustomButton(
                                  textColor: theme.buttonText,
                                  backgroundColor: theme.primaryPurple,
                                  text: l10n.secretKeyGeneratorPageNextButton,
                                  onPressed: () {
                                    Navigator.of(context).pushNamed(
                                      '/net_setup',
                                      arguments: {'keys': _keyPair},
                                    );
                                  },
                                  borderRadius: 30.0,
                                  height: 56.0,
                                  disabled: !_hasBackupWords,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleCopy(String address) async {
    await Clipboard.setData(ClipboardData(text: address));
    setState(() {
      isCopied = true;
    });
    await Future<void>.delayed(const Duration(seconds: 2));
    setState(() {
      isCopied = false;
    });
  }
}
