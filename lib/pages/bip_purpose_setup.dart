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

  List<BipPurposeOption> _getBipPurposeOptions(AppLocalizations l10n) {
    return [
      BipPurposeOption(
        purpose: kBip86Purpose,
        name: l10n.bip86Name,
        description: l10n.bip86Description,
      ),
      BipPurposeOption(
        purpose: kBip84Purpose,
        name: l10n.bip84Name,
        description: l10n.bip84Description,
      ),
      BipPurposeOption(
        purpose: kBip49Purpose,
        name: l10n.bip49Name,
        description: l10n.bip49Description,
      ),
      BipPurposeOption(
        purpose: kBip44Purpose,
        name: l10n.bip44Name,
        description: l10n.bip44Description,
      ),
    ];
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
                    title: l10n.bipPurposeSetupPageTitle,
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
                          OptionsList(
                            options: List.generate(
                              _getBipPurposeOptions(l10n).length,
                              (index) => _buildPurposeItem(
                                  _getBipPurposeOptions(l10n)[index],
                                  theme,
                                  index),
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
                          _getBipPurposeOptions(l10n)[_selectedPurposeIndex]
                              .purpose;

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

  BipPurposeOption({
    required this.purpose,
    required this.name,
    required this.description,
  });
}
