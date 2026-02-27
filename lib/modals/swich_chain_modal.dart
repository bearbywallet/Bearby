import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bearby/components/network_card.dart';
import 'package:bearby/components/swipe_button.dart';
import 'package:bearby/mixins/adaptive_size.dart';
import 'package:bearby/mixins/preprocess_url.dart';
import 'package:bearby/src/rust/api/provider.dart';
import 'package:bearby/src/rust/models/provider.dart';
import 'package:bearby/state/app_state.dart';
import 'package:bearby/theme/app_theme.dart';
import 'package:bearby/l10n/app_localizations.dart';

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
    final appState = Provider.of<AppState>(context, listen: false);
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
            style: theme.titleMedium.copyWith(color: theme.textPrimary),
          ),
        ),
      ],
    );
  }

  Widget _buildNetworkList(List<NetworkConfigInfo> networks, AppTheme theme,
      double padding, AppLocalizations l10n) {
    return Expanded(
      child: ListView(
        padding: EdgeInsets.symmetric(
          horizontal: padding,
          vertical: padding / 2,
        ),
        children: networks.map((network) {
          final isSelected = _selectedNetwork?.chainId == network.chainId;

          return NetworkCard(
            configInfo: network,
            isAdded: true,
            isDefault: false,
            isSelected: isSelected,
            isTestnet: network.testnet ?? false,
            iconUrl: viewChain(network: network, theme: theme.value),
            onNetworkSelect: (config) {
              setState(() {
                _selectedNetwork = config;
              });
            },
            onNetworkEdit: null,
          );
        }).toList(),
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
      if (network.chainIds.first == widget.selectedChainId) {
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
}
