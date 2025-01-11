import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/button.dart';
import 'package:zilpay/components/custom_app_bar.dart';
import 'package:zilpay/components/option_list.dart';
import 'package:zilpay/config/providers.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import 'package:zilpay/src/rust/api/provider.dart';
import 'package:zilpay/src/rust/models/keypair.dart';
import 'package:zilpay/state/app_state.dart';

class SetupNetworkSettingsPage extends StatefulWidget {
  const SetupNetworkSettingsPage({
    super.key,
  });

  @override
  State<SetupNetworkSettingsPage> createState() =>
      _SetupNetworkSettingsPageState();
}

class _SetupNetworkSettingsPageState extends State<SetupNetworkSettingsPage> {
  List<String>? _bip39List;
  KeyPairInfo? _keys;

  int selectedNetworkIndex = 0;
  bool optionsDisabled = false;
  final networks = DefaultNetworkProviders.defaultNetworks();

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final bip39 = args?['bip39'] as List<String>?;
    final keys = args?['keys'] as KeyPairInfo?;

    if (bip39 == null && keys == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/initial');
      });
    } else {
      setState(() {
        _bip39List = bip39;
        _keys = keys;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<AppState>(context).currentTheme;
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                CustomAppBar(
                  title: 'Setup Network',
                  onBackPressed: () => Navigator.pop(context),
                ),
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
                              networks.length,
                              (index) {
                                final network = networks[index];
                                return OptionItem(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        network.networkName,
                                        style: TextStyle(
                                          color: theme.textPrimary,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Chain ID: ${network.chainId}',
                                        style: TextStyle(
                                          color: theme.primaryPurple,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                    ],
                                  ),
                                  isSelected: selectedNetworkIndex == index,
                                  onSelect: () => setState(
                                      () => selectedNetworkIndex = index),
                                );
                              },
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
                    text: 'Next',
                    onPressed: () {
                      Navigator.of(context)
                          .pushNamed('/cipher_setup', arguments: {
                        'bip39': _bip39List,
                        'keys': _keys,
                        'provider': selectedNetworkIndex,
                      });
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
      ),
    );
  }

  Future<void> _init() async {
    try {
      final configs = await getProviders();

      for (final net in configs) {
        debugPrint('''
        Network: ${net.networkName}
        ChainId: ${net.chainId}
        Default: ${net.default_}
      ''');
      }

      if (configs.isEmpty) {
        await addProvidersList(providerConfig: configs);
      } else {
        for (final defaultNet in defaultNets) {
          final exists = configs.any((config) =>
              config.chainId == defaultNet.chainId &&
              config.networkName == defaultNet.networkName);

          // Если сеть отсутствует в configs, добавляем её
          if (!exists && defaultNet.default_) {
            await addProvider();
          }
        }
      }
    } catch (e, trace) {
      debugPrint('Error in _init: $e\n$trace');
    }
  }
}
