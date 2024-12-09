import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/network_options.dart';
import '../theme/theme_provider.dart';
import '../components/custom_app_bar.dart';
import '../mixins/adaptive_size.dart';

class NetworkPage extends StatefulWidget {
  const NetworkPage({super.key});

  @override
  State<NetworkPage> createState() => _NetworkPageState();
}

class _NetworkPageState extends State<NetworkPage> {
  String selectedNetwork = 'mainnet';
  String selectedMainnetNode = 'api.zilliqa.com';
  String selectedTestnetNode = 'dev-api.zilliqa.com';
  String customUrl = '';
  String customChainId = '';

  void updateSelectedNetwork(String network) {
    setState(() => selectedNetwork = network);
  }

  void updateMainnetNode(String node) {
    setState(() => selectedMainnetNode = node);
  }

  void updateTestnetNode(String node) {
    setState(() => selectedTestnetNode = node);
  }

  void updateCustomNetwork({required String url, required String chainId}) {
    setState(() {
      customUrl = url;
      customChainId = chainId;
      selectedNetwork = 'custom';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);

    return Scaffold(
      backgroundColor: theme.background,
      body: SafeArea(
        child: Column(
          children: [
            CustomAppBar(
              title: 'Network',
              onBackPressed: () => Navigator.pop(context),
            ),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: adaptivePadding),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        NetworkOptions(
                          theme: theme,
                          selectedNetwork: selectedNetwork,
                          selectedMainnetNode: selectedMainnetNode,
                          selectedTestnetNode: selectedTestnetNode,
                          customUrl: customUrl,
                          customChainId: customChainId,
                          onNetworkSelected: updateSelectedNetwork,
                          onMainnetNodeSelected: updateMainnetNode,
                          onTestnetNodeSelected: updateTestnetNode,
                          onCustomNetworkSaved: updateCustomNetwork,
                        ),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
