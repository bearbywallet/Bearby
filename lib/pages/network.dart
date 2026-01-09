import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zilpay/components/network_card.dart';
import 'package:zilpay/components/smart_input.dart';
import 'package:zilpay/mixins/preprocess_url.dart';
import 'package:zilpay/mixins/status_bar.dart';
import 'package:zilpay/modals/chain_config_edit.dart';
import 'package:zilpay/src/rust/api/provider.dart';
import 'package:zilpay/src/rust/models/provider.dart';
import 'package:zilpay/src/rust/models/wallet.dart';
import 'package:zilpay/state/app_state.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import 'package:zilpay/theme/app_theme.dart';
import '../components/custom_app_bar.dart';
import 'package:zilpay/l10n/app_localizations.dart';
import 'package:zilpay/config/web3_constants.dart';

const String kTestnetEnabledKey = 'testnet_enabled';

class NetworkPage extends StatefulWidget {
  const NetworkPage({super.key});

  @override
  State<NetworkPage> createState() => _NetworkPageState();
}

class _NetworkPageState extends State<NetworkPage> with StatusBarMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<NetworkItem> allNetworks = [];
  bool isLoading = true;
  String? errorMessage;
  String? _shortName;
  bool isTestnet = false;
  bool _popOnSelect = false;

  @override
  void initState() {
    super.initState();
    _loadTestnetPreference();
    _loadNetworks();
  }

  Future<void> _loadTestnetPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(kTestnetEnabledKey) ?? false;
    if (mounted) {
      setState(() {
        isTestnet = enabled;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final AppState appState = Provider.of<AppState>(context, listen: false);
    if (appState.chain != null && (appState.chain?.testnet ?? false)) {
      setState(() {
        isTestnet = true;
      });
    }

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      _popOnSelect = args['popOnSelect'] ?? false;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _createNetworkIdentifier(NetworkConfigInfo network) {
    final chainId = network.chainId.toString();
    final slip44 = network.slip44.toString();
    final name = network.name.toLowerCase();
    return '$slip44|$chainId|$name';
  }

  Future<void> _loadNetworks() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final storedProviders = await getProviders();
      final String mainnetJsonData =
          await rootBundle.loadString('assets/chains/mainnet-chains.json');
      final String testnetJsonData =
          await rootBundle.loadString('assets/chains/testnet-chains.json');
      final List<NetworkConfigInfo> mainnetChains =
          await getChainsProvidersFromJson(jsonStr: mainnetJsonData);
      final List<NetworkConfigInfo> testnetChains =
          await getChainsProvidersFromJson(jsonStr: testnetJsonData);

      setState(() {
        allNetworks.clear();

        allNetworks.addAll(storedProviders.map(
            (provider) => NetworkItem(configInfo: provider, isAdded: true)));

        final Set<String> addedNetworkIds = {};
        final Set<String> addedNetworkNamesLower = {};

        for (final network in allNetworks) {
          addedNetworkIds.add(_createNetworkIdentifier(network.configInfo));
          addedNetworkNamesLower.add(network.configInfo.name.toLowerCase());
        }

        for (final chain in mainnetChains) {
          final networkId = _createNetworkIdentifier(chain);
          final nameLower = chain.name.toLowerCase();

          if (!addedNetworkIds.contains(networkId) &&
              !addedNetworkNamesLower.contains(nameLower)) {
            allNetworks.add(NetworkItem(configInfo: chain, isAdded: false));
            addedNetworkIds.add(networkId);
            addedNetworkNamesLower.add(nameLower);
          }
        }

        for (final chain in testnetChains) {
          final networkId = _createNetworkIdentifier(chain);
          final nameLower = chain.name.toLowerCase();

          if (!addedNetworkIds.contains(networkId) &&
              !addedNetworkNamesLower.contains(nameLower)) {
            allNetworks.add(NetworkItem(configInfo: chain, isAdded: false));
          }
        }

        isLoading = false;
        if (_shortName != null) _trySelectNetworkByShortName();
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  void _trySelectNetworkByShortName() {
    if (_shortName == null) return;

    int index = allNetworks
        .indexWhere((network) => network.configInfo.name == _shortName);
    if (index >= 0) {
      _handleNetworkSelect(allNetworks[index]);
    }
  }

  List<NetworkItem> _getFilteredNetworks(List<NetworkItem> networks, NetworkConfigInfo? currentChain) {
    var filtered = networks;

    if (currentChain != null && currentChain.slip44 == kBitcoinlip44) {
      filtered = filtered.where((network) => network.configInfo.slip44 == kBitcoinlip44).toList();
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((network) => network.configInfo.name
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()))
          .toList();
    }

    return filtered;
  }

  List<NetworkItem> _getSortedNetworks(
      List<NetworkItem> networks, NetworkConfigInfo? chain, WalletInfo? wallet) {
    final sortedNetworks = List<NetworkItem>.from(networks);

    sortedNetworks.sort((a, b) {
      final aIsSelected = chain?.chainHash == a.configInfo.chainHash;
      final bIsSelected = chain?.chainHash == b.configInfo.chainHash;

      if (aIsSelected && !bIsSelected) return -1;
      if (!aIsSelected && bIsSelected) return 1;

      final aIsDefault = wallet?.defaultChainHash == a.configInfo.chainHash;
      final bIsDefault = wallet?.defaultChainHash == b.configInfo.chainHash;

      if (aIsDefault && !bIsDefault) return -1;
      if (!aIsDefault && bIsDefault) return 1;

      final aIsMainnet = !(a.configInfo.testnet ?? false);
      final bIsMainnet = !(b.configInfo.testnet ?? false);

      if (aIsMainnet && !bIsMainnet) return -1;
      if (!aIsMainnet && bIsMainnet) return 1;

      return 0;
    });

    return sortedNetworks;
  }

  void _handleNetworkSelect(NetworkItem networkItem) async {
    final appState = Provider.of<AppState>(context, listen: false);
    final config = networkItem.configInfo;

    if (!networkItem.isAdded) {
      try {
        await addProvider(providerConfig: config);
        await appState.syncData();
      } catch (e) {
        setState(() {
          errorMessage =
              '${AppLocalizations.of(context)!.networkPageAddError}$e';
        });
        return;
      }
    }

    try {
      await selectAccountsChain(
        walletIndex: BigInt.from(appState.selectedWallet),
        chainHash: config.chainHash,
      );
    } catch (_) {}

    await appState.syncData();

    if (_popOnSelect && mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  void _handleEditNetwork(NetworkItem networkItem) async {
    final appState = Provider.of<AppState>(context, listen: false);
    final config = networkItem.configInfo;

    if (!networkItem.isAdded) {
      try {
        await addProvider(providerConfig: config);
        await appState.syncData();
        await _loadNetworks();
      } catch (e) {
        setState(() {
          errorMessage =
              '${AppLocalizations.of(context)!.networkPageAddError}$e';
        });
        return;
      }
    }

    if (!mounted) return;

    showChainInfoModal(
      context: context,
      networkConfig: config,
      onRemoved: () async {
        Navigator.of(context).pop();
        await _loadNetworks();
      },
    );
  }

  Widget _buildNetworkList(List<NetworkItem> networks, AppTheme theme,
      NetworkConfigInfo? chain, WalletInfo? wallet) {
    if (networks.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: networks
          .map((network) => NetworkCard(
                configInfo: network.configInfo,
                isAdded: network.isAdded,
                isDefault:
                    wallet?.defaultChainHash == network.configInfo.chainHash,
                isSelected: chain?.chainHash == network.configInfo.chainHash,
                isTestnet: network.configInfo.testnet ?? false,
                iconUrl:
                    viewChain(network: network.configInfo, theme: theme.value),
                onNetworkSelect: (config) {
                  final item = networks.firstWhere(
                      (n) => n.configInfo.chainHash == config.chainHash);
                  _handleNetworkSelect(item);
                },
                onNetworkEdit: (config) {
                  final item = networks.firstWhere(
                      (n) => n.configInfo.chainHash == config.chainHash);
                  _handleEditNetwork(item);
                },
              ))
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final theme = appState.currentTheme;
    final chain = appState.chain;
    final wallet = appState.wallet;
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);
    final filtered = _getFilteredNetworks(allNetworks, chain)
        .where((network) => isTestnet || !(network.configInfo.testnet ?? false))
        .toList();
    final filteredNetworks = _getSortedNetworks(filtered, chain, wallet);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: theme.background,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: adaptivePadding,
                  ),
                  child: CustomAppBar(
                    title: l10n.networkPageTitle,
                    onBackPressed: () => Navigator.pop(context),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: adaptivePadding),
                  child: SmartInput(
                    controller: _searchController,
                    hint: l10n.networkPageSearchHint,
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
                      padding: const EdgeInsets.all(16),
                      child: Text(errorMessage!,
                          style:
                              theme.bodyText2.copyWith(color: theme.danger))),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                        horizontal: adaptivePadding, vertical: 24),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: _buildNetworkList(
                          filteredNetworks, theme, chain, wallet),
                    ),
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

class NetworkItem {
  final NetworkConfigInfo configInfo;
  final bool isAdded;

  NetworkItem({required this.configInfo, required this.isAdded});
}
