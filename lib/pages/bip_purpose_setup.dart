import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/button.dart';
import 'package:zilpay/components/custom_app_bar.dart';
import 'package:zilpay/components/option_list.dart';
import 'package:zilpay/config/bip_purposes.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import 'package:zilpay/mixins/status_bar.dart';
import 'package:zilpay/src/rust/models/keypair.dart';
import 'package:zilpay/src/rust/models/provider.dart';
import 'package:zilpay/state/app_state.dart';
import 'package:zilpay/theme/app_theme.dart';
import 'package:zilpay/l10n/app_localizations.dart';

class BipPurposeSetupPage extends StatefulWidget {
  const BipPurposeSetupPage({super.key});

  @override
  State<BipPurposeSetupPage> createState() => _BipPurposeSetupPageState();
}

class _BipPurposeSetupPageState extends State<BipPurposeSetupPage>
    with StatusBarMixin {
  List<String>? _bip39List;
  KeyPairInfo? _keys;
  NetworkConfigInfo? _chain;
  bool _bypassChecksumValidation = false;

  int _selectedPurposeIndex = 1;

  final List<BipPurposeOption> _bipPurposeOptions = [
    BipPurposeOption(
      purpose: kBip86Purpose,
      name: 'BIP86 (Taproot)',
      description: 'P2TR - Addresses starting with bc1p',
      path: "m/86'/0'/0'/0",
    ),
    BipPurposeOption(
      purpose: kBip84Purpose,
      name: 'BIP84 (Native SegWit)',
      description: 'P2WPKH - Addresses starting with bc1q',
      path: "m/84'/0'/0'/0",
    ),
    BipPurposeOption(
      purpose: kBip49Purpose,
      name: 'BIP49 (SegWit)',
      description: 'P2WPKH-nested-in-P2SH - Addresses starting with 3',
      path: "m/49'/0'/0'/0",
    ),
    BipPurposeOption(
      purpose: kBip44Purpose,
      name: 'BIP44 (Legacy)',
      description: 'P2PKH - Addresses starting with 1',
      path: "m/44'/0'/0'/0",
    ),
  ];

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
      _bypassChecksumValidation = args['ignore_checksum'] as bool? ?? false;
    });
  }

  OptionItem _buildPurposeItem(
      BipPurposeOption option, AppTheme theme, int index) {
    return OptionItem(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            option.name,
            style: theme.labelLarge.copyWith(
              color: theme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            option.description,
            style: theme.bodyText2.copyWith(
              color: theme.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            option.path,
            style: theme.labelSmall.copyWith(
              color: theme.primaryPurple,
            ),
          ),
        ],
      ),
      isSelected: _selectedPurposeIndex == index,
      onSelect: () => setState(() => _selectedPurposeIndex = index),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<AppState>(context).currentTheme;
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);
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
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: adaptivePadding),
                  child: CustomAppBar(
                    title: 'Bitcoin Address Type',
                    onBackPressed: () => Navigator.pop(context),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: EdgeInsets.all(adaptivePadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select the address type you want to restore',
                            style: theme.bodyLarge.copyWith(
                              color: theme.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          OptionsList(
                            options: List.generate(
                              _bipPurposeOptions.length,
                              (index) => _buildPurposeItem(
                                  _bipPurposeOptions[index], theme, index),
                            ),
                            unselectedOpacity: 0.5,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(adaptivePadding),
                  child: CustomButton(
                    textColor: theme.buttonText,
                    backgroundColor: theme.primaryPurple,
                    text: l10n.setupNetworkSettingsPageNextButton,
                    onPressed: () {
                      final selectedPurpose =
                          _bipPurposeOptions[_selectedPurposeIndex].purpose;

                      Navigator.of(context).pushNamed(
                        '/cipher_setup',
                        arguments: {
                          'bip39': _bip39List,
                          'keys': _keys,
                          'chain': _chain,
                          'ignore_checksum': _bypassChecksumValidation,
                          'bipPurpose': selectedPurpose,
                        },
                      );
                    },
                    borderRadius: 30.0,
                    height: 56.0,
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

class BipPurposeOption {
  final int purpose;
  final String name;
  final String description;
  final String path;

  BipPurposeOption({
    required this.purpose,
    required this.name,
    required this.description,
    required this.path,
  });
}
