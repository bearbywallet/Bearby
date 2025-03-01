import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/button.dart';
import 'package:zilpay/components/custom_app_bar.dart';
import 'package:zilpay/components/option_list.dart';
import 'package:zilpay/components/smart_input.dart';
import 'package:zilpay/config/providers.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import 'package:zilpay/mixins/preprocess_url.dart';
import 'package:zilpay/components/image_cache.dart';
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
  String? _shortName;
  bool _zilLegacy = false;
  bool isTestnet = false;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  int selectedNetworkIndex = 0;
  bool optionsDisabled = false;
  List<Chain> mainnetNetworks = [];
  List<Chain> testnetNetworks = [];

  @override
  void initState() {
    super.initState();
    _loadChains();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final bip39 = args?['bip39'] as List<String>?;
    final keys = args?['keys'] as KeyPairInfo?;
    final shortName = args?['shortName'] as String?;
    final zilLegacy = args?['zilLegacy'] as bool?;

    if (bip39 == null && keys == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/initial');
      });
    } else {
      setState(() {
        _bip39List = bip39;
        _keys = keys;
        _shortName = shortName;
        _zilLegacy = zilLegacy ?? false;
      });
    }
  }

  List<Chain> get filteredNetworks {
    final networks = isTestnet ? testnetNetworks : mainnetNetworks;
    if (_searchQuery.isEmpty) {
      return networks;
    }
    return networks.where((network) {
      final searchLower = _searchQuery.toLowerCase();
      return network.name.toLowerCase().contains(searchLower) ||
          network.chain.toLowerCase().contains(searchLower) ||
          network.chainId.toString().contains(searchLower);
    }).toList();
  }

  Future<void> _loadChains() async {
    try {
      final String mainnetJsonData =
          await rootBundle.loadString('assets/chains/mainnet-chains.json');
      final String testnetJsonData =
          await rootBundle.loadString('assets/chains/testnet-chains.json');

      final List<Chain> mainnetChains =
          await ChainService.loadChains(mainnetJsonData);
      final List<Chain> testnetChains =
          await ChainService.loadChains(testnetJsonData);

      setState(() {
        mainnetNetworks = mainnetChains;
        testnetNetworks = testnetChains;
        isLoading = false;

        if (_shortName != null) {
          final networks = isTestnet ? testnetNetworks : mainnetNetworks;
          int foundIndex =
              networks.indexWhere((network) => network.shortName == _shortName);
          if (foundIndex > 0) {
            selectedNetworkIndex = foundIndex;
          }
        }
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load network chains: $e';
      });
      debugPrint('Error loading chains: $e');
    }
  }

  OptionItem _buildNetworkItem(Chain chain, AppTheme theme, int index) {
    return OptionItem(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: AsyncImage(
                  url: preprocessUrl(chain.logo, theme.value),
                  fit: BoxFit.contain,
                  errorWidget: const Icon(Icons.error),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            chain.name,
                            style: TextStyle(
                              color: theme.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isTestnet
                                ? theme.warning.withValues(alpha: 0.2)
                                : theme.success.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isTestnet ? 'Testnet' : 'Mainnet',
                            style: TextStyle(
                              color: isTestnet ? theme.warning : theme.success,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Chain ID: ${chain.chainIds.where((id) => id != 0).toList().join(",")}',
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
                        'Explorer: ${chain.explorers.first.name}',
                        style: TextStyle(
                          color: theme.textSecondary,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
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
                  actionWidget: Row(
                    children: [
                      Text(
                        'Testnet',
                        style: TextStyle(
                          color: theme.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Switch(
                        value: isTestnet,
                        onChanged: (value) {
                          setState(() {
                            isTestnet = value;
                            selectedNetworkIndex = 0;
                          });
                        },
                        activeColor: theme.primaryPurple,
                      ),
                    ],
                  ),
                  onBackPressed: () => Navigator.pop(context),
                ),
                Padding(
                  padding: EdgeInsets.all(adaptivePadding),
                  child: SmartInput(
                    controller: _searchController,
                    hint: 'Search',
                    leftIconPath: 'assets/icons/search.svg',
                    onChanged: (value) => setState(() => _searchQuery = value),
                    borderColor: theme.textPrimary,
                    focusedBorderColor: theme.primaryPurple,
                    height: 48,
                    fontSize: 16,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
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
                else if (filteredNetworks.isEmpty)
                  Expanded(
                    child: Center(
                      child: Text(
                        mainnetNetworks.isEmpty && testnetNetworks.isEmpty
                            ? 'No networks available'
                            : 'No networks found for "$_searchQuery"',
                      ),
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
                                filteredNetworks.length,
                                (index) => _buildNetworkItem(
                                  filteredNetworks[index],
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
                    onPressed: filteredNetworks.isEmpty
                        ? () {}
                        : () {
                            final chain = isTestnet
                                ? testnetNetworks[selectedNetworkIndex]
                                : mainnetNetworks[selectedNetworkIndex];

                            if (isTestnet) {
                              chain.testnet = true;
                            }

                            Navigator.of(context).pushNamed(
                              '/cipher_setup',
                              arguments: {
                                'bip39': _bip39List,
                                'keys': _keys,
                                'chain': chain,
                                'isTestnet': isTestnet,
                                'zilLegacy': _zilLegacy,
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
