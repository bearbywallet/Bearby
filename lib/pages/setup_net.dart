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

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  int selectedNetworkIndex = 0;
  bool optionsDisabled = false;
  List<NetworkConfigInfo> networks = [];

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
      final List<NetworkConfigInfo> mainnetChains =
          await getChainsProvidersFromJson(jsonStr: mainnetJsonData);

      setState(() {
        networks = _appendUniqueNetworks(storedProviders, mainnetChains);

        if (_shortName != null) {
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

  List<NetworkConfigInfo> _appendUniqueNetworks(
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
    final iconSize = AdaptiveSize.getAdaptiveIconSize(context, 40);
    final spacing = AdaptiveSize.getAdaptiveSize(context, 12);

    return OptionItem(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: iconSize,
                height: iconSize,
                child: AsyncImage(
                  url: viewChain(network: chain, theme: theme.value),
                  fit: BoxFit.contain,
                  errorWidget: const Icon(Icons.error),
                ),
              ),
              SizedBox(width: spacing),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chain.name,
                      style: theme.labelLarge.copyWith(
                        color: theme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${l10n.setupNetworkSettingsPageChainIdLabel} ${chain.chainIds.where((id) => id != BigInt.zero).toList().join(",")}',
                      style: theme.bodyText2.copyWith(
                        color: theme.primaryPurple,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${l10n.setupNetworkSettingsPageTokenLabel} ${chain.chain}',
                      style: theme.bodyText2.copyWith(
                        color: theme.textSecondary,
                      ),
                    ),
                    if (chain.explorers.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${l10n.setupNetworkSettingsPageExplorerLabel} ${chain.explorers.first.name}',
                        style: theme.labelSmall.copyWith(
                          color: theme.textSecondary,
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
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: adaptivePadding),
                  child: CustomAppBar(
                    title: l10n.networkPageTitle,
                    onBackPressed: () => Navigator.pop(context),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: adaptivePadding),
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
                      style: theme.bodyText2.copyWith(
                        color: theme.danger,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                else if (filteredNetworks.isEmpty)
                  Expanded(
                    child: Center(
                      child: Text(
                        networks.isEmpty
                            ? l10n.setupNetworkSettingsPageNoNetworks
                            : l10n.setupNetworkSettingsPageNoResults(
                                _searchQuery),
                        style: theme.bodyLarge.copyWith(
                          color: theme.textSecondary,
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
                            const SizedBox(height: 16),
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
                            final chain = networks[selectedNetworkIndex];

                            if (_ledger != null) {
                              Navigator.of(context).pushNamed(
                                '/add_ledger_account',
                                arguments: {
                                  'chain': chain,
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
