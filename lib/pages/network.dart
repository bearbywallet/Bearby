import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/button.dart';
import 'package:zilpay/components/hoverd_svg.dart';
import 'package:zilpay/components/image_cache.dart';
import 'package:zilpay/components/smart_input.dart';
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

  final List<NetworkItem> enabledNetworks = [];
  final List<NetworkItem> additionalNetworks = [];

  @override
  void initState() {
    super.initState();
    _loadNetworks();
  }

  Future<void> _loadNetworks() async {
    try {
      final providers = await getProviders();

      setState(() {
        enabledNetworks.clear();
        enabledNetworks.addAll(
          providers.map((provider) => NetworkItem(
                configInfo: provider,
                icon: provider.logo,
                isEnabled: true,
              )),
        );
      });
    } catch (e) {
      debugPrint('Error loading networks: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<NetworkItem> _getFilteredNetworks(List<NetworkItem> networks) {
    if (_searchQuery.isEmpty) return networks;

    return networks
        .where((network) => network.configInfo.networkName
            .toLowerCase()
            .contains(_searchQuery.toLowerCase()))
        .toList();
  }

  void _handleNetworkSelect(String networkName) {
    print('Selected network: $networkName');
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final theme = state.currentTheme;
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);

    final filteredEnabledNetworks = _getFilteredNetworks(enabledNetworks);
    final filteredAdditionalNetworks = _getFilteredNetworks(additionalNetworks);
    final token = state.wallet!.accounts[state.wallet!.selectedAccount.toInt()];
    final selectedProvider = state.state.providers[token.providerIndex.toInt()];

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
                  child: ScrollConfiguration(
                    behavior: const ScrollBehavior().copyWith(
                      physics: const BouncingScrollPhysics(),
                      overscroll: true,
                    ),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.symmetric(
                        horizontal: adaptivePadding,
                        vertical: 24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (filteredEnabledNetworks.isNotEmpty) ...[
                            Text(
                              'Enabled networks',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: theme.textSecondary.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(height: 16),
                            ...filteredEnabledNetworks.map((network) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: _NetworkTile(
                                    icon: AsyncImage(
                                      url: network.icon ?? "",
                                      width: 24,
                                      height: 24,
                                      fit: BoxFit.contain,
                                      loadingWidget: const Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    ),
                                    title: network.configInfo.networkName,
                                    isEnabled: network.isEnabled,
                                    isSelected: selectedProvider.networkName ==
                                        network.configInfo.networkName,
                                    onTap: () => _handleNetworkSelect(
                                        network.configInfo.networkName),
                                  ),
                                )),
                          ],
                          if (filteredAdditionalNetworks.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            Text(
                              'Additional networks',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: theme.textSecondary.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(height: 16),
                            ...filteredAdditionalNetworks
                                .map((network) => Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: _NetworkTile(
                                        icon: AsyncImage(
                                          url: network.icon ?? "",
                                          width: 24,
                                          height: 24,
                                          fit: BoxFit.contain,
                                          loadingWidget: const Center(
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        ),
                                        title: network.configInfo.networkName,
                                        showAddButton: true,
                                      ),
                                    )),
                          ],
                        ],
                      ),
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
                          // Here you can add logic to save the new network
                          print('New network: $networkName');
                          print('RPC URL: $rpcUrl');
                          print('Chain ID: $chainId');
                          print('Symbol: $symbol');
                          print('Explorer URL: $explorerUrl');
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

  NetworkItem({
    required this.configInfo,
    required this.icon,
    this.isEnabled = false,
  });
}

class _NetworkTile extends StatelessWidget {
  final Widget icon;
  final String title;
  final bool isEnabled;
  final bool showAddButton;
  final bool isSelected;
  final VoidCallback? onTap;

  const _NetworkTile({
    required this.icon,
    required this.title,
    this.isEnabled = false,
    this.showAddButton = false,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<AppState>(context).currentTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? theme.primaryPurple
                : theme.textSecondary.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
          color: isSelected ? theme.primaryPurple.withOpacity(0.1) : null,
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: SizedBox(
            width: 32,
            height: 32,
            child: icon,
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: theme.textSecondary,
            ),
          ),
          trailing: showAddButton
              ? TextButton(
                  onPressed: () {
                    // Add button handler
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: Text(
                    'Add',
                    style: TextStyle(
                      color: theme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              : HoverSvgIcon(
                  assetName: 'assets/icons/edit.svg',
                  width: 20,
                  height: 20,
                  padding: const EdgeInsets.all(8),
                  color: theme.textSecondary,
                  onTap: () {
                    // Show edit modal
                  },
                ),
        ),
      ),
    );
  }
}
