import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/button.dart';
import 'package:zilpay/components/option_list.dart';
import 'package:zilpay/components/smart_input.dart';
import '../mixins/adaptive_size.dart';

import '../components/custom_app_bar.dart';
import '../theme/app_theme.dart' as theme;
import '../theme/theme_provider.dart';

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

  final Map<String, String> mainnetNodes = {
    'Zilliqa mainnet': 'api.zilliqa.com',
    'Zilliqa mainnet backup': 'api-backup.zilliqa.com',
  };

  final Map<String, String> testnetNodes = {
    'Zilliqa testnet': 'dev-api.zilliqa.com',
    'Zilliqa testnet backup': 'dev-api-backup.zilliqa.com',
  };

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
                        _buildNetworkOptions(theme),
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

  Widget _buildNetworkOptions(theme.AppTheme theme) {
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
              onSelect: () => setState(() => selectedNetwork = 'mainnet'),
              child: _buildNetworkOption(
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
              onSelect: () => setState(() => selectedNetwork = 'testnet'),
              child: _buildNetworkOption(
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
              onSelect: () => setState(() => selectedNetwork = 'custom'),
              child: _buildCustomNetworkOption(theme),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNetworkOption({
    required theme.AppTheme theme,
    required String name,
    required String chainId,
    required String currentNode,
    required VoidCallback onNodeTap,
    required bool isSelected,
    required String iconPath,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SvgPicture.asset(
                iconPath,
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(
                  isSelected ? theme.primaryPurple : theme.textSecondary,
                  BlendMode.srcIn,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: isSelected ? theme.primaryPurple : theme.textPrimary,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Chain ID: $chainId',
                  style: TextStyle(
                    color: theme.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: isSelected ? onNodeTap : null,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              backgroundColor: isSelected
                  ? theme.background
                  : theme.background.withOpacity(0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: isSelected
                      ? theme.primaryPurple
                      : theme.textSecondary.withOpacity(0.5),
                ),
              ),
              splashFactory: NoSplash.splashFactory,
            ),
            child: Text(
              currentNode,
              style: TextStyle(
                color: isSelected
                    ? theme.primaryPurple
                    : theme.textPrimary.withOpacity(0.5),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomNetworkOption(theme.AppTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SvgPicture.asset(
                'assets/icons/documents.svg',
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(
                  selectedNetwork == 'custom'
                      ? theme.primaryPurple
                      : theme.textSecondary,
                  BlendMode.srcIn,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Custom Network',
                    style: TextStyle(
                      color: selectedNetwork == 'custom'
                          ? theme.primaryPurple
                          : theme.textPrimary,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Configure your own network settings',
                    style: TextStyle(
                      color: theme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () => _showCustomNetworkModal(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              backgroundColor: selectedNetwork == 'custom'
                  ? theme.background
                  : theme.background.withOpacity(0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: selectedNetwork == 'custom'
                      ? theme.primaryPurple
                      : theme.textSecondary.withOpacity(0.5),
                ),
              ),
              splashFactory: NoSplash.splashFactory,
            ),
            child: Text(
              customUrl.isEmpty ? 'Configure Network' : customUrl,
              style: TextStyle(
                color: selectedNetwork == 'custom'
                    ? theme.primaryPurple
                    : theme.textPrimary.withOpacity(0.5),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showCustomNetworkModal(BuildContext context) {
    final theme =
        Provider.of<ThemeProvider>(context, listen: false).currentTheme;
    String tempUrl = customUrl;
    String tempChainId = customChainId;

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardBackground,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Configure Custom Network',
              style: TextStyle(
                color: theme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            SmartInput(
              controller: TextEditingController(text: tempUrl),
              hint: 'Node URL',
              onChanged: (value) => tempUrl = value,
              borderColor: theme.textSecondary.withOpacity(0.3),
              focusedBorderColor: theme.primaryPurple,
              height: 48,
              fontSize: 16,
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            const SizedBox(height: 16),
            SmartInput(
              controller: TextEditingController(text: tempChainId),
              hint: 'Chain ID',
              onChanged: (value) => tempChainId = value,
              borderColor: theme.textSecondary.withOpacity(0.3),
              focusedBorderColor: theme.primaryPurple,
              height: 48,
              fontSize: 16,
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                text: 'Save',
                onPressed: () {
                  setState(() {
                    customUrl = tempUrl;
                    customChainId = tempChainId;
                    selectedNetwork = 'custom';
                  });
                  Navigator.pop(context);
                },
                backgroundColor: theme.primaryPurple,
                textColor: theme.textPrimary,
                borderRadius: 8,
                height: 48,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showNodeSelectionModal(BuildContext context, bool isMainnet) {
    final theme =
        Provider.of<ThemeProvider>(context, listen: false).currentTheme;
    final nodes = isMainnet ? mainnetNodes : testnetNodes;

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Node',
              style: TextStyle(
                color: theme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            ...nodes.entries.map(
              (entry) => ListTile(
                title: Text(
                  entry.key,
                  style: TextStyle(color: theme.textPrimary),
                ),
                subtitle: Text(
                  entry.value,
                  style: TextStyle(color: theme.textSecondary),
                ),
                trailing: (isMainnet && entry.value == selectedMainnetNode) ||
                        (!isMainnet && entry.value == selectedTestnetNode)
                    ? SvgPicture.asset(
                        'assets/icons/ok.svg',
                        width: 24,
                        height: 24,
                        colorFilter: ColorFilter.mode(
                          theme.primaryPurple,
                          BlendMode.srcIn,
                        ),
                      )
                    : null,
                onTap: () {
                  setState(() {
                    if (isMainnet) {
                      selectedMainnetNode = entry.value;
                    } else {
                      selectedTestnetNode = entry.value;
                    }
                  });
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
