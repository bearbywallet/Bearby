import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/button.dart';
import 'package:zilpay/components/custom_app_bar.dart';
import 'package:zilpay/components/option_list.dart';
import 'package:zilpay/config/providers.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import 'package:zilpay/src/rust/models/keypair.dart';
import 'package:zilpay/state/app_state.dart';
import 'package:zilpay/theme/app_theme.dart';

class SetupNetworkSettingsPage extends StatefulWidget {
  const SetupNetworkSettingsPage({super.key});

  @override
  State<SetupNetworkSettingsPage> createState() =>
      _SetupNetworkSettingsPageState();
}

class _SetupNetworkSettingsPageState extends State<SetupNetworkSettingsPage> {
  List<String>? _bip39List;
  KeyPairInfo? _keys;
  bool isLoading = true;
  String? errorMessage;

  int selectedNetworkIndex = 0;
  bool optionsDisabled = false;
  List<Chain> networks = [];

  @override
  void initState() {
    super.initState();
    _loadChains();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final bip39 = args?['bip39'] as List<String>?;
    final keys = args?['keys'] as KeyPairInfo?;
    final symbol = args?['symbol'] as String?;

    if (bip39 == null && keys == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/initial');
      });
    } else {
      setState(() {
        _bip39List = bip39;
        _keys = keys;

        if (symbol != null) {
          int foundIndex =
              networks.indexWhere((network) => network.chain == symbol);
          if (foundIndex > 0) {
            selectedNetworkIndex = foundIndex;
          }
        }
      });
    }
  }

  Future<void> _loadChains() async {
    try {
      final String jsonData =
          await rootBundle.loadString('assets/chains/mainnet-chains.json');
      final List<Chain> mainnetChains = await ChainService.loadChains(jsonData);

      setState(() {
        networks.clear();
        networks.addAll(mainnetChains);
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load network chains: $e';
      });
      debugPrint('Error loading chains: $e');
    }
  }

  OptionItem _buildNetworkItem(
    Chain chain,
    AppTheme theme,
    int index,
  ) {
    return OptionItem(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            chain.name,
            style: TextStyle(
              color: theme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Chain ID: ${chain.chainId}',
            style: TextStyle(
              color: theme.primaryPurple,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Token: ${chain.chain}',
            style: TextStyle(
              color: theme.textSecondary,
              fontSize: 14,
            ),
          ),
          if (chain.explorers.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Explorer: ${chain.explorers}',
              style: TextStyle(
                color: theme.textSecondary,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
      isSelected: selectedNetworkIndex == index,
      onSelect: () => setState(() => selectedNetworkIndex = index),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<AppState>(context).currentTheme;
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);

    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                CustomAppBar(
                  title: 'Setup Network',
                  onBackPressed: () => Navigator.pop(context),
                ),
                if (errorMessage != null)
                  Padding(
                    padding: EdgeInsets.all(adaptivePadding),
                    child: Text(
                      errorMessage!,
                      style: TextStyle(
                        color: theme.danger,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                else if (networks.isEmpty)
                  const Expanded(
                    child: Center(
                      child: Text('No networks available'),
                    ),
                  )
                else
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: adaptivePadding),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            OptionsList(
                              disabled: optionsDisabled,
                              options: List.generate(
                                networks.length,
                                (index) => _buildNetworkItem(
                                  networks[index],
                                  theme,
                                  index,
                                ),
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
                    text: 'Next',
                    onPressed: networks.isEmpty
                        ? () {}
                        : () {
                            Navigator.of(context).pushNamed(
                              '/cipher_setup',
                              arguments: {
                                'bip39': _bip39List,
                                'keys': _keys,
                                'provider': selectedNetworkIndex,
                              },
                            );
                          },
                    backgroundColor: theme.primaryPurple,
                    borderRadius: 30.0,
                    height: 56.0,
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
