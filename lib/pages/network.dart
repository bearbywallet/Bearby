import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/button.dart';
import 'package:zilpay/components/hoverd_svg.dart';
import 'package:zilpay/components/smart_input.dart';
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

  final List<NetworkItem> enabledNetworks = [
    NetworkItem(
      icon: 'https://assets.coingecko.com/coins/images/279/small/ethereum.png',
      name: 'Ethereum Mainnet',
      isEnabled: true,
    ),
    NetworkItem(
      icon:
          'https://assets.coingecko.com/coins/images/2687/small/Zilliqa-logo.png',
      name: 'Zilliqa',
      isEnabled: true,
    ),
    NetworkItem(
      icon:
          'https://assets.coingecko.com/coins/images/825/small/bnb-icon2_2x.png',
      name: 'BNB Smart Chain',
      isEnabled: true,
    ),
  ];

  final List<NetworkItem> additionalNetworks = [
    NetworkItem(
      icon:
          'https://assets.coingecko.com/coins/images/825/small/bnb-icon2_2x.png',
      name: 'Arbitrum One',
      isEnabled: false,
    ),
    NetworkItem(
      icon:
          'https://assets.coingecko.com/coins/images/825/small/bnb-icon2_2x.png',
      name: 'Avalanche Network C-Chain',
      isEnabled: false,
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<NetworkItem> _getFilteredNetworks(List<NetworkItem> networks) {
    if (_searchQuery.isEmpty) return networks;

    return networks
        .where((network) =>
            network.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<AppState>(context).currentTheme;
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);

    final filteredEnabledNetworks = _getFilteredNetworks(enabledNetworks);
    final filteredAdditionalNetworks = _getFilteredNetworks(additionalNetworks);

    return Scaffold(
      backgroundColor: theme.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: adaptivePadding),
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
                      child: Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: adaptivePadding),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 24),
                            if (filteredEnabledNetworks.isNotEmpty) ...[
                              const Text(
                                'Enabled networks',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...filteredEnabledNetworks
                                  .map((network) => _NetworkTile(
                                        icon: Image.network(network.icon),
                                        title: network.name,
                                        isEnabled: network.isEnabled,
                                      )),
                            ],
                            if (filteredAdditionalNetworks.isNotEmpty) ...[
                              const SizedBox(height: 24),
                              const Row(
                                children: [
                                  Text(
                                    'Additional networks',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ...filteredAdditionalNetworks
                                  .map((network) => _NetworkTile(
                                        icon: Image.network(network.icon),
                                        title: network.name,
                                        showAddButton: true,
                                      )),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: CustomButton(
                      text: 'Add a custom network',
                      onPressed: () {},
                      backgroundColor: theme.primaryPurple,
                      borderRadius: 30.0,
                      height: 50.0,
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
  final String icon;
  final String name;
  final bool isEnabled;

  NetworkItem({
    required this.icon,
    required this.name,
    this.isEnabled = false,
  });
}

class _NetworkTile extends StatelessWidget {
  final Widget icon;
  final String title;
  final bool isEnabled;
  final bool showAddButton;

  const _NetworkTile({
    required this.icon,
    required this.title,
    this.isEnabled = false,
    this.showAddButton = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<AppState>(context).currentTheme;

    return ListTile(
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
            color: theme.textSecondary),
      ),
      trailing: showAddButton
          ? TextButton(
              onPressed: () {
                // Добавить обработчик для кнопки Add
              },
              child: const Text(
                'Add',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          : HoverSvgIcon(
              assetName: 'assets/icons/edit.svg',
              width: 20,
              height: 20,
              padding: EdgeInsets.fromLTRB(0, 0, 16, 0),
              color: theme.textSecondary,
              onTap: () {
                //show modal
              },
            ),
    );
  }
}
