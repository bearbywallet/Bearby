import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/bip_purpose_selector.dart';
import 'package:zilpay/components/button.dart';
import 'package:zilpay/components/custom_app_bar.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import 'package:zilpay/mixins/status_bar.dart';
import 'package:zilpay/src/rust/models/keypair.dart';
import 'package:zilpay/src/rust/models/provider.dart';
import 'package:zilpay/state/app_state.dart';
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
                      child: BipPurposeSelector(
                        selectedIndex: _selectedPurposeIndex,
                        onSelect: (index) =>
                            setState(() => _selectedPurposeIndex = index),
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
                      final options =
                          BipPurposeSelector.getBipPurposeOptions(l10n);
                      final selectedPurpose =
                          options[_selectedPurposeIndex].purpose;

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
