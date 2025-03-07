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
import 'package:zilpay/web3/eip_1193.dart';

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
  late NetworkConfigInfo _config;
  Map<String, String> _rpcStatus = {};

  @override
  void initState() {
    super.initState();
    _config = widget.networkConfig;
    _checkRpcStatus();
  }

  void _checkRpcStatus() async {}

  void _removeRpc(String rpc) async {
    if (_config.rpc.length > 5) {
      setState(() {
        _config.rpc.remove(rpc);
      });
      await createOrUpdateChain(providerConfig: _config);
    }
  }

  void _selectRpc(int index) async {
    setState(() {
      final selectedRpc = _config.rpc.removeAt(index);
      _config.rpc.insert(0, selectedRpc);
    });
    await createOrUpdateChain(providerConfig: _config);
  }

  void _selectExplorer(int index) async {
    setState(() {
      final selectedExplorer = _config.explorers.removeAt(index);
      _config.explorers.insert(0, selectedExplorer);
    });
    await createOrUpdateChain(providerConfig: _config);
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
            child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  if (_config.ftokens.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.all(adaptivePadding),
                      child: _buildFirstToken(theme),
                    ),
                  Padding(
                    padding: EdgeInsets.all(adaptivePadding),
                    child: _buildNetworkInfo(theme),
                  ),
                  Padding(
                    padding: EdgeInsets.all(adaptivePadding),
                    child: _buildExplorers(theme),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: adaptivePadding),
                    child: _buildRpcList(theme),
                  ),
                ],
              ),
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
              url: preprocessUrl(_config.logo, theme.value),
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
            _config.name,
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
    final chainIds = _config.chainIds.map((id) => id.toString()).join(', ');

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
          _buildInfoItem(
            'Chain',
            Text(
              _config.chain,
              style: TextStyle(color: theme.textPrimary, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
            theme,
            expandValue: true,
          ),
          _buildInfoItem(
            'Short Name',
            Text(
              _config.shortName,
              style: TextStyle(color: theme.textPrimary, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
            theme,
            expandValue: true,
          ),
          _buildInfoItem(
            'Chain ID',
            Text(
              _config.chainId.toString(),
              style: TextStyle(color: theme.textPrimary, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
            theme,
            expandValue: true,
          ),
          _buildInfoItem(
            'Slip44',
            Text(
              _config.slip44.toString(),
              style: TextStyle(color: theme.textPrimary, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
            theme,
            expandValue: true,
          ),
          _buildInfoItem(
            'Chain IDs',
            Text(
              chainIds,
              style: TextStyle(color: theme.textPrimary, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
            theme,
            expandValue: true,
          ),
          if (_config.testnet != null)
            _buildInfoItem(
              'Testnet',
              Text(
                _config.testnet! ? 'Yes' : 'No',
                style: TextStyle(color: theme.textPrimary, fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
              theme,
              expandValue: true,
            ),
          if (_config.diffBlockTime != BigInt.zero)
            _buildInfoItem(
              'Diff Block Time',
              Text(
                _config.diffBlockTime.toString(),
                style: TextStyle(color: theme.textPrimary, fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
              theme,
              expandValue: true,
            ),
          _buildInfoItem(
            'Fallback Enabled',
            Switch(
              value: _config.fallbackEnabled,
              onChanged: (value) async {
                setState(() {
                  _config = _config.copyWith(fallbackEnabled: value);
                });
                await createOrUpdateChain(providerConfig: _config);
              },
              activeColor: theme.primaryPurple,
            ),
            theme,
            expandValue: false,
          ),
        ],
      ),
    );
  }

  Widget _buildFirstToken(AppTheme theme) {
    if (_config.ftokens.isEmpty) {
      return const SizedBox.shrink();
    }

    final token = _config.ftokens.first;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.background.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.textSecondary.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          if (token.logo != null)
            ClipOval(
              child: AsyncImage(
                url: processTokenLogo(token, theme.value),
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
                  strokeWidth: 2,
                  color: theme.primaryPurple,
                ),
              ),
            ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  token.name,
                  style: TextStyle(
                    color: theme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  token.symbol,
                  style: TextStyle(
                    color: theme.textSecondary,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Decimals: ${token.decimals}',
                  style: TextStyle(
                    color: theme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
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
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          padding: EdgeInsets.only(bottom: 8),
          itemCount: _config.rpc.length,
          itemBuilder: (context, index) {
            final rpc = _config.rpc[index];
            final isSelected = index == 0;
            final canDelete = _config.rpc.length > 5;

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
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
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
            children: _config.explorers.asMap().entries.map((entry) {
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

  Widget _buildInfoItem(String label, Widget valueWidget, AppTheme theme,
      {bool expandValue = true}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              color: theme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (expandValue)
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: valueWidget,
              ),
            )
          else
            valueWidget,
        ],
      ),
    );
  }
}
