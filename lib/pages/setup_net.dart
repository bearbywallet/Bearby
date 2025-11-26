import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/button.dart';
import 'package:zilpay/components/custom_app_bar.dart';
import 'package:zilpay/components/option_list.dart';
import 'package:zilpay/components/smart_input.dart';
import 'package:zilpay/ledger/models/discovered_device.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import 'package:zilpay/mixins/preprocess_url.dart';
import 'package:zilpay/mixins/status_bar.dart';
import 'package:zilpay/components/image_cache.dart';
import 'package:zilpay/src/rust/api/provider.dart';
import 'package:zilpay/src/rust/models/keypair.dart';
import 'package:zilpay/src/rust/models/provider.dart';
import 'package:zilpay/state/app_state.dart';
import 'package:zilpay/theme/app_theme.dart';
import 'package:zilpay/l10n/app_localizations.dart';

class SetupNetworkSettingsPage extends StatefulWidget {
  const SetupNetworkSettingsPage({super.key});

  @override
  State<SetupNetworkSettingsPage> createState() =>
      _SetupNetworkSettingsPageState();
}

class _SetupNetworkSettingsPageState extends State<SetupNetworkSettingsPage>
    with StatusBarMixin {
  List<String>? _bip39List;
  KeyPairInfo? _keys;
  DiscoveredDevice? _ledger;
  String? _errorMessage;
  String? _shortName;
  bool _bypassChecksumValidation = false;
  bool _isTestnet = false;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  int selectedNetworkIndex = 0;
  bool optionsDisabled = false;
  List<NetworkConfigInfo> mainnetNetworks = [];
  List<NetworkConfigInfo> testnetNetworks = [];

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
    final ledger = args?['ledger'] as DiscoveredDevice?;
    final bypassChecksumValidation = args?['ignore_checksum'] as bool?;

    if (bip39 == null && keys == null && ledger == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/initial');
      });
    } else {
      setState(() {
        _bip39List = bip39;
        _ledger = ledger;
        _keys = keys;
        _shortName = shortName;
        _bypassChecksumValidation = bypassChecksumValidation ?? false;
      });
    }
  }

  List<NetworkConfigInfo> get filteredNetworks {
    final networks = _isTestnet ? testnetNetworks : mainnetNetworks;
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
      final appState = Provider.of<AppState>(context, listen: false);
      final storedProviders = appState.state.providers;

      final String mainnetJsonData =
          await rootBundle.loadString('assets/chains/mainnet-chains.json');
      final String testnetJsonData =
          await rootBundle.loadString('assets/chains/testnet-chains.json');
      final List<NetworkConfigInfo> mainnetChains =
          await getChainsProvidersFromJson(jsonStr: mainnetJsonData);
      final List<NetworkConfigInfo> testnetChains =
          await getChainsProvidersFromJson(jsonStr: testnetJsonData);

      setState(() {
        mainnetNetworks = mainnetChains;
        mainnetNetworks =
            _appendUniqueMainnetNetworks(storedProviders, mainnetNetworks);
        testnetNetworks = testnetChains;

        if (_shortName != null) {
          final networks = _isTestnet ? testnetNetworks : mainnetNetworks;
          int foundIndex =
              networks.indexWhere((network) => network.shortName == _shortName);
          if (foundIndex > 0) {
            selectedNetworkIndex = foundIndex;
          }
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = '$e';
      });
      debugPrint('Error loading chains: $e');
    }
  }

  List<NetworkConfigInfo> _appendUniqueMainnetNetworks(
      List<NetworkConfigInfo> storedProviders,
      List<NetworkConfigInfo> jsonChains) {
    final Set<String> jsonNetworkIds =
        jsonChains.map(_createNetworkIdentifier).toSet();
    final List<NetworkConfigInfo> uniqueStoredNetworks = [];

    for (final provider in storedProviders) {
      if (!(provider.testnet ?? false)) {
        final identifier = _createNetworkIdentifier(provider);
        if (!jsonNetworkIds.contains(identifier)) {
          uniqueStoredNetworks.add(provider);
        }
      }
    }

    return [...jsonChains, ...uniqueStoredNetworks];
  }

  String _createNetworkIdentifier(NetworkConfigInfo network) {
    return '${network.slip44}|${network.chainId}';
  }

  OptionItem _buildNetworkItem(
      NetworkConfigInfo chain, AppTheme theme, int index) {
    final l10n = AppLocalizations.of(context)!;

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
                  url: viewChain(network: chain, theme: theme.value),
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
                            color: _isTestnet
                                ? theme.warning.withValues(alpha: 0.2)
                                : theme.success.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _isTestnet
                                ? l10n.setupNetworkSettingsPageTestnetLabel
                                : l10n.setupNetworkSettingsPageMainnetLabel,
                            style: TextStyle(
                              color: _isTestnet ? theme.warning : theme.success,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${l10n.setupNetworkSettingsPageChainIdLabel} ${chain.chainIds.where((id) => id != BigInt.zero).toList().join(",")}',
                      style: TextStyle(
                        color: theme.primaryPurple,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${l10n.setupNetworkSettingsPageTokenLabel} ${chain.chain}',
                      style: TextStyle(
                        color: theme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    if (chain.explorers.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${l10n.setupNetworkSettingsPageExplorerLabel} ${chain.explorers.first.name}',
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
                  actionWidget: Row(
                    children: [
                      Text(
                        l10n.setupNetworkSettingsPageTestnetSwitch,
                        style: TextStyle(
                          color: theme.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Switch(
                        value: _isTestnet,
                        onChanged: (value) {
                          setState(() {
                            _isTestnet = value;
                            selectedNetworkIndex = 0;
                          });
                        },
                        activeThumbColor: theme.primaryPurple,
                      ),
                    ],
                  ),
                  onBackPressed: () => Navigator.pop(context),
                ),
                Padding(
                  padding: EdgeInsets.all(adaptivePadding),
                  child: SmartInput(
                    controller: _searchController,
                    hint: l10n.setupNetworkSettingsPageSearchHint,
                    leftIconPath: 'assets/icons/search.svg',
                    onChanged: (value) => setState(() => _searchQuery = value),
                    borderColor: theme.textPrimary,
                    focusedBorderColor: theme.primaryPurple,
                    height: 48,
                    fontSize: 16,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
                if (_errorMessage != null)
                  Padding(
                    padding: EdgeInsets.all(adaptivePadding),
                    child: Text(
                      _errorMessage!,
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
                            ? l10n.setupNetworkSettingsPageNoNetworks
                            : l10n.setupNetworkSettingsPageNoResults(
                                _searchQuery),
                        style: TextStyle(
                          color: theme.textSecondary,
                          fontSize: 16,
                        ),
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
                                    filteredNetworks[index], theme, index),
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
                    onPressed: filteredNetworks.isEmpty
                        ? () {}
                        : () {
                            final chain = _isTestnet
                                ? testnetNetworks[selectedNetworkIndex]
                                : mainnetNetworks[selectedNetworkIndex];

                            if (_ledger != null) {
                              Navigator.of(context).pushNamed(
                                '/add_ledger_account',
                                arguments: {
                                  'chain': chain,
                                  'isTestnet': _isTestnet,
                                  'ledger': _ledger,
                                },
                              );
                              return;
                            } else {
                              Navigator.of(context).pushNamed(
                                '/cipher_setup',
                                arguments: {
                                  'bip39': _bip39List,
                                  'keys': _keys,
                                  'chain': chain,
                                  'isTestnet': _isTestnet,
                                  'ignore_checksum': _bypassChecksumValidation,
                                },
                              );
                            }
                          },
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
