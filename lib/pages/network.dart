import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/button.dart';
import 'package:zilpay/components/network_tile.dart';
import 'package:zilpay/components/smart_input.dart';
import 'package:zilpay/config/providers.dart';
import 'package:zilpay/mixins/preprocess_url.dart';
import 'package:zilpay/modals/custom_network_modal.dart';
import 'package:zilpay/src/rust/api/provider.dart';
import 'package:zilpay/src/rust/models/provider.dart';
import 'package:zilpay/state/app_state.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import '../components/custom_app_bar.dart';

class NetworkPage extends StatefulWidget {
  const NetworkPage({super.key});

  @override
  State<NetworkPage> createState() => _NetworkPageState();
}

class _NetworkPageState extends State<NetworkPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<NetworkItem> addedNetworks = [];
  final List<NetworkItem> potentialNetworks = [];

  @override
  void initState() {
    super.initState();
    _loadNetworks();
  }

  bool isLoading = true;
  String? errorMessage;
  String? _shortName;

  Future<void> _loadNetworks() async {
    final appState = Provider.of<AppState>(context);
    try {
      final storedProviders = await getProviders();
      final String mainnetJsonData =
          await rootBundle.loadString('assets/chains/mainnet-chains.json');
      final String testnetJsonData =
          await rootBundle.loadString('assets/chains/testnet-chains.json');

      final List<Chain> mainnetChains =
          await ChainService.loadChains(mainnetJsonData);
      final List<Chain> testnetChains =
          await ChainService.loadChains(testnetJsonData);

      setState(() {
        potentialNetworks.clear();
        addedNetworks.clear();

        addedNetworks.addAll(
          storedProviders.map((provider) => NetworkItem(
                configInfo: provider,
                icon: preprocessUrl(provider.logo, appState.currentTheme.value),
                isEnabled: true,
                isAdded: true,
              )),
        );

        final addedChainIds =
            addedNetworks.map((network) => network.configInfo.chainId).toSet();

        // TODO: add check slip44 and make sure this is works right.
        potentialNetworks.addAll([
          ...mainnetChains
              .where((chain) =>
                  !addedChainIds.contains(BigInt.from(chain.chainId)))
              .map((chain) {
            chain.testnet = false;
            return NetworkItem(
              configInfo: chain.toNetworkConfigInfo(),
              icon: preprocessUrl(chain.logo, appState.currentTheme.value),
              isEnabled: true,
              isAdded: false,
            );
          }),
          ...testnetChains
              .where((chain) =>
                  !addedChainIds.contains(BigInt.from(chain.chainId)))
              .map((chain) {
            chain.testnet = true;
            return NetworkItem(
              configInfo: chain.toNetworkConfigInfo(),
              icon: preprocessUrl(chain.logo, appState.currentTheme.value),
              isEnabled: true,
              isAdded: false,
            );
          }),
        ]);

        isLoading = false;

        if (_shortName != null) {
          int addedIndex = addedNetworks
              .indexWhere((network) => network.configInfo.name == _shortName);
          if (addedIndex >= 0) {
            _handleNetworkSelect(addedNetworks[addedIndex].configInfo);
          } else {
            int potentialIndex = potentialNetworks
                .indexWhere((network) => network.configInfo.name == _shortName);
            if (potentialIndex >= 0) {
              _handleNetworkSelect(
                  potentialNetworks[potentialIndex].configInfo);
            }
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

  List<NetworkItem> _getFilteredNetworks(List<NetworkItem> networks) {
    if (_searchQuery.isEmpty) return networks;
    return networks
        .where((network) => network.configInfo.name
            .toLowerCase()
            .contains(_searchQuery.toLowerCase()))
        .toList();
  }

  void _handleNetworkSelect(NetworkConfigInfo network) async {
    debugPrint('Selected network: ${network.name}');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildNetworkSection(
    String title,
    List<NetworkItem> networks,
    AppState state,
  ) {
    if (networks.isEmpty) return const SizedBox.shrink();
    final theme = state.currentTheme;
    final provider = state.chain!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: theme.textSecondary.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 16),
        ...networks.map((network) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: NetworkTile(
                iconUrl: network.icon ?? "",
                title: network.configInfo.name,
                isTestnet: network.configInfo.testnet,
                isEnabled: network.isEnabled,
                isAdded: network.isAdded,
                isDefault: state.wallet?.defaultChainHash ==
                    network.configInfo.chainHash,
                isSelected:
                    provider.chainHash == network.configInfo.chainHash &&
                        provider.chainId == network.configInfo.chainId,
                disabled: provider.slip44 != network.configInfo.slip44,
                onTap: () => _handleNetworkSelect(network.configInfo),
                onAdd: network.isAdded
                    ? null
                    : () async {
                        await addProvider(providerConfig: network.configInfo);
                        await state.syncData();
                        await _loadNetworks();
                      },
                onEdit: network.isAdded
                    ? () {
                        debugPrint(
                            'Editing network: ${network.configInfo.name}');
                      }
                    : null,
              ),
            )),
      ],
    );
  }

  Widget _buildErrorMessage() {
    if (errorMessage == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        errorMessage!,
        style: const TextStyle(
          color: Colors.red,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final theme = state.currentTheme;
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);

    final filteredAddedNetworks = _getFilteredNetworks(addedNetworks);
    final filteredPotentialNetworks = _getFilteredNetworks(potentialNetworks);

    return Scaffold(
      backgroundColor: theme.background,
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: adaptivePadding,
                    vertical: 16,
                  ),
                  child: CustomAppBar(
                    title: 'Select a network',
                    onBackPressed: () => Navigator.pop(context),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: adaptivePadding),
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
                if (errorMessage != null) _buildErrorMessage(),
                Expanded(
                  child: isLoading
                      ? _buildLoadingIndicator()
                      : SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.symmetric(
                            horizontal: adaptivePadding,
                            vertical: 24,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildNetworkSection(
                                'Added Networks',
                                filteredAddedNetworks,
                                state,
                              ),
                              if (filteredAddedNetworks.isNotEmpty &&
                                  filteredPotentialNetworks.isNotEmpty)
                                const SizedBox(height: 24),
                              _buildNetworkSection(
                                'Available Networks',
                                filteredPotentialNetworks,
                                state,
                              ),
                            ],
                          ),
                        ),
                ),
                Container(
                  padding: EdgeInsets.all(adaptivePadding),
                  width: double.infinity,
                  child: CustomButton(
                    text: 'Add a custom network',
                    onPressed: () {
                      showCustomNetworkModal(
                        context: context,
                        theme: theme,
                        onSave: ({
                          required String networkName,
                          required String rpcUrl,
                          required String chainId,
                          required String symbol,
                          required String explorerUrl,
                        }) {
                          debugPrint('New custom network: $networkName');
                        },
                      );
                    },
                    backgroundColor: theme.primaryPurple,
                    borderRadius: 30.0,
                    height: 50.0,
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
  final String? icon;
  final bool isEnabled;
  final bool isAdded;

  NetworkItem({
    required this.configInfo,
    required this.icon,
    this.isEnabled = false,
    this.isAdded = false,
  });
}
