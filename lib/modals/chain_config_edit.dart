import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:bearby/components/detail_group_card.dart';
import 'package:bearby/components/detail_item_group_card.dart';
import 'package:bearby/components/glass_message.dart';
import 'package:bearby/components/hoverd_svg.dart';
import 'package:bearby/components/image_cache.dart';
import 'package:bearby/components/modal_drag_handle.dart';
import 'package:bearby/components/swipe_button.dart';
import 'package:bearby/mixins/preprocess_url.dart';
import 'package:bearby/src/rust/api/provider.dart';
import 'package:bearby/src/rust/models/provider.dart';
import 'package:bearby/state/app_state.dart';
import 'package:bearby/theme/app_theme.dart';
import 'package:bearby/l10n/app_localizations.dart';

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
  }

  bool _canRemove(AppState appState) {
    for (final wallet in appState.wallets) {
      if (wallet.defaultChainHash == _config.chainHash) return false;
      for (final account in wallet.accounts) {
        if (account.chainHash == _config.chainHash) return false;
      }
    }
    return true;
  }

  Future<void> _removeRpc(String rpc) async {
    if (_config.rpc.length <= 5) return;
    setState(() => _config.rpc.remove(rpc));
    await createOrUpdateChain(providerConfig: _config);
  }

  Future<void> _selectRpc(int index) async {
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
    final index =
        appState.state.providers.indexWhere((p) => p.chainHash == hash);

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
        setState(() => _isDeleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final theme = appState.currentTheme;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: BoxDecoration(
        color: theme.cardBackground.withValues(alpha: 0.85),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ModalDragHandle(theme: theme),
              if (_config.chain.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    _config.chain,
                    style: theme.titleMedium.copyWith(color: theme.textPrimary),
                  ),
                ),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      if (_config.ftokens.isNotEmpty)
                        _TokenSection(
                            config: _config, theme: theme, l10n: l10n),
                      if (_config.ftokens.isNotEmpty)
                        const SizedBox(height: 12),
                      _NetworkInfoSection(
                          config: _config,
                          theme: theme,
                          l10n: l10n,
                          onFallbackChanged: (value) async {
                            setState(() {
                              _config = NetworkConfigInfo(
                                name: _config.name,
                                logo: _config.logo,
                                chain: _config.chain,
                                shortName: _config.shortName,
                                rpc: _config.rpc,
                                features: _config.features,
                                chainId: _config.chainId,
                                chainIds: _config.chainIds,
                                slip44: _config.slip44,
                                diffBlockTime: _config.diffBlockTime,
                                chainHash: _config.chainHash,
                                ens: _config.ens,
                                explorers: _config.explorers,
                                fallbackEnabled: value,
                                testnet: _config.testnet,
                                ftokens: _config.ftokens,
                              );
                            });
                            await createOrUpdateChain(providerConfig: _config);
                          }),
                      const SizedBox(height: 12),
                      _ExplorersSection(
                          config: _config, theme: theme, l10n: l10n),
                      const SizedBox(height: 12),
                      _RpcSection(
                        config: _config,
                        theme: theme,
                        l10n: l10n,
                        onSelect: _selectRpc,
                        onRemove: _removeRpc,
                      ),
                      const SizedBox(height: 12),
                      _DeleteSection(
                        appState: appState,
                        theme: theme,
                        l10n: l10n,
                        canRemove: _canRemove(appState),
                        isDeleting: _isDeleting,
                        errorText: _errorText,
                        onDelete: () => _deleteProvider(appState),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _TokenSection extends StatelessWidget {
  final NetworkConfigInfo config;
  final AppTheme theme;
  final AppLocalizations l10n;

  const _TokenSection({
    required this.config,
    required this.theme,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final token = config.ftokens.first;

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
                        shortName: config.shortName,
                        theme: theme.value),
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
                        strokeWidth: 2, color: theme.primaryPurple),
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(token.name,
                        style:
                            theme.labelLarge.copyWith(color: theme.textPrimary),
                        overflow: TextOverflow.ellipsis),
                    Text(token.symbol,
                        style: theme.bodyText2
                            .copyWith(color: theme.textSecondary)),
                    Text(
                        '${l10n.chainInfoModalContentDecimalsLabel} ${token.decimals}',
                        style: theme.labelSmall
                            .copyWith(color: theme.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NetworkInfoSection extends StatelessWidget {
  final NetworkConfigInfo config;
  final AppTheme theme;
  final AppLocalizations l10n;
  final void Function(bool value) onFallbackChanged;

  const _NetworkInfoSection({
    required this.config,
    required this.theme,
    required this.l10n,
    required this.onFallbackChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DetailGroupCard(
      title: l10n.chainInfoModalContentNetworkInfoTitle,
      theme: theme,
      children: [
        DetailItem(
            label: l10n.chainInfoModalContentChainLabel,
            value: config.chain,
            theme: theme),
        DetailItem(
            label: l10n.chainInfoModalContentShortNameLabel,
            value: config.shortName,
            theme: theme),
        DetailItem(
            label: l10n.chainInfoModalContentChainIdLabel,
            value: config.chainId.toString(),
            theme: theme),
        DetailItem(
            label: l10n.chainInfoModalContentSlip44Label,
            value: config.slip44.toString(),
            theme: theme),
        DetailItem(
            label: l10n.chainInfoModalContentChainIdsLabel,
            value: config.chainIds.map((id) => id.toString()).join(', '),
            theme: theme),
        if (config.testnet != null)
          DetailItem(
            label: l10n.chainInfoModalContentTestnetLabel,
            value: config.testnet!
                ? l10n.chainInfoModalContentYes
                : l10n.chainInfoModalContentNo,
            theme: theme,
          ),
        if (config.diffBlockTime != BigInt.zero)
          DetailItem(
              label: l10n.chainInfoModalContentDiffBlockTimeLabel,
              value: config.diffBlockTime.toString(),
              theme: theme),
        DetailItem(
          label: l10n.chainInfoModalContentFallbackEnabledLabel,
          theme: theme,
          valueWidget: Switch(
            value: config.fallbackEnabled,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            activeThumbColor: theme.primaryPurple,
            onChanged: onFallbackChanged,
          ),
        ),
      ],
    );
  }
}

class _ExplorersSection extends StatelessWidget {
  final NetworkConfigInfo config;
  final AppTheme theme;
  final AppLocalizations l10n;

  const _ExplorersSection({
    required this.config,
    required this.theme,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return DetailGroupCard(
      title: l10n.chainInfoModalContentExplorersTitle,
      theme: theme,
      children: config.explorers.map((explorer) {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            border: Border.all(color: theme.modalBorder.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(8),
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
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(explorer.name,
                        style:
                            theme.labelSmall.copyWith(color: theme.textPrimary),
                        overflow: TextOverflow.ellipsis),
                    Text(explorer.url,
                        style:
                            theme.overline.copyWith(color: theme.textSecondary),
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _RpcSection extends StatelessWidget {
  final NetworkConfigInfo config;
  final AppTheme theme;
  final AppLocalizations l10n;
  final Future<void> Function(int index) onSelect;
  final Future<void> Function(String rpc) onRemove;

  const _RpcSection({
    required this.config,
    required this.theme,
    required this.l10n,
    required this.onSelect,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return DetailGroupCard(
      title: l10n.chainInfoModalContentRpcNodesTitle,
      theme: theme,
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: config.rpc.length,
          itemBuilder: (context, index) {
            final rpc = config.rpc[index];
            final isSelected = index == 0;
            final canDelete = config.rpc.length > 5;

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onSelect(index),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 3),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(
                      color: isSelected
                          ? theme.primaryPurple
                          : theme.modalBorder.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(8),
                  color: isSelected
                      ? theme.primaryPurple.withValues(alpha: 0.1)
                      : Colors.transparent,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        rpc,
                        style: theme.bodyText2.copyWith(
                          color: theme.textPrimary,
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
                        onTap: () => onRemove(rpc),
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
}

class _DeleteSection extends StatelessWidget {
  final AppState appState;
  final AppTheme theme;
  final AppLocalizations l10n;
  final bool canRemove;
  final bool isDeleting;
  final String? errorText;
  final Future<void> Function() onDelete;

  const _DeleteSection({
    required this.appState,
    required this.theme,
    required this.l10n,
    required this.canRemove,
    required this.isDeleting,
    required this.errorText,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return DetailGroupCard(
      title: l10n.chainInfoModalContentDeleteProviderTitle,
      theme: theme,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: SwipeButton(
              width: MediaQuery.of(context).size.width * 0.8,
              text: l10n.chainInfoModalContentSwipeToDelete,
              onSwipeComplete: onDelete,
              disabled: !canRemove || isDeleting,
            ),
          ),
        ),
        if (errorText != null)
          GlassMessage(
            message: errorText!,
            type: GlassMessageType.error,
            margin: const EdgeInsets.only(top: 8, bottom: 8),
          ),
      ],
    );
  }
}
