import 'package:flutter/material.dart';
import 'package:zilpay/components/custom_network_option.dart';
import 'package:zilpay/components/network_option_item.dart';
import 'package:zilpay/modals/custom_network_modal.dart';
import 'package:zilpay/modals/node_selection_modal.dart';
import '../../theme/app_theme.dart';
import '../../components/option_list.dart';

class NetworkOptions extends StatelessWidget {
  final AppTheme theme;
  final String selectedNetwork;
  final String selectedMainnetNode;
  final String selectedTestnetNode;
  final String customUrl;
  final String customChainId;
  final Function(String) onNetworkSelected;
  final Function(String) onMainnetNodeSelected;
  final Function(String) onTestnetNodeSelected;
  final Function({required String url, required String chainId})
      onCustomNetworkSaved;

  const NetworkOptions({
    super.key,
    required this.theme,
    required this.selectedNetwork,
    required this.selectedMainnetNode,
    required this.selectedTestnetNode,
    required this.customUrl,
    required this.customChainId,
    required this.onNetworkSelected,
    required this.onMainnetNodeSelected,
    required this.onTestnetNodeSelected,
    required this.onCustomNetworkSaved,
  });

  void _showNodeSelectionModal(BuildContext context, bool isMainnet) {
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => NodeSelectionModal(
        theme: theme,
        isMainnet: isMainnet,
        selectedMainnetNode: selectedMainnetNode,
        selectedTestnetNode: selectedTestnetNode,
        onNodeSelected:
            isMainnet ? onMainnetNodeSelected : onTestnetNodeSelected,
      ),
    );
  }

  void _showCustomNetworkModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardBackground,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => CustomNetworkModal(
        theme: theme,
        initialUrl: customUrl,
        initialChainId: customChainId,
        onSave: onCustomNetworkSaved,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 16),
          child: Text(
            'Network Selection',
            style: TextStyle(
              color: theme.textSecondary,
              fontSize: 16,
            ),
          ),
        ),
        OptionsList(
          options: [
            OptionItem(
              isSelected: selectedNetwork == 'mainnet',
              onSelect: () => onNetworkSelected('mainnet'),
              child: NetworkOptionItem(
                theme: theme,
                name: 'Zilliqa mainnet',
                chainId: '1',
                currentNode: selectedMainnetNode,
                onNodeTap: () => _showNodeSelectionModal(context, true),
                isSelected: selectedNetwork == 'mainnet',
                iconPath: 'assets/icons/zil.svg',
              ),
            ),
            OptionItem(
              isSelected: selectedNetwork == 'testnet',
              onSelect: () => onNetworkSelected('testnet'),
              child: NetworkOptionItem(
                theme: theme,
                name: 'Zilliqa testnet',
                chainId: '333',
                currentNode: selectedTestnetNode,
                onNodeTap: () => _showNodeSelectionModal(context, false),
                isSelected: selectedNetwork == 'testnet',
                iconPath: 'assets/icons/flask.svg',
              ),
            ),
            OptionItem(
              isSelected: selectedNetwork == 'custom',
              onSelect: () => onNetworkSelected('custom'),
              child: CustomNetworkOption(
                theme: theme,
                isSelected: selectedNetwork == 'custom',
                customUrl: customUrl,
                onConfigureTap: () => _showCustomNetworkModal(context),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
