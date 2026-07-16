import 'package:bearby/components/app_icon.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bearby/components/image_cache.dart';
import 'package:bearby/components/smart_input.dart';
import 'package:bearby/modals/qr_scanner_modal.dart';
import 'package:bearby/services/walletconnect_service.dart';
import 'package:bearby/state/app_state.dart';
import 'package:bearby/l10n/app_localizations.dart';

void showConnectedDappsModal({
  required BuildContext context,
  Function(String)? onDappDisconnect,
}) {
  showModalBottomSheet(
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
        child: _ConnectedDappsModalContent(
          onDappDisconnect: onDappDisconnect,
        ),
      );
    },
  );
}

class _ConnectedDappsModalContent extends StatefulWidget {
  final Function(String)? onDappDisconnect;

  const _ConnectedDappsModalContent({
    this.onDappDisconnect,
  });

  @override
  State<_ConnectedDappsModalContent> createState() =>
      _ConnectedDappsModalContentState();
}

class _ConnectedDappsModalContentState
    extends State<_ConnectedDappsModalContent> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _wcUriController = TextEditingController();
  String _searchQuery = '';
  bool _isPairing = false;

  @override
  void dispose() {
    _searchController.dispose();
    _wcUriController.dispose();
    super.dispose();
  }

  Future<void> _pairUri(String raw) async {
    final uri = raw.trim();
    if (uri.isEmpty || _isPairing) return;
    setState(() => _isPairing = true);
    try {
      await context.read<WalletConnectService>().pair(uri);
      _wcUriController.clear();
    } catch (e) {
      if (!mounted) return;
      final theme = context.read<AppState>().currentTheme;
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n?.wcPairFailed ?? 'WalletConnect pair failed',
            style: theme.bodyLarge.copyWith(color: theme.buttonText),
          ),
          backgroundColor: theme.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _isPairing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final theme = appState.currentTheme;
    final wcService = context.watch<WalletConnectService>();
    final l10n = AppLocalizations.of(context);
    final query = _searchQuery.toLowerCase();

    final connectedDapps = appState.connections;
    final filteredDapps = connectedDapps
        .where((dapp) =>
            dapp.domain.toLowerCase().contains(query) ||
            dapp.title.toLowerCase().contains(query))
        .toList(growable: false);

    final wcSessions = wcService.sessionViews
        .where((s) =>
            s.name.toLowerCase().contains(query) ||
            s.url.toLowerCase().contains(query))
        .toList(growable: false);

    final isEmpty = filteredDapps.isEmpty && wcSessions.isEmpty;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
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
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: theme.modalBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SmartInput(
              controller: _searchController,
              hint: l10n?.connectedDappsModalSearchHint ?? 'Search DApps',
              onChanged: (value) => setState(() => _searchQuery = value),
              borderColor: theme.textPrimary,
              focusedBorderColor: theme.primaryPurple,
              height: 48,
              fontSize: 16,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              leftIcon: AppIcon.search,
              rightIcon: AppIcon.close,
              onRightIconTap: () {
                _searchController.text = '';
                setState(() => _searchQuery = '');
              },
            ),
          ),
          Expanded(
            child: isEmpty
                ? Center(
                    child: Text(
                      l10n?.connectedDappsModalNoDapps ?? 'No connected DApps',
                      style:
                          theme.bodyLarge.copyWith(color: theme.textSecondary),
                    ),
                  )
                : ListView(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    children: [
                      if (wcSessions.isNotEmpty) ...[
                        _SectionHeader(
                          title: l10n?.wcSectionTitle ?? 'WalletConnect',
                        ),
                        for (var i = 0; i < wcSessions.length; i++) ...[
                          _DappListItem(
                            name: wcSessions[i].name,
                            url: wcSessions[i].url,
                            iconUrl: wcSessions[i].icon,
                            lastConnected: null,
                            disconnectLabel: l10n?.wcDisconnect ?? 'Disconnect',
                            onDisconnect: () {
                              wcService.disconnectSession(wcSessions[i].topic);
                            },
                          ),
                          if (i < wcSessions.length - 1)
                            Divider(
                              height: 1,
                              color: theme.textSecondary.withValues(alpha: 0.1),
                            ),
                        ],
                        const SizedBox(height: 16),
                      ],
                      if (filteredDapps.isNotEmpty) ...[
                        _SectionHeader(
                          title: l10n?.wcBrowserSectionTitle ?? 'Browser',
                        ),
                        for (var i = 0; i < filteredDapps.length; i++) ...[
                          _DappListItem(
                            name: filteredDapps[i].title,
                            url: filteredDapps[i].domain,
                            iconUrl: filteredDapps[i].favicon ?? '',
                            lastConnected: fromLargeBigInt(
                              filteredDapps[i].lastConnected,
                            ),
                            onDisconnect: () => widget.onDappDisconnect
                                ?.call(filteredDapps[i].domain),
                          ),
                          if (i < filteredDapps.length - 1)
                            Divider(
                              height: 1,
                              color: theme.textSecondary.withValues(alpha: 0.1),
                            ),
                        ],
                      ],
                    ],
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n?.wcNewConnection ?? 'New connection',
                  style: theme.titleMedium.copyWith(color: theme.textPrimary),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: SmartInput(
                        controller: _wcUriController,
                        hint: l10n?.wcPasteUri ?? 'Paste wc: URI',
                        borderColor: theme.textPrimary,
                        focusedBorderColor: theme.primaryPurple,
                        height: 48,
                        fontSize: 14,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        onSubmitted: _pairUri,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _isPairing
                          ? null
                          : () {
                              showQRScannerModal(
                                context: context,
                                onScanned: (code) {
                                  _pairUri(code);
                                },
                              );
                            },
                      icon: AppIconView(
                        icon: AppIcon.scan,
                        size: 24,
                        color: theme.primaryPurple,
                      ),
                    ),
                    IconButton(
                      onPressed: _isPairing
                          ? null
                          : () => _pairUri(_wcUriController.text),
                      icon: _isPairing
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.primaryPurple,
                              ),
                            )
                          : AppIconView(
                              icon: AppIcon.plus,
                              size: 24,
                              color: theme.primaryPurple,
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  DateTime fromLargeBigInt(BigInt timestamp) {
    return DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp.toString()));
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = context.read<AppState>().currentTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        title,
        style: theme.bodyLarge.copyWith(
          color: theme.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _DappListItem extends StatelessWidget {
  final String name;
  final String url;
  final String iconUrl;
  final DateTime? lastConnected;
  final String? disconnectLabel;
  final VoidCallback? onDisconnect;

  const _DappListItem({
    required this.name,
    required this.url,
    required this.iconUrl,
    this.lastConnected,
    this.disconnectLabel,
    this.onDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    final appTheme = context.watch<AppState>().currentTheme;
    const double iconSize = 40.0;

    return Container(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AsyncImage(
            url: iconUrl,
            width: iconSize,
            height: iconSize,
            fit: BoxFit.cover,
            loadingWidget: Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                color: appTheme.textSecondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: appTheme.textSecondary.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
            errorWidget: Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                color: appTheme.textSecondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(
                  Icons.link,
                  size: 24,
                  color: appTheme.textSecondary.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style:
                      appTheme.bodyLarge.copyWith(color: appTheme.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  url,
                  style: appTheme.bodyText2
                      .copyWith(color: appTheme.textSecondary),
                ),
                if (lastConnected != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    AppLocalizations.of(context)?.dappListItemConnected(
                          _formatLastConnected(context, lastConnected),
                        ) ??
                        'Connected ${_formatLastConnected(context, lastConnected)}',
                    style: appTheme.labelSmall
                        .copyWith(color: appTheme.textSecondary),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: disconnectLabel,
            onPressed: onDisconnect,
            icon: AppIconView(
              icon: AppIcon.disconnect,
              size: 24,
              color: appTheme.danger,
            ),
          ),
        ],
      ),
    );
  }

  String _formatLastConnected(BuildContext context, DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return AppLocalizations.of(context)?.dappListItemJustNow ?? 'just now';
    }
  }
}
