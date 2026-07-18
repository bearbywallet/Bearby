import 'package:bearby/components/app_icon.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bearby/components/image_cache.dart';
import 'package:bearby/components/smart_input.dart';
import 'package:bearby/src/rust/api/walletconnect.dart';
import 'package:bearby/src/rust/models/walletconnect/ffi.dart';
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
  String _searchQuery = '';
  List<WcSessionInfo> _wcSessions = const [];

  @override
  void initState() {
    super.initState();
    _loadWcSessions();
  }

  Future<void> _loadWcSessions() async {
    try {
      final sessions = await wcSessions();
      if (mounted) setState(() => _wcSessions = sessions);
    } catch (_) {
      // Engine may not be started yet.
    }
  }

  Future<void> _disconnectWc(String topic) async {
    try {
      await wcDisconnect(topic: topic);
      await _loadWcSessions();
    } catch (e) {
      debugPrint('wc disconnect: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<AppState>(context, listen: false).currentTheme;
    final appState = Provider.of<AppState>(context, listen: false);
    final connectedDapps = appState.connections;
    final q = _searchQuery.toLowerCase();

    final filteredDapps = connectedDapps
        .where((dapp) =>
            dapp.domain.toLowerCase().contains(q) ||
            dapp.title.toLowerCase().contains(q))
        .toList();
    final filteredWc = _wcSessions
        .where((s) =>
            s.peerName.toLowerCase().contains(q) ||
            s.peerUrl.toLowerCase().contains(q) ||
            s.topic.toLowerCase().contains(q))
        .toList();

    final total = filteredDapps.length + filteredWc.length;

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
            margin: EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: theme.modalBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: SmartInput(
              controller: _searchController,
              hint: AppLocalizations.of(context)!.connectedDappsModalSearchHint,
              onChanged: (value) => setState(() => _searchQuery = value),
              borderColor: theme.textPrimary,
              focusedBorderColor: theme.primaryPurple,
              height: 48,
              fontSize: 16,
              padding: EdgeInsets.symmetric(horizontal: 16),
              leftIcon: AppIcon.search,
              rightIcon: AppIcon.close,
              onRightIconTap: () {
                _searchController.text = "";
              },
            ),
          ),
          Expanded(
            child: total == 0
                ? Center(
                    child: Text(
                      AppLocalizations.of(context)!.connectedDappsModalNoDapps,
                      style:
                          theme.bodyLarge.copyWith(color: theme.textSecondary),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: total,
                    itemBuilder: (context, index) {
                      if (index < filteredDapps.length) {
                        final dapp = filteredDapps[index];
                        return Column(
                          children: [
                            _DappListItem(
                              name: dapp.title,
                              url: dapp.domain,
                              iconUrl: dapp.favicon ?? "",
                              lastConnected:
                                  fromLargeBigInt(dapp.lastConnected),
                              onDisconnect: () =>
                                  widget.onDappDisconnect?.call(dapp.domain),
                            ),
                            if (index < total - 1)
                              Divider(
                                height: 1,
                                color:
                                    theme.textSecondary.withValues(alpha: 0.1),
                              ),
                          ],
                        );
                      }
                      final s = filteredWc[index - filteredDapps.length];
                      return Column(
                        children: [
                          _DappListItem(
                            name: s.peerName.isEmpty ? 'WalletConnect' : s.peerName,
                            url: s.peerUrl.isEmpty ? s.topic : s.peerUrl,
                            iconUrl: s.peerIcon ?? '',
                            lastConnected: DateTime.fromMillisecondsSinceEpoch(
                              s.expiry.toInt() * 1000,
                              isUtc: true,
                            ),
                            onDisconnect: () => _disconnectWc(s.topic),
                          ),
                          if (index < total - 1)
                            Divider(
                              height: 1,
                              color:
                                  theme.textSecondary.withValues(alpha: 0.1),
                            ),
                        ],
                      );
                    },
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

class _DappListItem extends StatelessWidget {
  final String name;
  final String url;
  final String iconUrl;
  final DateTime lastConnected;
  final VoidCallback? onDisconnect;

  const _DappListItem({
    required this.name,
    required this.url,
    required this.iconUrl,
    required this.lastConnected,
    this.onDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    final appTheme = Provider.of<AppState>(context).currentTheme;
    const double iconSize = 40.0;

    return Container(
      margin: EdgeInsets.zero,
      padding: EdgeInsets.symmetric(vertical: 12),
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
          SizedBox(width: 12),
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
                SizedBox(height: 4),
                Text(
                  url,
                  style: appTheme.bodyText2
                      .copyWith(color: appTheme.textSecondary),
                ),
                SizedBox(height: 2),
                Text(
                  AppLocalizations.of(context)!.dappListItemConnected(
                      _formatLastConnected(context, lastConnected)),
                  style: appTheme.labelSmall
                      .copyWith(color: appTheme.textSecondary),
                ),
              ],
            ),
          ),
          IconButton(
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

  String _formatLastConnected(BuildContext context, DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return AppLocalizations.of(context)!.dappListItemJustNow;
    }
  }
}
