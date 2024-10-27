import 'package:flutter/material.dart';
import 'package:zilpay/components/button.dart';
import 'package:zilpay/components/custom_app_bar.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/gradient_bg.dart';
import 'package:zilpay/components/toggle_item.dart';
import '../theme/theme_provider.dart';

class BlockchainNetwork {
  final String title;
  final String subtitle;
  bool value;

  BlockchainNetwork({
    required this.title,
    required this.subtitle,
    this.value = false,
  });
}

class EVMNetwork {
  final String title;
  final String subtitle;
  bool value;

  EVMNetwork({
    required this.title,
    required this.subtitle,
    this.value = false,
  });
}

class BlockchainSettingsPage extends StatefulWidget {
  const BlockchainSettingsPage({
    super.key,
  });

  @override
  State<BlockchainSettingsPage> createState() => _BlockchainSettingsPageState();
}

class _BlockchainSettingsPageState extends State<BlockchainSettingsPage> {
  List<String>? _bip39List;

  final TextEditingController _rpcUrlController = TextEditingController();
  final List<EVMNetwork> _evmNetworks = [
    EVMNetwork(
      title: "Zilliqa",
      subtitle: "Zilliqa network",
      value: true,
    ),
    EVMNetwork(
      title: "Ethereum",
      subtitle: "Ethereum network",
      value: true,
    ),
    EVMNetwork(
      title: "BSC chain",
      subtitle: "Binance smart chain network",
      value: true,
    ),
  ];
  final List<BlockchainNetwork> _blockchainNetworks = [
    BlockchainNetwork(
      title: "Bitcoin",
      subtitle: "Bitcoin network",
    ),
    BlockchainNetwork(
      title: "Solana",
      subtitle: "Solana blockchain",
    ),
    BlockchainNetwork(
      title: "Tron",
      subtitle: "TRON network",
    ),
    BlockchainNetwork(
      title: "Massa",
      subtitle: "Massa blockchain",
    ),
    BlockchainNetwork(
      title: "NEAR",
      subtitle: "NEAR Protocol",
    ),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments
        as Map<String, List<String>>?;

    if (args == null || args['bip39'] == null || args['bip39']!.isEmpty) {
      // TODO: make it enable if bip39 doesnt exists
      // WidgetsBinding.instance.addPostFrameCallback((_) {
      //   Navigator.of(context).pushReplacementNamed('/gen_bip39');
      // });
    } else {
      setState(() {
        _bip39List = args['bip39'];
      });
    }
  }

  @override
  void dispose() {
    _rpcUrlController.dispose();
    super.dispose();
  }

  void _updateNetworkValue(int index, bool newValue, bool state) {
    setState(() {
      if (state) {
        _evmNetworks[index].value = newValue;
      } else {
        _blockchainNetworks[index].value = newValue;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              CustomAppBar(
                title: 'Blockchain Settings',
                onBackPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: theme.cardBackground,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: List.generate(_evmNetworks.length * 2 - 1,
                                (index) {
                              if (index.isOdd) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  child: Divider(
                                    height: 1,
                                    color: theme.textSecondary.withOpacity(0.2),
                                  ),
                                );
                              }
                              final networkIndex = index ~/ 2;
                              final network = _evmNetworks[networkIndex];
                              return ToggleItem(
                                title: network.title,
                                subtitle: network.subtitle,
                                value: network.value,
                                onChanged: (newValue) => _updateNetworkValue(
                                    networkIndex, newValue, true),
                              );
                            }),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            color: theme.cardBackground,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: List.generate(
                                _blockchainNetworks.length * 2 - 1, (index) {
                              if (index.isOdd) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  child: Divider(
                                    height: 1,
                                    color: theme.textSecondary.withOpacity(0.2),
                                  ),
                                );
                              }
                              final networkIndex = index ~/ 2;
                              final network = _blockchainNetworks[networkIndex];
                              return ToggleItem(
                                title: network.title,
                                subtitle: network.subtitle,
                                value: network.value,
                                onChanged: (newValue) => _updateNetworkValue(
                                    networkIndex, newValue, false),
                              );
                            }),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: CustomButton(
                  text: 'Next',
                  onPressed: () {
                    Navigator.of(context)
                        .pushNamed('/cipher_setup', arguments: {'bip39': []});
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
    );
  }
}
