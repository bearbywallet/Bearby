import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/image_cache.dart';
import 'package:zilpay/components/swipe_button.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import 'package:zilpay/mixins/preprocess_url.dart';
import 'package:zilpay/src/rust/api/provider.dart';
import 'package:zilpay/src/rust/models/provider.dart';
import 'package:zilpay/state/app_state.dart';
import 'package:zilpay/theme/app_theme.dart';
import 'package:zilpay/l10n/app_localizations.dart';

void showSwitchChainNetworkModal({
  required BuildContext context,
  required BigInt selectedChainId,
  required Function() onNetworkSelected,
  required Function() onReject,
}) {
  bool isCallbackCalled = false;

  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    enableDrag: true,
    isDismissible: true,
    useSafeArea: true,
    barrierColor: Colors.black54,
    builder: (BuildContext context) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _SwitchChainNetworkContent(
          selectedChainId: selectedChainId,
          onNetworkSelected: () {
            isCallbackCalled = true;
            onNetworkSelected();
          },
        ),
      );
    },
  ).then((_) {
    if (!isCallbackCalled) {
      onReject();
    }
  });
}

class _SwitchChainNetworkContent extends StatefulWidget {
  final BigInt selectedChainId;
  final Function() onNetworkSelected;

  const _SwitchChainNetworkContent({
    required this.selectedChainId,
    required this.onNetworkSelected,
  });

  @override
  State<_SwitchChainNetworkContent> createState() =>
      _SwitchChainNetworkContentState();
}

class _SwitchChainNetworkContentState
    extends State<_SwitchChainNetworkContent> {
  NetworkConfigInfo? _selectedNetwork;

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = appState.currentTheme;
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final l10n = AppLocalizations.of(context)!;

    final sortedNetworks = _getSortedNetworks(appState);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: theme.modalBorder, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(theme, adaptivePadding, l10n),
          _buildNetworkList(sortedNetworks, theme, adaptivePadding, l10n),
          _buildSwipeButton(theme, bottomPadding, l10n),
        ],
      ),
    );
  }

  Widget _buildHeader(AppTheme theme, double padding, AppLocalizations l10n) {
    return Column(
      children: [
        Container(
          width: 36,
          height: 4,
          margin: EdgeInsets.symmetric(vertical: padding),
          decoration: BoxDecoration(
            color: theme.modalBorder,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: padding),
          child: Text(
            l10n.switchChainNetworkContentTitle,
            style: TextStyle(
              color: theme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNetworkList(List<NetworkConfigInfo> networks, AppTheme theme,
      double padding, AppLocalizations l10n) {
    return Expanded(
      child: ListView.separated(
        padding: EdgeInsets.symmetric(
          horizontal: padding,
          vertical: padding / 2,
        ),
        itemCount: networks.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          color: theme.textSecondary.withValues(alpha: 0.1),
        ),
        itemBuilder: (context, index) {
          final network = networks[index];
          final isSelected = _selectedNetwork?.chainId == network.chainId;

          return _buildNetworkItem(
            network: network,
            isSelected: isSelected,
            theme: theme,
            l10n: l10n,
          );
        },
      ),
    );
  }

  Widget _buildSwipeButton(
      AppTheme theme, double bottomPadding, AppLocalizations l10n) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 8 + bottomPadding),
          decoration: BoxDecoration(
            color: theme.cardBackground.withValues(alpha: 0.9),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              Center(
                child: SwipeButton(
                  text: l10n.switchChainNetworkContentButton,
                  backgroundColor: theme.primaryPurple,
                  textColor: theme.textPrimary,
                  disabled: _selectedNetwork == null,
                  onSwipeComplete: () async {
                    if (_selectedNetwork != null) {
                      final appState =
                          Provider.of<AppState>(context, listen: false);
                      try {
                        await selectAccountsChain(
                          walletIndex: BigInt.from(appState.selectedWallet),
                          chainHash: _selectedNetwork!.chainHash,
                        );
                        await appState.syncData();
                      } catch (_) {}

                      widget.onNetworkSelected();

                      if (mounted) Navigator.pop(context);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<NetworkConfigInfo> _getSortedNetworks(AppState appState) {
    final networks = List<NetworkConfigInfo>.from(appState.state.providers);

    NetworkConfigInfo? selectedNetwork;
    final filteredNetworks = <NetworkConfigInfo>[];

    for (final network in networks) {
      if (network.chainIds.contains(widget.selectedChainId)) {
        selectedNetwork = network;
        setState(() {
          _selectedNetwork = network;
        });
      } else {
        filteredNetworks.add(network);
      }
    }

    if (selectedNetwork != null) {
      return [selectedNetwork, ...filteredNetworks];
    }

    return networks;
  }

  Widget _buildNetworkItem({
    required NetworkConfigInfo network,
    required bool isSelected,
    required AppTheme theme,
    required AppLocalizations l10n,
  }) {
    final isTestnet = network.testnet ?? false;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedNetwork = network;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: isSelected
              ? theme.primaryPurple.withValues(alpha: 0.1)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            _buildNetworkLogo(network, isSelected, theme),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildNetworkNameRow(
                      network, isSelected, isTestnet, theme, l10n),
                  const SizedBox(height: 4),
                  _buildNetworkDetailsRow(network, theme, l10n),
                ],
              ),
            ),
            if (isSelected)
              SvgPicture.asset(
                'assets/icons/ok.svg',
                width: 24,
                height: 24,
                colorFilter:
                    ColorFilter.mode(theme.primaryPurple, BlendMode.srcIn),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkLogo(
      NetworkConfigInfo network, bool isSelected, AppTheme theme) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected
              ? theme.primaryPurple
              : theme.textSecondary.withValues(alpha: 0.2),
          width: 2,
        ),
      ),
      child: ClipOval(
        child: AsyncImage(
          url: viewChain(network: network, theme: theme.value),
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorWidget: SvgPicture.asset(
            'assets/icons/warning.svg',
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(theme.warning, BlendMode.srcIn),
          ),
          loadingWidget: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: theme.primaryPurple,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNetworkNameRow(
    NetworkConfigInfo network,
    bool isSelected,
    bool isTestnet,
    AppTheme theme,
    AppLocalizations l10n,
  ) {
    return Row(
      children: [
        Expanded(
          child: Text(
            network.name,
            style: TextStyle(
              color: theme.textPrimary,
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (isTestnet)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            margin: const EdgeInsets.only(left: 4),
            decoration: BoxDecoration(
              color: theme.warning.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              l10n.switchChainNetworkContentTestnetLabel,
              style: TextStyle(
                color: theme.warning,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildNetworkDetailsRow(
      NetworkConfigInfo network, AppTheme theme, AppLocalizations l10n) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: theme.primaryPurple.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            network.shortName,
            style: TextStyle(
              color: theme.primaryPurple,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${l10n.switchChainNetworkContentIdLabel} ${network.chainIds.join(", ")}',
          style: TextStyle(
            color: theme.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
