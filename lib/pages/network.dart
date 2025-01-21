import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/button.dart';
import 'package:zilpay/components/network_tile.dart';
import 'package:zilpay/components/smart_input.dart';
import 'package:zilpay/config/providers.dart';
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

  final List<NetworkItem> addedMainnetNetworks = [];
  final List<NetworkItem> addedTestnetNetworks = [];
  final List<NetworkItem> potentialMainnetNetworks = [];
  final List<NetworkItem> potentialTestnetNetworks = [];

  @override
  void initState() {
    super.initState();
    _loadNetworks();
  }

  Future<void> _loadNetworks() async {
    try {
      final providers = await getProviders();

      // TODO: add here fetch from out json file networks.
      final defaultMainnets = [];
      final defaultTestnets = [];

      setState(() {
        addedMainnetNetworks.clear();
        addedTestnetNetworks.clear();
        potentialMainnetNetworks.clear();
        potentialTestnetNetworks.clear();

        for (var provider in providers) {
          final networkItem = NetworkItem(
            configInfo: provider,
            icon: provider.name, // TODO: remake view icon for porviders.
            isEnabled: true,
            isAdded: true,
          );

          if (isMainnetNetwork(provider.chainId)) {
            addedMainnetNetworks.add(networkItem);
          } else {
            addedTestnetNetworks.add(networkItem);
          }
        }

        for (var network in defaultMainnets) {
          bool isAlreadyAdded = addedMainnetNetworks
              .any((added) => added.configInfo.chainId == network.chainId);

          if (!isAlreadyAdded) {
            potentialMainnetNetworks.add(NetworkItem(
              configInfo: network,
              icon: network.logo,
              isEnabled: true,
              isAdded: false,
            ));
          }
        }

        for (var network in defaultTestnets) {
          bool isAlreadyAdded = addedTestnetNetworks
              .any((added) => added.configInfo.chainId == network.chainId);

          if (!isAlreadyAdded) {
            potentialTestnetNetworks.add(NetworkItem(
              configInfo: network,
              icon: network.logo,
              isEnabled: true,
              isAdded: false,
            ));
          }
        }
      });
    } catch (e) {
      debugPrint('Error loading networks: $e');
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
    // TODO: Implement network selection logic
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
            color: theme.textSecondary.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 16),
        ...networks.map((network) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: NetworkTile(
                iconUrl: network.icon ?? "",
                title: network.configInfo.name,
                isEnabled: network.isEnabled,
                isAdded: network.isAdded,
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
                        // TODO: Implement network editing
                        debugPrint(
                            'Editing network: ${network.configInfo.name}');
                      }
                    : null,
              ),
            )),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final theme = state.currentTheme;
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);

    final filteredAddedMainnet = _getFilteredNetworks(addedMainnetNetworks);
    final filteredAddedTestnet = _getFilteredNetworks(addedTestnetNetworks);
    final filteredPotentialMainnet =
        _getFilteredNetworks(potentialMainnetNetworks);
    final filteredPotentialTestnet =
        _getFilteredNetworks(potentialTestnetNetworks);

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
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: adaptivePadding,
                      vertical: 24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildNetworkSection('Added Mainnet Networks',
                            filteredAddedMainnet, state),
                        if (filteredAddedMainnet.isNotEmpty &&
                            filteredAddedTestnet.isNotEmpty)
                          const SizedBox(height: 24),
                        _buildNetworkSection('Added Testing Networks',
                            filteredAddedTestnet, state),
                        if ((filteredAddedMainnet.isNotEmpty ||
                                filteredAddedTestnet.isNotEmpty) &&
                            filteredPotentialMainnet.isNotEmpty)
                          const SizedBox(height: 24),
                        _buildNetworkSection('Available Mainnet Networks',
                            filteredPotentialMainnet, state),
                        if (filteredPotentialMainnet.isNotEmpty &&
                            filteredPotentialTestnet.isNotEmpty)
                          const SizedBox(height: 24),
                        _buildNetworkSection('Available Testing Networks',
                            filteredPotentialTestnet, state),
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
                          // TODO: Implement custom network addition
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
