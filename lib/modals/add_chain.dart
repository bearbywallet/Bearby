import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/enable_card.dart';
import 'package:zilpay/components/image_cache.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import 'package:zilpay/mixins/preprocess_url.dart';
import 'package:zilpay/src/rust/models/provider.dart';
import 'package:zilpay/state/app_state.dart';
import 'package:zilpay/components/swipe_button.dart';
import 'package:zilpay/theme/app_theme.dart';
import 'package:zilpay/l10n/app_localizations.dart';

void showAddChainModal({
  required BuildContext context,
  required String title,
  required String appIcon,
  required NetworkConfigInfo chain,
  required Function(List<String>) onConfirm,
  required VoidCallback onReject,
}) {
  showModalBottomSheet<List<String>>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    enableDrag: true,
    isDismissible: true,
    useSafeArea: true,
    barrierColor: Colors.black54,
    builder: (context) => _AddChainModalContent(
      onConfirm: onConfirm,
      title: title,
      appIcon: appIcon,
      chain: chain,
    ),
  ).then((selectedRpcs) {
    if (selectedRpcs == null) {
      onReject();
    }
  });
}

class _AddChainModalContent extends StatefulWidget {
  final String title;
  final String appIcon;
  final NetworkConfigInfo chain;
  final Function(List<String>) onConfirm;

  const _AddChainModalContent({
    required this.title,
    required this.appIcon,
    required this.chain,
    required this.onConfirm,
  });

  @override
  State<_AddChainModalContent> createState() => _AddChainModalContentState();
}

class _AddChainModalContentState extends State<_AddChainModalContent> {
  late List<bool> rpcSelections;

  @override
  void initState() {
    super.initState();
    rpcSelections = List.filled(widget.chain.rpc.length, true);
  }

  String _extractDomain(String url) {
    Uri uri = Uri.parse(url);
    return uri.host.isNotEmpty ? uri.host : url;
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = appState.currentTheme;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);
    final l10n = AppLocalizations.of(context)!;

    return Container(
      constraints:
          BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: theme.modalBorder, width: 2),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(adaptivePadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: children(theme, l10n),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 16),
              itemCount: widget.chain.rpc.length,
              itemBuilder: (context, index) {
                final rpc = widget.chain.rpc[index];
                final domain = _extractDomain(rpc);
                return EnableCard(
                  title: domain,
                  name: rpc,
                  isDefault: false,
                  isEnabled: rpcSelections[index],
                  onToggle: (value) {
                    setState(() {
                      rpcSelections[index] = value;
                    });
                  },
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8 + bottomPadding),
            decoration: BoxDecoration(
              color: theme.cardBackground,
              boxShadow: const [
                BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, -2)),
              ],
            ),
            child: Column(
              children: [
                Text(
                  l10n.addChainModalContentWarning,
                  style: TextStyle(color: theme.danger, fontSize: 14),
                ),
                SizedBox(height: adaptivePadding),
                Center(
                  child: SwipeButton(
                    text: l10n.addChainModalContentApprove,
                    backgroundColor: theme.primaryPurple,
                    textColor: theme.buttonText,
                    onSwipeComplete: () async {
                      final selected = widget.chain.rpc
                          .asMap()
                          .entries
                          .where((entry) => rpcSelections[entry.key])
                          .map((entry) => entry.value)
                          .toList();
                      widget.onConfirm(selected);
                      Navigator.pop(context, selected);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> children(AppTheme theme, AppLocalizations l10n) {
    return [
      Container(
        width: 36,
        height: 4,
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: theme.modalBorder,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      Text(
        widget.title,
        style: TextStyle(
          color: theme.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: theme.primaryPurple, width: 2),
            ),
            child: ClipOval(
              child: AsyncImage(
                url: widget.appIcon,
                width: 64,
                height: 64,
                fit: BoxFit.cover,
                loadingWidget: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.primaryPurple,
                  ),
                ),
                errorWidget: Icon(
                  Icons.broken_image,
                  color: theme.textSecondary,
                  size: 24,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SvgPicture.asset(
            'assets/icons/right_circle_arrow.svg',
            width: 32,
            height: 32,
            colorFilter: ColorFilter.mode(theme.textPrimary, BlendMode.srcIn),
          ),
          const SizedBox(width: 12),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: theme.primaryPurple, width: 2),
            ),
            child: ClipOval(
              child: AsyncImage(
                url: preprocessUrl(widget.chain.logo, theme.value),
                width: 64,
                height: 64,
                fit: BoxFit.cover,
                loadingWidget: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.primaryPurple,
                  ),
                ),
                errorWidget: SvgPicture.asset(
                  'assets/icons/warning.svg',
                  width: 24,
                  height: 24,
                  colorFilter: ColorFilter.mode(
                    theme.warning,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      Text(
        widget.chain.name,
        style: TextStyle(
          color: theme.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: theme.textSecondary.withValues(alpha: 0.2)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.addChainModalContentDetails,
              style: TextStyle(
                color: theme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text('${l10n.addChainModalContentNetworkName} ${widget.chain.name}',
                style: TextStyle(color: theme.textSecondary)),
            Text(
                '${l10n.addChainModalContentCurrencySymbol} ${widget.chain.shortName}',
                style: TextStyle(color: theme.textSecondary)),
            Text('${l10n.addChainModalContentChainId} ${widget.chain.chainId}',
                style: TextStyle(color: theme.textSecondary)),
            if (widget.chain.explorers.isNotEmpty)
              Text(
                  '${l10n.addChainModalContentBlockExplorer} ${widget.chain.explorers.first.url}',
                  style: TextStyle(color: theme.textSecondary)),
          ],
        ),
      ),
    ];
  }
}
