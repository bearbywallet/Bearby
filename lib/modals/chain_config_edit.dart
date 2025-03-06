import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/image_cache.dart';
import 'package:zilpay/components/hoverd_svg.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import 'package:zilpay/mixins/preprocess_url.dart';
import 'package:zilpay/src/rust/api/provider.dart';
import 'package:zilpay/src/rust/models/provider.dart';
import 'package:zilpay/state/app_state.dart';
import 'package:zilpay/theme/app_theme.dart';

void showChainInfoModal({
  required BuildContext context,
  required NetworkConfigInfo networkConfig,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    enableDrag: true,
    isDismissible: true,
    useSafeArea: true,
    barrierColor: Colors.black54,
    builder: (context) => Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: _ChainInfoModalContent(networkConfig: networkConfig),
    ),
  );
}

class _ChainInfoModalContent extends StatefulWidget {
  final NetworkConfigInfo networkConfig;

  const _ChainInfoModalContent({required this.networkConfig});

  @override
  State<_ChainInfoModalContent> createState() => _ChainInfoModalContentState();
}

class _ChainInfoModalContentState extends State<_ChainInfoModalContent> {
  Map<String, String> _rpcStatus = {};

  @override
  void initState() {
    super.initState();
    _checkRpcStatus();
  }

  void _checkRpcStatus() async {}

  void _removeRpc(String rpc) async {
    if (widget.networkConfig.rpc.length > 5) {
      setState(() {
        widget.networkConfig.rpc.remove(rpc);
      });
    }

    await createOrUpdateChain(providerConfig: widget.networkConfig);
  }

  void _selectRpc(int index) async {
    setState(() {
      final selectedRpc = widget.networkConfig.rpc.removeAt(index);
      widget.networkConfig.rpc.insert(0, selectedRpc);
    });

    await createOrUpdateChain(providerConfig: widget.networkConfig);
  }

  void _selectExplorer(int index) async {
    setState(() {
      final selectedExplorer = widget.networkConfig.explorers.removeAt(index);
      widget.networkConfig.explorers.insert(0, selectedExplorer);
    });

    await createOrUpdateChain(providerConfig: widget.networkConfig);
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = appState.currentTheme;
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 12);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: theme.modalBorder, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 4,
            margin: EdgeInsets.symmetric(vertical: adaptivePadding),
            decoration: BoxDecoration(
              color: theme.modalBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: adaptivePadding),
            child: _buildHeader(theme),
          ),
          Expanded(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(adaptivePadding),
                  child: _buildNetworkInfo(theme),
                ),
                Padding(
                  padding: EdgeInsets.all(adaptivePadding),
                  child: _buildExplorers(theme),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: adaptivePadding),
                    child: _buildRpcList(theme),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }

  Widget _buildHeader(AppTheme theme) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
                color: theme.primaryPurple.withValues(alpha: 0.2), width: 2),
          ),
          child: ClipOval(
            child: AsyncImage(
              url: preprocessUrl(widget.networkConfig.logo, theme.value),
              width: 40,
              height: 40,
              fit: BoxFit.cover,
              errorWidget: SvgPicture.asset(
                'assets/icons/warning.svg',
                width: 20,
                height: 20,
                colorFilter: ColorFilter.mode(theme.warning, BlendMode.srcIn),
              ),
              loadingWidget: CircularProgressIndicator(
                  strokeWidth: 2, color: theme.primaryPurple),
            ),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            widget.networkConfig.name,
            style: TextStyle(
              color: theme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildNetworkInfo(AppTheme theme) {
    final chainIds =
        widget.networkConfig.chainIds.map((id) => id.toString()).join(', ');

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.background.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.textSecondary.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Network Information',
            style: TextStyle(
              color: theme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          _buildInfoItem('Chain', widget.networkConfig.chain, theme),
          _buildInfoItem('Short Name', widget.networkConfig.shortName, theme),
          _buildInfoItem(
              'Chain ID', widget.networkConfig.chainId.toString(), theme),
          _buildInfoItem(
              'Slip44', widget.networkConfig.slip44.toString(), theme),
          _buildInfoItem('Chain IDs', chainIds, theme),
        ],
      ),
    );
  }

  Widget _buildRpcList(AppTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RPC Nodes',
          style: TextStyle(
            color: theme.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.only(bottom: 8),
            itemCount: widget.networkConfig.rpc.length,
            itemBuilder: (context, index) {
              final rpc = widget.networkConfig.rpc[index];
              final isSelected = index == 0;
              final canDelete = widget.networkConfig.rpc.length > 5;

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _selectRpc(index),
                child: Container(
                  margin: EdgeInsets.only(bottom: 6),
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: isSelected
                            ? theme.primaryPurple
                            : theme.textSecondary.withValues(alpha: 0.2)),
                    borderRadius: BorderRadius.circular(8),
                    color: isSelected
                        ? theme.primaryPurple.withValues(alpha: 0.1)
                        : theme.background.withValues(alpha: 0.5),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          rpc,
                          style: TextStyle(
                            color: theme.textPrimary,
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (canDelete)
                        HoverSvgIcon(
                          assetName: 'assets/icons/minus.svg',
                          width: 20,
                          height: 20,
                          color: theme.danger,
                          onTap: () => _removeRpc(rpc),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildExplorers(AppTheme theme) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.background.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.textSecondary.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Explorers',
            style: TextStyle(
              color: theme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Column(
            children:
                widget.networkConfig.explorers.asMap().entries.map((entry) {
              final index = entry.key;
              final explorer = entry.value;
              final isSelected = index == 0;

              return GestureDetector(
                onTap: () => _selectExplorer(index),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  margin: EdgeInsets.only(bottom: 6),
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSelected
                          ? theme.primaryPurple
                          : theme.textSecondary.withValues(alpha: 0.2),
                    ),
                    borderRadius: BorderRadius.circular(8),
                    color: isSelected
                        ? theme.primaryPurple.withValues(alpha: 0.1)
                        : Colors.transparent,
                  ),
                  child: Row(
                    children: [
                      if (explorer.icon != null)
                        AsyncImage(
                          url: explorer.icon!,
                          width: 20,
                          height: 20,
                          fit: BoxFit.cover,
                          errorWidget: SvgPicture.asset(
                            'assets/icons/warning.svg',
                            width: 16,
                            height: 16,
                            colorFilter: ColorFilter.mode(
                                theme.warning, BlendMode.srcIn),
                          ),
                          loadingWidget: CircularProgressIndicator(
                              strokeWidth: 2, color: theme.primaryPurple),
                        ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              explorer.name,
                              style: TextStyle(
                                color: theme.textPrimary,
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              explorer.url,
                              style: TextStyle(
                                  color: theme.textSecondary, fontSize: 10),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, AppTheme theme) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              color: theme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: theme.textPrimary, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
