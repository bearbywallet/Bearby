import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/detail_group_card.dart';
import 'package:zilpay/components/detail_item_group_card.dart';
import 'package:zilpay/components/image_cache.dart';
import 'package:zilpay/components/hoverd_svg.dart';
import 'package:zilpay/components/swipe_button.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import 'package:zilpay/mixins/preprocess_url.dart';
import 'package:zilpay/src/rust/api/provider.dart';
import 'package:zilpay/src/rust/models/provider.dart';
import 'package:zilpay/state/app_state.dart';
import 'package:zilpay/theme/app_theme.dart';
import 'package:zilpay/web3/eip_1193.dart';
import 'package:zilpay/l10n/app_localizations.dart';

void showChainInfoModal({
  required BuildContext context,
  required NetworkConfigInfo networkConfig,
  VoidCallback? onRemoved,
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
      child: _ChainInfoModalContent(
        networkConfig: networkConfig,
        onRemoved: onRemoved,
      ),
    ),
  );
}

class _ChainInfoModalContent extends StatefulWidget {
  final NetworkConfigInfo networkConfig;
  final VoidCallback? onRemoved;

  const _ChainInfoModalContent({
    required this.networkConfig,
    this.onRemoved,
  });

  @override
  State<_ChainInfoModalContent> createState() => _ChainInfoModalContentState();
}

