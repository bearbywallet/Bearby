import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/network_tile.dart';
import 'package:zilpay/components/smart_input.dart';
import 'package:zilpay/mixins/preprocess_url.dart';
import 'package:zilpay/modals/chain_config_edit.dart';
import 'package:zilpay/src/rust/api/provider.dart';
import 'package:zilpay/src/rust/models/provider.dart';
import 'package:zilpay/src/rust/models/wallet.dart';
import 'package:zilpay/state/app_state.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import 'package:zilpay/theme/app_theme.dart';
import '../components/custom_app_bar.dart';
import 'package:zilpay/l10n/app_localizations.dart';

class NetworkPage extends StatefulWidget {
  const NetworkPage({super.key});

  @override
  State<NetworkPage> createState() => _NetworkPageState();
}

class _NetworkPageState extends State<NetworkPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<NetworkItem> addedNetworks = [];
  List<NetworkItem> potentialNetworks = [];
  bool isLoading = true;
  String? errorMessage;
  String? _shortName;
  bool isTestnet = false;

  @override
  void initState() {
    super.initState();
    _loadNetworks();
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
        addedNetworks.clear();
        potentialNetworks.clear();

        addedNetworks.addAll(storedProviders.map(
            (provider) => NetworkItem(configInfo: provider, isAdded: true)));

        final Set<String> addedNetworkIds = {};
        final Set<String> addedNetworkNamesLower = {};

        for (final network in addedNetworks) {
          addedNetworkIds.add(_createNetworkIdentifier(network.configInfo));
          addedNetworkNamesLower.add(network.configInfo.name.toLowerCase());
        }

        final List<NetworkItem> potentialMainnetItems = [];
        for (final chain in mainnetChains) {
          final networkId = _createNetworkIdentifier(chain);
          final nameLower = chain.name.toLowerCase();

          if (!addedNetworkIds.contains(networkId) &&
              !addedNetworkNamesLower.contains(nameLower)) {
            potentialMainnetItems
                .add(NetworkItem(configInfo: chain, isAdded: false));
          }
        }

        final List<NetworkItem> potentialTestnetItems = [];
        for (final chain in testnetChains) {
          final networkId = _createNetworkIdentifier(chain);
          final nameLower = chain.name.toLowerCase();

          if (!addedNetworkIds.contains(networkId) &&
              !addedNetworkNamesLower.contains(nameLower)) {
            potentialTestnetItems
                .add(NetworkItem(configInfo: chain, isAdded: false));
          }
        }

        potentialNetworks.clear();
        potentialNetworks
            .addAll([...potentialMainnetItems, ...potentialTestnetItems]);

        isLoading = false;
        if (_shortName != null) _trySelectNetworkByShortName();
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage =
            AppLocalizations.of(context)!.networkPageLoadError + '$e';
      });
    }
  }

  void _trySelectNetworkByShortName() {
    if (_shortName == null) return;

    int addedIndex = addedNetworks
        .indexWhere((network) => network.configInfo.name == _shortName);
    if (addedIndex >= 0) {
      _handleNetworkSelect(addedNetworks[addedIndex].configInfo);
      return;
    }

    int potentialIndex = potentialNetworks
        .indexWhere((network) => network.configInfo.name == _shortName);
    if (potentialIndex >= 0) {
      _handleNetworkSelect(potentialNetworks[potentialIndex].configInfo);
    }
  }

  List<NetworkItem> _getFilteredNetworks(List<NetworkItem> networks) {
    if (_searchQuery.isEmpty) return networks;
    return networks
        .where((network) => network.configInfo.name
            .toLowerCase()
            .contains(_searchQuery.toLowerCase()))
        .toList();
  }

  void _handleNetworkSelect(NetworkConfigInfo network) async {
    final appState = Provider.of<AppState>(context, listen: false);
    try {
      await selectAccountsChain(
          walletIndex: BigInt.from(appState.selectedWallet),
          chainHash: network.chainHash);
      await appState.syncData();
    } catch (_) {}
  }

  Future<void> _handleAddNetwork(
      NetworkConfigInfo config, AppState state) async {
    try {
      await addProvider(providerConfig: config);
      await state.syncData();
      await _loadNetworks();
    } catch (e) {
      setState(() {
        errorMessage = AppLocalizations.of(context)!.networkPageAddError + '$e';
      });
    }
  }

  void _handleEditNetwork(NetworkConfigInfo config) {
    showChainInfoModal(context: context, networkConfig: config);
  }

  Widget _buildNetworkSection(
      String title,
      List<NetworkItem> networks,
      AppTheme theme,
      NetworkConfigInfo? chain,
      WalletInfo? wallet,
      bool isAvailableSection) {
    if (networks.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: theme.textSecondary.withValues(alpha: 0.7))),
        const SizedBox(height: 16),
        ...networks.map((network) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: NetworkTile(
                iconUrl:
                    viewChain(network: network.configInfo, theme: theme.value),
                title: network.configInfo.name,
                isTestnet: network.configInfo.testnet ?? false,
                isAdded: network.isAdded,
                isDefault:
                    wallet?.defaultChainHash == network.configInfo.chainHash,
                isSelected: chain?.chainId == network.configInfo.chainId &&
                    chain?.slip44 == network.configInfo.slip44,
                disabled: chain?.slip44 != network.configInfo.slip44,
                onTap: isAvailableSection
                    ? null
                    : () => _handleNetworkSelect(network.configInfo),
                onAdd: network.isAdded
                    ? null
                    : () => _handleAddNetwork(network.configInfo,
                        Provider.of<AppState>(context, listen: false)),
                onEdit: network.isAdded
                    ? () => _handleEditNetwork(network.configInfo)
                    : null,
              ),
            )),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = appState.currentTheme;
    final chain = appState.chain;
    final wallet = appState.wallet;
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);
    final filteredAddedNetworks = _getFilteredNetworks(addedNetworks);
    final filteredPotentialNetworks = _getFilteredNetworks(potentialNetworks)
        .where((network) => isTestnet || !(network.configInfo.testnet ?? false))
        .toList();
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: theme.background,
      body: SafeArea(
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
                  actionWidget: Row(
                    children: [
                      Text(l10n.networkPageShowTestnet,
                          style: TextStyle(
                              color: theme.textSecondary, fontSize: 14)),
                      const SizedBox(width: 8),
                      Switch(
                          value: isTestnet,
                          onChanged: (value) => setState(() {
                                isTestnet = value;
                                _loadNetworks();
                              }),
                          activeColor: theme.primaryPurple),
                    ],
                  ),
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
                        style: TextStyle(color: theme.danger, fontSize: 14))),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                      horizontal: adaptivePadding, vertical: 24),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildNetworkSection(l10n.networkPageAddedNetworks,
                            filteredAddedNetworks, theme, chain, wallet, false),
                        if (filteredAddedNetworks.isNotEmpty &&
                            filteredPotentialNetworks.isNotEmpty)
                          const SizedBox(height: 24),
                        _buildNetworkSection(
                            l10n.networkPageAvailableNetworks,
                            filteredPotentialNetworks,
                            theme,
                            chain,
                            wallet,
                            true),
                      ],
                    ),
                  ),
                ),
              ),
            ],
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
