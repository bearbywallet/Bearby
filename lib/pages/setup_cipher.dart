import 'package:flutter/material.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:zilpay/components/button.dart';
import 'package:zilpay/components/custom_app_bar.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/option_list.dart';
import 'package:zilpay/config/argon.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import 'package:zilpay/modals/argon2.dart';
import 'package:zilpay/src/rust/models/keypair.dart';
import 'package:zilpay/src/rust/models/provider.dart';
import 'package:zilpay/src/rust/models/settings.dart';
import 'package:zilpay/state/app_state.dart';
import 'package:zilpay/l10n/app_localizations.dart';

class CipherSettingsPage extends StatefulWidget {
  const CipherSettingsPage({super.key});

  @override
  State<CipherSettingsPage> createState() => _CipherSettingsPageState();
}

class _CipherSettingsPageState extends State<CipherSettingsPage> {
  List<String>? _bip39List;
  NetworkConfigInfo? _chain;
  KeyPairInfo? _keys;
  bool _zilLegacy = false;
  bool _bypassChecksumValidation = false;
  WalletArgonParamsInfo _argonParams = Argon2DefaultParams.owaspDefault();
  int selectedCipherIndex = 2;

  final List<Map<String, String>> cipherDescriptions = [
    {
      'title': '',
      'subtitle': '',
      'description': '',
    },
    {
      'title': '',
      'subtitle': '',
      'description': '',
    },
    {
      'title': '',
      'subtitle': '',
      'description': '',
    },
  ];

  void _onAdvancedPressed() {
    showArgonSettingsModal(
      context: context,
      onParamsSelected: (params) => setState(() => _argonParams = params),
      argonParams: _argonParams,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/initial');
      });
      return;
    }
    setState(() {
      _bip39List = args['bip39'] as List<String>?;
      _chain = args['chain'] as NetworkConfigInfo?;
      _keys = args['keys'] as KeyPairInfo?;
      _zilLegacy = args['zilLegacy'] as bool? ?? false;
      _bypassChecksumValidation = args['ignore_checksum'] as bool? ?? false;
    });

    cipherDescriptions[0]['title'] =
        AppLocalizations.of(context)!.cipherSettingsPageStandardTitle;
    cipherDescriptions[0]['subtitle'] =
        AppLocalizations.of(context)!.cipherSettingsPageStandardSubtitle;
    cipherDescriptions[0]['description'] =
        AppLocalizations.of(context)!.cipherSettingsPageStandardDescription;
    cipherDescriptions[1]['title'] =
        AppLocalizations.of(context)!.cipherSettingsPageHybridTitle;
    cipherDescriptions[1]['subtitle'] =
        AppLocalizations.of(context)!.cipherSettingsPageHybridSubtitle;
    cipherDescriptions[1]['description'] =
        AppLocalizations.of(context)!.cipherSettingsPageHybridDescription;
    cipherDescriptions[2]['title'] =
        AppLocalizations.of(context)!.cipherSettingsPageQuantumTitle;
    cipherDescriptions[2]['subtitle'] =
        AppLocalizations.of(context)!.cipherSettingsPageQuantumSubtitle;
    cipherDescriptions[2]['description'] =
        AppLocalizations.of(context)!.cipherSettingsPageQuantumDescription;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<AppState>(context).currentTheme;
    final padding = AdaptiveSize.getAdaptivePadding(context, 16);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                CustomAppBar(
                  title: AppLocalizations.of(context)!.cipherSettingsPageTitle,
                  onBackPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: padding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: _onAdvancedPressed,
                          style: ButtonStyle(
                            overlayColor: const WidgetStatePropertyAll(
                                Colors.transparent),
                            foregroundColor: WidgetStateProperty.resolveWith(
                              (states) => states.contains(WidgetState.pressed)
                                  ? theme.primaryPurple.withValues(alpha: 0.7)
                                  : theme.primaryPurple,
                            ),
                          ),
                          child: Text(
                            AppLocalizations.of(context)!
                                .cipherSettingsPageAdvancedButton,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                        ),
                        OptionsList(
                          options: List.generate(
                            cipherDescriptions.length,
                            (index) => OptionItem(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cipherDescriptions[index]['title']!,
                                    style: TextStyle(
                                      color: theme.textPrimary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    cipherDescriptions[index]['subtitle']!,
                                    style: TextStyle(
                                      color: theme.primaryPurple,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    cipherDescriptions[index]['description']!,
                                    style: TextStyle(
                                      color: theme.textSecondary,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              isSelected: selectedCipherIndex == index,
                              onSelect: () =>
                                  setState(() => selectedCipherIndex = index),
                            ),
                          ),
                          unselectedOpacity: 0.5,
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(padding),
                  child: Column(
                    children: [
                      if (selectedCipherIndex == 2)
                        Text(
                          AppLocalizations.of(context)!
                              .cipherSettingsPageQuantumWarning,
                          style: TextStyle(
                            color: theme.textSecondary,
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      CustomButton(
                        textColor: theme.buttonText,
                        backgroundColor: theme.primaryPurple,
                        text: AppLocalizations.of(context)!
                            .cipherSettingsPageConfirmButton,
                        onPressed: () => Navigator.of(context).pushNamed(
                          '/pass_setup',
                          arguments: {
                            'bip39': _bip39List,
                            'chain': _chain,
                            'keys': _keys,
                            'cipher': _getCipherOrders(),
                            'argon2': _argonParams,
                            'zilLegacy': _zilLegacy,
                            'ignore_checksum': _bypassChecksumValidation,
                          },
                        ),
                        borderRadius: 30.0,
                        height: 50.0,
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

  Uint8List _getCipherOrders() {
    switch (selectedCipherIndex) {
      case 0:
        return Uint8List.fromList([0, 1]); // AES-256 + KUZNECHIK-GOST
      case 1:
        return Uint8List.fromList([1, 3]); // CYBER + KUZNECHIK-GOST
      case 2:
        return Uint8List.fromList([3, 2, 1]); // CYBER + KUZNECHIK + NTRUP1277
      default:
        return Uint8List.fromList([3, 2, 1]); // CYBER + KUZNECHIK + NTRUP1277
    }
  }
}