class _ChainInfoModalContentState extends State<_ChainInfoModalContent> {
  late NetworkConfigInfo _config;
  bool _isDeleting = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _config = widget.networkConfig;
    _checkRpcStatus();
  }

  void _checkRpcStatus() async {}

  bool _canRemove(AppState appState) {
    for (int i = 0; i < appState.wallets.length; i++) {
      final wallet = appState.wallets[i];

      if (wallet.defaultChainHash == _config.chainHash) {
        return false;
      }

      for (int j = 0; j < wallet.accounts.length; j++) {
        final account = wallet.accounts[j];

        if (account.chainHash == _config.chainHash) {
          return false;
        }
      }
    }
    return true;
  }

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

  Future<void> _deleteProvider(AppState appState) async {
    if (_isDeleting) return;

    setState(() {
      _isDeleting = true;
      _errorText = null;
    });

    final hash = _config.chainHash;
    int index = appState.state.providers.indexWhere((p) => p.chainHash == hash);

    if (index == -1) {
      setState(() {
        _isDeleting = false;
        _errorText = 'Provider not found';
      });
      return;
    }

    try {
      await removeProvider(providerIndex: index);
      await appState.syncData();

      if (mounted) {
        if (widget.onRemoved != null) {
          widget.onRemoved!();
        } else {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDeleting = false;
          _errorText = e.toString();
        });
      }
    } finally {
      if (mounted && _isDeleting) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = appState.currentTheme;
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 12);
    final l10n = AppLocalizations.of(context)!;

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
          _buildModalHeader(theme, adaptivePadding, _config.chain),
          Expanded(
            child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: adaptivePadding,
                  vertical: adaptivePadding / 2,
                ),
                child: Column(
                  children: [
                    if (_config.ftokens.isNotEmpty)
                      _buildTokenSection(appState, theme, l10n),
                    const SizedBox(height: 12),
                    _buildNetworkInfoSection(theme, l10n),
                    const SizedBox(height: 12),
                    _buildExplorersSection(theme, l10n),
                    const SizedBox(height: 12),
                    _buildRpcNodesSection(theme, l10n),
                    const SizedBox(height: 12),
                    _buildDeleteProviderSection(appState, l10n),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }

  Widget _buildModalHeader(AppTheme theme, double padding, String title) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 4,
          margin: EdgeInsets.symmetric(vertical: padding),
          decoration: BoxDecoration(
            color: theme.modalBorder,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        if (title.isNotEmpty)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: padding),
            child: Text(
              title,
              style: TextStyle(
                color: theme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        SizedBox(height: padding),
      ],
    );
  }

  Widget _buildTokenSection(
      AppState appState, AppTheme theme, AppLocalizations l10n) {
    if (_config.ftokens.isEmpty) {
      return const SizedBox.shrink();
    }

    final token = _config.ftokens.first;

    return DetailGroupCard(
      title: l10n.chainInfoModalContentTokenTitle,
      theme: theme,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              if (token.logo != null)
                ClipOval(
                  child: AsyncImage(
                    url: processTokenLogo(
                      token: token,
                      shortName: appState.chain?.shortName ?? "",
                      theme: theme.value,
                    ),
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorWidget: SvgPicture.asset(
                      'assets/icons/warning.svg',
                      width: 20,
                      height: 20,
                      colorFilter:
                          ColorFilter.mode(theme.warning, BlendMode.srcIn),
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
                      '${l10n.chainInfoModalContentDecimalsLabel} ${token.decimals}',
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
        ),
      ],
    );
  }

  Widget _buildNetworkInfoSection(AppTheme theme, AppLocalizations l10n) {
    final chainIds = _config.chainIds.map((id) => id.toString()).join(', ');

    return DetailGroupCard(
      title: l10n.chainInfoModalContentNetworkInfoTitle,
      theme: theme,
      children: [
        DetailItem(
          label: l10n.chainInfoModalContentChainLabel,
          value: _config.chain,
          theme: theme,
        ),
        DetailItem(
          label: l10n.chainInfoModalContentShortNameLabel,
          value: _config.shortName,
          theme: theme,
        ),
        DetailItem(
          label: l10n.chainInfoModalContentChainIdLabel,
          value: _config.chainId.toString(),
          theme: theme,
        ),
        DetailItem(
          label: l10n.chainInfoModalContentSlip44Label,
          value: _config.slip44.toString(),
          theme: theme,
        ),
        DetailItem(
          label: l10n.chainInfoModalContentChainIdsLabel,
          value: chainIds,
          theme: theme,
        ),
        if (_config.testnet != null)
          DetailItem(
            label: l10n.chainInfoModalContentTestnetLabel,
            value: _config.testnet!
                ? l10n.chainInfoModalContentYes
                : l10n.chainInfoModalContentNo,
            theme: theme,
          ),
        if (_config.diffBlockTime != BigInt.zero)
          DetailItem(
            label: l10n.chainInfoModalContentDiffBlockTimeLabel,
            value: _config.diffBlockTime.toString(),
            theme: theme,
          ),
        DetailItem(
          label: l10n.chainInfoModalContentFallbackEnabledLabel,
          valueWidget: Switch(
            value: _config.fallbackEnabled,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            onChanged: (value) async {
              setState(() {
                _config = _config.copyWith(fallbackEnabled: value);
              });
              await createOrUpdateChain(providerConfig: _config);
            },
            activeColor: theme.primaryPurple,
          ),
          theme: theme,
        ),
      ],
    );
  }

  Widget _buildExplorersSection(AppTheme theme, AppLocalizations l10n) {
    return DetailGroupCard(
      title: l10n.chainInfoModalContentExplorersTitle,
      theme: theme,
      children: _config.explorers.map((explorer) {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.textSecondary.withValues(alpha: 0.2),
            ),
            borderRadius: BorderRadius.circular(8),
            color: Colors.transparent,
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
                    colorFilter:
                        ColorFilter.mode(theme.warning, BlendMode.srcIn),
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
                        fontWeight: FontWeight.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      explorer.url,
                      style:
                          TextStyle(color: theme.textSecondary, fontSize: 10),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRpcNodesSection(AppTheme theme, AppLocalizations l10n) {
    return DetailGroupCard(
      title: l10n.chainInfoModalContentRpcNodesTitle,
      theme: theme,
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: _config.rpc.length,
          itemBuilder: (context, index) {
            final rpc = _config.rpc[index];
            final isSelected = index == 0;
            final canDelete = _config.rpc.length > 5;

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _selectRpc(index),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 3),
                padding: const EdgeInsets.all(10),
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

  Widget _buildDeleteProviderSection(AppState appState, AppLocalizations l10n) {
    final theme = appState.currentTheme;
    final canRemove = _canRemove(appState);

    return DetailGroupCard(
      title: l10n.chainInfoModalContentDeleteProviderTitle,
      theme: theme,
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: SwipeButton(
                  width: MediaQuery.of(context).size.width * 0.8,
                  text: l10n.chainInfoModalContentSwipeToDelete,
                  onSwipeComplete: () => _deleteProvider(appState),
                  backgroundColor:
                      theme.danger.withValues(alpha: canRemove ? 0.2 : 0.05),
                  textColor:
                      theme.danger.withValues(alpha: canRemove ? 1.0 : 0.5),
                  secondaryColor:
                      theme.danger.withValues(alpha: canRemove ? 1.0 : 0.5),
                  disabled: !canRemove || _isDeleting,
                ),
              ),
            ),
            if (_errorText != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  _errorText!,
                  style: TextStyle(
                    color: theme.danger,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
