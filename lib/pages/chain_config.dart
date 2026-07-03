import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:bearby/components/detail_group_card.dart';
import 'package:bearby/components/detail_item_group_card.dart';
import 'package:bearby/components/glass_message.dart';
import 'package:bearby/components/hover_icon.dart';
import 'package:bearby/components/app_icon.dart';
import 'package:bearby/components/image_cache.dart';
import 'package:bearby/components/swipe_button.dart';
import 'package:bearby/components/token_avatar.dart';
import 'package:bearby/components/custom_app_bar.dart';
import 'package:bearby/mixins/adaptive_size.dart';
import 'package:bearby/mixins/status_bar.dart';
import 'package:bearby/mixins/preprocess_url.dart';
import 'package:bearby/src/rust/api/provider.dart';
import 'package:bearby/src/rust/models/provider.dart';
import 'package:bearby/state/app_state.dart';
import 'package:bearby/theme/app_theme.dart';
import 'package:bearby/l10n/app_localizations.dart';

class ChainConfigPage extends StatefulWidget {
  final NetworkConfigInfo networkConfig;

  const ChainConfigPage({super.key, required this.networkConfig});

  @override
  State<ChainConfigPage> createState() => _ChainConfigPageState();
}

class _ChainConfigPageState extends State<ChainConfigPage>
    with StatusBarMixin {
  late NetworkConfigInfo _config;
  bool _isDeleting = false;
  String? _errorText;
  bool _advancedExpanded = false;

  @override
  void initState() {
    super.initState();
    _config = widget.networkConfig;
  }

  bool _canRemove(AppState appState) {
    for (final wallet in appState.wallets) {
      if (wallet.chainHash == _config.chainHash) return false;
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
      await removeProvider(chainHash: hash);
      await appState.syncData();
      if (mounted) {
        context.pop();
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

  Future<void> _toggleFallback(bool value) async {
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
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final theme = appState.currentTheme;
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const SizedBox.shrink();
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        toolbarHeight: 0,
        systemOverlayStyle: getSystemUiOverlayStyle(context),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: adaptivePadding),
                  child: CustomAppBar(
                    title: _config.chain.isNotEmpty
                        ? _config.chain
                        : l10n.chainInfoModalContentNetworkInfoTitle,
                    onBackPressed: () => context.pop(),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: adaptivePadding,
                      vertical: 8,
                    ),
                    child: Column(
                      children: [
                        _BasicNetworkSection(
                            config: _config, theme: theme, l10n: l10n),
                        const SizedBox(height: 12),
                        _AdvancedSectionButton(
                          theme: theme,
                          l10n: l10n,
                          expanded: _advancedExpanded,
                          onToggle: () {
                            setState(() {
                              _advancedExpanded = !_advancedExpanded;
                            });
                          },
                        ),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          child: _advancedExpanded
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    _AdvancedNetworkSection(
                                      config: _config,
                                      theme: theme,
                                      l10n: l10n,
                                      onFallbackChanged: _toggleFallback,
                                    ),
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
                                  ],
                                )
                              : const SizedBox.shrink(),
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
                        SizedBox(
                          height: MediaQuery.of(context).padding.bottom + 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BasicNetworkSection extends StatelessWidget {
  final NetworkConfigInfo config;
  final AppTheme theme;
  final AppLocalizations l10n;

  const _BasicNetworkSection({
    required this.config,
    required this.theme,
    required this.l10n,
  });

  Widget _tokenItem(BuildContext context) {
    final token = config.ftokens.first;
    final appState = Provider.of<AppState>(context, listen: false);
    return DetailItem(
      label: l10n.chainInfoModalContentTokenTitle,
      theme: theme,
      valueWidget: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (token.logo != null)
            TokenAvatar(
              token: token,
              size: 20,
              appState: appState,
              showNetworkBadge: false,
              showBorder: false,
              iconUrl: processTokenLogo(
                  token: token,
                  shortName: config.shortName,
                  theme: theme.value),
            ),
          const SizedBox(width: 8),
          Text(
            '${token.symbol} (${token.decimals})',
            style: theme.bodyText2.copyWith(color: theme.textPrimary),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DetailGroupCard(
      title: l10n.chainInfoModalContentNetworkInfoTitle,
      theme: theme,
      children: [
        if (config.ftokens.isNotEmpty) _tokenItem(context),
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
      ],
    );
  }
}

class _AdvancedSectionButton extends StatelessWidget {
  final AppTheme theme;
  final AppLocalizations l10n;
  final bool expanded;
  final VoidCallback onToggle;

  const _AdvancedSectionButton({
    required this.theme,
    required this.l10n,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: onToggle,
        icon: AnimatedRotation(
          turns: expanded ? 0.5 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: AppIconView(
            icon: AppIcon.arrowDown,
            color: theme.primaryPurple,
            size: 20,
          ),
        ),
        label: Text(
          l10n.chainConfigPageAdvancedButton,
          style: theme.labelMedium.copyWith(color: theme.primaryPurple),
        ),
      ),
    );
  }
}

class _AdvancedNetworkSection extends StatelessWidget {
  final NetworkConfigInfo config;
  final AppTheme theme;
  final AppLocalizations l10n;
  final void Function(bool value) onFallbackChanged;

  const _AdvancedNetworkSection({
    required this.config,
    required this.theme,
    required this.l10n,
    required this.onFallbackChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: DetailGroupCard(
        title: l10n.chainConfigPageAdvancedButton,
        theme: theme,
        children: [
          DetailItem(
              label: l10n.chainInfoModalContentSlip44Label,
              value: config.slip44.toString(),
              theme: theme),
          DetailItem(
              label: l10n.chainInfoModalContentChainIdsLabel,
              value: config.chainIds.map((id) => id.toString()).join(', '),
              theme: theme),
          DetailItem(
            label: l10n.chainInfoModalContentTestnetLabel,
            value: (config.testnet ?? false)
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
      ),
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
        final String? explorerIcon = explorer.icon;
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            border: Border.all(color: theme.modalBorder.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              if (explorerIcon != null)
                AsyncImage(
                  url: explorerIcon,
                  width: 20,
                  height: 20,
                  fit: BoxFit.cover,
                  errorWidget: AppIconView(
                    icon: AppIcon.warning,
                    size: 16,
                    color: theme.warning,
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
                      HoverIcon(
                        icon: AppIcon.minus,
                        size: 20,
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
            message: errorText ?? '',
            type: GlassMessageType.error,
            margin: const EdgeInsets.only(top: 8, bottom: 8),
          ),
      ],
    );
  }
}