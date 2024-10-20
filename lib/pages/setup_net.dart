import 'package:flutter/material.dart';
import 'package:zilpay/components/button.dart';
import 'package:zilpay/components/custom_app_bar.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/gradient_bg.dart';
import 'package:zilpay/components/toggle_item.dart';
import '../theme/theme_provider.dart';

class BlockchainSettingsPage extends StatefulWidget {
  const BlockchainSettingsPage({
    super.key,
  });

  @override
  State<BlockchainSettingsPage> createState() => _BlockchainSettingsPageState();
}

class _BlockchainSettingsPageState extends State<BlockchainSettingsPage> {
  final TextEditingController _rpcUrlController = TextEditingController();
  final List<Map<String, dynamic>> _evmNet = [
    {"title": "Zilliqa", "subtitle": "Zilliqa network", "value": true},
    {"title": "Ethereum", "subtitle": "Ethereum network", "value": true},
    {
      "title": "BSC chain",
      "subtitle": "Binance smart chain network",
      "value": true
    }
  ];

  final List<Map<String, dynamic>> _blockchainNetworks = [
    {"title": "Bitcoin", "subtitle": "Bitcoin network", "value": false},
    {"title": "Solana", "subtitle": "Solana blockchain", "value": false},
    {"title": "Tron", "subtitle": "TRON network", "value": false},
    {"title": "Massa", "subtitle": "Massa blockchain", "value": false},
    {"title": "NEAR", "subtitle": "NEAR Protocol", "value": false}
  ];

  @override
  void dispose() {
    _rpcUrlController.dispose();
    super.dispose();
  }

  void _updateNetworkValue(int index, bool newValue, bool state) {
    setState(() {
      if (state) {
        _evmNet[index]['value'] = newValue;
      } else {
        _blockchainNetworks[index]['value'] = newValue;
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
                            children:
                                List.generate(_evmNet.length * 2 - 1, (index) {
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
                              final network = _evmNet[networkIndex];
                              return ToggleItem(
                                title: network['title'],
                                subtitle: network['subtitle'],
                                value: network['value'],
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
                                title: network['title'],
                                subtitle: network['subtitle'],
                                value: network['value'],
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
                  onPressed: () {},
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
